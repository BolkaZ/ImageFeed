import XCTest
@testable import ImageFeed

final class ProfileViewControllerTests: XCTestCase {

    private var sut: ProfileViewController!
    private var presenterSpy: ProfilePresenterSpy!

    override func setUp() {
        super.setUp()
        sut = ProfileViewController()
        presenterSpy = ProfilePresenterSpy()
        sut.configure(presenter: presenterSpy)
    }

    override func tearDown() {
        sut = nil
        presenterSpy = nil
        super.tearDown()
    }

    func testViewDidLoadNotifiesPresenter() {
        sut.loadViewIfNeeded()
        XCTAssertTrue(presenterSpy.viewDidLoadCalled, "Presenter should be notified on viewDidLoad.")
    }

    func testLogoutTapTriggersPresenter() {
        sut.loadViewIfNeeded()
        tapLogoutButton(on: sut.view)
        XCTAssertTrue(presenterSpy.didTapLogoutCalled, "Presenter should handle logout tap.")
    }

    func testDisplayProfileUpdatesLabels() {
        sut.loadViewIfNeeded()
        let model = ProfileViewModel(name: "Name", login: "@login", bio: "Bio")

        sut.displayProfile(model)

        XCTAssertEqual(findLabel(identifier: "profile-name-label")?.text, model.name)
        XCTAssertEqual(findLabel(identifier: "profile-login-label")?.text, model.login)
        XCTAssertEqual(findLabel(identifier: "profile-description-label")?.text, model.bio)
    }

    func testDisplayAvatarWithNilSetsPlaceholder() {
        sut.loadViewIfNeeded()
        sut.displayAvatar(with: nil)

        let imageView = findImageView(identifier: "profile-avatar-image-view")
        XCTAssertNotNil(imageView?.image, "Avatar image view should display placeholder when URL is nil.")
    }
}

// MARK: - Helpers

private extension ProfileViewControllerTests {
    func tapLogoutButton(on view: UIView?) {
        guard
            let button = findLogoutButton(in: view)
        else {
            XCTFail("Logout button not found.")
            return
        }
        button.sendActions(for: .touchUpInside)
    }

    func findLogoutButton(in view: UIView?) -> UIButton? {
        guard let view else { return nil }
        if let button = view as? UIButton, button.accessibilityLabel == "Logout" {
            return button
        }
        for subview in view.subviews {
            if let button = findLogoutButton(in: subview) {
                return button
            }
        }
        return nil
    }

    func findLabel(identifier: String) -> UILabel? {
        sut.view?.findView(withAccessibilityIdentifier: identifier) as? UILabel
    }

    func findImageView(identifier: String) -> UIImageView? {
        sut.view?.findView(withAccessibilityIdentifier: identifier) as? UIImageView
    }
}

// MARK: - Test Doubles

private final class ProfilePresenterSpy: ProfilePresenterProtocol {
    private(set) var viewDidLoadCalled = false
    private(set) var didTapLogoutCalled = false

    func viewDidLoad() {
        viewDidLoadCalled = true
    }

    func didTapLogout() {
        didTapLogoutCalled = true
    }
}

private extension UIView {
    func findView(withAccessibilityIdentifier identifier: String) -> UIView? {
        if accessibilityIdentifier == identifier {
            return self
        }
        for subview in subviews {
            if let found = subview.findView(withAccessibilityIdentifier: identifier) {
                return found
            }
        }
        return nil
    }
}

