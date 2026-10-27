import XCTest

@MainActor
final class AgainstRobotUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // Catches lost hero selection, ignored premise input, broken chat/roll state,
    // or navigation that discards the current in-memory adventure.
    func testNewAdventureCarriesHeroAndMessagesThroughTheWholeJourney() {
        let app = XCUIApplication()
        app.launch()
        app.buttons["newGame"].tap()
        XCTAssertTrue(app.navigationBars["Персонаж"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["character.continue"].isEnabled)
        app.buttons["hero.scout"].tap()
        app.buttons["avatar.moon"].tap()
        app.textFields["character.name"].tap()
        app.textFields["character.name"].typeText("Ася\n")
        app.buttons["character.continue"].tap()

        XCTAssertTrue(app.staticTexts["Маяк в тумане"].waitForExistence(timeout: 5))
        app.textFields["premise.hint"].tap()
        app.textFields["premise.hint"].typeText("Без пауков\n")
        app.buttons["premise.regenerate"].tap()
        XCTAssertTrue(app.staticTexts["Тайна лесной станции"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "Без пауков")).firstMatch.exists)
        capture(app, "01-premise-with-player-hint")
        app.buttons["premise.accept"].tap()

        XCTAssertTrue(app.navigationBars["Игра"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.navigationBars.buttons["Завязка"].exists, "Starting play must end character creation navigation")
        XCTAssertFalse(app.buttons["game.send"].isEnabled)
        app.textFields["game.input"].tap()
        app.textFields["game.input"].typeText("Осматриваю дверь\n")
        app.buttons["game.send"].tap()
        XCTAssertTrue(app.staticTexts["Осматриваю дверь"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["game.roll"].waitForExistence(timeout: 5))
        app.buttons["game.roll"].tap()
        XCTAssertTrue(app.staticTexts["Тестовый бросок: 14. Дверь открыта."].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["game.roll"].exists)
        capture(app, "02-chat-and-mock-roll")

        app.buttons["game.hero"].tap()
        XCTAssertTrue(app.navigationBars["Карточка героя"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Ася"].exists)
        XCTAssertTrue(app.staticTexts["Следопыт"].exists)
        XCTAssertTrue(app.staticTexts["Луна"].exists)
        capture(app, "03-selected-hero-sheet")
        app.buttons["hero.close"].tap()
        app.buttons["game.home"].tap()
        XCTAssertTrue(app.navigationBars["AgainstRobot"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["resumeGame"].exists)
        capture(app, "04-home-with-current-adventure")
        app.buttons["resumeGame"].tap()
        XCTAssertTrue(app.staticTexts["Осматриваю дверь"].waitForExistence(timeout: 5))
    }

    // Catches back navigation losing drafts, whitespace validation regressions,
    // and a history entry that cannot open its demonstration transcript.
    func testBackNavigationValidationAndDemoHistory() {
        let app = XCUIApplication()
        app.launch()
        app.buttons["newGame"].tap()
        app.textFields["character.name"].tap()
        app.textFields["character.name"].typeText("   \n")
        XCTAssertFalse(app.buttons["character.continue"].isEnabled)
        app.textFields["character.name"].tap()
        app.textFields["character.name"].typeText("Мира\n")
        app.buttons["character.continue"].tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertEqual(app.textFields["character.name"].value as? String, "   Мира")
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.buttons["history.demo"].tap()
        XCTAssertTrue(app.navigationBars["Игра"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Это пример истории. Сохранения появятся позже."].exists)
        capture(app, "05-demo-history")
        app.buttons["game.home"].tap()
    }

    // Browsing a sample must not overwrite the player's hero, transcript or
    // unfinished roll. A long action also exercises wrapping in the transcript.
    func testBrowsingDemoHistoryPreservesCurrentAdventureAndPendingRoll() {
        let app = XCUIApplication()
        app.launch()
        app.buttons["newGame"].tap()
        app.textFields["character.name"].tap()
        app.textFields["character.name"].typeText("Лея\n")
        app.buttons["character.continue"].tap()
        app.buttons["premise.accept"].tap()
        let action = "Осматриваю замок, проверяю следы на пороге и прислушиваюсь к шагам за дверью, прежде чем осторожно повернуть найденный медный ключ."
        app.textFields["game.input"].tap()
        app.textFields["game.input"].typeText(action + "\n")
        app.buttons["game.send"].tap()
        XCTAssertTrue(app.buttons["game.roll"].waitForExistence(timeout: 5))
        app.buttons["game.home"].tap()
        app.buttons["history.demo"].tap()
        XCTAssertTrue(app.staticTexts["Это пример истории. Сохранения появятся позже."].exists)
        app.buttons["game.home"].tap()
        app.buttons["resumeGame"].tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label == %@", action)).firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["game.roll"].exists)
        capture(app, "06-active-adventure-preserved-after-history")
        app.buttons["game.hero"].tap()
        XCTAssertTrue(app.staticTexts["Лея"].waitForExistence(timeout: 5))
    }

    private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testMockModeStartsEnabledAndCanBeSwitched() {
        let app = XCUIApplication()
        app.launch()

        let toggle = app.switches["mockModeToggle"]
        // SwiftUI exposes the labeled row as a switch containing the actual control.
        let switchControl = toggle.switches.firstMatch
        XCTAssertEqual(toggle.value as? String, "1")
        XCTAssertTrue(app.staticTexts["Локальный режим. Запросов к API нет."].exists)

        switchControl.tap()
        XCTAssertEqual(toggle.value as? String, "0")
        XCTAssertFalse(app.buttons["newGame"].isEnabled)
        XCTAssertTrue(app.staticTexts["Сервис не подключён. Запросов к API нет."].exists)

        switchControl.tap()
        XCTAssertEqual(toggle.value as? String, "1")
        XCTAssertTrue(app.staticTexts["Локальный режим. Запросов к API нет."].exists)
    }
}
