import XCTest

@MainActor
final class AgainstRobotUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testHomeOpensEveryPlaceholder() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.navigationBars["AgainstRobot"].exists)
        let destinations = [
            ("route.character", "Персонаж"),
            ("route.premise", "Завязка"),
            ("route.game", "Игра"),
            ("route.heroCard", "Карточка героя")
        ]

        for (identifier, title) in destinations {
            app.buttons[identifier].tap()
            XCTAssertTrue(app.navigationBars[title].waitForExistence(timeout: 5))
            app.navigationBars.buttons.element(boundBy: 0).tap()
            XCTAssertTrue(app.navigationBars["AgainstRobot"].exists)
        }
    }

    func testMockModeStartsEnabledAndCanBeSwitched() {
        let app = XCUIApplication()
        app.launch()

        let toggle = app.switches["mockModeToggle"]
        XCTAssertEqual(toggle.value as? String, "1")
        XCTAssertTrue(app.staticTexts["Локальный режим. Запросов к API нет."].exists)

        toggle.tap()
        XCTAssertEqual(toggle.value as? String, "0")
        XCTAssertTrue(app.staticTexts["Сервис не подключён. Запросов к API нет."].exists)

        toggle.tap()
        XCTAssertEqual(toggle.value as? String, "1")
        XCTAssertTrue(app.staticTexts["Локальный режим. Запросов к API нет."].exists)
    }
}
