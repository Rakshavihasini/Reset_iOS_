//
//  VoiceRoomViewController.swift
//  Reset
//
//  Created by Prasanjit Panda on 06/02/25.


import UIKit
import SendBirdCalls
import AVFoundation

class VoiceRoomViewController: UIViewController, RoomDelegate {
    // MARK: - Properties
    private let room: Room
    private var participants: [Participant] = []
    
    private let leaveButton = UIButton()
    private let microphoneButton = UIButton()
    private let speakerButton = UIButton()
    private var participantsCollectionView: UICollectionView!
    private let buttonsContainerView = UIView()
    
    private var audioSession: AVAudioSession?
    private var isAudioEnabled = true
    private var isSpeakerOn = true

    // MARK: - Initialization
    init(room: Room) {
        self.room = room
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupAudioSession()
        setupUI()
        setupCollectionView()
        enterRoom()
        setupRoomDelegate()
    }

    // MARK: - Setup Methods
    private func setupAudioSession() {
        audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession?.setCategory(.playAndRecord, mode: .default)
            try audioSession?.overrideOutputAudioPort(.speaker)
            try audioSession?.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }

    private func setupUI() {
        // Set up gradient background
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = view.bounds
        gradientLayer.colors = [
            UIColor(red: 0.95, green: 0.95, blue: 1.0, alpha: 1.0).cgColor,
            UIColor.white.cgColor
        ]
        view.layer.insertSublayer(gradientLayer, at: 0)
        
        // Configure buttons container view with blur effect
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        let blurView = UIVisualEffectView(effect: blurEffect)
        buttonsContainerView.addSubview(blurView)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: buttonsContainerView.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: buttonsContainerView.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: buttonsContainerView.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: buttonsContainerView.bottomAnchor)
        ])
        
        buttonsContainerView.layer.cornerRadius = 20
        buttonsContainerView.clipsToBounds = true
        buttonsContainerView.layer.shadowColor = UIColor.black.cgColor
        buttonsContainerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        buttonsContainerView.layer.shadowRadius = 8
        buttonsContainerView.layer.shadowOpacity = 0.1

        // Configure symbol size for buttons
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 36
                                                     , weight: .medium)

        // Configure all buttons with modern styling
        [leaveButton, microphoneButton, speakerButton].forEach { button in
            button.layer.cornerRadius = 40
            button.clipsToBounds = true
            button.layer.shadowColor = UIColor.black.cgColor
            button.layer.shadowOffset = CGSize(width: 0, height: 2)
            button.layer.shadowRadius = 4
            button.layer.shadowOpacity = 0.15
            
            let hoverView = UIView()
            hoverView.backgroundColor = .white
            hoverView.alpha = 0.1
            hoverView.isUserInteractionEnabled = false
            button.addSubview(hoverView)
            hoverView.frame = button.bounds
            hoverView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        }

        // Leave Room Button
        let leaveImage = UIImage(systemName: "xmark.circle.fill", withConfiguration: iconConfig)
        leaveButton.setImage(leaveImage, for: .normal)
        leaveButton.tintColor = .systemRed
        leaveButton.backgroundColor = UIColor.systemRed.withAlphaComponent(0.1)
        leaveButton.addTarget(self, action: #selector(leaveRoom), for: .touchUpInside)

        // Microphone Button
        let micImage = UIImage(systemName: "mic.fill", withConfiguration: iconConfig)
        microphoneButton.setImage(micImage, for: .normal)
        microphoneButton.tintColor = .systemBlue
        microphoneButton.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
        microphoneButton.addTarget(self, action: #selector(toggleMicrophone), for: .touchUpInside)

        // Speaker Button
        let speakerImage = UIImage(systemName: "speaker.wave.3.fill", withConfiguration: iconConfig)
        speakerButton.setImage(speakerImage, for: .normal)
        speakerButton.tintColor = .systemGreen
        speakerButton.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.1)
        speakerButton.addTarget(self, action: #selector(toggleSpeaker), for: .touchUpInside)

        view.addSubview(buttonsContainerView)
        buttonsContainerView.addSubview(leaveButton)
        buttonsContainerView.addSubview(microphoneButton)
        buttonsContainerView.addSubview(speakerButton)

        buttonsContainerView.translatesAutoresizingMaskIntoConstraints = false
        leaveButton.translatesAutoresizingMaskIntoConstraints = false
        microphoneButton.translatesAutoresizingMaskIntoConstraints = false
        speakerButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            buttonsContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            buttonsContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            buttonsContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            buttonsContainerView.heightAnchor.constraint(equalToConstant: 100),
            
            microphoneButton.centerYAnchor.constraint(equalTo: buttonsContainerView.centerYAnchor),
            microphoneButton.centerXAnchor.constraint(equalTo: buttonsContainerView.centerXAnchor),
            microphoneButton.widthAnchor.constraint(equalToConstant: 80),
            microphoneButton.heightAnchor.constraint(equalToConstant: 80),

            leaveButton.centerYAnchor.constraint(equalTo: buttonsContainerView.centerYAnchor),
            leaveButton.centerXAnchor.constraint(equalTo: buttonsContainerView.centerXAnchor, constant: 100),
            leaveButton.widthAnchor.constraint(equalToConstant: 80),
            leaveButton.heightAnchor.constraint(equalToConstant: 80),

            speakerButton.centerYAnchor.constraint(equalTo: buttonsContainerView.centerYAnchor),
            speakerButton.centerXAnchor.constraint(equalTo: buttonsContainerView.centerXAnchor, constant: -100),
            speakerButton.widthAnchor.constraint(equalToConstant: 80),
            speakerButton.heightAnchor.constraint(equalToConstant: 80)
        ])
    }

    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 20
        layout.minimumInteritemSpacing = 15
        
        participantsCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        participantsCollectionView.delegate = self
        participantsCollectionView.dataSource = self
        participantsCollectionView.backgroundColor = .clear
        participantsCollectionView.register(ParticipantCell.self, forCellWithReuseIdentifier: "ParticipantCell")
        participantsCollectionView.contentInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)

        view.addSubview(participantsCollectionView)
        participantsCollectionView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            participantsCollectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            participantsCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            participantsCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            participantsCollectionView.bottomAnchor.constraint(equalTo: buttonsContainerView.topAnchor, constant: -10)
        ])
    }

    private func setupRoomDelegate() {
        room.addDelegate(self, identifier: "VoiceRoomDelegate")
    }

    // MARK: - Room Actions
    private func enterRoom() {
        room.enter(with: Room.EnterParams(isAudioEnabled: true)) { [weak self] error in
            if let error = error {
                print("Error joining room: \(error.localizedDescription)")
                self?.showErrorAlert(message: "Failed to join room")
            } else {
                print("Successfully joined room: \(self?.room.roomId ?? "")")
                self?.updateParticipants()
            }
        }
    }

    @objc func leaveRoom() {
        try? room.exit()
        print("Left room: \(room.roomId)")
        self.dismiss(animated: true)
    }

    @objc private func toggleMicrophone() {
        isAudioEnabled.toggle()
        
        if isAudioEnabled {
            room.localParticipant?.unmuteMicrophone()
        } else {
            room.localParticipant?.muteMicrophone()
        }
        
        configureMicrophoneButton()
    }

    @objc private func toggleSpeaker() {
        isSpeakerOn.toggle()
        do {
            try audioSession?.setCategory(.playAndRecord, mode: .default)
            try audioSession?.overrideOutputAudioPort(isSpeakerOn ? .speaker : .none)
            configureSpeakerButton()
        } catch {
            print("Failed to toggle speaker: \(error)")
        }
    }

    // MARK: - UI Updates
    private func configureMicrophoneButton() {
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 44, weight: .medium)
        
        if isAudioEnabled {
            let micImage = UIImage(systemName: "mic.fill", withConfiguration: iconConfig)
            microphoneButton.setImage(micImage, for: .normal)
            microphoneButton.tintColor = .systemBlue
            microphoneButton.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
        } else {
            let mutedImage = UIImage(systemName: "mic.slash.fill", withConfiguration: iconConfig)
            microphoneButton.setImage(mutedImage, for: .normal)
            microphoneButton.tintColor = .systemGray
            microphoneButton.backgroundColor = UIColor.systemGray.withAlphaComponent(0.1)
        }
    }

    private func configureSpeakerButton() {
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 44, weight: .medium)
        
        if isSpeakerOn {
            let speakerImage = UIImage(systemName: "speaker.wave.3.fill", withConfiguration: iconConfig)
            speakerButton.setImage(speakerImage, for: .normal)
            speakerButton.tintColor = .systemGreen
            speakerButton.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.1)
        } else {
            let mutedImage = UIImage(systemName: "speaker.slash.fill", withConfiguration: iconConfig)
            speakerButton.setImage(mutedImage, for: .normal)
            speakerButton.tintColor = .systemGray
            speakerButton.backgroundColor = UIColor.systemGray.withAlphaComponent(0.1)
        }
    }

    private func updateParticipants() {
        self.participants = Array(room.participants)
        DispatchQueue.main.async {
            self.participantsCollectionView.reloadData()
        }
    }

    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - RoomDelegate Methods
    func didRemoteParticipantEnter(_ participant: RemoteParticipant) {
        print("\(participant.user.userId) entered the room")
        updateParticipants()
    }

    func didRemoteParticipantExit(_ participant: RemoteParticipant) {
        print("\(participant.user.userId) left the room")
        updateParticipants()
    }
}

