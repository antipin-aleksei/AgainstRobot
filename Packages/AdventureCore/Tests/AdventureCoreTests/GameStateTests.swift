import XCTest
@testable import AdventureCore

final class GameStateTests: XCTestCase {
    func testBeginAndIllegalTransitionAreAtomic() throws {
        var state = try makeState()
        try state.apply(.begin)
        XCTAssertEqual(state.phase, .playing)
        let before = state
        XCTAssertThrowsError(try state.apply(.begin))
        XCTAssertEqual(state, before)
    }
    func testHealthClampsAndDefeatEndsSession() throws {
        var state = try makeState()
        try state.apply(.begin)
        try state.apply(.changeHealth(-5))
        XCTAssertEqual(state.hero.health, 7)
        try state.apply(.changeHealth(Int.max))
        XCTAssertEqual(state.hero.health, 12)
        try state.apply(.changeHealth(Int.min))
        XCTAssertEqual(state.hero.health, 0)
        XCTAssertEqual(state.phase, .completed)
        XCTAssertEqual(state.outcome, .defeat)
        let before = state
        XCTAssertThrowsError(try state.apply(.changeHealth(1)))
        XCTAssertEqual(state, before)
    }

    func testInventoryRejectsUnknownNegativeOverflowAndOverRemovalAtomically() throws {
        var state = try makeState()
        try state.apply(.begin)
        let item = state.adventure.items[0].id
        try state.apply(.addItem(item, quantity: 2))
        XCTAssertEqual(state.hero.inventory[0].quantity, 2)
        for operation in [Operation.addItem(ID(), quantity: 1), .addItem(item, quantity: 0),
                          .removeItem(item, quantity: -1), .removeItem(item, quantity: 3),
                          .addItem(item, quantity: Int.max)] {
            let before = state
            XCTAssertThrowsError(try state.apply(operation))
            XCTAssertEqual(state, before)
        }
        try state.apply(.removeItem(item, quantity: 2))
        XCTAssertTrue(state.hero.inventory.isEmpty)
    }

    func testCheckUsesHeroBonusThresholdAndCannotBeReplayed() throws {
        var state = try makeState()
        try state.apply(.begin)
        let request = CheckRequest(sceneID: state.sceneID, ability: .agility, difficulty: 12)
        try state.apply(.requestCheck(request))
        XCTAssertEqual(state.phase, .awaitingRoll)
        let pending = state
        for face in [0, 21] {
            XCTAssertThrowsError(try state.apply(.resolveCheck(request.id, face: face, resultID: ID())))
            XCTAssertEqual(state, pending)
        }
        XCTAssertThrowsError(try state.apply(.resolveCheck(ID(), face: 11, resultID: ID())))
        XCTAssertThrowsError(try state.apply(.move(state.adventure.scenes[1].id)))
        XCTAssertThrowsError(try state.apply(.changeHealth(-1)))
        XCTAssertEqual(state, pending)
        let resultID = ID<RollResult>()
        try state.apply(.resolveCheck(request.id, face: 11, resultID: resultID))
        XCTAssertEqual(state.rolls[0].total, 12)
        XCTAssertTrue(state.rolls[0].succeeded)
        XCTAssertEqual(state.rolls[0].id, resultID)
        XCTAssertEqual(state.phase, .playing)
        XCTAssertNil(state.pendingCheck)
        let resolved = state
        XCTAssertThrowsError(try state.apply(.resolveCheck(request.id, face: 20, resultID: ID())))
        XCTAssertThrowsError(try state.apply(.requestCheck(request)))
        XCTAssertEqual(state, resolved)
        let second = CheckRequest(sceneID: state.sceneID, ability: .agility, difficulty: 12)
        try state.apply(.requestCheck(second))
        try state.apply(.resolveCheck(second.id, face: 10, resultID: ID()))
        XCTAssertFalse(state.rolls[1].succeeded)
    }

