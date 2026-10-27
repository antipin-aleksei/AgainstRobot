# AgainstRobot

Каркас одиночного приключения для iPhone на SwiftUI. Сейчас доступны главная и
пустые экраны персонажа, завязки, игры и карточки героя. Данные приключения,
ИИ, сохранения, голос и карта ещё не реализованы.

**plan-1 заблокирован до проверки на Mac.** В Linux подготовлены файлы проекта,
но сборка, запуск и UI-тесты не подтверждены. plan-2 пока не начинается.

## Требования

- Выбранная базовая среда: **Xcode 16.0**, macOS **14.5+**, SDK iOS **18.0**.
  Можно использовать более новый совместимый Xcode с его требованиями к macOS.
- Deployment target: **iOS 17.0**, только iPhone. Swift — языковой режим **5.0**
  компилятора из Xcode 16 (код использует Swift 5.9 switch expressions).
- Для указанных UI-тестов: симулятор **iPhone 16 / iOS 18.0**. Другой установленный
  iPhone-симулятор с iOS 17+ можно выбрать через `-destination`.
- Зависимостей приложения, менеджера пакетов и генератора проекта нет.
  `.xcodeproj` и общая схема `AgainstRobot` хранятся в Git.

Это выбранные требования, а не зафиксированная успешная среда сборки. В среде
подготовки доступны Linux x86_64 и Python 3.12.14; Swift и Xcode отсутствуют.

## Открытие и запуск на Mac

1. Открыть `AgainstRobot.xcodeproj` в Xcode и выбрать схему `AgainstRobot`.
2. Установить iOS Simulator runtime в Xcode Settings → Components, если нужен.
3. Выбрать iPhone-симулятор и выполнить Product → Run (`⌘R`).
4. Убедиться, что видна главная `AgainstRobot`. Открыть каждый из четырёх
   экранов, вернуться назад и переключить «Тестовые данные» в обе стороны.

Для симулятора аккаунт разработчика не требуется. Для физического iPhone
назначить собственный Team и уникальный Bundle Identifier в Signing &
Capabilities. В проекте нет привязки к аккаунту или сертификатам.

## Команды проверки на Mac

Из корня репозитория проверить фактические версии и доступные устройства:

```sh
xcodebuild -version
xcrun swift --version
xcrun simctl list devices available
```

Собрать Debug для симулятора без подписи:

```sh
xcodebuild -project AgainstRobot.xcodeproj \
  -scheme AgainstRobot -configuration Debug -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath build/DerivedData CODE_SIGNING_ALLOWED=NO build
```

Запустить два UI smoke-теста (домашний экран/четыре маршрута и переключение
mock-режима). Если такого симулятора нет, заменить `-destination` на устройство
из списка выше, например `platform=iOS Simulator,id=<UDID>`:

```sh
xcodebuild -project AgainstRobot.xcodeproj \
  -scheme AgainstRobot -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.0' \
  -derivedDataPath build/DerivedData \
  -resultBundlePath build/SmokeTests.xcresult CODE_SIGNING_ALLOWED=NO test
```

При повторном тестировании использовать новый путь `-resultBundlePath`, если
папка результата уже существует. UI-тесты добавлены, но **ни разу не выполнены**:
в Linux `xcodebuild` заканчивается кодом 127 (`command not found`). Это не
результат RED или GREEN для поведения приложения. Нужны реальная сборка, запуск
и запись версии Xcode, destination, команд и результатов в [plan-1](vibe/plans/plan-1.md),
прежде чем снимать блокер.

## CI на облачном Mac

Workflow [.github/workflows/ios-ci.yml](.github/workflows/ios-ci.yml) запускается
при push в `main`, для pull request и вручную через GitHub Actions → **iOS CI** →
**Run workflow**. Задание выполняется **только в публичном репозитории**:
`github.event.repository.private == false`; в приватном оно пропускается.
Используется стандартный hosted runner `macos-15`, без larger runner и секретов.
Публикация репозитория и первый реальный запуск — отдельные действия; наличие
workflow не подтверждает, что они выполнены.

CI явно выбирает Xcode **16.4**, записывает версии инструментов и выбирает
доступный iPhone-симулятор с runtime того же основного поколения, что и SDK
(iOS 18 для выбранного Xcode). Затем ожидает загрузку симулятора, выполняет
Debug `build-for-testing`, два существующих UI smoke-теста через
`test-without-building` и Release `build`, везде без подписи. Проверка
`xcresulttool get test-results summary` требует хотя бы одного завершённого
успешного теста и нуля ошибок; пустой прогон не считается успешным.

Ограничение задания — 30 минут; устаревший запуск той же ветки/PR отменяется.
Логи, версии, destination, JSON результата и `.xcresult` сохраняются в артефакте
`ios-diagnostics-<run_id>-<attempt>` на 7 дней, в том числе при ошибке, если файлы
успели появиться. Внешние actions закреплены полными SHA, токен имеет только
`contents: read`, credentials после checkout не сохраняются.

**Облачная сборка и тесты пока не подтверждены.** Локальная статическая проверка
workflow в Linux не заменяет Xcode. В [plan-11](vibe/plans/plan-11.md) нужно
записать URL запуска, точный commit SHA, версии, destination, число тестов и
результаты обоих build; до этого [plan-1](vibe/plans/plan-1.md) заблокирован,
plan-2 не начинается.

## Режим данных и структура

`AppConfiguration.usesMockData` включён по умолчанию. Переключатель на главной
меняет только состояние в памяти; перезапуск возвращает безопасное значение.
Включённый режим предназначен для будущих локальных тестовых данных. При
выключении отображается «Сервис не подключён». Оба режима сейчас полностью
офлайн: сетевого клиента, URL, ключей и платных вызовов нет. Подключение сервиса
вынесено в последующие планы.

- `AgainstRobot/App` — точка входа и состояние конфигурации.
- `AgainstRobot/Features` — главная, навигация и пустые экраны.
- `AgainstRobot/Models` — маршруты; игровые модели появятся в plan-3.
- `AgainstRobot/Services` — конфигурация; реальных сервисов пока нет.
- `AgainstRobotUITests` — проверки навигации и переключателя для симулятора.

Планы: [vibe/README.md](vibe/README.md). Рабочий процесс:
[vibe/SUPERPOWERS.md](vibe/SUPERPOWERS.md).