// MARK: - UICollectionView Extensions
extension VoiceRoomViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return participants.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ParticipantCell", for: indexPath) as? ParticipantCell else {
            fatalError("Unable to dequeue ParticipantCell")
        }

        let participant = participants[indexPath.row]
        let nickname = participant.user.nickname ?? "Unknown"
        let profileURL = participant.user.profileURL

        cell.configure(with: nickname, profileURL: profileURL)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let spacing: CGFloat = 15
        let availableWidth = collectionView.bounds.width - (spacing * 4) // Account for left, right, and between items spacing
        let width = availableWidth / 3
        return CGSize(width: width, height: width + 40) // Added more height for the name label
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedUser = participants[indexPath.row]
        print(selectedUser.user.userId)
        let userDetailSheet = UserDetailSheetViewController(userId: selectedUser.user.userId)
        present(userDetailSheet, animated: true)
    }

}

// MARK: - Custom CollectionView Cell
class ParticipantCell: UICollectionViewCell {
    private let imageView = UIImageView()
    private let nameLabel = UILabel()
    private let containerView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        // Add container view with shadow and rounded corners
        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = 16
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        containerView.layer.shadowRadius = 6
        containerView.layer.shadowOpacity = 0.1
        
        contentView.addSubview(containerView)
        containerView.addSubview(imageView)
        containerView.addSubview(nameLabel)

        containerView.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 40
        imageView.clipsToBounds = true
        imageView.layer.borderWidth = 3
        imageView.layer.borderColor = UIColor.systemBlue.withAlphaComponent(0.3).cgColor

        nameLabel.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        nameLabel.textAlignment = .center
        nameLabel.numberOfLines = 1
        nameLabel.textColor = .darkGray

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            imageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            imageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 80),
            imageView.heightAnchor.constraint(equalToConstant: 80),

            nameLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            nameLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            nameLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12)
        ])
    }

    func configure(with nickname: String, profileURL: String?) {
        nameLabel.text = nickname

        if let urlString = profileURL, let url = URL(string: urlString) {
            // Load image asynchronously
            DispatchQueue.global().async {
                if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self.imageView.image = image
                    }
                } else {
                    DispatchQueue.main.async {
                        self.imageView.image = UIImage(systemName: "person.circle.fill")
                        self.imageView.tintColor = .systemGray
                    }
                }
            }
        } else {
            imageView.image = UIImage(systemName: "person.circle.fill")
            imageView.tintColor = .systemGray
        }
    }
}

