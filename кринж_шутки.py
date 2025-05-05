from hikkatl.types import Message
from .. import loader, utils
import random

@loader.tds
class КринжШутки(loader.Module):
    """Коллекция самых кринжовых шуток"""
    strings = {
        "name": "КринжШутки",
        "joke": "🤡 <b>Кринж-шутка:</b>\n\n{}",
        "bomb": "💣 <b>Готовьтесь к кринж-атаке!</b>"
    }

    jokes = [
        "Я не токсичный, я просто тестирую твою психику на прочность",
        "Моя жизнь — это баг, который разработчики не хотят фиксить",
        "Ты не кринжовый, ты просто ранняя бета-версия человека",
        "Я как Windows XP — все знают, что умер, но ностальгируют",
        "Мои соцнавыки — это DLC, которое я не купил",
        "Ошибка 404: Личность не найдена",
        "У меня нет проблем с доверием, у меня проблемы с 'обнаружена предыдущая версия'",
        "Моё существование — это стикер 'У меня работает'"
    ]

    @loader.command(
        ru_doc="Отправить случайную кринж-шутку",
        en_doc="Send random cringe joke"
    )
    async def кринж(self, message: Message):
        """Отправить случайную кринж-шутку"""
        await utils.answer(message, self.strings("joke").format(random.choice(self.jokes)))

    @loader.command(
        ru_doc="Отправить 5 кринж-шуток подряд",
        en_doc="Send 5 cringe jokes in a row"
    )
    async def кринжатака(self, message: Message):
        """Завалить чат кринжом"""
        await utils.answer(message, self.strings("bomb"))
        for _ in range(5):
            await self.кринж(message)

    @loader.watcher(only_messages=True, only_pm=True)
    async def watcher(self, message: Message):
        """Автоответ на 'кринж' в личке"""
        if "кринж" in message.raw_text.lower():
            await self.кринж(message)