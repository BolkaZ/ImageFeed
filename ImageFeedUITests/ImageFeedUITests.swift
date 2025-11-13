import XCTest
import UIKit

enum AuthData {
    static let login = ""
    static let password = ""
}

class ImageFeedUITests: XCTestCase {
    private let app = XCUIApplication()
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchArguments = ["testMode"]
        app.launch()
    }
    
    func testAuth() throws {
        app.buttons["Войти"].tap()
        
        let webView = app.webViews["UnsplashWebView"]
        
        XCTAssertTrue(webView.waitForExistence(timeout: 10))

        let loginTextField = webView.descendants(matching: .textField).element
        XCTAssertTrue(loginTextField.waitForExistence(timeout: 10))
        
        loginTextField.tap()
        sleep(10)
        loginTextField.typeText(AuthData.login)
        webView.swipeUp()
        
        tapKeyboardArrowDownIfPresent()
        
        sleep(10)
        
        let passwordTextField = webView.descendants(matching: .secureTextField).element
        XCTAssertTrue(passwordTextField.waitForExistence(timeout: 10))
        
        passwordTextField.tap()
        passwordTextField.typeText(AuthData.password)
        webView.swipeUp()
        loginTextField.tap()
        webView.buttons["Login"].tap()
        
        let tablesQuery = app.tables
        let cell = tablesQuery.children(matching: .cell).element(boundBy: 0)
        
        XCTAssertTrue(cell.waitForExistence(timeout: 20))
    }
    
    func testFeed() throws {
        let tablesQuery = app.tables
        
        let cell = tablesQuery.children(matching: .cell).element(boundBy: 0)
        cell.swipeUp()
        
        sleep(2)
        
        let cellToLike = tablesQuery.children(matching: .cell).element(boundBy: 1)
        XCTAssertTrue(cellToLike.waitForExistence(timeout: 5))

        cellToLike.buttons["Like"].tap()
        cellToLike.buttons["Like"].tap()
        
        sleep(2)
        
        cellToLike.tap()
        
        sleep(2)
        
        let image = app.scrollViews.images.element(boundBy: 0)
        XCTAssertTrue(image.waitForExistence(timeout: 5))
        sleep(10)
        
        image.pinch(withScale: 3, velocity: 1)
        
        image.pinch(withScale: 0.5, velocity: -1)
        
        let navBackButtonWhiteButton = app.buttons["Backward"]
        navBackButtonWhiteButton.tap()
    }
    
    func testProfile() throws {
        sleep(3)
        app.tabBars.buttons.element(boundBy: 1).tap()
       
        #warning("Пробел в конце если нет lastName")
        XCTAssertTrue(app.staticTexts["Kirill Ivanov"].exists)
        XCTAssertTrue(app.staticTexts["@bolkazzz"].exists)
        
        app.buttons["Logout"].tap()
        
        app.alerts["Пока, пока!"].scrollViews.otherElements.buttons["Да"].tap()
        
        sleep(3)
    }
    
    private func tapKeyboardArrowDownIfPresent() {
        let toolbar = app.toolbars.firstMatch
        guard toolbar.waitForExistence(timeout: 2) else { return }
        let candidates = ["Chevron Down", "Down", "Вниз", "↓", "next", "Next"]
        for title in candidates {
            let btn = toolbar.buttons[title]
            if btn.exists {
                btn.tap()
                usleep(300_000)
                return
            }
        }
        let allButtons = toolbar.buttons.allElementsBoundByIndex
        if let last = allButtons.last, last.exists {
            last.tap()
            usleep(300_000)
        }
    }
}

