from hikkatl.types import Message
from .. import loader, utils
import random
import time
import asyncio

@loader.tds
class DepModule(loader.Module):
    """Игра 'Деп' - удвой или проиграй"""
    strings = {
        "name": "Деп",
        "dep_usage": "🚀 Используй <code>.деп <сумма></code> чтобы начать игру",
        "balance": "💰 Твой баланс: {balance}",
        "waiting": "⏳ Ты поставил {amount}. Рост: {multiplier:.2f}\n{graph}",
        "win": "🎉 Ты выиграл {multiplier:.2f}x и получил {amount}!",
        "lose": "💥 Ты проиграл! Потеряно: {amount}",
        "no_money": "❌ У тебя недостаточно средств",
        "min_bet": "❌ Минимальная ставка: 1",
        "timeout": "⏱ Время вышло! Деньги возвращены на баланс.\n💰 Баланс: {balance}",
        "money_returned": "💸 Деньги возвращены на баланс из-за бездействия",
        "graph_green": "🟩",  # Зеленый квадрат
        "graph_red": "🟥",  # Красный квадрат
        "graph_white": "⬜",  # Белый квадрат
        "max_candles": 10,  # Максимальное количество свечей для отображения
        "max_multiplier": 15.0, # Максимальный множитель
        "bankrupt": [  # Сообщения при банкротстве
            "Ты обанкротился!",
            "Ты проиграл все деньги, придурок!",
            "Ты депнул хату!",
            "Теперь ты бомж!",
            "Поздравляю, ты достиг дна!",
        ],
        "sold_house": "🏠 Ты продал дом за {amount}!",
        "sold_dacha": "🏡 Ты продал дачу за {amount}!",
        "sold_car": "🚗 Ты продал машину за {amount}!",
        "no_property": "❌ У тебя нет {property} для продажи!",
    }

    async def client_ready(self, client, db):
        self._db = db
        self._client = client
        self._me = await client.get_me()
        self._games = {}  # {user_id: {"amount": int, "start_time": float, "multiplier": float, "message_id": int, "history": []}}
        
        # Инициализация баланса (100 по умолчанию)
        if "balance" not in self._db.get(__name__, "data", {}):
            self._db.set(__name__, "data", {"balance": 100})
        
        # Инициализация наличия имущества
        if "properties" not in self._db.get(__name__, "data", {}):
            self._db.set(__name__, "data", {"properties": {"house": True, "dacha": True, "car": True}})


    async def get_balance(self):
        """Получаем текущий баланс"""
        return self._db.get(__name__, "data", {}).get("balance", 50)

    async def set_balance(self, amount):
        """Устанавливаем новый баланс"""
        data = self._db.get(__name__, "data", {})
        data["balance"] = amount
        self._db.set(__name__, "data", data)

    async def get_properties(self):
        """Получаем информацию об имуществе"""
        return self._db.get(__name__, "data", {}).get("properties", {"house": True, "dacha": True, "car": True})

    async def set_properties(self, properties):
        """Устанавливаем информацию об имуществе"""
        data = self._db.get(__name__, "data", {})
        data["properties"] = properties
        self._db.set(__name__, "data", data)


    @loader.command(ru_doc="Показать текущий баланс")
    async def баланс(self, message: Message):
        """Показать баланс"""
        balance = await self.get_balance()
        await utils.answer(message, self.strings("balance").format(balance=balance))

    @loader.command(ru_doc="<сумма> - игра 'Деп'")
    async def деп(self, message: Message):
        """[сумма] - игра Деп"""
        args = utils.get_args_raw(message)
        
        if not args:
            balance = await self.get_balance()
            await utils.answer(message, self.strings("balance").format(balance=balance))
            return
            
        if not args.isdigit():
            await utils.answer(message, self.strings("dep_usage"))
            return

        amount = int(args)
        
        if amount < 1:
            await utils.answer(message, self.strings("min_bet"))
            return
        
        current_balance = await self.get_balance()
        if amount > current_balance:
            await utils.answer(message, self.strings("no_money"))
            return

        await self.set_balance(current_balance - amount)

        msg = await utils.answer(
            message,
            self.strings("waiting").format(amount=amount, multiplier=1.0, graph="")
        )

        self._games[message.sender_id] = {
            "amount": amount,
            "start_time": time.time(),
            "multiplier": 1.0,
            "history": [],  # Добавляем историю изменений
            "chat_id": message.chat_id,
            "message_id": msg.id,
        }

        asyncio.create_task(self.update_multiplier(message.sender_id))

    async def update_multiplier(self, user_id):
        """Обновляет множитель, график и редактирует сообщение"""
        game = self._games.get(user_id)
        if not game:
            return

        try:
            while True:
                await asyncio.sleep(1)  # Изменено: Обновляем каждую 1 секунду

                # Запоминаем предыдущий множитель
                previous_multiplier = game["multiplier"]

                # Шанс падения множителя (50%)
                if random.random() < 0.5:
                    game["multiplier"] -= random.uniform(0.15, 0.35)  # Изменено: Больше диапазон изменения
                    if game["multiplier"] < 0.0:  # Минимальный множитель теперь 0
                        game["multiplier"] = 0.0
                else:
                    game["multiplier"] += random.uniform(0.15, 0.35)  # Изменено: Больше диапазон изменения
                    max_multiplier = self.strings("max_multiplier")
                    if game["multiplier"] > max_multiplier:  # Проверка на максимальный множитель
                        game["multiplier"] = max_multiplier

                if game["multiplier"] <= 0.0:  # Проигрыш, если множитель упал до 0
                    amount = game["amount"]  # Сохраняем amount перед удалением игры
                    del self._games[user_id]
                    await self.safe_delete_message(game["chat_id"], game["message_id"])

                    # Проверяем, остались ли деньги на балансе
                    current_balance = await self.get_balance()
                    if current_balance <= 0:
                        # Выбираем случайное сообщение о банкротстве
                        bankrupt_messages = self.strings("bankrupt")
                        bankrupt_message = random.choice(bankrupt_messages)
                        await self._client.send_message(
                            game["chat_id"],
                            bankrupt_message
                        )
                    else:
                        await self._client.send_message(
                            game["chat_id"],
                            self.strings("lose").format(amount=amount) + f"\n💰 Баланс: {await self.get_balance():.2f}"
                        )
                    return

                # Определяем цвет для "свечи"
                if game["multiplier"] > previous_multiplier:
                    candle_color = self.strings("graph_green")  # Зеленый, если вырос
                elif game["multiplier"] < previous_multiplier:
                    candle_color = self.strings("graph_red")  # Красный, если упал
                else:
                    candle_color = self.strings("graph_white")  # Белый, если не изменился

                # Добавляем "свечу" в историю
                game["history"].append(candle_color)

                # Обрезаем историю, если она слишком длинная
                max_candles = self.strings("max_candles")
                if len(game["history"]) > max_candles:
                    game["history"] = game["history"][-max_candles:]

                # Формируем график из истории
                graph = "".join(game["history"])  # Соединяем символы "свечей"

                try:
                    await self._client.edit_message(
                        game["chat_id"],
                        game["message_id"],
                        self.strings("waiting").format(amount=game["amount"], multiplier=game["multiplier"], graph=graph)
                    )
                except Exception as e:
                    self.logger.error(f"Ошибка при редактировании сообщения: {e}")
                    return

        except Exception as e:
            self.logger.error(f"Ошибка в update_multiplier: {e}")

    async def safe_delete_message(self, chat_id, message_id):
        """Безопасное удаление сообщения с обработкой ошибок"""
        try:
            await self._client.delete_messages(chat_id, message_id)
        except Exception as e:
            self.logger.error(f"Ошибка при удалении сообщения: {e}")

    @loader.command(ru_doc="Остановить игру и получить выигрыш")
    async def стоп(self, message: Message):
        """Остановить игру Деп"""
        user_id = message.sender_id
        game = self._games.get(user_id)
        if not game:
            await utils.answer(message, "Игра не найдена. Начните с команды .деп")
            return
        
        amount = game["amount"] # Сохраняем amount перед удалением игры

        # Останавливаем игру
        del self._games[user_id]
        await self.safe_delete_message(game["chat_id"], game["message_id"])

        # Вычисляем выигрыш
        win_amount = int(amount * game["multiplier"])
        current_balance = await self.get_balance()
        new_balance = current_balance + win_amount

        # Обновляем баланс
        await self.set_balance(new_balance)

        # Отправляем сообщение о выигрыше
        await utils.answer(
            message,
            self.strings("win").format(multiplier=game["multiplier"], amount=win_amount) + f"\n💰 Новый баланс: {new_balance}"
        )

    @loader.command(ru_doc="Продать дом")
    async def продать_дом(self, message: Message):
        """Продать дом"""
        properties = await self.get_properties()
        if not properties["house"]:
            await utils.answer(message, self.strings("no_property").format(property="дом"))
            return
        
        # Генерируем случайную цену продажи
        sale_amount = random.randint(1000, 3500)
        
        # Обновляем баланс
        current_balance = await self.get_balance()
        await self.set_balance(current_balance + sale_amount)
        
        # Устанавливаем, что дома больше нет
        properties["house"] = False
        await self.set_properties(properties)
        
        await utils.answer(message, self.strings("sold_house").format(amount=sale_amount))


    @loader.command(ru_doc="Продать дачу")
    async def продать_дачу(self, message: Message):
        """Продать дачу"""
        properties = await self.get_properties()
        if not properties["dacha"]:
            await utils.answer(message, self.strings("no_property").format(property="дачу"))
            return
        
        # Генерируем случайную цену продажи
        sale_amount = random.randint(500, 1000)
        
        # Обновляем баланс
        current_balance = await self.get_balance()
        await self.set_balance(current_balance + sale_amount)
        
        # Устанавливаем, что дачи больше нет
        properties["dacha"] = False
        await self.set_properties(properties)
        
        await utils.answer(message, self.strings("sold_dacha").format(amount=sale_amount))

    @loader.command(ru_doc="Продать машину")
    async def продать_машину(self, message: Message):
        """Продать машину"""
        properties = await self.get_properties()
        if not properties["car"]:
            await utils.answer(message, self.strings("no_property").format(property="машину"))
            return
        
        # Генерируем случайную цену продажи
        sale_amount = random.randint(800, 2500)
        
        # Обновляем баланс
        current_balance = await self.get_balance()
        await self.set_balance(current_balance + sale_amount)
        
        # Устанавливаем, что машины больше нет
        properties["car"] = False
        await self.set_properties(properties)
        
        await utils.answer(message, self.strings("sold_car").format(amount=sale_amount))


    async def watcher(self, message: Message):
        return