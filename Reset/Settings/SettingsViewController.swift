import UIKit
import FirebaseAuth

class SettingsViewController: UIViewController {
    
    // MARK: - UI Components
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "settings"
        label.font = .systemFont(ofSize: 24, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let dismissButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let profileCardView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground// Dark gray background
        view.layer.cornerRadius = 12
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 25 // Half of the height for circular image
        imageView.backgroundColor = .gray // Placeholder color
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let chevronImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "chevron.right")
        imageView.tintColor = .gray
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let logoutButton: UIButton = {
        let button = UIButton()
        button.setTitle("Logout", for: .normal)
        button.setTitleColor(.systemRed, for: .normal)
        button.backgroundColor = .systemGray6
        button.layer.cornerRadius = 12
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let privacyPolicyLabel: UILabel = {
        let label = UILabel()
        label.text = "Privacy Policy"
        label.textColor = .systemBlue
        label.font = .systemFont(ofSize: 14)
        label.isUserInteractionEnabled = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let termsLabel: UILabel = {
        let label = UILabel()
        label.text = "Terms & Conditions"
        label.textColor = .systemBlue
        label.font = .systemFont(ofSize: 14)
        label.isUserInteractionEnabled = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        if let cachedImageData = UserDefaults.standard.data(forKey: "profileImage"),
           let cachedImage = UIImage(data: cachedImageData) {
            profileImageView.image = cachedImage
        }
        fetchUserData()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Add subviews
        view.addSubview(titleLabel)
        view.addSubview(dismissButton)
        view.addSubview(profileCardView)
        view.addSubview(logoutButton)
        view.addSubview(privacyPolicyLabel)
        view.addSubview(termsLabel)
        
        profileCardView.addSubview(profileImageView)
        profileCardView.addSubview(nameLabel)
        profileCardView.addSubview(usernameLabel)
        profileCardView.addSubview(chevronImageView)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            // Title Label
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Dismiss Button
            dismissButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            dismissButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            dismissButton.widthAnchor.constraint(equalToConstant: 24),
            dismissButton.heightAnchor.constraint(equalToConstant: 24),
            
            // Profile Card View
            profileCardView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30),
            profileCardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            profileCardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            profileCardView.heightAnchor.constraint(equalToConstant: 70),
            
            // Profile Image View
            profileImageView.leadingAnchor.constraint(equalTo: profileCardView.leadingAnchor, constant: 10),
            profileImageView.centerYAnchor.constraint(equalTo: profileCardView.centerYAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 50),
            profileImageView.heightAnchor.constraint(equalToConstant: 50),
            
            // Name Label
            nameLabel.topAnchor.constraint(equalTo: profileCardView.topAnchor, constant: 15),
            nameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 12),
            
            // Username Label
            usernameLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            usernameLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            
            // Chevron Image View
            chevronImageView.centerYAnchor.constraint(equalTo: profileCardView.centerYAnchor),
            chevronImageView.trailingAnchor.constraint(equalTo: profileCardView.trailingAnchor, constant: -10),
            chevronImageView.widthAnchor.constraint(equalToConstant: 20),
            chevronImageView.heightAnchor.constraint(equalToConstant: 20),
            
            // Logout Button
            logoutButton.topAnchor.constraint(equalTo: profileCardView.bottomAnchor, constant: 20),
            logoutButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            logoutButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            logoutButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Privacy Policy Label
            privacyPolicyLabel.topAnchor.constraint(equalTo: logoutButton.bottomAnchor, constant: 20),
            privacyPolicyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Terms Label
            termsLabel.topAnchor.constraint(equalTo: privacyPolicyLabel.bottomAnchor, constant: 12),
            termsLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        
        // Add targets
        dismissButton.addTarget(self, action: #selector(dismissButtonTapped), for: .touchUpInside)
        logoutButton.addTarget(self, action: #selector(logoutButtonTapped), for: .touchUpInside)
        
        // Add tap gestures for privacy and terms labels
        let privacyTapGesture = UITapGestureRecognizer(target: self, action: #selector(privacyPolicyTapped))
        privacyPolicyLabel.addGestureRecognizer(privacyTapGesture)
        
        let termsTapGesture = UITapGestureRecognizer(target: self, action: #selector(termsTapped))
        termsLabel.addGestureRecognizer(termsTapGesture)
        
        // Add tap gesture to profile card
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(profileCardTapped))
        profileCardView.addGestureRecognizer(tapGesture)
        profileCardView.isUserInteractionEnabled = true
    }
    
    @objc private func chevronTapped(){
        let vc = AccountViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    // MARK: - Data Fetching
    private func fetchUserData() {
        AuthService.shared.fetchUser { [weak self] user, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching user: \(error.localizedDescription)")
                return
            }
            
            if let user = user {
                DispatchQueue.main.async {
                    self.nameLabel.text = user.username
                    self.usernameLabel.text = "@\(user.username.lowercased().replacingOccurrences(of: " ", with: "."))"
                    
                    // Load profile image if available
                    if let imageUrl = URL(string: user.imageURL) {
                        // You might want to use an image loading library here
                        // For now, we'll just print the URL
                        print("Profile image URL: \(imageUrl)")
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    @objc private func dismissButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func profileCardTapped() {
        // Handle profile card tap
        print("Profile card tapped")
        let vc = AccountViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func logoutButtonTapped() {
        let alert = UIAlertController(title: "Logout", message: "Are you sure you want to logout?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Logout", style: .destructive) { [weak self] _ in
            self?.performLogout()
        })
        
        present(alert, animated: true)
    }
    
    private func performLogout() {
        AuthService.shared.signOut { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error signing out: \(error.localizedDescription)")
                // Show an alert to the user
                let alert = UIAlertController(
                    title: "Logout Failed",
                    message: "There was an error logging out. Please try again.",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true)
                return
            }
            
            // Navigate to login screen using SceneDelegate to ensure proper authentication flow
            DispatchQueue.main.async {
                if let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate {
                    sceneDelegate.checkAuthentication()
                } else {
                    // Fallback if we can't access the SceneDelegate
                    let loginVC = LoginController()
                    let nav = UINavigationController(rootViewController: loginVC)
                    nav.modalPresentationStyle = .fullScreen
                    self.present(nav, animated: true)
                }
            }
        }
    }
    
    @objc private func privacyPolicyTapped() {
        if let url = URL(string: "https://resetapp.tech/privacy/") {
            UIApplication.shared.open(url)
        }
    }
    
    @objc private func termsTapped() {
        if let url = URL(string: "https://resetapp.tech/terms/") {
            UIApplication.shared.open(url)
        }
    }
}