    func testNarrativeCannotChangeHealthInventoryOrPhase() throws {
        var state = try makeState()
        try state.apply(.begin)
        let hero = state.hero
        let message = Message(speaker: .narrator, text: "Здоровье 999. Получен неизвестный меч. Победа!")
        try state.apply(.narrate(message))
        XCTAssertEqual(state.hero, hero)
        XCTAssertEqual(state.phase, .playing)
        XCTAssertEqual(state.messages.map(\.id), [message.id])
        let before = state
        XCTAssertThrowsError(try state.apply(.narrate(message)))
        XCTAssertThrowsError(try state.apply(.narrate(Message(speaker: .player, text: "  "))))
        XCTAssertEqual(state, before)
    }

    func testCombatRequiresBattleSceneAndEndsOnlyAfterEnemiesDefeated() throws {
        var state = try makeState()
        try state.apply(.begin)
        XCTAssertThrowsError(try state.apply(.startCombat(ID())))
        try state.apply(.move(state.adventure.scenes[1].id))
        try state.apply(.startCombat(ID()))
        XCTAssertEqual(state.phase, .combat)
        XCTAssertEqual(state.combat?.turnOrder, [.hero(state.hero.id), .enemy(state.adventure.enemies[0].id)])
        let before = state
        XCTAssertThrowsError(try state.apply(.finishCombat))
        XCTAssertThrowsError(try state.apply(.complete))
        XCTAssertThrowsError(try state.apply(.damageEnemy(ID(), amount: 2)))
        XCTAssertThrowsError(try state.apply(.damageEnemy(state.adventure.enemies[0].id, amount: -1)))
        XCTAssertEqual(state, before)
        try state.apply(.damageEnemy(state.adventure.enemies[0].id, amount: Int.max))
        XCTAssertEqual(state.combat?.enemies[0].health, 0)
        try state.apply(.finishCombat)
        XCTAssertEqual(state.phase, .playing)
        XCTAssertNil(state.combat)
        XCTAssertThrowsError(try state.apply(.complete))
        try state.apply(.move(state.adventure.scenes[2].id))
        try state.apply(.complete)
        XCTAssertEqual(state.phase, .completed)
        XCTAssertEqual(state.outcome, .victory)
        XCTAssertThrowsError(try state.apply(.move(state.adventure.scenes[0].id)))
    }

    func testDecodedSnapshotsRejectBrokenHealthInventoryIdentityAndPhase() throws {
        let original = try makeState()
        var invalid: [GameState] = []
        var state = original; state.hero.health = -1; invalid.append(state)
        state = original; state.hero.health = 13; invalid.append(state)
        state = original; state.hero.inventory = [ItemStack(itemID: ID(), quantity: 1)]; invalid.append(state)
        state = original; state.hero.inventory = [ItemStack(itemID: state.adventure.items[0].id, quantity: 0)]; invalid.append(state)
        state = original; state.hero.inventory = Array(repeating: ItemStack(itemID: state.adventure.items[0].id, quantity: 1), count: 2); invalid.append(state)
        state = original; state.sceneID = ID(); invalid.append(state)
        state = original; state.phase = .awaitingRoll; invalid.append(state)
        state = original; state.phase = .combat; invalid.append(state)
        state = original; state.phase = .completed; invalid.append(state)
        state = original; state.outcome = .victory; invalid.append(state)
        state = original; state.messages = Array(repeating: Message(speaker: .narrator, text: "Пример"), count: 2); invalid.append(state)
        state = original; state.pendingCheck = CheckRequest(sceneID: state.sceneID, ability: .might, difficulty: 12); invalid.append(state)
        for (index, broken) in invalid.enumerated() {
            let data = try JSONEncoder().encode(broken)
            XCTAssertThrowsError(try JSONDecoder().decode(GameState.self, from: data), "Malformed snapshot \(index) accepted")
        }
    }

