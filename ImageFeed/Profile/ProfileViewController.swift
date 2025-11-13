import UIKit
import Kingfisher

final class ProfileViewController: UIViewController {

    private enum Constants {
        static let avatarCornerRadius: CGFloat = 35
    }

    private var presenter: ProfilePresenterProtocol?

    private(set) lazy var userPickView = UIImageView()
    private(set) lazy var nameLabel = UILabel()
    private(set) lazy var logoutButton = UIButton(type: .custom)
    private(set) lazy var loginLabel = UILabel()
    private(set) lazy var descriptionLabel = UILabel()

    // MARK: - Configuration

    func configure(presenter: ProfilePresenterProtocol) {
        self.presenter = presenter
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupUIObjects()
        setupConstraints()
        if presenter == nil {
            presenter = ProfilePresenter(view: self)
        }
        presenter?.viewDidLoad()
    }

    // MARK: - UI Setup

    private func setupView() {
        view.backgroundColor = UIColor(named: "YP Black")
    }

    private func setupUIObjects() {
        setupUserPickView()
        setupLogoutButton()
        setupNameLabel()
        setupLoginLabel()
        setupDescriptionLabel()
    }

    private func setupUserPickView() {
        userPickView.layer.masksToBounds = true
        userPickView.layer.cornerRadius = 35
        userPickView.contentMode = .scaleAspectFill
        userPickView.translatesAutoresizingMaskIntoConstraints = false
        userPickView.accessibilityIdentifier = "profile-avatar-image-view"
        view.addSubview(userPickView)
    }

    private func setupLogoutButton() {
        let image = UIImage(named: "Exit")?.withRenderingMode(.alwaysOriginal)
            ?? UIImage(systemName: "arrow.backward")

        logoutButton.setImage(image, for: .normal)
        logoutButton.translatesAutoresizingMaskIntoConstraints = false
        logoutButton.accessibilityLabel = "Logout"
        logoutButton.accessibilityIdentifier = "profile-logout-button"
        logoutButton.addTarget(self, action: #selector(didTapLogout), for: .touchUpInside)
        view.addSubview(logoutButton)
    }

    private func setupNameLabel() {
        nameLabel.textColor = UIColor(named: "YP White")
        nameLabel.font = UIFont.systemFont(ofSize: 23, weight: .bold)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.accessibilityIdentifier = "profile-name-label"
        view.addSubview(nameLabel)
    }

    private func setupLoginLabel() {
        loginLabel.textColor = UIColor(named: "YP Gray")
        loginLabel.font = UIFont.systemFont(ofSize: 13)
        loginLabel.translatesAutoresizingMaskIntoConstraints = false
        loginLabel.accessibilityIdentifier = "profile-login-label"
        view.addSubview(loginLabel)
    }

    private func setupDescriptionLabel() {
        descriptionLabel.textColor = UIColor(named: "YP White")
        descriptionLabel.font = UIFont.systemFont(ofSize: 13)
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.accessibilityIdentifier = "profile-description-label"
        view.addSubview(descriptionLabel)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            userPickView.widthAnchor.constraint(equalToConstant: 70),
            userPickView.heightAnchor.constraint(equalTo: userPickView.widthAnchor),
            userPickView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            userPickView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32),

            logoutButton.heightAnchor.constraint(equalToConstant: 44),
            logoutButton.widthAnchor.constraint(equalToConstant: 44),
            logoutButton.centerYAnchor.constraint(equalTo: userPickView.centerYAnchor),
            logoutButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),

            nameLabel.leadingAnchor.constraint(equalTo: userPickView.leadingAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            nameLabel.topAnchor.constraint(equalTo: userPickView.bottomAnchor, constant: 8),

            loginLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            loginLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            loginLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),

            descriptionLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            descriptionLabel.topAnchor.constraint(equalTo: loginLabel.bottomAnchor, constant: 8)
        ])
    }

    // MARK: - Update UI

    private func updateProfileDetails(viewModel: ProfileViewModel) {
        nameLabel.text = viewModel.name
        loginLabel.text = viewModel.login
        descriptionLabel.text = viewModel.bio
        descriptionLabel.isHidden = viewModel.bio?.isEmpty ?? true
    }

    private func updateAvatar(with url: URL?) {
        let placeholder = UIImage(named: "profileImage") ?? UIImage(systemName: "person.crop.circle.fill")
        let processor = RoundCornerImageProcessor(cornerRadius: Constants.avatarCornerRadius)

        guard let url else {
            userPickView.kf.cancelDownloadTask()
            userPickView.image = placeholder
            return
        }

        userPickView.kf.indicatorType = .activity
        userPickView.kf.setImage(
            with: url,
            placeholder: placeholder,
            options: [
                .processor(processor),
                .scaleFactor(UIScreen.main.scale),
                .cacheOriginalImage
            ]
        )
    }

    // MARK: - Actions

    @objc private func didTapLogout() {
        presenter?.didTapLogout()
    }
}

// MARK: - ProfileView

extension ProfileViewController: ProfileView {
    func displayProfile(_ viewModel: ProfileViewModel) {
        updateProfileDetails(viewModel: viewModel)
    }

    func displayAvatar(with url: URL?) {
        updateAvatar(with: url)
    }

    func presentLogoutAlert(confirmHandler: @escaping () -> Void) {
        let alert = UIAlertController(
            title: "Пока, пока!",
            message: "Уверены, что хотите выйти?",
            preferredStyle: .alert
        )
        alert.addAction(.init(title: "Нет", style: .cancel))
        alert.addAction(.init(title: "Да", style: .default, handler: { _ in
            confirmHandler()
        }))
        present(alert, animated: true)
    }
}
