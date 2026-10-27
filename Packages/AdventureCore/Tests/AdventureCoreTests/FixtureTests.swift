import XCTest
@testable import AdventureCore

final class FixtureTests: XCTestCase {
    func testBothPremisesAndHeroPresetsProduceValidatedStableCatalogs() throws {
        for index in 0...1 {
            for kind in HeroKind.allCases {
                let state = try AdventureFixtures.newSession(name: "  Мира  ", kind: kind, avatar: .moon, premiseIndex: index)
                XCTAssertEqual(state.hero.name, "Мира")
                XCTAssertEqual(state.hero.kind, kind)
                XCTAssertEqual(state.hero.avatar, .moon)
                XCTAssertEqual(state.hero.maximumHealth, kind == .guardian ? 12 : 10)
                XCTAssertEqual(state.adventure.scenes.map(\.kind), [.conversation, .exploration, .battle, .ending])
                XCTAssertEqual(Set(state.adventure.enemies.map(\.kind)), [.brassMite, .signalWarden])
                let repeated = try AdventureFixtures.newSession(name: "Другой", premiseIndex: index)
                XCTAssertEqual(state.adventure, repeated.adventure)
                XCTAssertEqual(state.hero.inventory.map(\.quantity), [1, 1])
                try state.validate()
            }
        }
        XCTAssertThrowsError(try AdventureFixtures.newSession(name: " \n "))
        XCTAssertThrowsError(try AdventureFixtures.newSession(name: "Мира", premiseIndex: 2))
    }

    func testScriptedScenarioTraversesConversationCheckTwoEnemyBattleAndEnding() throws {
        var state = try AdventureFixtures.newSession(name: "Мира")
        try state.apply(.begin)
        try state.apply(.narrate(Message(speaker: .player, text: "Расспрашиваю рыбачку о маяке.")))
        try state.apply(.move(state.adventure.scenes[1].id))
        let request = CheckRequest(sceneID: state.sceneID, ability: .agility, difficulty: 12)
        try state.apply(.requestCheck(request))
        try state.apply(.resolveCheck(request.id, face: 14, resultID: ID()))
        XCTAssertTrue(state.rolls[0].succeeded)
        try state.apply(.move(state.adventure.scenes[2].id))
        try state.apply(.startCombat(ID()))
        XCTAssertEqual(state.combat?.enemies.count, 2)
        for enemy in state.adventure.enemies { try state.apply(.damageEnemy(enemy.id, amount: enemy.maximumHealth)) }
        try state.apply(.finishCombat)
        try state.apply(.move(state.adventure.scenes[3].id))
        try state.apply(.complete)
        XCTAssertEqual(state.outcome, .victory)
        XCTAssertEqual(state.hero.health, 12)
    }
}
