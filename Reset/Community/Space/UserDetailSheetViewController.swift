//
//  UserDetailSheetViewController.swift
//  Reset
//
//  Created by PJ on 09/03/25.
//


import UIKit
import SendbirdUIKit
import SendbirdChatSDK
import FirebaseFirestore

class UserDetailSheetViewController: UIViewController {
    
    private let userId: String
    private var username: String = ""
    private var profileUrl: String = ""
    
    // UI Components
    private let containerView = UIView()
    private let headerView = UIView()
    private let profileImageView = UIImageView()
    private let nameLabel = UILabel()
    private let statsView = UIView()
    private let messageButton = UIButton(type: .system)
    
    // Stats Components
    private let statsStackView = UIStackView()
    private let resetCountContainer = UIView()
    private let streakContainer = UIView()
    private let resetCountIconView = UIImageView()
    private let streakIconView = UIImageView()
    private let resetCountLabel = UILabel()
    private let resetCountValueLabel = UILabel()
    private let streakLabel = UILabel()
    private let streakValueLabel = UILabel()
    
    // Visual elements
    private let separatorView = UIView()
    
    init(userId: String) {
        self.userId = userId
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .pageSheet
        if #available(iOS 15.0, *) {
            sheetPresentationController?.detents = [.medium()]
            sheetPresentationController?.prefersGrabberVisible = true
        }
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
        
        // Container View with shadow and rounded corners
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = .systemBackground
        containerView.layer.cornerRadius = 16
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.1
        containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        containerView.layer.shadowRadius = 8
        view.addSubview(containerView)
        
        // Header View with gradient background
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.backgroundColor = .systemBackground
        containerView.addSubview(headerView)
        
        // Profile Image Setup - larger and with border
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.clipsToBounds = true
        profileImageView.layer.cornerRadius = 35
        profileImageView.layer.borderWidth = 3
        profileImageView.layer.borderColor = UIColor.systemBrown.cgColor
        profileImageView.backgroundColor = .systemGray5
        headerView.addSubview(profileImageView)
        
        // Name Label Setup - better typography
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = .systemFont(ofSize: 20, weight: .bold)
        nameLabel.textColor = .label
        headerView.addSubview(nameLabel)
        
        // Separator
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        separatorView.backgroundColor = .systemGray5
        containerView.addSubview(separatorView)
        
        // Stats View Setup - with card-like appearance
        statsView.translatesAutoresizingMaskIntoConstraints = false
        statsView.backgroundColor = .systemGray6
        statsView.layer.cornerRadius = 14
        statsView.clipsToBounds = true
        containerView.addSubview(statsView)
        
        // Stats Stack View
        statsStackView.translatesAutoresizingMaskIntoConstraints = false
        statsStackView.axis = .horizontal
        statsStackView.distribution = .fillEqually
        statsStackView.spacing = 1
        statsView.addSubview(statsStackView)
        
        // Reset Count Container
        resetCountContainer.translatesAutoresizingMaskIntoConstraints = false
        resetCountContainer.backgroundColor = .systemBackground
        statsStackView.addArrangedSubview(resetCountContainer)
        
        // Streak Container
        streakContainer.translatesAutoresizingMaskIntoConstraints = false
        streakContainer.backgroundColor = .systemBackground
        statsStackView.addArrangedSubview(streakContainer)
        
        // Reset Count Icon
        resetCountIconView.translatesAutoresizingMaskIntoConstraints = false
        resetCountIconView.contentMode = .scaleAspectFit
        resetCountIconView.tintColor = .systemBrown
        resetCountIconView.image = UIImage(systemName: "arrow.counterclockwise.circle.fill")
        resetCountContainer.addSubview(resetCountIconView)
        
        // Streak Icon
        streakIconView.translatesAutoresizingMaskIntoConstraints = false
        streakIconView.contentMode = .scaleAspectFit
        streakIconView.tintColor = .systemBrown
        streakIconView.image = UIImage(systemName: "flame.fill")
        streakContainer.addSubview(streakIconView)
        
        // Reset Count Label
        resetCountLabel.translatesAutoresizingMaskIntoConstraints = false
        resetCountLabel.font = .systemFont(ofSize: 14, weight: .medium)
        resetCountLabel.textColor = .secondaryLabel
        resetCountLabel.text = "Resets"
        resetCountContainer.addSubview(resetCountLabel)
        
