//
//  ChangePhotoViewController.swift
//  Reset
//
//  Created by Prasanjit Panda on 08/01/25.
//


import UIKit
import FirebaseStorage
import FirebaseAuth
import FirebaseFirestore

class ChangePhotoViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    private let storage = Storage.storage().reference()
    
    // MARK: - UI Components
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 30
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Change Profile Photo"
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let closeButton: UIButton = {
        let button = UIButton()
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        let image = UIImage(systemName: "xmark.circle.fill", withConfiguration: config)
        button.setImage(image, for: .normal)
        button.tintColor = .secondaryLabel
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 90
        imageView.image = UIImage(named: "onboarding1")
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isUserInteractionEnabled = true
        
        // Add border
        imageView.layer.borderWidth = 3
        imageView.layer.borderColor = UIColor.systemBrown.cgColor
        
        // Add shadow
        imageView.layer.shadowColor = UIColor.black.cgColor
        imageView.layer.shadowOffset = CGSize(width: 0, height: 2)
        imageView.layer.shadowRadius = 6
        imageView.layer.shadowOpacity = 0.2
        return imageView
    }()
    
    private let changePhotoButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Choose Photo", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = .systemBackground
        button.layer.cornerRadius = 20
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemBrown.cgColor  // Changed to brown
        button.tintColor = .systemBrown  // Changed to brown
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let doneButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Save Changes", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        button.backgroundColor = .systemBrown  // Changed to brown
        button.layer.cornerRadius = 20
        button.setTitleColor(.white, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        // Add shadow
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        button.layer.shadowOpacity = 0.1
        return button
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupGestures()
        loadCurrentProfileImage()
    }
    
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(containerView)
        
        [titleLabel, closeButton, profileImageView,
         changePhotoButton, doneButton, loadingIndicator].forEach {
            containerView.addSubview($0)
        }
        
        setupConstraints()
    }
    private func loadCurrentProfileImage() {
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
           loadingIndicator.startAnimating()

           Firestore.firestore().collection("users").document(userID).getDocument { [weak self] snapshot, error in
               guard let self = self,
                     let data = snapshot?.data(),
                     let imageURL = data["imageURL"] as? String else {
                   self?.loadingIndicator.stopAnimating()
                   return
               }

               let storageRef = Storage.storage().reference(forURL: imageURL)
               storageRef.getData(maxSize: 5 * 1024 * 1024) { [weak self] data, error in
                   guard let self = self else { return }

                   DispatchQueue.main.async {
                       self.loadingIndicator.stopAnimating()

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
    
    private func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapProfileImage))
        profileImageView.addGestureRecognizer(tapGesture)
        
        changePhotoButton.addTarget(self, action: #selector(didTapProfileImage), for: .touchUpInside)
        doneButton.addTarget(self, action: #selector(didTapDone), for: .touchUpInside)
        closeButton.addTarget(self, action: #selector(didTapClose), for: .touchUpInside)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            
            closeButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            closeButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            closeButton.widthAnchor.constraint(equalToConstant: 30),
            closeButton.heightAnchor.constraint(equalToConstant: 30),
            
            profileImageView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 40),
            profileImageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 180),
            profileImageView.heightAnchor.constraint(equalToConstant: 180),
            
            changePhotoButton.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 24),
            changePhotoButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            changePhotoButton.widthAnchor.constraint(equalToConstant: 160),
            changePhotoButton.heightAnchor.constraint(equalToConstant: 40),
            
            doneButton.bottomAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            doneButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 30),
            doneButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -30),
            doneButton.heightAnchor.constraint(equalToConstant: 50),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: doneButton.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: doneButton.centerYAnchor)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func didTapProfileImage() {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        picker.allowsEditing = true
        present(picker, animated: true)
    }
    
    @objc private func didTapDone() {
        dismiss(animated: true)
    }
    
    @objc private func didTapClose() {
        dismiss(animated: true)
    }
    
    // MARK: - UIImagePickerController Delegate
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        guard let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage,
              let imageData = image.pngData() else {
            return
        }
        
        // Show loading state
        loadingIndicator.startAnimating()
        doneButton.setTitle("", for: .normal)
        
        let imageId = UUID().uuidString
        storage.child("images/\(imageId).png").putData(imageData, metadata: nil) { [weak self] _, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Failed to upload: \(error.localizedDescription)")
                self.handleUploadCompletion()
                return
            }
            
            guard let userID = Auth.auth().currentUser?.uid else {
                self.handleUploadCompletion()
                return
            }
            
            self.storage.child("images/\(imageId).png").downloadURL { [weak self] url, error in
                guard let self = self,
                      let url = url else {
                    self?.handleUploadCompletion()
                    return
                }
                
                let urlString = url.absoluteString
                
                // Update local UI and cache
                DispatchQueue.main.async {
                    self.profileImageView.image = image
                    UserDefaults.standard.set(imageData, forKey: "profileImage")
                }
                
                // Update Firestore
                Firestore.firestore().collection("users").document(userID)
                    .updateData(["imageURL": urlString]) { [weak self] error in
                        if let error = error {
                            print("Error updating Firestore: \(error.localizedDescription)")
                        }
                        self?.handleUploadCompletion()
                        
                        // Post notification to update ProfileViewController
                        NotificationCenter.default.post(name: NSNotification.Name("ProfileImageUpdated"), object: nil)
                    }
            }
        }
    }
    
    private func handleUploadCompletion() {
        DispatchQueue.main.async {
            self.loadingIndicator.stopAnimating()
            self.doneButton.setTitle("Save Changes", for: .normal)
        }
    }
}
