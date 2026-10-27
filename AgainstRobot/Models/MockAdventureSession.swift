import Foundation
import Observation
import AdventureCore

// Creation drafts and presentation only. AdventureCore owns the accepted game state.
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

@Observable
final class MockAdventureSession {
    var name = ""
    var hero: HeroPreset = .guardian
    var avatar: AvatarPreset = .fox
    var hint = ""
    private(set) var premiseIndex = 0
    private(set) var gameState: GameState?
    private(set) var issueMessage: String?
    private(set) var isDemoHistory = false

    var messages: [Message] { gameState?.messages ?? [] }
    var isAwaitingRoll: Bool { gameState?.phase == .awaitingRoll }
    var hasAdventure: Bool { gameState != nil }
    var heroName: String { gameState?.hero.name ?? name.trimmingCharacters(in: .whitespacesAndNewlines) }
    var canContinue: Bool { !heroName.isEmpty }
    var premiseTitle: String { preview.adventure.title }
    var premiseDescription: String {
        let wish = hint.trimmingCharacters(in: .whitespacesAndNewlines)
        return preview.adventure.premise + (wish.isEmpty ? "" : "\n\nВаше пожелание: \(wish). Это локальный пример; ИИ пока не обрабатывает пожелания.")
    }
    private var preview: GameState {
        // Constants are covered by native fixture tests; user input is validated on acceptance.
        try! AdventureFixtures.newSession(name: "Пример", premiseIndex: premiseIndex)
    }

    func reset() {
        name = ""; hero = .guardian; avatar = .fox; hint = ""; premiseIndex = 0
        gameState = nil; issueMessage = nil; isDemoHistory = false
    }

    func regeneratePremise() {
        guard gameState == nil else { return }
        premiseIndex = (premiseIndex + 1) % 2
    }

    func beginAdventure() {
        guard canContinue, gameState == nil else { return }
        do {
            var state = try AdventureFixtures.newSession(name: name,
                kind: hero == .guardian ? .guardian : .scout,
                avatar: avatar == .fox ? .fox : .moon, premiseIndex: premiseIndex)
            try state.apply(.begin)
            try state.apply(.narrate(Message(speaker: .narrator,
                text: "\(state.hero.name), перед вами закрытая дверь. Вдалеке слышен колокольчик. Что вы делаете?")))
            gameState = state; issueMessage = nil; isDemoHistory = false
        } catch { issueMessage = "Не удалось начать пример: некорректное состояние." }
    }

    func openDemoHistory() {
        reset(); name = "Мира"; hero = .scout; premiseIndex = 1
        beginAdventure()
        isDemoHistory = true
        update { state in
            try state.apply(.narrate(Message(speaker: .player, text: "Спрашиваю механика о станции.")))
            try state.apply(.narrate(Message(speaker: .narrator,
                text: "Механик протягивает фонарь: «Свет появляется у северной двери».")))
        }
    }

    func send(_ text: String) {
        let action = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !action.isEmpty, gameState?.phase == .playing else { return }
        update { state in
            try state.apply(.narrate(Message(speaker: .player, text: action)))
            try state.apply(.narrate(Message(speaker: .narrator,
                text: "Пример ответа мастера: на двери виден старый замок. Попробуйте открыть его — нажмите кнопку тестового броска.")))
            try state.apply(.requestCheck(CheckRequest(sceneID: state.sceneID, ability: .agility, difficulty: 12)))
        }
    }

    func roll() {
        guard let request = gameState?.pendingCheck else { return }
        update { state in
            // Demonstration input, deliberately fixed. Real random dice belong to plan-7.
            try state.apply(.resolveCheck(request.id, face: 14, resultID: ID()))
            try state.apply(.narrate(Message(speaker: .narrator, text: "Тестовый бросок: 14. Дверь открыта.")))
        }
    }

    private func update(_ operation: (inout GameState) throws -> Void) {
        guard var candidate = gameState else { return }
        do {
            try operation(&candidate)
            gameState = candidate; issueMessage = nil
        } catch { issueMessage = "Действие отклонено правилами. Состояние сохранено." }
    }
}
