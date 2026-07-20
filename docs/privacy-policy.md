# Privacy Policy · Политика приватности

**Wickly** · updated 2026-07-20 · [github.com/THET1ME-1/Wickly](https://github.com/THET1ME-1/Wickly)

---

## English

### Short version
Wickly has no account, no server and no analytics. Your journal lives on your device. The developer never receives your entries, photos, locations or any other data — there is nowhere for them to arrive.

### What the app stores and where
Entries, photos, voice notes, mood, trackers and settings are stored in the app's private folder on your device. Entry text and attachments are encrypted with AES-256-GCM; the key is generated on the device and kept in Android Keystore. Uninstalling the app deletes all of it.

### What leaves the device
The app opens a network connection in exactly three cases, all of them optional:

| When | Where | What is sent |
|:--|:--|:--|
| You add place and weather to an entry | [Open-Meteo](https://open-meteo.com) | approximate coordinates of the entry |
| You look for a cover picture | [Openverse](https://openverse.org) | your search query |
| Update check (once a day) | GitHub Releases API | nothing but the request itself |

No identifiers, no advertising IDs, no crash reports, no usage statistics. The app contains no ad SDKs and no analytics libraries.

### Sync
Sync runs between your own devices only — over the local network directly, or through a folder you share yourself (for example with Syncthing). Packets are encrypted with a passphrase known to your devices alone. There is no intermediate server.

### Permissions
- **Location** — the place of an entry, only when you ask for it.
- **Camera, microphone, photos** — a shot, a voice note or an attachment, only at the moment you add one.
- **Notifications** — writing reminders you set up yourself.
- **Gallery (Android 9 and older)** — saving an attachment back to the device when you ask for it.
- **Install packages** — installing an update downloaded from GitHub Releases.

Any of them can be denied: the app keeps working, minus that feature.

### Children
The app collects no data at all, and therefore collects nothing about children either.

### Contact
Questions and reports — [GitHub Issues](https://github.com/THET1ME-1/Wickly/issues).

---

## Русский

### Коротко
У Wickly нет аккаунта, сервера и аналитики. Дневник лежит на твоём устройстве. Разработчик не получает ни записей, ни фотографий, ни мест, ни чего-либо ещё — им просто некуда приходить.

### Что хранится и где
Записи, фотографии, голосовые заметки, настроение, трекеры и настройки лежат в приватной папке приложения на устройстве. Текст записей и вложения зашифрованы AES-256-GCM; ключ создаётся на устройстве и хранится в Android Keystore. Удаление приложения стирает всё это.

### Что уходит с устройства
Приложение выходит в сеть ровно в трёх случаях, и каждый из них необязателен:

| Когда | Куда | Что уходит |
|:--|:--|:--|
| Добавляешь к записи место и погоду | [Open-Meteo](https://open-meteo.com) | примерные координаты записи |
| Ищешь картинку для обложки | [Openverse](https://openverse.org) | твой поисковый запрос |
| Проверка обновления (раз в сутки) | GitHub Releases API | ничего, кроме самого запроса |

Ни идентификаторов, ни рекламных ID, ни отчётов о падениях, ни статистики использования. Рекламных SDK и библиотек аналитики в приложении нет.

### Синхронизация
Синхронизация идёт только между твоими устройствами — напрямую по домашней сети или через папку, которой ты делишься сам (например, через Syncthing). Пакеты шифруются фразой, известной только твоим устройствам. Промежуточного сервера нет.

### Разрешения
- **Геолокация** — место записи, только когда ты его просишь.
- **Камера, микрофон, фотографии** — снимок, голосовая заметка или вложение, только в момент добавления.
- **Уведомления** — напоминания писать, которые ты сам настроил.
- **Галерея (Android 9 и старше)** — сохранение вложения обратно на устройство, когда ты об этом просишь.
- **Установка приложений** — установка обновления, скачанного с GitHub Releases.

Любое можно не давать: приложение продолжит работать, но без этой возможности.

### Дети
Приложение не собирает данные вообще, а значит, не собирает их и о детях.

### Связь
Вопросы и сообщения об ошибках — [GitHub Issues](https://github.com/THET1ME-1/Wickly/issues).
