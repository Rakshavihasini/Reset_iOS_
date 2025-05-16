//
//  CreateRoomActionSheetViewController.swift
//  Reset
//
//  Created by Prasanjit Panda on 04/02/25.
//


import UIKit
import FirebaseFirestore
import SendBirdCalls
import FirebaseAuth

class CreateRoomActionSheetViewController: UIViewController {
    
    // MARK: - UI Components
    private let cancelButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: "Cancel", style: .plain, target: nil, action: nil)
        button.tintColor = .systemBrown
        return button
    }()
    
    private let headerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let headerLabel: UILabel = {
        let label = UILabel()
        label.text = "Create Your Space"
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let headerSubtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Connect with others in real-time voice conversations"
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let roomNameContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 12
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let roomNameIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "bubble.left.fill")
        imageView.tintColor = .systemBrown
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let roomNameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "What's your space about?"
        textField.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        textField.textAlignment = .left
        textField.borderStyle = .none
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let descriptionContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 12
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let descriptionIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "text.alignleft")
        imageView.tintColor = .systemBrown
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let descriptionTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Add a brief description"
        textField.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        textField.textAlignment = .left
        textField.borderStyle = .none
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let optionsContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 12
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let startNowIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "play.circle.fill")
        imageView.tintColor = .systemBrown
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let startNowLabel: UILabel = {
        let label = UILabel()
        label.text = "Start Now"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let startNowSwitch: UISwitch = {
        let switchControl = UISwitch()
        switchControl.isOn = true
        switchControl.onTintColor = .systemBrown
        switchControl.translatesAutoresizingMaskIntoConstraints = false
        return switchControl
    }()
    
    private let createButton: UIButton = {
        let button = UIButton()
        button.setTitle("Create Space", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        button.backgroundColor = .systemBrown
        button.layer.cornerRadius = 25
        button.clipsToBounds = true
        
        // Add shadow
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowRadius = 8
        button.layer.shadowOpacity = 0.15
        button.layer.masksToBounds = false
        
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.color = .white
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    private let previewView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0.4, green: 0.2, blue: 0.1, alpha: 1.0)
        view.layer.cornerRadius = 16
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let previewTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Your Space Preview"
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let previewHostLabel: UILabel = {
        let label = UILabel()
        label.text = "Hosted by you"
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = .white.withAlphaComponent(0.8)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let previewLiveIndicator: UIView = {
        let view = UIView()
        view.backgroundColor = .systemRed
        view.layer.cornerRadius = 4
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let previewLiveLabel: UILabel = {
        let label = UILabel()
        label.text = "LIVE"
        label.font = UIFont.systemFont(ofSize: 10, weight: .bold)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let scheduleContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 12
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()
    
    private let scheduleIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "calendar")
        imageView.tintColor = .systemBrown
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let scheduleLabel: UILabel = {
        let label = UILabel()
        label.text = "Schedule for later"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let dateTimePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .dateAndTime
        picker.preferredDatePickerStyle = .compact
        picker.minimumDate = Date().addingTimeInterval(60 * 5) // At least 5 minutes in future
        picker.tintColor = .systemBrown
        picker.translatesAutoresizingMaskIntoConstraints = false
        picker.isHidden = true
        return picker
    }()
    
    private let scheduledDateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()
    
    private let previewScheduledLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = .white.withAlphaComponent(0.8)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()
    
    // MARK: - Properties
    private var keyboardHeight: CGFloat = 0
    private var gradientLayer: CAGradientLayer?
    private var isScheduled = false
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupKeyboardObservers()
        setupTapGesture()
        setupTextFieldDelegates()
        
        // Add date picker target
        dateTimePicker.addTarget(self, action: #selector(datePickerChanged(_:)), for: .valueChanged)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Update gradient layer frame
        if let gradientLayer = gradientLayer {
            gradientLayer.frame = previewView.bounds
        } else {
            setupGradientBackground()
        }
        
        // Ensure proper shadow rendering
        createButton.layer.shadowPath = UIBezierPath(roundedRect: createButton.bounds, cornerRadius: 25).cgPath
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        view.backgroundColor = .systemBackground
        navigationController?.navigationBar.prefersLargeTitles = false
        title = ""
        
        // Add Cancel button to navigation bar
        navigationItem.leftBarButtonItem = cancelButton
        cancelButton.target = self
        cancelButton.action = #selector(dismissSheet)
        
        // Add header view
        view.addSubview(headerView)
        headerView.addSubview(headerLabel)
        headerView.addSubview(headerSubtitleLabel)
        
        // Add room name container
        view.addSubview(roomNameContainerView)
        roomNameContainerView.addSubview(roomNameIconView)
        roomNameContainerView.addSubview(roomNameTextField)
        
        // Add description container
        view.addSubview(descriptionContainerView)
        descriptionContainerView.addSubview(descriptionIconView)
        descriptionContainerView.addSubview(descriptionTextField)
        
        // Add options container
        view.addSubview(optionsContainerView)
        optionsContainerView.addSubview(startNowIconView)
        optionsContainerView.addSubview(startNowLabel)
        optionsContainerView.addSubview(startNowSwitch)
        
        // Add schedule container
        view.addSubview(scheduleContainerView)
        scheduleContainerView.addSubview(scheduleIconView)
        scheduleContainerView.addSubview(scheduleLabel)
        scheduleContainerView.addSubview(dateTimePicker)
        scheduleContainerView.addSubview(scheduledDateLabel)
        
        // Add preview view
        view.addSubview(previewView)
        previewView.addSubview(previewTitleLabel)
        previewView.addSubview(previewHostLabel)
        previewView.addSubview(previewLiveIndicator)
        previewLiveIndicator.addSubview(previewLiveLabel)
        
        // Add scheduled label to preview
        previewView.addSubview(previewScheduledLabel)
        
        // Add create button
        view.addSubview(createButton)
        createButton.addSubview(loadingIndicator)
        
        NSLayoutConstraint.activate([
            // Header View
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            headerView.heightAnchor.constraint(equalToConstant: 60),
            
            headerLabel.topAnchor.constraint(equalTo: headerView.topAnchor),
            headerLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            headerLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            
            headerSubtitleLabel.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 8),
            headerSubtitleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            headerSubtitleLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            
            // Room Name Container
            roomNameContainerView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 20),
            roomNameContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            roomNameContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            roomNameContainerView.heightAnchor.constraint(equalToConstant: 56),
            
            roomNameIconView.leadingAnchor.constraint(equalTo: roomNameContainerView.leadingAnchor, constant: 16),
            roomNameIconView.centerYAnchor.constraint(equalTo: roomNameContainerView.centerYAnchor),
            roomNameIconView.widthAnchor.constraint(equalToConstant: 24),
            roomNameIconView.heightAnchor.constraint(equalToConstant: 24),
            
            roomNameTextField.leadingAnchor.constraint(equalTo: roomNameIconView.trailingAnchor, constant: 16),
            roomNameTextField.trailingAnchor.constraint(equalTo: roomNameContainerView.trailingAnchor, constant: -16),
            roomNameTextField.centerYAnchor.constraint(equalTo: roomNameContainerView.centerYAnchor),
            
            // Description Container
            descriptionContainerView.topAnchor.constraint(equalTo: roomNameContainerView.bottomAnchor, constant: 16),
            descriptionContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            descriptionContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            descriptionContainerView.heightAnchor.constraint(equalToConstant: 56),
            
            descriptionIconView.leadingAnchor.constraint(equalTo: descriptionContainerView.leadingAnchor, constant: 16),
            descriptionIconView.centerYAnchor.constraint(equalTo: descriptionContainerView.centerYAnchor),
            descriptionIconView.widthAnchor.constraint(equalToConstant: 24),
            descriptionIconView.heightAnchor.constraint(equalToConstant: 24),
            
            descriptionTextField.leadingAnchor.constraint(equalTo: descriptionIconView.trailingAnchor, constant: 16),
            descriptionTextField.trailingAnchor.constraint(equalTo: descriptionContainerView.trailingAnchor, constant: -16),
            descriptionTextField.centerYAnchor.constraint(equalTo: descriptionContainerView.centerYAnchor),
            
            // Options Container
            optionsContainerView.topAnchor.constraint(equalTo: descriptionContainerView.bottomAnchor, constant: 16),
            optionsContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            optionsContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            optionsContainerView.heightAnchor.constraint(equalToConstant: 56),
            
            startNowIconView.leadingAnchor.constraint(equalTo: optionsContainerView.leadingAnchor, constant: 16),
            startNowIconView.centerYAnchor.constraint(equalTo: optionsContainerView.centerYAnchor),
            startNowIconView.widthAnchor.constraint(equalToConstant: 24),
            startNowIconView.heightAnchor.constraint(equalToConstant: 24),
            
            startNowLabel.leadingAnchor.constraint(equalTo: startNowIconView.trailingAnchor, constant: 16),
            startNowLabel.centerYAnchor.constraint(equalTo: optionsContainerView.centerYAnchor),
            
            startNowSwitch.trailingAnchor.constraint(equalTo: optionsContainerView.trailingAnchor, constant: -16),
            startNowSwitch.centerYAnchor.constraint(equalTo: optionsContainerView.centerYAnchor),
            
            // Schedule Container
            scheduleContainerView.topAnchor.constraint(equalTo: optionsContainerView.bottomAnchor, constant: 16),
            scheduleContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            scheduleContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            scheduleContainerView.heightAnchor.constraint(equalToConstant: 90),
            
            scheduleIconView.leadingAnchor.constraint(equalTo: scheduleContainerView.leadingAnchor, constant: 16),
            scheduleIconView.topAnchor.constraint(equalTo: scheduleContainerView.topAnchor, constant: 16),
            scheduleIconView.widthAnchor.constraint(equalToConstant: 24),
            scheduleIconView.heightAnchor.constraint(equalToConstant: 24),
            
            scheduleLabel.leadingAnchor.constraint(equalTo: scheduleIconView.trailingAnchor, constant: 16),
            scheduleLabel.centerYAnchor.constraint(equalTo: scheduleIconView.centerYAnchor),
            
            dateTimePicker.topAnchor.constraint(equalTo: scheduleLabel.bottomAnchor, constant: 8),
            dateTimePicker.trailingAnchor.constraint(equalTo: scheduleContainerView.trailingAnchor, constant: -16),
            
            scheduledDateLabel.centerYAnchor.constraint(equalTo: dateTimePicker.centerYAnchor),
            scheduledDateLabel.leadingAnchor.constraint(equalTo: scheduleContainerView.leadingAnchor, constant: 16),
            scheduledDateLabel.trailingAnchor.constraint(equalTo: dateTimePicker.leadingAnchor, constant: -8),
            
            // Preview View
            previewView.topAnchor.constraint(equalTo: scheduleContainerView.bottomAnchor, constant: 24),
            previewView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            previewView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            previewView.heightAnchor.constraint(equalToConstant: 120),
            
            previewTitleLabel.topAnchor.constraint(equalTo: previewView.topAnchor, constant: 16),
            previewTitleLabel.leadingAnchor.constraint(equalTo: previewView.leadingAnchor, constant: 16),
            previewTitleLabel.trailingAnchor.constraint(equalTo: previewView.trailingAnchor, constant: -16),
            
            previewHostLabel.topAnchor.constraint(equalTo: previewTitleLabel.bottomAnchor, constant: 8),
            previewHostLabel.leadingAnchor.constraint(equalTo: previewView.leadingAnchor, constant: 16),
            
            previewLiveIndicator.topAnchor.constraint(equalTo: previewHostLabel.bottomAnchor, constant: 12),
            previewLiveIndicator.leadingAnchor.constraint(equalTo: previewView.leadingAnchor, constant: 16),
            previewLiveIndicator.widthAnchor.constraint(equalToConstant: 40),
            previewLiveIndicator.heightAnchor.constraint(equalToConstant: 18),
            
            previewLiveLabel.centerXAnchor.constraint(equalTo: previewLiveIndicator.centerXAnchor),
            previewLiveLabel.centerYAnchor.constraint(equalTo: previewLiveIndicator.centerYAnchor),
            
            // Add scheduled date label to preview
            previewScheduledLabel.topAnchor.constraint(equalTo: previewHostLabel.bottomAnchor, constant: 8),
            previewScheduledLabel.leadingAnchor.constraint(equalTo: previewView.leadingAnchor, constant: 16),
            previewScheduledLabel.trailingAnchor.constraint(equalTo: previewView.trailingAnchor, constant: -16),
            
            // Create Button
            createButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            createButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            createButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            createButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Loading Indicator
            loadingIndicator.centerXAnchor.constraint(equalTo: createButton.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: createButton.centerYAnchor)
        ])
        
        createButton.addTarget(self, action: #selector(createRoomTapped), for: .touchUpInside)
        startNowSwitch.addTarget(self, action: #selector(startNowSwitchChanged), for: .valueChanged)
        
        // Initial preview update
        updatePreview()
    }
    
    private func setupGradientBackground() {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor(red: 0.4, green: 0.2, blue: 0.1, alpha: 1.0).cgColor,
            UIColor(red: 0.6, green: 0.3, blue: 0.1, alpha: 1.0).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.frame = previewView.bounds
        previewView.layer.insertSublayer(gradientLayer, at: 0)
        
        self.gradientLayer = gradientLayer
    }
    
    private func setupTextFieldDelegates() {
        roomNameTextField.delegate = self
        descriptionTextField.delegate = self
        
        // Add editing changed actions
        roomNameTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        descriptionTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
    }
    
    // MARK: - Preview Updates
    @objc private func textFieldDidChange(_ textField: UITextField) {
        updatePreview()
    }
    
    @objc private func datePickerChanged(_ sender: UIDatePicker) {
        updateScheduledDateLabel()
        updatePreview()
    }
    
    @objc private func startNowSwitchChanged(_ sender: UISwitch) {
        isScheduled = !sender.isOn
        toggleScheduleUI(isScheduled)
        updatePreview()
        
        // Animate the change
        UIView.animate(withDuration: 0.3) {
            self.previewLiveIndicator.alpha = sender.isOn ? 1.0 : 0.5
        }
    }
    
    private func toggleScheduleUI(_ show: Bool) {
        UIView.animate(withDuration: 0.3) {
            self.scheduleContainerView.isHidden = !show
            self.dateTimePicker.isHidden = !show
            self.scheduledDateLabel.isHidden = !show
            
            // Only show date picker once when toggling to scheduled mode
            if show && self.scheduledDateLabel.text?.isEmpty != false {
                self.updateScheduledDateLabel()
            }
            
            // Force layout to ensure proper animation
            self.view.layoutIfNeeded()
        }
    }
    
    private func updateScheduledDateLabel() {
        scheduledDateLabel.text = dateFormatter.string(from: dateTimePicker.date)
    }
    
    private func updatePreview() {
        // Update preview title
        if let roomName = roomNameTextField.text, !roomName.isEmpty {
            previewTitleLabel.text = roomName
        } else {
            previewTitleLabel.text = "Your Space Preview"
        }
        
        // Update live indicator
        previewLiveIndicator.isHidden = !startNowSwitch.isOn || isScheduled
        
        // Update scheduled indicator
        if isScheduled {
            previewScheduledLabel.text = "Starts on: \(dateFormatter.string(from: dateTimePicker.date))"
            previewScheduledLabel.isHidden = false
        } else {
            previewScheduledLabel.isHidden = true
        }
        
        // Animate the preview
        UIView.animate(withDuration: 0.3) {
            self.previewView.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
        } completion: { _ in
            UIView.animate(withDuration: 0.2) {
                self.previewView.transform = .identity
            }
        }
    }
    
    // MARK: - Keyboard Handling
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(self,
                                             selector: #selector(keyboardWillShow),
                                             name: UIResponder.keyboardWillShowNotification,
                                             object: nil)
        NotificationCenter.default.addObserver(self,
                                             selector: #selector(keyboardWillHide),
                                             name: UIResponder.keyboardWillHideNotification,
                                             object: nil)
    }
    
    private func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Actions
    @objc private func dismissSheet() {
        // Add a subtle animation when dismissing
        UIView.animate(withDuration: 0.2, animations: {
            self.view.alpha = 0.9
            self.view.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            self.dismiss(animated: true)
        }
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func keyboardWillShow(notification: Notification) {
        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            let keyboardHeight = keyboardFrame.height
            let bottomPadding: CGFloat = 20
            
            UIView.animate(withDuration: 0.3) {
                self.createButton.transform = CGAffineTransform(translationX: 0, y: -keyboardHeight + bottomPadding)
            }
        }
    }
    
    @objc private func keyboardWillHide(notification: Notification) {
        UIView.animate(withDuration: 0.3) {
            self.createButton.transform = .identity
        }
    }
    
    @objc private func createRoomTapped() {
        // Show loading state
        createButton.setTitle("", for: .normal)
        loadingIndicator.startAnimating()
        createButton.isEnabled = false
        
        // Add a subtle animation
        UIView.animate(withDuration: 0.1, animations: {
            self.createButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.createButton.transform = .identity
            }
        }
        
        print("CreateRoomActionSheetViewController: Create room button tapped")
        
        guard let roomName = roomNameTextField.text, !roomName.isEmpty else {
            showAlert(message: "Please enter a room name")
            resetCreateButton()
            return
        }
        
        guard let description = descriptionTextField.text, !description.isEmpty else {
            showAlert(message: "Please enter a room description")
            resetCreateButton()
            return
        }
        
        // First fetch the current user
        print("CreateRoomActionSheetViewController: Fetching current user")
        AuthService.shared.fetchUser { [weak self] user, error in
            if let error = error {
                print("CreateRoomActionSheetViewController: Error fetching user: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self?.showAlert(message: "Error fetching user: \(error.localizedDescription)")
                    self?.resetCreateButton()
                }
                return
            }
            
            guard let user = user else {
                print("CreateRoomActionSheetViewController: No user found")
                DispatchQueue.main.async {
                    self?.showAlert(message: "No user found")
                    self?.resetCreateButton()
                }
                return
            }
            
            print("CreateRoomActionSheetViewController: User found: \(user.userUID)")
            
            let startNow = self?.startNowSwitch.isOn ?? false
            let isScheduled = self?.isScheduled ?? false
            let params = RoomParams(roomType: .largeRoomForAudioOnly)
            
            // Fetch Sendbird token from Firestore for proper authentication
            print("CreateRoomActionSheetViewController: Fetching SendBird token")
            self?.fetchSendbirdTokenFromFirestore(userId: user.userUID) { [weak self] token, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("CreateRoomActionSheetViewController: Failed to get Sendbird token: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self.showAlert(message: "Failed to get Sendbird token: \(error.localizedDescription)")
                        self.resetCreateButton()
                    }
                    return
                }
                
                guard let token = token else {
                    print("CreateRoomActionSheetViewController: Token is nil")
                    DispatchQueue.main.async {
                        self.showAlert(message: "Failed to get Sendbird token: Token is nil")
                        self.resetCreateButton()
                    }
                    return
                }
                
                print("CreateRoomActionSheetViewController: Got token, authenticating with SendBird")
                
                let authParams = AuthenticateParams(userId: user.userUID, accessToken: token)
                SendBirdCall.authenticate(with: authParams) { (sendbirdUser, error) in
                    if let error = error {
                        print("CreateRoomActionSheetViewController: Authentication failed: \(error.localizedDescription)")
                        DispatchQueue.main.async {
                            self.showAlert(message: "Failed to authenticate: \(error.localizedDescription)")
                            self.resetCreateButton()
                        }
                        return
                    }
                    
                    guard let sendbirdUser = sendbirdUser else {
                        print("CreateRoomActionSheetViewController: Authentication returned nil user")
                        DispatchQueue.main.async {
                            self.showAlert(message: "Failed to authenticate: No user returned")
                            self.resetCreateButton()
                        }
                        return
                    }
                    
                    print("CreateRoomActionSheetViewController: Authentication successful as: \(sendbirdUser.userId)")
                    print("CreateRoomActionSheetViewController: Creating room")
                    
                    SendBirdCall.createRoom(with: params) { room, error in
                        if let error = error {
                            print("CreateRoomActionSheetViewController: Failed to create room: \(error.localizedDescription)")
                            DispatchQueue.main.async {
                                self.showAlert(message: "Failed to create room: \(error.localizedDescription)")
                                self.resetCreateButton()
                            }
                            return
                        }
                        
                        guard let room = room else {
                            print("CreateRoomActionSheetViewController: Room creation returned nil room")
                            DispatchQueue.main.async {
                                self.showAlert(message: "Failed to create room: No room returned")
                                self.resetCreateButton()
                            }
                            return
                        }
                        
                        print("CreateRoomActionSheetViewController: Room created successfully: \(room.roomId)")
                        
                        // Firestore setup
                        let db = Firestore.firestore()
                        var newSpace: [String: Any] = [
                            "roomID": room.roomId,
                            "title": roomName,
                            "host": user.username,  // Use the actual username
                            "description": description,
                            "listenersCount": 0,
                            "liveDuration": startNow ? "Live" : "Not Live",
                            "isLive": startNow && !isScheduled,
                            "creatorID": Auth.auth().currentUser?.uid ?? "",  // Add creator ID
                            "addedToCalendar": true  // Automatically mark as added to calendar for creator
                        ]
                        
                        // Add scheduling information if scheduled
                        if isScheduled {
                            newSpace["scheduledDate"] = self.dateTimePicker.date
                            // Calculate duration in minutes (default to 30 min)
                            newSpace["scheduledDuration"] = 30
                        }
                        
                        print("CreateRoomActionSheetViewController: Adding room to Firestore")
                        
                        db.collection("spaces").addDocument(data: newSpace) { error in
                            if let error = error {
                                print("CreateRoomActionSheetViewController: Error adding room to Firestore: \(error.localizedDescription)")
                                DispatchQueue.main.async {
                                    self.showAlert(message: "Error adding room to Firestore: \(error.localizedDescription)")
                                    self.resetCreateButton()
                                }
                                return
                            }
                            
                            print("CreateRoomActionSheetViewController: Room added to Firestore successfully")
                            
                            DispatchQueue.main.async {
                                // Post notification with new space data
                                print("CreateRoomActionSheetViewController: Posting SpaceCreated notification")
                                NotificationCenter.default.post(name: NSNotification.Name("SpaceCreated"), object: newSpace)
                                
                                // Dismiss the modal
                                self.dismiss(animated: true)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Helper method to fetch Sendbird token from Firestore
    private func fetchSendbirdTokenFromFirestore(userId: String, completion: @escaping (String?, Error?) -> Void) {
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { snapshot, error in
            if let error = error {
                print("CreateRoomActionSheetViewController: Firestore error: \(error.localizedDescription)")
                completion(nil, error)
                return
            }
            
            guard let data = snapshot?.data() else {
                print("CreateRoomActionSheetViewController: No data found for user: \(userId)")
                completion(nil, NSError(domain: "com.team5app.Reset", code: 404, userInfo: [NSLocalizedDescriptionKey: "User data not found in Firestore"]))
                return
            }
            
            guard let token = data["sendbirdAccessToken"] as? String else {
                print("CreateRoomActionSheetViewController: No sendbirdAccessToken found for user: \(userId)")
                completion(nil, NSError(domain: "com.team5app.Reset", code: 404, userInfo: [NSLocalizedDescriptionKey: "Sendbird token not found in Firestore"]))
                return
            }
            
            print("CreateRoomActionSheetViewController: Successfully retrieved token for user: \(userId)")
            completion(token, nil)
        }
    }
    
    private func resetCreateButton() {
        DispatchQueue.main.async {
            self.loadingIndicator.stopAnimating()
            self.createButton.isEnabled = true
            self.createButton.setTitle("Create Space", for: .normal)
        }
    }
    
    private func showAlert(message: String) {
        DispatchQueue.main.async {
            // Create a custom alert with animation
            let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            
            // Present with animation
            self.present(alert, animated: true) {
                // Add a subtle shake animation to the alert
                if let alertView = alert.view {
                    let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
                    animation.timingFunction = CAMediaTimingFunction(name: .linear)
                    animation.duration = 0.6
                    animation.values = [-20.0, 20.0, -20.0, 20.0, -10.0, 10.0, -5.0, 5.0, 0.0]
                    alertView.layer.add(animation, forKey: "shake")
                }
            }
        }
    }
    
    // MARK: - Cleanup
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - UITextFieldDelegate
extension CreateRoomActionSheetViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == roomNameTextField {
            descriptionTextField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        // Add a subtle animation when text field becomes active
        UIView.animate(withDuration: 0.2) {
            if textField == self.roomNameTextField {
                self.roomNameContainerView.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.7)
                self.roomNameIconView.tintColor = .systemBrown
            } else if textField == self.descriptionTextField {
                self.descriptionContainerView.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.7)
                self.descriptionIconView.tintColor = .systemBrown
            }
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        // Reset appearance when editing ends
        UIView.animate(withDuration: 0.2) {
            if textField == self.roomNameTextField {
                self.roomNameContainerView.backgroundColor = .secondarySystemBackground
                self.roomNameIconView.tintColor = textField.text?.isEmpty ?? true ? .systemGray : .systemBrown
            } else if textField == self.descriptionTextField {
                self.descriptionContainerView.backgroundColor = .secondarySystemBackground
                self.descriptionIconView.tintColor = textField.text?.isEmpty ?? true ? .systemGray : .systemBrown
            }
        }
    }
}




