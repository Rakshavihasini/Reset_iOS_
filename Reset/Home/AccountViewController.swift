//
//  AccountViewController.swift
//  Reset
//
//  Created by Prasanjit Panda on 08/01/25.
//


import UIKit
import FirebaseAuth

class AccountViewController: UIViewController {
    
    // MARK: - Properties
    private let accountLabel: UILabel = {
        let label = UILabel()
        label.text = "account"
        label.font = .systemFont(ofSize: 24, weight: .semibold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let cardView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray6
        view.layer.cornerRadius = 12
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let usernameLabel: UILabel = {
        let label = UILabel()
        label.text = "username"
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let usernameValueLabel: UILabel = {
        let label = UILabel()
        label.text = "Loading..."
        label.textColor = .label
        label.font = .systemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let emailLabel: UILabel = {
        let label = UILabel()
        label.text = "email"
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let emailValueLabel: UILabel = {
        let label = UILabel()
        label.text = "Loading..."
        label.textColor = .label
        label.font = .systemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let deactivateButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("deactivate account", for: .normal)
        button.setTitleColor(.systemRed, for: .normal)
        button.backgroundColor = .systemGray6
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.tintColor = .label
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true
        return button
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        fetchUserData()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(closeButton)
        view.addSubview(accountLabel)
        view.addSubview(cardView)
        view.addSubview(deactivateButton)
        
        cardView.addSubview(usernameLabel)
        cardView.addSubview(usernameValueLabel)
        cardView.addSubview(emailLabel)
        cardView.addSubview(emailValueLabel)
        
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        deactivateButton.addTarget(self, action: #selector(deactivateButtonTapped), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            // Close Button
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Account Label
            accountLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            accountLabel.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),
            
            // Card View
            cardView.topAnchor.constraint(equalTo: accountLabel.bottomAnchor, constant: 24),
            cardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            // Username Label
            usernameLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),
            usernameLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            
            // Username Value
            usernameValueLabel.centerYAnchor.constraint(equalTo: usernameLabel.centerYAnchor),
            usernameValueLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            
            // Email Label
            emailLabel.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor, constant: 24),
            emailLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            emailLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -16),
            
            // Email Value
            emailValueLabel.centerYAnchor.constraint(equalTo: emailLabel.centerYAnchor),
            emailValueLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            
            // Deactivate Button
            deactivateButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            deactivateButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            deactivateButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            deactivateButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    // MARK: - Data Fetching
    private func fetchUserData() {
        AuthService.shared.fetchUser { [weak self] user, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let error = error {
                    // Handle error - show alert
                    print("Error fetching user: \(error)")
                    return
                }
                
                if let user = user {
                    self.usernameValueLabel.text = user.username
                    self.emailValueLabel.text = user.email
                }
            }
        }
    }
    
    // MARK: - Actions
    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func deactivateButtonTapped() {
        let alert = UIAlertController(
            title: "Deactivate Account",
            message: "Are you sure you want to deactivate your account? This action cannot be undone.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Deactivate", style: .destructive) { [weak self] _ in
            // Handle account deactivation
            self?.handleAccountDeactivation()
        })
        
        present(alert, animated: true)
    }
    
    private func handleAccountDeactivation() {
        // Show loading indicator or disable UI
        let loadingAlert = UIAlertController(title: nil, message: "Deactivating account...", preferredStyle: .alert)
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = .medium
        loadingIndicator.startAnimating()
        loadingAlert.view.addSubview(loadingIndicator)
        present(loadingAlert, animated: true)

        // Get current user
        guard let user = Auth.auth().currentUser else {
            loadingAlert.dismiss(animated: true)
            showError(message: "No user found")
            return
        }

        // Re-authenticate user before deletion
        let alertController = UIAlertController(
            title: "Confirm Deletion",
            message: "Please enter your password to confirm account deletion",
            preferredStyle: .alert
        )

        alertController.addTextField { textField in
            textField.placeholder = "Password"
            textField.isSecureTextEntry = true
        }

        let confirmAction = UIAlertAction(title: "Confirm", style: .destructive) { [weak self] _ in
            guard let password = alertController.textFields?.first?.text,
                  let email = user.email else {
                self?.showError(message: "Please enter your password")
                return
            }

            // Create credentials
            let credential = EmailAuthProvider.credential(withEmail: email, password: password)

            // Re-authenticate
            user.reauthenticate(with: credential) { [weak self] _, error in
                if let error = error {
                    loadingAlert.dismiss(animated: true)
                    self?.showError(message: "Authentication failed: \(error.localizedDescription)")
                    return
                }

                // Delete the user
                user.delete { [weak self] error in
                    loadingAlert.dismiss(animated: true)
                    
                    if let error = error {
                        self?.showError(message: "Failed to delete account: \(error.localizedDescription)")
                        return
                    }

                    // Successfully deleted user, navigate to login screen
                    DispatchQueue.main.async {
                        if let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate {
                            sceneDelegate.checkAuthentication()
                        } else {
                            let loginVC = LoginController()
                            let nav = UINavigationController(rootViewController: loginVC)
                            nav.modalPresentationStyle = .fullScreen
                            self?.present(nav, animated: true)
                        }
                    }
                }
            }
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            loadingAlert.dismiss(animated: true)
        }

        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)

        loadingAlert.dismiss(animated: true) {
            self.present(alertController, animated: true)
        }
    }

    private func showError(message: String) {
        let alert = UIAlertController(
            title: "Error",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
