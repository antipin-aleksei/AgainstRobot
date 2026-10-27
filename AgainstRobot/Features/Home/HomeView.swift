import SwiftUI

struct HomeView: View {
    @Binding var configuration: AppConfiguration
    @State private var session = MockAdventureSession()
    @State private var demoSession = MockAdventureSession()
    @State private var path: [AppRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Section {
                    Text("Ваше короткое приключение").font(.title2.bold())
                    Text("Выберите героя и шагните в историю. Пока все ответы — локальные примеры.")
                        .foregroundStyle(.secondary)
                    PrimaryAdventureButton(title: "Новая игра") {
                        session.reset()
                        path = [.character]
                    }
                    .disabled(!configuration.usesMockData)
                    .accessibilityIdentifier("newGame")
                }
                Section("История игр") {
                    if session.hasAdventure {
                        Button {
                            path = [.game]
                        } label: {
                            Label("Продолжить: \(session.heroName)", systemImage: "play.circle")
                        }
                        .disabled(!configuration.usesMockData)
                        .accessibilityIdentifier("resumeGame")
                        Text("Текущая игра только в памяти до закрытия приложения.")
                            .font(.footnote).foregroundStyle(.secondary)
                    } else {
                        Text("Вы ещё не начали приключение.").foregroundStyle(.secondary)
                    }
                    Button {
                        demoSession.openDemoHistory()
                        path = [.demoHistory]
                    } label: {
                        Label("Лесная станция · пример истории", systemImage: "book.closed")
                    }
                    .disabled(!configuration.usesMockData)
                    .accessibilityIdentifier("history.demo")
                }
                Section {
                    Toggle("Тестовые данные", isOn: $configuration.usesMockData)
                        .accessibilityIdentifier("mockModeToggle")
                    if !configuration.usesMockData {
                        AdventureNotice(text: "Сервис не подключён. Включите тестовые данные, чтобы пройти пример.", isError: true)
                    }
                } header: {
                    Text("Режим данных")
                } footer: {
                    Text(configuration.usesMockData
                         ? "Локальный режим. Запросов к API нет."
                         : "Сервис не подключён. Запросов к API нет.")
                }
            }
            .navigationTitle("AgainstRobot")
            .navigationBarTitleDisplayMode(.inline)
            .tint(AdventureStyle.accent)
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .character:
                    CharacterView(session: session) { path.append(.premise) }
                case .premise:
                    PremiseView(session: session) {
                        session.beginAdventure()
                        path = [.game]
                    }
                case .game:
                    GameView(session: session) { path = [] }
                case .demoHistory:
                    GameView(session: demoSession) { path = [] }
                }
            }
        }
    }
}
