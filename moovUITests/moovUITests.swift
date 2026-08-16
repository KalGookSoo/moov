//
//  moovUITests.swift
//  moovUITests
//

import XCTest

/// docs/testing-strategy.md의 핵심 플로우 3가지를 커버한다.
final class moovUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// -uiTesting: 인메모리 저장소 사용, -uiTestResetState: 온보딩/업데이트 안내 상태 초기화.
    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-uiTesting", "-uiTestResetState"]
        app.launch()
        return app
    }

    private func skipOnboardingIfPresent(_ app: XCUIApplication) {
        let skipButton = app.buttons["건너뛰기"]
        if skipButton.waitForExistence(timeout: 3) {
            skipButton.tap()
        }
    }

    @MainActor
    func testOnboardingShowsOnFirstLaunchAndDismissesToMainTabs() throws {
        let app = launchApp()

        XCTAssertTrue(app.staticTexts["세션"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["다음"].waitForExistence(timeout: 2))

        app.buttons["다음"].tap()
        XCTAssertTrue(app.staticTexts["히스토리"].waitForExistence(timeout: 2))

        app.buttons["다음"].tap()
        XCTAssertTrue(app.staticTexts["PR"].waitForExistence(timeout: 2))

        app.buttons["다음"].tap()
        XCTAssertTrue(app.staticTexts["관리"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["시작하기"].exists)

        app.buttons["시작하기"].tap()

        XCTAssertTrue(app.tabBars.buttons["세션"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testCreateSessionWithPartAndBlock() throws {
        let app = launchApp()
        skipOnboardingIfPresent(app)

        XCTAssertTrue(app.buttons["세션 기록하기"].waitForExistence(timeout: 5))
        app.buttons["세션 기록하기"].tap()

        XCTAssertTrue(app.buttons["파트 추가"].waitForExistence(timeout: 5))
        app.buttons["파트 추가"].tap()

        app.buttons["EMOM, 블록 없음"].tap()

        XCTAssertTrue(app.buttons["블록 추가"].waitForExistence(timeout: 5))
        app.buttons["블록 추가"].tap()

        XCTAssertTrue(app.buttons["종목 추가"].waitForExistence(timeout: 5))
        app.buttons["종목 추가"].tap()

        let nameField = app.alerts.textFields.firstMatch
        XCTAssertTrue(nameField.waitForExistence(timeout: 3))
        nameField.typeText("Back Squat")
        app.alerts.buttons["추가"].tap()

        app.navigationBars.buttons["저장"].tap() // 블록 저장 → 파트 화면으로 복귀
        app.navigationBars.buttons["세션 기록"].tap() // 뒤로가기 → 세션 작성 화면으로 복귀
        app.navigationBars.buttons["저장"].tap() // 세션 저장 → 목록으로 복귀

        let sessionRow = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "EMOM")).firstMatch
        XCTAssertTrue(sessionRow.waitForExistence(timeout: 5))
    }

    @MainActor
    func testPRWarnsWhenNewValueIsLowerThanExistingBest() throws {
        let app = launchApp()
        skipOnboardingIfPresent(app)

        app.tabBars.buttons["PR"].tap()

        XCTAssertTrue(app.navigationBars.buttons["PR 등록"].waitForExistence(timeout: 5))
        app.navigationBars.buttons["PR 등록"].tap()

        app.buttons["종목 추가"].tap()
        let nameField = app.alerts.textFields.firstMatch
        XCTAssertTrue(nameField.waitForExistence(timeout: 3))
        nameField.typeText("Back Squat")
        app.alerts.buttons["추가"].tap()

        let weightField = app.textFields["중량"]
        weightField.tap()
        weightField.typeText("100")
        app.navigationBars.buttons["저장"].tap()

        // 두 번째 등록: 같은 종목에 더 낮은 값 → 경고 다이얼로그가 떠야 한다.
        app.navigationBars.buttons["PR 등록"].tap()
        app.buttons["종목, 선택 안 함"].tap()
        app.buttons["Back Squat"].tap()

        let weightField2 = app.textFields["중량"]
        weightField2.tap()
        weightField2.typeText("90")
        app.navigationBars.buttons["저장"].tap()

        XCTAssertTrue(app.staticTexts["기존 PR보다 낮은 값이에요"].waitForExistence(timeout: 3))
    }
}
