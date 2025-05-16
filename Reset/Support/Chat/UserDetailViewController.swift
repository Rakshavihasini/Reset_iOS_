import UIKit
import SendbirdUIKit
import SendbirdChatSDK
import FirebaseFirestore

class UserDetailViewController: UIViewController {
    
    private let userId: String
    private var username: String = ""
    private var profileUrl: String = ""
    private var resetCount: Int = 0
    private var soberSince: Date?
    private var currentStreak: Int = 0
    
    // UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let profileImageView = UIImageView()
    private let nameLabel = UILabel()
    private let statsStackView = UIStackView()
    private let messageButton = UIButton(type: .system)
    
    // Stats Views
    private let resetCountView = StatItemView(title: "Total Resets")
    private let soberSinceView = StatItemView(title: "Sober Since")
    private let streakView = StatItemView(title: "Current Streak")
    
    init(userId: String) {
        self.userId = userId
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        fetchUserDetails()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Setup ScrollView
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // Profile Image Setup
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.clipsToBounds = true
        profileImageView.layer.cornerRadius = 60
        profileImageView.backgroundColor = .systemGray5
        contentView.addSubview(profileImageView)
        
        // Name Label Setup
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.textAlignment = .center
        nameLabel.font = .systemFont(ofSize: 24, weight: .bold)
        contentView.addSubview(nameLabel)
        
        // Stats Stack View Setup
        statsStackView.translatesAutoresizingMaskIntoConstraints = false
        statsStackView.axis = .horizontal
        statsStackView.distribution = .fillEqually
        statsStackView.spacing = 20
        statsStackView.addArrangedSubview(resetCountView)
        statsStackView.addArrangedSubview(soberSinceView)
        statsStackView.addArrangedSubview(streakView)
        contentView.addSubview(statsStackView)
        
        // Message Button Setup
        messageButton.translatesAutoresizingMaskIntoConstraints = false
        messageButton.setTitle("Message", for: .normal)
        messageButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        messageButton.backgroundColor = .systemBrown
        messageButton.setTitleColor(.white, for: .normal)
        messageButton.layer.cornerRadius = 16
        messageButton.addTarget(self, action: #selector(startChat), for: .touchUpInside)
        contentView.addSubview(messageButton)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // ScrollView
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Content View
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Profile Image
            profileImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 30),
            profileImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 120),
            profileImageView.heightAnchor.constraint(equalToConstant: 120),
            
            // Name Label
            nameLabel.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 16),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Stats Stack View
            statsStackView.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 30),
            statsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            statsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Message Button
            messageButton.topAnchor.constraint(equalTo: statsStackView.bottomAnchor, constant: 40),
            messageButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 30),
            messageButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -30),
            messageButton.heightAnchor.constraint(equalToConstant: 50),
            messageButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -30)
        ])
    }
    
    private func fetchUserDetails() {
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { [weak self] snapshot, error in
            if let error = error {
                print("Failed to fetch user details: \(error.localizedDescription)")
                return
            }
            
            guard let data = snapshot?.data(),
                  let username = data["username"] as? String,
                  let profileUrl = data["imageUrl"] as? String else {
                print("Invalid user data.")
                return
            }
            
            // Extract additional stats
            let resetCount = data["numberOfResets"] as? Int ?? 0
            let soberSinceTimestamp = data["soberSince"] as? Timestamp
            let streak = data["soberStreak"] as? Int ?? 0
            
            DispatchQueue.main.async {
                self?.updateUI(
                    username: username,
                    profileUrl: profileUrl,
                    resetCount: resetCount,
                    soberSince: soberSinceTimestamp?.dateValue(),
                    streak: streak
                )
            }
        }
    }
    
    private func updateUI(username: String, profileUrl: String, resetCount: Int, soberSince: Date?, streak: Int) {
        self.nameLabel.text = username
        
        if let url = URL(string: profileUrl) {
            loadImage(from: url)
        }
        
        // Update stats
        resetCountView.setValue("\(resetCount)")
        
        if let soberSince = soberSince {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "MMM d, yyyy"
                    soberSinceView.setValue(formatter.string(from: soberSince))
        } else {
                    soberSinceView.setValue("Not set")
        }
        
        streakView.setValue("\(streak) days")
    }
    
    private func loadImage(from url: URL) {
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let data = data, error == nil else { return }
            DispatchQueue.main.async {
                self?.profileImageView.image = UIImage(data: data)
            }
        }.resume()
    }
    
    @objc private func startChat() {
        let params = GroupChannelCreateParams()
        params.userIds = [userId]
        params.isDistinct = true
        
        GroupChannel.createChannel(params: params) { [weak self] channel, error in
            guard let channel = channel, error == nil else { return }
            DispatchQueue.main.async {
                let chatVC = SBUGroupChannelViewController(channelURL: channel.channelURL)
                self?.navigationController?.pushViewController(chatVC, animated: true)
            }
        }
    }
}

// MARK: - Helper Views
class StatItemView: UIView {
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    private let stackView = UIStackView()
    
    init(title: String) {
        super.init(frame: .zero)
        
        setupView()
        titleLabel.text = title
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 8
        addSubview(stackView)
        
        titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = .secondaryLabel
        valueLabel.font = .systemFont(ofSize: 18, weight: .bold)
        
        stackView.addArrangedSubview(valueLabel)
        stackView.addArrangedSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    func setValue(_ value: String) {
        valueLabel.text = value
    }
}
