import UIKit
import Kingfisher

final class ProfileViewController: UIViewController {

    private let userPickView = UIImageView()
    private let nameLabel = UILabel()
    private let logoutButton = UIButton(type: .custom)
    private let loginLabel = UILabel()
    private let descriptionLabel = UILabel()

    private var profileImageServiceObserver: NSObjectProtocol?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupUIObjects()
        setupConstraints()

        if let profile = ProfileService.shared.profile {
            updateProfileDetails(profile: profile)
        }

        profileImageServiceObserver = NotificationCenter.default.addObserver(
            forName: ProfileImageService.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateAvatar()
        }

        updateAvatar()
    }

    deinit {
        if let observer = profileImageServiceObserver {
            NotificationCenter.default.removeObserver(observer)
        }
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
        view.addSubview(userPickView)
    }

    private func setupLogoutButton() {
        let image = UIImage(named: "Exit")?.withRenderingMode(.alwaysOriginal)
            ?? UIImage(systemName: "arrow.backward")

        logoutButton.setImage(image, for: .normal)
        logoutButton.translatesAutoresizingMaskIntoConstraints = false
        logoutButton.accessibilityLabel = "Logout"
        logoutButton.addTarget(self, action: #selector(didTapLogout), for: .touchUpInside)
        view.addSubview(logoutButton)
    }

    private func setupNameLabel() {
        nameLabel.textColor = UIColor(named: "YP White")
        nameLabel.font = UIFont.systemFont(ofSize: 23, weight: .bold)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(nameLabel)
    }

    private func setupLoginLabel() {
        loginLabel.textColor = UIColor(named: "YP Gray")
        loginLabel.font = UIFont.systemFont(ofSize: 13)
        loginLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loginLabel)
    }

    private func setupDescriptionLabel() {
        descriptionLabel.textColor = UIColor(named: "YP White")
        descriptionLabel.font = UIFont.systemFont(ofSize: 13)
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
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

    private func updateProfileDetails(profile: Profile) {
        nameLabel.text = profile.name
        loginLabel.text = profile.loginName
        descriptionLabel.text = profile.bio
    }

    private func updateAvatar() {
        guard
            let profileImageURL = ProfileImageService.shared.avatarURL,
            let url = URL(string: profileImageURL)
        else { return }

        let placeholder = UIImage(named: "profileImage") ?? UIImage(systemName: "person.crop.circle.fill")
        let processor = RoundCornerImageProcessor(cornerRadius: 35)

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
        let alert = UIAlertController(
            title: "Пока, пока!",
            message: "Уверены, что хотите выйти?",
            preferredStyle: .alert
        )
        alert.addAction(.init(title: "Нет", style: .cancel))
        alert.addAction(.init(title: "Да", style: .default, handler: { [weak self] _ in
            guard let self else { return }
            ProfileLogoutService.shared.logout()
        }))
        present(alert, animated: true)
    }
}
