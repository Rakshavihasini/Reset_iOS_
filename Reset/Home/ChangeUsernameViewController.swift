import UIKit
import FirebaseFirestore

class ChangeUsernameViewController: UIViewController {
    // MARK: - UI Components
    private let backButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Change Username"
        label.textColor = .white
        label.numberOfLines = 2
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 24, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let aliasTextField: UITextField = {
        let textField = UITextField()
        textField.backgroundColor = .secondarySystemBackground
        textField.layer.cornerRadius = 8
        textField.translatesAutoresizingMaskIntoConstraints = false
        // Add left padding to text field
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: textField.frame.height))
        textField.leftViewMode = .always
        return textField
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "pick any username that you like"
        label.textColor = .gray
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 14)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let addButton: UIButton = {
        let button = UIButton()
        button.setTitle("Done", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0)
        button.layer.cornerRadius = 25
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Properties
    private var currentUser: User?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        fetchCurrentUser()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Add subviews
        view.addSubview(backButton)
        view.addSubview(titleLabel)
        view.addSubview(aliasTextField)
        view.addSubview(descriptionLabel)
        view.addSubview(addButton)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            // Back button
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Title label
            titleLabel.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Text field
            aliasTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30),
            aliasTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            aliasTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            aliasTextField.heightAnchor.constraint(equalToConstant: 50),
            
            // Description label
            descriptionLabel.topAnchor.constraint(equalTo: aliasTextField.bottomAnchor, constant: 15),
            descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Add button
            addButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            addButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            addButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            addButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        // Add targets
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Data Fetching
    private func fetchCurrentUser() {
        AuthService.shared.fetchUser { [weak self] user, error in
            if let error = error {
                self?.showAlert(title: "Error", message: "Failed to fetch user: \(error.localizedDescription)")
                return
            }
            
            guard let user = user else {
                self?.showAlert(title: "Error", message: "No user found")
                return
            }
            
            self?.currentUser = user
            DispatchQueue.main.async {
                self?.aliasTextField.text = user.username
            }
        }
    }
    
    // MARK: - Actions
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func addButtonTapped() {
        guard let newUsername = aliasTextField.text, !newUsername.isEmpty else {
            showAlert(title: "Error", message: "Please enter a username")
            return
        }
        
        guard let userUID = currentUser?.userUID else {
            showAlert(title: "Error", message: "User not found")
            return
        }
        
        // Update username in Firestore
        let db = Firestore.firestore()
        db.collection("users").document(userUID).updateData([
            "username": newUsername
        ]) { [weak self] error in
            if let error = error {
                self?.showAlert(title: "Error", message: "Failed to update username: \(error.localizedDescription)")
            } else {
                self?.showAlert(title: "Success", message: "Username updated successfully") { _ in
                    self?.navigationController?.popViewController(animated: true)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private func showAlert(title: String, message: String, completion: ((UIAlertAction) -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: completion)
        alert.addAction(okAction)
        present(alert, animated: true)
    }
}
