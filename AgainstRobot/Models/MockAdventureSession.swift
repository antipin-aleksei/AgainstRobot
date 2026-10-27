import Foundation
import Observation

// Presentation fixtures only. Plan-3 introduces authoritative rules and game state.
enum HeroPreset: String, CaseIterable, Identifiable {
    case guardian, scout
    var id: String { rawValue }
    var title: String { self == .guardian ? "Страж" : "Следопыт" }
    var detail: String {
        self == .guardian ? "Защищает спутников и не отступает." : "Замечает следы и находит обходной путь."
    }
    var symbol: String { self == .guardian ? "shield.fill" : "leaf.fill" }
}

enum AvatarPreset: String, CaseIterable, Identifiable {
    case fox, moon
    var id: String { rawValue }
    var title: String { self == .fox ? "Лис" : "Луна" }
    var symbol: String { self == .fox ? "pawprint.fill" : "moon.stars.fill" }
}

struct ChatMessage: Identifiable {
    enum Speaker { case narrator, player }
    let id = UUID()
    let speaker: Speaker
    let text: String
}

@Observable
final class MockAdventureSession {
    var name = ""
    var hero: HeroPreset = .guardian
    var avatar: AvatarPreset = .fox
    var hint = ""
    private(set) var premiseIndex = 0
    private(set) var messages: [ChatMessage] = []
    private(set) var isAwaitingRoll = false
    private(set) var hasAdventure = false
    private(set) var isDemoHistory = false

    var heroName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    var canContinue: Bool { !heroName.isEmpty }
    var premiseTitle: String {
        premiseIndex == 0 ? "Маяк в тумане" : "Тайна лесной станции"
    }
    var premiseDescription: String {
        let story = premiseIndex == 0
            ? "Каждый вечер над бухтой загорается заброшенный маяк. Сегодня его свет остановился на вашем окне. Смотритель исчез, а в порту нашли письмо с просьбой прийти до рассвета.\n\nНа берегу вас ждёт лодка. В её борту спрятан медный ключ, но никто из рыбаков не признаётся, кому она принадлежит. Вы решаете, с кем поговорить и какой дорогой добраться до маяка."
            : "Старая станция глубоко в лесу подаёт сигналы, хотя поездов здесь не было много лет. Молодой механик просит вас найти источник света и вернуть пропавший журнал.\n\nУ входа видны свежие следы. Можно осмотреть закрытую дверь, расспросить механика или обойти станцию по тропе. Ветер приносит звон колокольчика с пустой платформы."
        let wish = hint.trimmingCharacters(in: .whitespacesAndNewlines)
        return story + (wish.isEmpty ? "" : "\n\nВаше пожелание: \(wish). Это локальный пример; ИИ пока не обрабатывает пожелания.")
    }

    func reset() {
        name = ""
        hero = .guardian
        avatar = .fox
        hint = ""
        premiseIndex = 0
        messages = []
        isAwaitingRoll = false
        hasAdventure = false
        isDemoHistory = false
    }

    func regeneratePremise() {
        premiseIndex = (premiseIndex + 1) % 2
    }

    func beginAdventure() {
        guard canContinue else { return }
        hasAdventure = true
        isDemoHistory = false
        isAwaitingRoll = false
        messages = [ChatMessage(speaker: .narrator,
            text: "\(heroName), перед вами закрытая дверь. Вдалеке слышен колокольчик. Что вы делаете?")]
    }

    func openDemoHistory() {
        reset()
        name = "Мира"
        hero = .scout
        premiseIndex = 1
        beginAdventure()
        isDemoHistory = true
        messages.append(ChatMessage(speaker: .player, text: "Спрашиваю механика о станции."))
        messages.append(ChatMessage(speaker: .narrator,
            text: "Механик протягивает фонарь: «Свет появляется у северной двери»."))
    }

    func send(_ text: String) {
        let action = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !action.isEmpty, !isAwaitingRoll else { return }
        messages.append(ChatMessage(speaker: .player, text: action))
        messages.append(ChatMessage(speaker: .narrator,
            text: "Пример ответа мастера: на двери виден старый замок. Попробуйте открыть его — нажмите кнопку тестового броска."))
        isAwaitingRoll = true
    }

    func roll() {
        guard isAwaitingRoll else { return }
        messages.append(ChatMessage(speaker: .narrator, text: "Тестовый бросок: 14. Дверь открыта."))
        isAwaitingRoll = false
    }
}
