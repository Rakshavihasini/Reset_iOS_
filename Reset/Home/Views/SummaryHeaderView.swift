//
//  SummaryHeaderView.swift
//  Reset
//
//  Created by Prasanjit Panda on 07/01/25.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

class SummaryHeaderView: UIView {
    weak var parentViewController: UIViewController?

    private let dateLabel = UILabel()
    private let titleLabel = UILabel()
    private let profileImageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        updateDateLabel()
        loadProfileImage()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
        updateDateLabel()
        loadProfileImage()
    }

    private func setupView() {
        // View setup
        dateLabel.font = .systemFont(ofSize: 16, weight: .medium)
        dateLabel.textColor = .gray
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(dateLabel)

        titleLabel.text = "Summary"
        titleLabel.font = .systemFont(ofSize: 32, weight: .bold)
        titleLabel.textColor = .black
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)

        profileImageView.backgroundColor = UIColor(red: 0.97, green: 0.76, blue: 0.19, alpha: 1.0)
        profileImageView.layer.cornerRadius = 25
        profileImageView.clipsToBounds = true
        profileImageView.image = UIImage(named: "person.fill")
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.isUserInteractionEnabled = true
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(profileImageView)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(openProfileViewController))
        profileImageView.addGestureRecognizer(tapGesture)

        setupConstraints()
    }

    private func updateDateLabel() {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE dd MMM"
        let currentDate = Date()
        dateLabel.text = formatter.string(from: currentDate)
    }

    private func loadProfileImage() {
        if loadCachedImage() {
            return
        }
        fetchImageFromFirebase()
    }

    private func loadCachedImage() -> Bool {
        guard let userID = Auth.auth().currentUser?.uid else { return false }
        Firestore.firestore().collection("users").document(userID).getDocument { [weak self] snapshot, error in
            guard let self = self, let data = snapshot?.data(), let imageURL = data["imageURL"] as? String else {
                return
            }
            let cacheKey = "profileImage-\(abs(imageURL.hash))"
            let fileManager = FileManager.default
            if let cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
                let fileURL = cacheDirectory.appendingPathComponent(cacheKey)
                if fileManager.fileExists(atPath: fileURL.path) {
                    do {
                        let imageData = try Data(contentsOf: fileURL)
                        if let cachedImage = UIImage(data: imageData) {
                            DispatchQueue.main.async {
                                self.profileImageView.image = cachedImage
                            }
                        }
                    } catch {
                        print("DEBUG: Error reading cached image: \(error.localizedDescription)")
                    }
                }
            }
        }
        return false
    }

    private func fetchImageFromFirebase() {
        guard let userID = Auth.auth().currentUser?.uid else { return }

        Firestore.firestore().collection("users").document(userID).getDocument { [weak self] snapshot, error in
            guard let self = self,
                  let data = snapshot?.data(),
                  let imageURL = data["imageURL"] as? String else {
                return
            }

            let storageRef = Storage.storage().reference(forURL: imageURL)
            storageRef.getData(maxSize: 5 * 1024 * 1024) { [weak self] data, error in
                guard let self = self else { return }

                DispatchQueue.main.async {
                    if let error = error {
                        print("Failed to fetch profile image: \(error.localizedDescription)")
                        return
                    }

                    if let imageData = data, let image = UIImage(data: imageData) {
                        self.profileImageView.image = image
                        self.cacheImage(imageData: imageData, url: imageURL)
                    }
                }
            }
        }
    }

    private func cacheImage(imageData: Data, url: String) {
        let cacheKey = "profileImage-\(abs(url.hash))"
        let fileManager = FileManager.default
        if let cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
            let fileURL = cacheDirectory.appendingPathComponent(cacheKey)
            do {
                try imageData.write(to: fileURL)
            } catch {
                print("DEBUG: Failed to cache image: \(error.localizedDescription)")
            }
        }
    }

    @objc private func openProfileViewController() {
        guard let parentVC = parentViewController else {
            print("Parent view controller is not set.")
            return
        }
        let profileVC = UINavigationController(rootViewController: ProfileViewController())
        parentVC.present(profileVC, animated: true)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            dateLabel.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            dateLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),

            titleLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20),

            profileImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            profileImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            profileImageView.widthAnchor.constraint(equalToConstant: 50),
            profileImageView.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
}
