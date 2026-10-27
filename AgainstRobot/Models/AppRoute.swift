enum AppRoute: String, CaseIterable, Hashable {
    case character
    case premise
    case game
    case heroCard

    var title: String {
        switch self {
        case .character: "Персонаж"
        case .premise: "Завязка"
        case .game: "Игра"
        case .heroCard: "Карточка героя"
        }
    }
}
