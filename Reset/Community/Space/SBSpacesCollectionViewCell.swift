//
//  SpacesCollectionViewCell 2.swift
//  Reset
//
//  Created by Prasanjit Panda on 07/02/25.
//


import UIKit

class SBSpacesCollectionViewCell: UICollectionViewCell {
    
    // MARK: - Properties
    static let identifier = "SpacesCollectionViewCell"
    
    // Main container view with gradient background
    private let containerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 16
        view.clipsToBounds = true
        return view
    }()
    
    // Gradient layer for background
    private let gradientLayer = CAGradientLayer()
    
    // Title label with dynamic font
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.textColor = .white
        label.numberOfLines = 2
        return label
    }()
    
    // Host name with icon
    private let hostView: UIView = {
        let view = UIView()
        return view
    }()
    
    private let hostIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "person.fill")
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let hostLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = .white.withAlphaComponent(0.9)
        return label
    }()
    
    // Live indicator
    private let liveView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemRed
        view.layer.cornerRadius = 4
        view.isHidden = true
        return view
    }()
    
    private let liveLabel: UILabel = {
        let label = UILabel()
        label.text = "LIVE"
        label.font = UIFont.systemFont(ofSize: 10, weight: .bold)
        label.textColor = .white
        return label
    }()
    
    // Scheduled indicator
    private let scheduledView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBlue
        view.layer.cornerRadius = 4
        view.isHidden = true
        return view
    }()
    
    private let scheduledLabel: UILabel = {
        let label = UILabel()
        label.text = "SCHEDULED"
        label.font = UIFont.systemFont(ofSize: 10, weight: .bold)
        label.textColor = .white
        return label
    }()
    
    // Scheduled date label
    private let scheduledDateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = .white.withAlphaComponent(0.9)
        label.numberOfLines = 1
        label.isHidden = true
        return label
    }()
    
    // Participants count with icon
    private let participantsView: UIView = {
        let view = UIView()
        return view
    }()
    
    private let participantsIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "person.3.fill")
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let participantsLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = .white.withAlphaComponent(0.9)
        return label
    }()
    
    // Participant images stack
    private let participantImagesStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = -10
        stack.distribution = .fillEqually
        return stack
    }()
    
    private var participantImageViews: [UIImageView] = []
    
    // Join button
    private let joinButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Join", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        button.backgroundColor = .white
        button.setTitleColor(.systemBrown, for: .normal)
        button.layer.cornerRadius = 16
        button.isUserInteractionEnabled = false // Cell handles the tap
        return button
    }()
    
    // Pulsating animation for live rooms
    private let pulseLayer = CALayer()
    
    // Date formatter for scheduled dates
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupGradient()
        
        // Set initial gradient frame
        gradientLayer.frame = bounds
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Update gradient frame to match container bounds
        gradientLayer.frame = containerView.bounds
        
        // Update pulse layer
        pulseLayer.frame = CGRect(x: 10, y: 10, width: 8, height: 8)
        pulseLayer.cornerRadius = 4
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        stopPulseAnimation()
        
        // Reset participant images
        for imageView in participantImageViews {
            imageView.image = nil
            imageView.layer.borderWidth = 0
        }
        
        // Reset scheduled indicators
        scheduledView.isHidden = true
        scheduledDateLabel.isHidden = true
        liveView.isHidden = true
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        // Add shadow to cell
        contentView.layer.cornerRadius = 16
        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowOffset = CGSize(width: 0, height: 2)
        contentView.layer.shadowRadius = 6
        contentView.layer.shadowOpacity = 0.1
        
        // Setup container with gradient
        contentView.addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        
        // Force an immediate layout to ensure containerView has valid bounds
        containerView.layoutIfNeeded()
        
        // Setup title
        containerView.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16)
        ])
        
        // Setup host view
        containerView.addSubview(hostView)
        hostView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            hostView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            hostView.heightAnchor.constraint(equalToConstant: 20)
        ])
        
        hostView.addSubview(hostIcon)
        hostIcon.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostIcon.leadingAnchor.constraint(equalTo: hostView.leadingAnchor),
            hostIcon.centerYAnchor.constraint(equalTo: hostView.centerYAnchor),
            hostIcon.widthAnchor.constraint(equalToConstant: 16),
            hostIcon.heightAnchor.constraint(equalToConstant: 16)
        ])
        
        hostView.addSubview(hostLabel)
        hostLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostLabel.leadingAnchor.constraint(equalTo: hostIcon.trailingAnchor, constant: 4),
            hostLabel.centerYAnchor.constraint(equalTo: hostView.centerYAnchor),
            hostLabel.trailingAnchor.constraint(equalTo: hostView.trailingAnchor)
        ])
        
        // Setup live indicator
        containerView.addSubview(liveView)
        liveView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            liveView.topAnchor.constraint(equalTo: hostView.bottomAnchor, constant: 8),
            liveView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            liveView.widthAnchor.constraint(equalToConstant: 40),
            liveView.heightAnchor.constraint(equalToConstant: 18)
        ])
        
        liveView.addSubview(liveLabel)
        liveLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            liveLabel.centerXAnchor.constraint(equalTo: liveView.centerXAnchor),
            liveLabel.centerYAnchor.constraint(equalTo: liveView.centerYAnchor)
        ])
        
        // Setup scheduled indicator
        containerView.addSubview(scheduledView)
        scheduledView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scheduledView.topAnchor.constraint(equalTo: hostView.bottomAnchor, constant: 8),
            scheduledView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            scheduledView.widthAnchor.constraint(equalToConstant: 80),
            scheduledView.heightAnchor.constraint(equalToConstant: 18)
        ])
        
        scheduledView.addSubview(scheduledLabel)
        scheduledLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scheduledLabel.centerXAnchor.constraint(equalTo: scheduledView.centerXAnchor),
            scheduledLabel.centerYAnchor.constraint(equalTo: scheduledView.centerYAnchor)
        ])
        
        // Setup scheduled date label
        containerView.addSubview(scheduledDateLabel)
        scheduledDateLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scheduledDateLabel.topAnchor.constraint(equalTo: scheduledView.bottomAnchor, constant: 6),
            scheduledDateLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            scheduledDateLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16)
        ])
        
        // Setup pulse layer
        pulseLayer.backgroundColor = UIColor.systemRed.cgColor
        pulseLayer.cornerRadius = 4
        containerView.layer.addSublayer(pulseLayer)
        
        // Setup participants view
        containerView.addSubview(participantsView)
        participantsView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            participantsView.topAnchor.constraint(equalTo: liveView.bottomAnchor, constant: 8),
            participantsView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            participantsView.heightAnchor.constraint(equalToConstant: 20)
        ])
        
        participantsView.addSubview(participantsIcon)
        participantsIcon.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            participantsIcon.leadingAnchor.constraint(equalTo: participantsView.leadingAnchor),
            participantsIcon.centerYAnchor.constraint(equalTo: participantsView.centerYAnchor),
            participantsIcon.widthAnchor.constraint(equalToConstant: 20),
            participantsIcon.heightAnchor.constraint(equalToConstant: 16)
        ])
        
        participantsView.addSubview(participantsLabel)
        participantsLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            participantsLabel.leadingAnchor.constraint(equalTo: participantsIcon.trailingAnchor, constant: 4),
            participantsLabel.centerYAnchor.constraint(equalTo: participantsView.centerYAnchor),
            participantsLabel.trailingAnchor.constraint(equalTo: participantsView.trailingAnchor)
        ])
        
        // Setup participant images stack
        containerView.addSubview(participantImagesStack)
        participantImagesStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            participantImagesStack.topAnchor.constraint(equalTo: participantsView.bottomAnchor, constant: 12),
            participantImagesStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            participantImagesStack.heightAnchor.constraint(equalToConstant: 36)
        ])
        
        // Create participant image views
        for _ in 0..<3 {
            let imageView = createParticipantImageView()
            participantImageViews.append(imageView)
            participantImagesStack.addArrangedSubview(imageView)
        }
        
        // Setup join button
        containerView.addSubview(joinButton)
        joinButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            joinButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            joinButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16),
            joinButton.widthAnchor.constraint(equalToConstant: 80),
            joinButton.heightAnchor.constraint(equalToConstant: 32)
        ])
    }
    
    private func createParticipantImageView() -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = UIColor.lightGray.withAlphaComponent(0.3)
        imageView.layer.cornerRadius = 18
        imageView.layer.borderColor = UIColor(red: 0.6, green: 0.3, blue: 0.1, alpha: 1.0).cgColor
        imageView.layer.borderWidth = 2
        
        // Set fixed size constraints
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 36),
            imageView.heightAnchor.constraint(equalToConstant: 36)
        ])
        
        return imageView
    }
    
    // MARK: - Configuration
    func configureCell(with space: Space, profileImages: [UIImage]) {
        titleLabel.text = space.title
        hostLabel.text = space.host
        participantsLabel.text = "\(space.listenersCount) listening"
        
        // Handle scheduled spaces
        if let scheduledDate = space.scheduledDate, !space.isLive {
            // This is a scheduled space that's not yet live
            scheduledView.isHidden = false
            liveView.isHidden = true
            scheduledDateLabel.isHidden = false
            scheduledDateLabel.text = "Starts on: \(dateFormatter.string(from: scheduledDate))"
            stopPulseAnimation()
        } 
        // Handle live spaces
        else if space.isLive {
            scheduledView.isHidden = true
            liveView.isHidden = false
            scheduledDateLabel.isHidden = true
            startPulseAnimation()
        } 
        // Handle other states
        else {
            scheduledView.isHidden = true
            liveView.isHidden = true
            scheduledDateLabel.isHidden = true
            stopPulseAnimation()
        }
        
        // Configure participant images
        for (index, imageView) in participantImageViews.enumerated() {
            if index < profileImages.count {
                imageView.image = profileImages[index]
                imageView.isHidden = false
            } else {
                imageView.isHidden = index >= max(1, min(space.listenersCount, 3))
            }
        }
        
        // Ensure gradient covers the entire cell
        updateGradient()
        
        // Animate the cell appearance
        animateCellAppearance()
    }
    
    // Update gradient frame
    private func updateGradient() {
        // Ensure the gradient covers the full bounds when the cell is configured
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        gradientLayer.frame = containerView.bounds
        CATransaction.commit()
    }
    
    // MARK: - Animations
    private func startPulseAnimation() {
        // Remove any existing animations
        pulseLayer.removeAllAnimations()
        
        // Create pulse animation
        let pulseAnimation = CABasicAnimation(keyPath: "opacity")
        pulseAnimation.duration = 1.0
        pulseAnimation.fromValue = 0.8
        pulseAnimation.toValue = 0.2
        pulseAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        pulseAnimation.autoreverses = true
        pulseAnimation.repeatCount = .infinity
        
        pulseLayer.add(pulseAnimation, forKey: "pulseAnimation")
    }
    
    private func stopPulseAnimation() {
        pulseLayer.removeAllAnimations()
    }
    
    private func animateCellAppearance() {
        // Start with a slight scale down
        self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        self.alpha = 0.8
        
        // Animate to normal size
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseOut], animations: {
            self.transform = CGAffineTransform.identity
            self.alpha = 1.0
        })
    }
    
    // MARK: - Helper Methods
    func updateParticipantCount(_ count: Int) {
        participantsLabel.text = "\(count) listening"
    }
    
    func setParticipantImage(at index: Int, with url: URL) {
        guard index < participantImageViews.count else { return }
        
        let imageView = participantImageViews[index]
        imageView.isHidden = false
        
        // Load image asynchronously
        DispatchQueue.global().async {
            if let data = try? Data(contentsOf: url),
               let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    UIView.transition(with: imageView, duration: 0.3, options: .transitionCrossDissolve, animations: {
                        imageView.image = image
                    })
                }
            }
        }
    }
    
    // Move gradient setup to a separate method
    private func setupGradient() {
        // Use CATransaction to ensure immediate application
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        // Setup gradient
        gradientLayer.colors = [
            UIColor(red: 0.8, green: 0.6, blue: 0.4, alpha: 1.0).cgColor, // Warm light brown (top/left)
            UIColor(red: 0.7, green: 0.4, blue: 0.2, alpha: 1.0).cgColor  // Slightly darker warm amber (bottom/right)
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        
        // Remove existing gradient if any
        if let existingGradient = containerView.layer.sublayers?.first(where: { $0 is CAGradientLayer }) {
            existingGradient.removeFromSuperlayer()
        }
        
        // Ensure gradient is inserted at the bottom
        containerView.layer.insertSublayer(gradientLayer, at: 0)
        
        // Make sure frame is set properly
        gradientLayer.frame = containerView.bounds
        
        CATransaction.commit()
        
        // Force immediate layout
        setNeedsLayout()
        layoutIfNeeded()
    }
}