        // Reset Count Value
        resetCountValueLabel.translatesAutoresizingMaskIntoConstraints = false
        resetCountValueLabel.font = .systemFont(ofSize: 22, weight: .bold)
        resetCountValueLabel.textColor = .label
        resetCountValueLabel.text = "0"
        resetCountContainer.addSubview(resetCountValueLabel)
        
        // Streak Label
        streakLabel.translatesAutoresizingMaskIntoConstraints = false
        streakLabel.font = .systemFont(ofSize: 14, weight: .medium)
        streakLabel.textColor = .secondaryLabel
        streakLabel.text = "Current Streak"
        streakContainer.addSubview(streakLabel)
        
        // Streak Value
        streakValueLabel.translatesAutoresizingMaskIntoConstraints = false
        streakValueLabel.font = .systemFont(ofSize: 22, weight: .bold)
        streakValueLabel.textColor = .label
        streakValueLabel.text = "0"
        streakContainer.addSubview(streakValueLabel)
        
        // Message Button - stylish gradient
        messageButton.translatesAutoresizingMaskIntoConstraints = false
        messageButton.setTitle("Message", for: .normal)
        messageButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        messageButton.backgroundColor = .systemBrown
        messageButton.setTitleColor(.white, for: .normal)
        messageButton.layer.cornerRadius = 22
        messageButton.clipsToBounds = true
        
        // Add subtle shadow to button
        messageButton.layer.shadowColor = UIColor.black.cgColor
        messageButton.layer.shadowOpacity = 0.2
        messageButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        messageButton.layer.shadowRadius = 4
        messageButton.layer.masksToBounds = false
        
