# AirFake 0.2.1

Исправленная вторая версия для iPhone X / iOS 16 / Dopamine rootless.

## Что есть
- отдельная иконка AirFake на рабочем столе;
- настройки прямо в приложении;
- резервные настройки через PreferenceLoader;
- поиск Bluetooth-устройства по подстроке имени, по умолчанию `Soundcore`;
- регистр не важен: `Soundcore`, `soundcore`, `SOUNDCORE` совпадают;
- тестовая карточка;
- автоматическая проверка подключённых Bluetooth-устройств каждые 1.5 секунды как запасной способ, если приватное Bluetooth-уведомление iOS не сработает;
- скрытие иконки AirFake после Respring;
- Respring через Darwin notification в SpringBoard, без запуска `killall` из приложения.

## Если скрыли иконку
Открой `Настройки iOS → AirFake`, выключи `Скрыть иконку AirFake`, затем нажми `Сделать Respring`.

## Сборка
Проект уже содержит `.github/workflows/build.yml`.
Загрузи содержимое архива в корень репозитория GitHub и дождись Build AirFake.
Готовый `.deb` будет в `Artifacts → AirFake-deb`.
