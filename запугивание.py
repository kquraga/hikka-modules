from .. import loader, utils
from ..inline.types import InlineCall
import asyncio
import logging
from telethon.tl.types import User

logger = logging.getLogger(__name__)

@loader.tds
class PublicScaryButtonMod(loader.Module):
    """Страшная кнопка для всех пользователей"""
    
    strings = {
        "name": "ScaryButton",
        "start_text": "⚠️ <b>Внимание! Нажми на кнопку ниже!</b> ⚠️",
        "button_text": "🚨 НАЖМИ МЕНЯ 🚨",
        "alert_text": "🛑 ВАШ АККАУНТ БУДЕТ УДАЛЁН! 🛑",
        "activated_text": "💀 <b>СИСТЕМА УНИЧТОЖЕНИЯ АКТИВИРОВАНА</b> 💀",
        "cancel_text": "❌ ОТМЕНА НЕВОЗМОЖНА ❌",
        "final_text": "😂 <b>ТВОЙ АККАУНТ БЫЛ УСПЕШНО ВЗЛОМАН, {user}</b> 😂\n\n<i>Жди публикаций интимных фотографий.</i>",
        "close_text": "😡 ОПЛАТИТЬ ВОЗВРАЩЕНИЕ АККАУНТА",
        "error_text": "❌ Произошла ошибка! Попробуйте позже."
    }

    async def scarycmd(self, message):
        """Активировать страшную кнопку"""
        try:
            await self.inline.form(
                text=self.strings["start_text"],
                message=message,
                reply_markup=[
                    [
                        {
                            "text": self.strings["button_text"],
                            "callback": self.scary_callback,
                        }
                    ]
                ],
                force_me=False,
                disable_security=True,
                silent=True,
            )
        except Exception as e:
            logger.error(f"Ошибка при создании формы: {e}")
            await utils.answer(message, self.strings["error_text"])

    async def scary_callback(self, call: InlineCall):
        """Обработчик нажатия кнопки"""
        try:
            # Получаем информацию о пользователе
            user = await self.client.get_entity(call.from_user.id)
            user_name = user.first_name if isinstance(user, User) else "Неизвестный пользователь"

            threats = [
                "🚨 ВАШ АККАУНТ БУДЕТ ВЗЛОМАН ЧЕРЕЗ 5 СЕКУНД, СПАСИБО ЗА ПОДАРОК!",
                "👹 ХАКЕРЫ ВЗЛОМАЮТ ВАШ ТЕЛЕГРАМ!",
                "💀 ВАШЕ УСТРОЙСТВО ЗАРАЖЕНО ВИРУСОМ!",
                "👻 ПРИЗРАКИ В ВАШЕМ ТЕЛЕФОНЕ!",
                "🔥 СЕРВЕР ТЕЛЕГРАМА ГОРИТ ИЗ-ЗА ВАС!",
                "⚠️ ПОЛИЦИЯ УЖЕ В ПУТИ!",
                "☠️ ВАШ IP: 127.0.0.1... МЫ ИДЁМ К ВАМ!",
                "💣 УНИЧТОЖЕНИЕ НЕИЗБЕЖНО!"
            ]

            # Первое уведомление
            try:
                await call.answer(self.strings["alert_text"], alert=True)
            except:
                pass

            # Обновляем сообщение
            await call.edit(
                text=self.strings["activated_text"],
                reply_markup=[
                    [
                        {
                            "text": self.strings["cancel_text"],
                            "callback": self.scary_callback,
                        }
                    ]
                ]
            )

            # Последовательность угроз
            for threat in threats:
                try:
                    await call.answer(threat, show_alert=True)
                    await asyncio.sleep(1.5)
                except:
                    await asyncio.sleep(1.5)
                    continue

            # Финальное сообщение с именем пользователя
            await call.edit(
                text=self.strings["final_text"].format(user=user_name),
                reply_markup=[
                    [
                        {
                            "text": self.strings["close_text"],
                            "action": "close",
                        }
                    ]
                ]
            )

        except Exception as e:
            logger.error(f"Ошибка в обработчике: {e}")
            try:
                await call.edit(self.strings["error_text"])
            except:
                pass