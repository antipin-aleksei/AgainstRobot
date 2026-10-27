import SwiftUI

struct HomeView: View {
    @Binding var configuration: AppConfiguration

    var body: some View {
        NavigationStack {
            List {
                Section("Главная") {
                    Text("Каркас приключения")
                        .font(.headline)
                    Text("Основные экраны пока пустые.")
                        .foregroundStyle(.secondary)
                    ForEach(AppRoute.allCases, id: \.self) { route in
                        NavigationLink(route.title, value: route)
                            .accessibilityIdentifier("route.\(route.rawValue)")
                    }
                }

                Section {
                    Toggle("Тестовые данные", isOn: $configuration.usesMockData)
                        .accessibilityIdentifier("mockModeToggle")
                } header: {
                    Text("Режим данных")
                } footer: {
                    Text(configuration.usesMockData
                         ? "Локальный режим. Запросов к API нет."
                         : "Сервис не подключён. Запросов к API нет.")
                }
            }
            .navigationTitle("AgainstRobot")
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .character: CharacterView()
                case .premise: PremiseView()
                case .game: GameView()
                case .heroCard: HeroCardView()
                }
            }
        }
    }
}