        messageButton.addTarget(self, action: #selector(startChat), for: .touchUpInside)
        containerView.addSubview(messageButton)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container View
            containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            containerView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            
            // Header View
            headerView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            headerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            headerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            headerView.heightAnchor.constraint(equalToConstant: 80),
            
            // Profile Image
            profileImageView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 8),
            profileImageView.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 70),
            profileImageView.heightAnchor.constraint(equalToConstant: 70),
            
            // Name Label
            nameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -10),
            nameLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            
            // Separator
            separatorView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 16),
            separatorView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            separatorView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            separatorView.heightAnchor.constraint(equalToConstant: 1),
            
            // Stats View
            statsView.topAnchor.constraint(equalTo: separatorView.bottomAnchor, constant: 16),
            statsView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            statsView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            statsView.heightAnchor.constraint(equalToConstant: 100),
            
            // Stats Stack View
            statsStackView.topAnchor.constraint(equalTo: statsView.topAnchor),
            statsStackView.leadingAnchor.constraint(equalTo: statsView.leadingAnchor),
            statsStackView.trailingAnchor.constraint(equalTo: statsView.trailingAnchor),
            statsStackView.bottomAnchor.constraint(equalTo: statsView.bottomAnchor),
            
            // Reset Count Icon
            resetCountIconView.topAnchor.constraint(equalTo: resetCountContainer.topAnchor, constant: 16),
            resetCountIconView.centerXAnchor.constraint(equalTo: resetCountContainer.centerXAnchor),
            resetCountIconView.widthAnchor.constraint(equalToConstant: 24),
            resetCountIconView.heightAnchor.constraint(equalToConstant: 24),
            
            // Reset Count Label
            resetCountLabel.topAnchor.constraint(equalTo: resetCountIconView.bottomAnchor, constant: 4),
            resetCountLabel.centerXAnchor.constraint(equalTo: resetCountContainer.centerXAnchor),
            
            // Reset Count Value
            resetCountValueLabel.topAnchor.constraint(equalTo: resetCountLabel.bottomAnchor, constant: 2),
            resetCountValueLabel.centerXAnchor.constraint(equalTo: resetCountContainer.centerXAnchor),
            
            // Streak Icon
            streakIconView.topAnchor.constraint(equalTo: streakContainer.topAnchor, constant: 16),
            streakIconView.centerXAnchor.constraint(equalTo: streakContainer.centerXAnchor),
            streakIconView.widthAnchor.constraint(equalToConstant: 24),
            streakIconView.heightAnchor.constraint(equalToConstant: 24),
            
            // Streak Label
            streakLabel.topAnchor.constraint(equalTo: streakIconView.bottomAnchor, constant: 4),
            streakLabel.centerXAnchor.constraint(equalTo: streakContainer.centerXAnchor),
            
            // Streak Value
            streakValueLabel.topAnchor.constraint(equalTo: streakLabel.bottomAnchor, constant: 2),
            streakValueLabel.centerXAnchor.constraint(equalTo: streakContainer.centerXAnchor),
            
            // Message Button
            messageButton.topAnchor.constraint(equalTo: statsView.bottomAnchor, constant: 24),
            messageButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            messageButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            messageButton.heightAnchor.constraint(equalToConstant: 44),
            messageButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
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
                  let profileUrl = data["imageURL"] as? String else {
                print("Invalid user data.")
                return
            }
            
            // Extract additional stats
            let resetCount = data["numberOfResets"] as? Int ?? 0
            let streak = data["soberStreak"] as? Int ?? 0
            
            DispatchQueue.main.async {
                self?.updateUI(
                    username: username,
                    profileUrl: profileUrl,
                    resetCount: resetCount,
                    streak: streak
                )
            }
        }
    }
    
    private func updateUI(username: String, profileUrl: String, resetCount: Int, streak: Int) {
        self.nameLabel.text = username
        
        if let url = URL(string: profileUrl) {
            loadImage(from: url)
        }
        
        // Update stats with animation
        UIView.animate(withDuration: 0.5) {
            self.resetCountValueLabel.text = "\(resetCount)"
            self.streakValueLabel.text = "\(streak)"
            
            
            // Change streak color based on value for visual effect
            if streak > 30 {
                self.streakIconView.tintColor = .systemOrange
                self.streakValueLabel.textColor = .systemOrange
            } else if streak > 7 {
                self.streakIconView.tintColor = .systemYellow
                self.streakValueLabel.textColor = .systemYellow
            }
        }
    }
    
    private func loadImage(from url: URL) {
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let data = data, error == nil else { return }
            
            DispatchQueue.main.async {
                UIView.transition(with: self?.profileImageView ?? UIImageView(),
                                 duration: 0.3,
                                 options: .transitionCrossDissolve,
                                 animations: {
                    self?.profileImageView.image = UIImage(data: data)
                })
            }
        }
        task.resume()
    }
    
    @objc private func startChat() {
        // Add button press animation
        UIView.animate(withDuration: 0.1, animations: {
            self.messageButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }, completion: { _ in
            UIView.animate(withDuration: 0.1) {
                self.messageButton.transform = CGAffineTransform.identity
            }
        })
        
        let params = GroupChannelCreateParams()
        params.userIds = [userId]
        params.isDistinct = true
        
        GroupChannel.createChannel(params: params) { [weak self] channel, error in
            guard let channel = channel, error == nil else { return }
            let channelURL = channel.channelURL
            
            DispatchQueue.main.async {
                // First dismiss this detail sheet
                self?.dismiss(animated: true) {
                    // Now check if the presenting view controller is a voice room
                    if let rootVC = UIApplication.shared.windows.first?.rootViewController,
                       let voiceRoomVC = rootVC.presentedViewController as? VoiceRoomViewController {
                        
                        // Call leaveRoom on the voice room VC
                        voiceRoomVC.perform(#selector(VoiceRoomViewController.leaveRoom))
                        
                        // We need a delay to allow leaveRoom to complete its work
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            // Now navigate to the chat tab
                            if let tabBarController = rootVC as? UITabBarController {
                                // Switch to the Support tab (index 1)
                                tabBarController.selectedIndex = 1
                                
                                // Get the nav controller that wraps the ChatListViewController
                                if let navController = tabBarController.viewControllers?[1] as? UINavigationController {
                                    // Create and push the chat view controller
                                    let chatVC = SBUGroupChannelViewController(channelURL: channelURL)
                                    navController.pushViewController(chatVC, animated: true)
                                }
                            }
                        }
                    } else {
                        // If no voice room, just navigate to chat
                        if let tabBarController = UIApplication.shared.windows.first?.rootViewController as? UITabBarController {
                            // Switch to the Support tab (index 1)
                            tabBarController.selectedIndex = 1
                            
                            // Get the nav controller that wraps the ChatListViewController
                            if let navController = tabBarController.viewControllers?[1] as? UINavigationController {
                                // Create and push the chat view controller
                                let chatVC = SBUGroupChannelViewController(channelURL: channelURL)
                                navController.pushViewController(chatVC, animated: true)
                            }
                        }
                    }
                }
            }
        }
    }
}
