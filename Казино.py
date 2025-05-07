from hikkatl.types import Message
from .. import loader, utils
import logging
import random
import time

logger = logging.getLogger(__name__)

@loader.tds
class CasinoModule(loader.Module):
    """Казино с рулеткой, слотами, криптой и бинго"""
    strings = {
        "name": "Казино",
        "balance": "💰 Баланс: <code>{balance}</code> ₽",
        "work_success": "🛠 Вы {work_type} и заработали <code>{amount}</code> ₽!\nБаланс: <code>{new_balance}</code>",
        "work_cooldown": "⏳ Подождите <code>{time}</code> до следующей работы",
        "daily_reward": "🎁 Ежедневный бонус: <code>{amount}</code> ₽!\nБаланс: <code>{new_balance}</code>",
        "daily_already": "ℹ️ Вы уже получали бонус сегодня",
        "roulette_win": "🎉 Выигрыш! Выпало <code>{number}</code>\n+<code>{amount}</code> ₽ (×9)\nБаланс: <code>{new_balance}</code>",
        "roulette_lose": "💥 Проигрыш. Выпало <code>{number}</code>\n-<code>{amount}</code> ₽\nБаланс: <code>{new_balance}</code>",
        "slots_win": "{slots}\nВыигрыш <code>{amount}</code> ₽ (×{mult})\nБаланс: <code>{new_balance}</code>",
        "slots_lose": "{slots}\nПроигрыш -<code>{amount}</code> ₽\nБаланс: <code>{new_balance}</code>",
        "crypto_up": "📈 {coin} +{change}%\nПрибыль: +<code>{amount}</code> ₽\nБаланс: <code>{new_balance}</code>",
        "crypto_down": "📉 {coin} -{change}%\nУбыток: -<code>{amount}</code> ₽\nБаланс: <code>{new_balance}</code>",
        "bingo_start": "🎫 Бинго! Ставка: <code>{bet}</code> ₽\nНомера:\n{numbers}\nИспользуй .б для следующего числа",
        "bingo_win": "🎉 Бинго! Выпало <code>{number}</code> (есть в карточке)\nВыигрыш: <code>{amount}</code> ₽ (×{mult})\nБаланс: <code>{new_balance}</code>",
        "bingo_lose": "❌ Выпало <code>{number}</code> (нет в карточке)\nБаланс: <code>{new_balance}</code>",
        "bingo_full": "🏆 Полное бинго! +<code>{amount}</code> ₽ (×10)\nБаланс: <code>{new_balance}</code>",
        "no_money": "❌ Недостаточно средств. Баланс: <code>{balance}</code> ₽",
        "invalid_args": "❌ Неверные аргументы"
    }

    def __init__(self):
        self.db = None
        self.config = loader.ModuleConfig(
            loader.ConfigValue(
                "START_BALANCE",
                1000,
                lambda: loader.validators.Integer(minimum=500)
            ),
            loader.ConfigValue(
                "WORK_MIN",
                100,
                lambda: loader.validators.Integer(minimum=50)
            ),
            loader.ConfigValue(
                "WORK_MAX",
                300,
                lambda: loader.validators.Integer(minimum=100)
            ),
            loader.ConfigValue(
                "WORK_COOLDOWN",
                10800,
                lambda: loader.validators.Integer(minimum=3600)
            ),
            loader.ConfigValue(
                "DAILY_MIN",
                150,
                lambda: loader.validators.Integer(minimum=50)
            ),
            loader.ConfigValue(
                "DAILY_MAX",
                500,
                lambda: loader.validators.Integer(minimum=100)
            )
        )
        self.jobs = [
            ("программировали", "💻 Написали код"),
            ("торговали", "📈 Продали акции"),
            ("майнили", "⛏ Добыли крипту")
        ]
        self.slots_symbols = ["🍒", "🍋", "🍊", "🍇", "🍉", "7️⃣"]
        self.crypto_coins = ["BTC", "ETH", "DOGE", "SHIB", "SOL"]
        self.bingo_multipliers = {5: 2, 10: 5, 15: 10}

    async def client_ready(self, client, db):
        self._client = client
        self._db = db
        if "casino" not in self._db:
            self._db.set("casino", "balance", self.config["START_BALANCE"])
            self._db.set("casino", "last_work", 0)
            self._db.set("casino", "last_daily", 0)
            self._db.set("casino", "bingo_game", None)

    async def get_balance(self) -> int:
        return self._db.get("casino", "balance", self.config["START_BALANCE"])

    async def set_balance(self, amount: int):
        self._db.set("casino", "balance", amount)

    async def update_balance(self, amount: int) -> int:
        balance = await self.get_balance()
        new_balance = max(0, balance + amount)
        await self.set_balance(new_balance)
        return new_balance

    @loader.command()
    async def баланс(self, message: Message):
        """Проверить баланс"""
        balance = await self.get_balance()
        await utils.answer(message, self.strings["balance"].format(balance=balance))

    @loader.command()
    async def рулетка(self, message: Message):
        """<ставка> <число 1-10> - Классическая рулетка"""
        try:
            args = utils.get_args_raw(message).split()
            if len(args) != 2:
                await utils.answer(message, "❌ Используйте: .рулетка <ставка> <1-10>")
                return

            bet, number = map(int, args)
            balance = await self.get_balance()

            if bet <= 0 or number < 1 or number > 10:
                await utils.answer(message, self.strings["invalid_args"])
                return
            if bet > balance:
                await utils.answer(message, self.strings["no_money"].format(balance=balance))
                return

            win_number = random.randint(1, 10)
            if number == win_number:
                win = bet * 9
                new_balance = await self.update_balance(win)
                await utils.answer(
                    message,
                    self.strings["roulette_win"].format(
                        number=win_number,
                        amount=win,
                        new_balance=new_balance
                    )
                )
            else:
                new_balance = await self.update_balance(-bet)
                await utils.answer(
                    message,
                    self.strings["roulette_lose"].format(
                        number=win_number,
                        amount=bet,
                        new_balance=new_balance
                    )
                )
        except Exception as e:
            logger.exception("Roulette error:")
            await utils.answer(message, self.strings["invalid_args"])

    @loader.command()
    async def слоты(self, message: Message):
        """<ставка> - Игровые автоматы"""
        try:
            bet = int(utils.get_args_raw(message))
            balance = await self.get_balance()

            if bet <= 0:
                await utils.answer(message, self.strings["invalid_args"])
                return
            if bet > balance:
                await utils.answer(message, self.strings["no_money"].format(balance=balance))
                return

            slots = [random.choice(self.slots_symbols) for _ in range(3)]
            unique = len(set(slots))
            slots_display = "|".join(slots)  # Изменено на разделитель "|"

            if unique == 1:  # 3 одинаковых
                mult = 10
            elif unique == 2:  # 2 одинаковых
                mult = 3
            else:
                mult = 0

            if mult > 0:
                win = bet * mult
                new_balance = await self.update_balance(win)
                await utils.answer(
                    message,
                    self.strings["slots_win"].format(
                        slots=slots_display,
                        amount=win,
                        mult=mult,
                        new_balance=new_balance
                    )
                )
            else:
                new_balance = await self.update_balance(-bet)
                await utils.answer(
                    message,
                    self.strings["slots_lose"].format(
                        slots=slots_display,
                        amount=bet,
                        new_balance=new_balance
                    )
                )
        except Exception as e:
            logger.exception("Slots error:")
            await utils.answer(message, self.strings["invalid_args"])

    @loader.command()
    async def крипта(self, message: Message):
        """<сумма> - Инвестиции в криптовалюту"""
        try:
            amount = int(utils.get_args_raw(message))
            balance = await self.get_balance()

            if amount <= 0:
                await utils.answer(message, self.strings["invalid_args"])
                return
            if amount > balance:
                await utils.answer(message, self.strings["no_money"].format(balance=balance))
                return

            coin = random.choice(self.crypto_coins)
            change = random.uniform(0.5, 2.0)
            profit = int(amount * change) - amount
            new_balance = await self.update_balance(profit)

            if profit >= 0:
                await utils.answer(
                    message,
                    self.strings["crypto_up"].format(
                        coin=coin,
                        change=int((change-1)*100),
                        amount=profit,
                        new_balance=new_balance
                    )
                )
            else:
                await utils.answer(
                    message,
                    self.strings["crypto_down"].format(
                        coin=coin,
                        change=int((1-change)*100),
                        amount=abs(profit),
                        new_balance=new_balance
                    )
                )
        except Exception as e:
            logger.exception("Crypto error:")
            await utils.answer(message, self.strings["invalid_args"])

    @loader.command()
    async def бинго(self, message: Message):
        """<ставка> - Игра в бинго"""
        try:
            bet = int(utils.get_args_raw(message))
            balance = await self.get_balance()

            if bet <= 0:
                await utils.answer(message, self.strings["invalid_args"])
                return
            if bet > balance:
                await utils.answer(message, self.strings["no_money"].format(balance=balance))
                return

            numbers = random.sample(range(1, 91), 15)
            await self.update_balance(-bet)
            
            self._db.set("casino", "bingo_game", {
                "bet": bet,
                "numbers": numbers,
                "matched": [],
                "drawn": []
            })

            # Упрощенная карточка бинго без вертикальных линий
            card_rows = []
            for i in range(0, 15, 5):
                row = " ".join(f"{n:^3}" for n in numbers[i:i+5])
                card_rows.append(row)
            card = "\n".join(card_rows)

            await utils.answer(
                message,
                self.strings["bingo_start"].format(
                    bet=bet,
                    numbers=card
                )
            )
        except Exception as e:
            logger.exception("Bingo error:")
            await utils.answer(message, self.strings["invalid_args"])

    @loader.command()
    async def б(self, message: Message):
        """Следующее число в бинго"""
        try:
            game = self._db.get("casino", "bingo_game")
            if not game:
                await utils.answer(message, "❌ Нет активной игры. Начните: .бинго")
                return

            available = [n for n in range(1, 91) if n not in game["drawn"]]
            if not available:
                await utils.answer(message, "🎲 Все числа уже выпали! Игра завершена.")
                self._db.set("casino", "bingo_game", None)
                return

            number = random.choice(available)
            game["drawn"].append(number)
            is_match = number in game["numbers"]
            balance = await self.get_balance()

            if is_match:
                game["matched"].append(number)
                matched_count = len(game["matched"])
                multiplier = next((mult for t, mult in sorted(self.bingo_multipliers.items(), reverse=True) if matched_count >= t), 1)
                
                win = game["bet"] * multiplier
                new_balance = await self.update_balance(win)
                self._db.set("casino", "bingo_game", game)

                if matched_count == 15:
                    await utils.answer(
                        message,
                        self.strings["bingo_full"].format(
                            amount=win,
                            new_balance=new_balance
                        )
                    )
                    self._db.set("casino", "bingo_game", None)
                else:
                    await utils.answer(
                        message,
                        self.strings["bingo_win"].format(
                            number=number,
                            amount=win,
                            mult=multiplier,
                            new_balance=new_balance
                        )
                    )
            else:
                await utils.answer(
                    message,
                    self.strings["bingo_lose"].format(
                        number=number,
                        new_balance=balance
                    )
                )
        except Exception as e:
            logger.exception("Bingo draw error:")
            await utils.answer(message, f"❌ Ошибка: {str(e)}")

    @loader.command()
    async def работа(self, message: Message):
        """Заработать деньги (3ч кд)"""
        try:
            now = int(time.time())
            last_work = self._db.get("casino", "last_work", 0)
            
            if now - last_work < self.config["WORK_COOLDOWN"]:
                remaining = self.config["WORK_COOLDOWN"] - (now - last_work)
                await utils.answer(
                    message,
                    self.strings["work_cooldown"].format(
                        time=time.strftime("%H:%M:%S", time.gmtime(remaining))
                    )
                )
                return

            work_type, work_desc = random.choice(self.jobs)
            amount = random.randint(self.config["WORK_MIN"], self.config["WORK_MAX"])
            new_balance = await self.update_balance(amount)

            self._db.set("casino", "last_work", now)
            await utils.answer(
                message,
                self.strings["work_success"].format(
                    work_type=work_desc,
                    amount=amount,
                    new_balance=new_balance
                )
            )
        except Exception as e:
            logger.exception("Work error:")
            await utils.answer(message, f"❌ Ошибка: {str(e)}")

    @loader.command()
    async def ежедневный(self, message: Message):
        """Ежедневный бонус (24ч кд)"""
        try:
            now = int(time.time())
            last_daily = self._db.get("casino", "last_daily", 0)
            
            if now - last_daily < 86400:
                await utils.answer(message, self.strings["daily_already"])
                return

            amount = random.randint(self.config["DAILY_MIN"], self.config["DAILY_MAX"])
            new_balance = await self.update_balance(amount)

            self._db.set("casino", "last_daily", now)
            await utils.answer(
                message,
                self.strings["daily_reward"].format(
                    amount=amount,
                    new_balance=new_balance
                )
            )
        except Exception as e:
            logger.exception("Daily error:")
            await utils.answer(message, f"❌ Ошибка: {str(e)}")

    @loader.command()
    async def казино(self, message: Message):
        """Главное меню"""
        balance = await self.get_balance()
        await utils.answer(
            message,
            f"🎰 <b>Казино</b> | Баланс: <code>{balance}</code> ₽\n\n"
            "🎮 <b>Игры</b>:\n"
            "• <code>.рулетка [ставка] [1-10]</code> - классическая рулетка (×9)\n"
            "• <code>.слоты [ставка]</code> - игровые автоматы (×3/×10)\n"
            "• <code>.крипта [сумма]</code> - инвестиции в криптовалюту\n"
            "• <code>.бинго [ставка]</code> - игра в бинго (×2-×10)\n\n"
            "💼 <b>Заработок</b>:\n"
            "• <code>.работа</code> - заработок (3ч кд)\n"
            "• <code>.ежедневный</code> - бонус (24ч кд)\n\n"
            "💰 <code>.баланс</code> - проверить средства\n"
            "🎲 <code>.б</code> - следующее число в Бинго"
        )