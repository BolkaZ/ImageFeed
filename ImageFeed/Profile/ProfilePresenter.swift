import Foundation

struct ProfileViewModel {
    let name: String
    let login: String
    let bio: String?
}

protocol ProfileView: AnyObject {
    func displayProfile(_ viewModel: ProfileViewModel)
    func displayAvatar(with url: URL?)
    func presentLogoutAlert(confirmHandler: @escaping () -> Void)
}

protocol ProfilePresenterProtocol: AnyObject {
    func viewDidLoad()
    func didTapLogout()
}

final class ProfilePresenter: ProfilePresenterProtocol {

    private weak var view: ProfileView?
    private let profileService: ProfileService
    private let profileImageService: ProfileImageService
    private let logoutService: ProfileLogoutService
    private let notificationCenter: NotificationCenter

    private var profileImageObserver: NSObjectProtocol?

    init(view: ProfileView,
         profileService: ProfileService = .shared,
         profileImageService: ProfileImageService = .shared,
         logoutService: ProfileLogoutService = .shared,
         notificationCenter: NotificationCenter = .default) {
        self.view = view
        self.profileService = profileService
        self.profileImageService = profileImageService
        self.logoutService = logoutService
        self.notificationCenter = notificationCenter
    }

    deinit {
        if let observer = profileImageObserver {
            notificationCenter.removeObserver(observer)
        }
    }

    // MARK: - Lifecycle

    func viewDidLoad() {
        updateProfile()
        observeAvatarUpdates()
        updateAvatar()
    }

    // MARK: - Actions

    func didTapLogout() {
        view?.presentLogoutAlert(confirmHandler: { [weak self] in
            self?.logoutService.logout()
        })
    }

    // MARK: - Private helpers

    private func updateProfile() {
        guard let profile = profileService.profile else { return }
        let viewModel = ProfileViewModel(
            name: profile.name,
            login: profile.loginName,
            bio: profile.bio
        )
        view?.displayProfile(viewModel)
    }

    private func observeAvatarUpdates() {
        profileImageObserver = notificationCenter.addObserver(
            forName: ProfileImageService.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateAvatar()
        }
    }

    private func updateAvatar() {
        let url = profileImageService.avatarURL.flatMap(URL.init(string:))
        view?.displayAvatar(with: url)
    }
}

