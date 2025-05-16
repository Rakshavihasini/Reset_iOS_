//
//  ScheduledSpaceCollectionViewCell.swift
//  Reset
//
//  Created by Prasanjit Panda on 09/27/25.
//

import UIKit

class ScheduledSpaceCollectionViewCell: UICollectionViewCell {
    
    // MARK: - Properties
    static let identifier = "ScheduledSpaceCollectionViewCell"
    
    // Main container view with gradient background
    private let containerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 16
        view.clipsToBounds = true
        return view
    }()
    
    // Gradient layer for background
    private let gradientLayer = CAGradientLayer()
    
    // Calendar icon for scheduled events
    private let calendarIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "calendar")
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
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
    
    // Date display
    private let dateView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemIndigo.withAlphaComponent(0.3)
        view.layer.cornerRadius = 12
        return view
    }()
    
    private let dayLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    private let monthLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    // Time display
    private let timeView: UIView = {
        let view = UIView()
        return view
    }()
    
    private let timeIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "clock.fill")
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = .white.withAlphaComponent(0.9)
        return label
    }()
    
    // Description label
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        label.textColor = .white.withAlphaComponent(0.8)
        label.numberOfLines = 2
        return label
    }()
    
    // Add to calendar button
    private let addToCalendarButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Add to Calendar", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        button.backgroundColor = .white
        button.setTitleColor(.systemIndigo, for: .normal)
        button.layer.cornerRadius = 14
        button.isUserInteractionEnabled = false // Cell handles the tap
        return button
    }()
    
    // Date formatters
    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()
    
    private let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter
    }()
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupGradient()
        
        // Set initial gradient frame
        gradientLayer.frame = bounds
        
        // Force immediate layout to ensure everything is rendered properly
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Update gradient frame to match container bounds - must be here to handle scrolling
        gradientLayer.frame = containerView.bounds
        
        // Force gradients to update immediately by disabling animations
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        // Any other layer updates would go here
        CATransaction.commit()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        titleLabel.text = nil
        hostLabel.text = nil
        dayLabel.text = nil
        monthLabel.text = nil
        timeLabel.text = nil
        descriptionLabel.text = nil
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
        
        // Setup calendar icon
        containerView.addSubview(calendarIconView)
        calendarIconView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            calendarIconView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            calendarIconView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            calendarIconView.widthAnchor.constraint(equalToConstant: 24),
            calendarIconView.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        // Setup title
        containerView.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: calendarIconView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16)
        ])
        
        // Setup host view
        containerView.addSubview(hostView)
        hostView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            hostView.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
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
        
        // Setup date view
        containerView.addSubview(dateView)
        dateView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            dateView.topAnchor.constraint(equalTo: hostView.bottomAnchor, constant: 16),
            dateView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            dateView.widthAnchor.constraint(equalToConstant: 55),
            dateView.heightAnchor.constraint(equalToConstant: 60)
        ])
        
        dateView.addSubview(dayLabel)
        dayLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            dayLabel.topAnchor.constraint(equalTo: dateView.topAnchor, constant: 8),
            dayLabel.centerXAnchor.constraint(equalTo: dateView.centerXAnchor),
            dayLabel.leadingAnchor.constraint(equalTo: dateView.leadingAnchor, constant: 4),
            dayLabel.trailingAnchor.constraint(equalTo: dateView.trailingAnchor, constant: -4)
        ])
        
        dateView.addSubview(monthLabel)
        monthLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            monthLabel.topAnchor.constraint(equalTo: dayLabel.bottomAnchor, constant: 4),
            monthLabel.centerXAnchor.constraint(equalTo: dateView.centerXAnchor),
            monthLabel.leadingAnchor.constraint(equalTo: dateView.leadingAnchor, constant: 4),
            monthLabel.trailingAnchor.constraint(equalTo: dateView.trailingAnchor, constant: -4)
        ])
        
        // Setup time view
        containerView.addSubview(timeView)
        timeView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            timeView.centerYAnchor.constraint(equalTo: dateView.centerYAnchor),
            timeView.leadingAnchor.constraint(equalTo: dateView.trailingAnchor, constant: 16),
            timeView.heightAnchor.constraint(equalToConstant: 20)
        ])
        
        timeView.addSubview(timeIcon)
        timeIcon.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            timeIcon.leadingAnchor.constraint(equalTo: timeView.leadingAnchor),
            timeIcon.centerYAnchor.constraint(equalTo: timeView.centerYAnchor),
            timeIcon.widthAnchor.constraint(equalToConstant: 16),
            timeIcon.heightAnchor.constraint(equalToConstant: 16)
        ])
        
        timeView.addSubview(timeLabel)
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            timeLabel.leadingAnchor.constraint(equalTo: timeIcon.trailingAnchor, constant: 4),
            timeLabel.centerYAnchor.constraint(equalTo: timeView.centerYAnchor),
            timeLabel.trailingAnchor.constraint(equalTo: timeView.trailingAnchor)
        ])
        
        // Setup description label
        containerView.addSubview(descriptionLabel)
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            descriptionLabel.topAnchor.constraint(equalTo: dateView.bottomAnchor, constant: 16),
            descriptionLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            descriptionLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16)
        ])
        
        // Setup add to calendar button
        containerView.addSubview(addToCalendarButton)
        addToCalendarButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            addToCalendarButton.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 16),
            addToCalendarButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            addToCalendarButton.heightAnchor.constraint(equalToConstant: 28),
            addToCalendarButton.widthAnchor.constraint(equalToConstant: 120),
            addToCalendarButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
        ])
    }
    
    // MARK: - Configuration
    func configure(with space: Space) {
        titleLabel.text = space.title
        hostLabel.text = "Hosted by \(space.host)"
        descriptionLabel.text = space.description
        
        if let scheduledDate = space.scheduledDate {
            dayLabel.text = dayFormatter.string(from: scheduledDate)
            monthLabel.text = monthFormatter.string(from: scheduledDate)
            timeLabel.text = timeFormatter.string(from: scheduledDate)
        }
        
        // Ensure gradient covers the entire cell
        updateGradient()
        
        // Animate the cell appearance
        animateCellAppearance()
    }
    
    // Update gradient frame
    func updateGradient() {
        // Ensure the gradient covers the full bounds when the cell is configured
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        gradientLayer.frame = containerView.bounds
        CATransaction.commit()
    }
    
    // MARK: - Animations
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
    
    // Move gradient setup to a separate method
    private func setupGradient() {
        // Use CATransaction to ensure immediate application
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        // Setup gradient
        gradientLayer.colors = [
            UIColor.systemIndigo.withAlphaComponent(0.8).cgColor,
            UIColor.systemBlue.withAlphaComponent(0.8).cgColor
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