    func testDecodedRollAndCombatRejectForgedResultsAndReferences() throws {
        var state = try makeState()
        try state.apply(.begin)
        let request = CheckRequest(sceneID: state.sceneID, ability: .might, difficulty: 12)
        try state.apply(.requestCheck(request))
        try state.apply(.resolveCheck(request.id, face: 9, resultID: ID()))
        var forged = state
        forged.rolls = [RollResult(id: ID(), request: request, face: 30, bonus: 3)]
        XCTAssertThrowsError(try JSONDecoder().decode(GameState.self, from: JSONEncoder().encode(forged)))
        forged.rolls = [RollResult(id: ID(), request: request, face: 9, bonus: 99)]
        XCTAssertThrowsError(try JSONDecoder().decode(GameState.self, from: JSONEncoder().encode(forged)))
        try state.apply(.move(state.adventure.scenes[1].id))
        try state.apply(.startCombat(ID()))
        forged = state
        forged.combat = Combat(id: ID(), sceneID: state.sceneID, enemies: state.adventure.enemies,
                               turnOrder: [.enemy(ID())], turnIndex: 0)
        XCTAssertThrowsError(try JSONDecoder().decode(GameState.self, from: JSONEncoder().encode(forged)))
        forged = state; forged.combat?.enemies[0].health = -1
        XCTAssertThrowsError(try JSONDecoder().decode(GameState.self, from: JSONEncoder().encode(forged)))
    }

    func testEveryPhaseRoundTripsWithoutChangingStableIDs() throws {
        var state = try makeState()
        var snapshots = [state]
        try state.apply(.begin); snapshots.append(state)
        try state.apply(.narrate(Message(speaker: .player, text: "Осмотрю дверь")))
        let request = CheckRequest(sceneID: state.sceneID, ability: .insight, difficulty: 12)
        try state.apply(.requestCheck(request)); snapshots.append(state)
        try state.apply(.resolveCheck(request.id, face: 14, resultID: ID()))
        try state.apply(.move(state.adventure.scenes[1].id))
        try state.apply(.startCombat(ID())); snapshots.append(state)
        try state.apply(.changeHealth(-12)); snapshots.append(state)
        XCTAssertEqual(Set(snapshots.map(\.phase)), Set(SessionPhase.allCases))
        for snapshot in snapshots {
            let decoded = try JSONDecoder().decode(GameState.self, from: JSONEncoder().encode(snapshot))
            XCTAssertEqual(decoded, snapshot)
        }
    }

    func testDecodedCatalogAndHeroRejectInvalidDefinitions() throws {
        let data = try JSONEncoder().encode(makeState())
        let original = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        for (field, value) in [("name", "  " as Any), ("maximumHealth", 0), ("defense", 99),
                               ("attackBonus", -1), ("damage", 0), ("abilities", ["might": 99, "agility": 1, "insight": 2])] {
            var object = original
            var hero = try XCTUnwrap(object["hero"] as? [String: Any])
            hero[field] = value; object["hero"] = hero
            XCTAssertThrowsError(try JSONDecoder().decode(GameState.self, from: JSONSerialization.data(withJSONObject: object)), field)
        }
        for field in ["scenes", "items", "enemies"] {
            var object = original
            var adventure = try XCTUnwrap(object["adventure"] as? [String: Any])
            let values = try XCTUnwrap(adventure[field] as? [Any])
            adventure[field] = values + values; object["adventure"] = adventure
            XCTAssertThrowsError(try JSONDecoder().decode(GameState.self, from: JSONSerialization.data(withJSONObject: object)), field)
        }
    }

}

func makeState() throws -> GameState {
    let hero = Hero(id: ID(), name: "Мира", kind: .guardian, avatar: .fox,
                    abilities: Abilities(might: 3, agility: 1, insight: 2), maximumHealth: 12,
                    health: 12, defense: 12, attackBonus: 3, damage: 3, inventory: [])
    let scenes = [Scene(id: ID(), kind: .conversation, title: "Порт", text: "Разговор"),
                  Scene(id: ID(), kind: .battle, title: "Двор", text: "Бой"),
                  Scene(id: ID(), kind: .ending, title: "Свет", text: "Финал")]
    let enemy = Enemy(id: ID(), kind: .brassMite, name: "Клещ", maximumHealth: 4, health: 4,
                      defense: 10, attackBonus: 1, damage: 2)
    let adventure = Adventure(id: ID(), title: "Маяк", premise: "Туман", scenes: scenes,
                              items: [Item(id: ID(), name: "Ключ")], enemies: [enemy])
    return try GameState(hero: hero, adventure: adventure)
}
