//
//  ImprovedSBSpaceViewController.swift
//  Reset
//
//  Created by Prasanjit Panda on 04/02/25.r
//

import UIKit
import SendBirdCalls
import AVFoundation
import FirebaseFirestore
import FirebaseAuth
import FirebaseFunctions
import TipKit
import SwiftUI

// Note: This class uses RoomCreationDelegate protocol and CreateRoomTip struct
// that are defined in SBSpaceViewController.swift

class ImprovedSBSpaceViewController: UIViewController {
    
    // Tips
    private let createRoomTip = CreateRoomTip()
    private var tipObservationTask: Task<Void, Never>?
    private let tipShownKey = "createRoomTipShown" // Key to track tip display
    
    private let createRoomButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .systemBrown
        button.tintColor = .white
        button.setImage(UIImage(systemName: "plus"), for: .normal)
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        button.layer.shadowOpacity = 0.2
        button.layer.cornerRadius = 30
        return button
    }()
    
    private var room: Room?
    weak var delegate: RoomCreationDelegate?
    
    // MARK: - Collection View Components
    private var spacesCollectionView: UICollectionView!
    private var spaces: [Space] = []
    
    // Thread-safe access to spaces array using a serial queue
    private let spacesQueue = DispatchQueue(label: "com.team5app.Reset.SpacesQueue")
    private let sendbirdQueue = DispatchQueue(label: "com.team5app.Reset.SendbirdQueue")
    
    // Firestore listener
    private var spacesListener: ListenerRegistration?
    
    // Add a property to track authentication state
    private var isAuthenticating = false
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        print("ImprovedSBSpaceViewController: viewDidLoad")
        setupUI()
        setupCollectionView()
        setupSendbird() // This will handle authentication
        
        // Add notification observer
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(spaceCreated(notification:)),
            name: NSNotification.Name("SpaceCreated"),
            object: nil
        )
        
        // Configure TipKit
        configureTipKit()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("ImprovedSBSpaceViewController: viewWillAppear")
        
        // Only start listening if we're authenticated
        if SendBirdCall.currentUser != nil && !isAuthenticating {
            print("ImprovedSBSpaceViewController: Already authenticated, starting to listen for space changes")
            startListeningForSpaceChanges()
        } else {
            print("ImprovedSBSpaceViewController: Not authenticated or authentication in progress, skipping space listening")
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showTipIfNeeded()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Cancel the tip observation task
        tipObservationTask?.cancel()
        tipObservationTask = nil
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // Stop listening for space changes when view disappears
        stopListeningForSpaceChanges()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        // Ensure button is properly rounded during layout
        createRoomButton.layer.cornerRadius = createRoomButton.bounds.width / 2
    }
    
    deinit {
        // Clean up resources
        NotificationCenter.default.removeObserver(self)
        stopListeningForSpaceChanges()
        tipObservationTask?.cancel()
    }
    
    // MARK: - TipKit Configuration
    private func configureTipKit() {
        if #available(iOS 17.0, *) {
            Task {
                try? Tips.configure([
                    .displayFrequency(.immediate),
                    .datastoreLocation(.applicationDefault)
                ])
                print("TipKit configured successfully")
            }
        } else {
            print("TipKit requires iOS 17.0 or later")
        }
    }
    
    private func showTipIfNeeded() {
        if #available(iOS 17.0, *) {
            // Check if the tip has been shown before
            let tipShown = UserDefaults.standard.bool(forKey: tipShownKey)
            
            if !tipShown && createRoomButton.superview != nil {
                Task { @MainActor in
                    print("Attempting to show tip for createRoomButton")
                    
                    let shouldDisplay = await createRoomTip.shouldDisplay
                    print("Tip should display: \(shouldDisplay)")
                    
                    if shouldDisplay {
                        let popoverController = TipUIPopoverViewController(createRoomTip, sourceItem: createRoomButton)
                        popoverController.backgroundColor = .systemBrown.withAlphaComponent(0.9)
                        popoverController.imageStyle = .brown
                        present(popoverController, animated: true) {
                            print("Tip popover presented")
                            
                            // Mark the tip as shown after it's displayed
                            UserDefaults.standard.set(true, forKey: self.tipShownKey)
                        }
                    }
                }
            } else {
                print("Tip already shown or button not in view hierarchy, skipping display.")
            }
        }
    }
    
    // MARK: - Firestore Listener
    private func startListeningForSpaceChanges() {
        print("ImprovedSBSpaceViewController: Starting to listen for space changes")
        
        // If authentication is in progress, wait for it to complete
        if isAuthenticating {
            print("ImprovedSBSpaceViewController: Authentication in progress, delaying space listening")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.startListeningForSpaceChanges()
            }
            return
        }
        
        // Check if we're authenticated before proceeding
        if SendBirdCall.currentUser == nil {
            print("ImprovedSBSpaceViewController: Not authenticated with SendBird, cannot listen for spaces")
            return
        }
        
        // Stop any existing listener first to prevent duplicates
        stopListeningForSpaceChanges()
        
        let db = Firestore.firestore()
        let spacesRef = db.collection("spaces")
        
        print("ImprovedSBSpaceViewController: Setting up Firestore listener")
        
        spacesListener = spacesRef.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("ImprovedSBSpaceViewController: Error fetching spaces: \(error.localizedDescription)")
                return
            }
            
            guard let snapshot = snapshot else {
                print("ImprovedSBSpaceViewController: Empty snapshot returned")
                return
            }
            
            print("ImprovedSBSpaceViewController: Received snapshot with \(snapshot.documentChanges.count) changes")
            
            // Process changes on a background queue
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else { return }
                
                // Group changes by type
                var addedDocuments: [DocumentSnapshot] = []
                var modifiedDocuments: [DocumentSnapshot] = []
                var removedIDs: [String] = []
                
                for diff in snapshot.documentChanges {
                    switch diff.type {
                    case .added:
                        print("ImprovedSBSpaceViewController: New space added: \(diff.document.documentID)")
                        addedDocuments.append(diff.document)
                    case .modified:
                        print("ImprovedSBSpaceViewController: Space modified: \(diff.document.documentID)")
                        modifiedDocuments.append(diff.document)
                    case .removed:
                        print("ImprovedSBSpaceViewController: Space removed: \(diff.document.documentID)")
                        removedIDs.append(diff.document.documentID)
                    }
                }
                
                // Process changes in a specific order to avoid index issues
                if !removedIDs.isEmpty {
                    self.processRemovedSpaces(removedIDs)
                }
                
                if !modifiedDocuments.isEmpty {
                    self.processModifiedSpaces(modifiedDocuments)
                }
                
                if !addedDocuments.isEmpty {
                    self.processAddedSpaces(addedDocuments)
                }
            }
        }
    }
    
    private func stopListeningForSpaceChanges() {
        spacesListener?.remove()
        spacesListener = nil
    }
    
    // MARK: - Process Firestore Changes
    private func processAddedSpaces(_ documents: [DocumentSnapshot]) {
        print("ImprovedSBSpaceViewController: Processing \(documents.count) added spaces")
        
        // Check if we're authenticated before proceeding
        if SendBirdCall.currentUser == nil {
            print("ImprovedSBSpaceViewController: Not authenticated with SendBird, cannot process added spaces")
            return
        }
        
        var spacesToAdd: [Space] = []
        
        for document in documents {
            guard let data = document.data(),
                  let roomID = data["roomID"] as? String else {
                continue
            }
            
            // Skip if we already have this space
            var spaceExists = false
            spacesQueue.sync {
                spaceExists = self.spaces.contains { $0.roomID == roomID }
            }
            
            if spaceExists {
                continue
            }
            
            let newSpace = Space(
                roomID: roomID,
                title: data["title"] as? String ?? "Untitled",
                host: data["host"] as? String ?? "Unknown Host",
                description: data["description"] as? String ?? "",
                listenersCount: 0, // Will be updated when fetching room details
                liveDuration: data["liveDuration"] as? String ?? "N/A"
            )
            
            spacesToAdd.append(newSpace)
            
            // Fetch room details asynchronously
            sendbirdQueue.async { [weak self] in
                print("ImprovedSBSpaceViewController: Fetching room details for: \(roomID)")
                
                // Double-check authentication before making the call
                if SendBirdCall.currentUser == nil {
                    print("ImprovedSBSpaceViewController: Not authenticated with SendBird, skipping room fetch")
                    return
                }
                
                SendBirdCall.fetchRoom(by: roomID) { room, error in
                    if let error = error {
                        print("ImprovedSBSpaceViewController: Error fetching room details: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let self = self, let room = room else {
                        print("ImprovedSBSpaceViewController: Room is nil for roomID: \(roomID)")
                        return
                    }
                    
                    print("ImprovedSBSpaceViewController: Successfully fetched room: \(roomID) with \(room.participants.count) participants")
                    
                    // Update listener count
                    let participantCount = room.participants.count
                    
                    self.spacesQueue.async {
                        if let index = self.spaces.firstIndex(where: { $0.roomID == roomID }) {
                            self.spaces[index].listenersCount = participantCount
                            
                            // Update UI on main thread
                            DispatchQueue.main.async {
                                if self.spacesCollectionView != nil {
                                    self.spacesCollectionView.reloadItems(at: [IndexPath(item: index, section: 0)])
                                }
                            }
                        }
                    }
                }
            }
        }
        
        // Add all new spaces at once
        if !spacesToAdd.isEmpty {
            var indexPaths: [IndexPath] = []
            
            spacesQueue.async {
                let startIndex = self.spaces.count
                self.spaces.append(contentsOf: spacesToAdd)
                
                for i in 0..<spacesToAdd.count {
                    indexPaths.append(IndexPath(item: startIndex + i, section: 0))
                }
                
                // Update UI on main thread
                DispatchQueue.main.async { [weak self] in
                    guard let self = self, self.spacesCollectionView != nil else { return }
                    
                    print("ImprovedSBSpaceViewController: Updating UI with \(indexPaths.count) new spaces")
                    
                    self.spacesCollectionView.performBatchUpdates({
                        self.spacesCollectionView.insertItems(at: indexPaths)
                    }, completion: { success in
                        if !success {
                            print("ImprovedSBSpaceViewController: Batch update failed, reloading collection view")
                            self.spacesCollectionView.reloadData()
                        }
                    })
                }
            }
        }
    }
    
    private func processModifiedSpaces(_ documents: [DocumentSnapshot]) {
        var updatedIndexPaths: [IndexPath] = []
        
        for document in documents {
            guard let data = document.data(),
                  let roomID = data["roomID"] as? String else {
                continue
            }
            
            spacesQueue.async { [weak self] in
                guard let self = self else { return }
                
                if let index = self.spaces.firstIndex(where: { $0.roomID == roomID }) {
                    // Update space properties
                    self.spaces[index].title = data["title"] as? String ?? self.spaces[index].title
                    self.spaces[index].host = data["host"] as? String ?? self.spaces[index].host
                    self.spaces[index].description = data["description"] as? String ?? self.spaces[index].description
                    self.spaces[index].liveDuration = data["liveDuration"] as? String ?? self.spaces[index].liveDuration
                    
                    updatedIndexPaths.append(IndexPath(item: index, section: 0))
                    
                    // Fetch updated room details
                    self.sendbirdQueue.async {
                        SendBirdCall.fetchRoom(by: roomID) { room, error in
                            if let error = error {
                                print("Error fetching room details: \(error.localizedDescription)")
                                return
                            }
                            
                            if let room = room {
                                self.spacesQueue.async {
                                    if let index = self.spaces.firstIndex(where: { $0.roomID == roomID }) {
                                        self.spaces[index].listenersCount = room.participants.count
                                        
                                        // Update UI on main thread
                                        DispatchQueue.main.async {
                                            if self.spacesCollectionView != nil {
                                                self.spacesCollectionView.reloadItems(at: [IndexPath(item: index, section: 0)])
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Update UI for modified spaces
                if !updatedIndexPaths.isEmpty {
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self, self.spacesCollectionView != nil else { return }
                        
                        self.spacesCollectionView.performBatchUpdates({
                            self.spacesCollectionView.reloadItems(at: updatedIndexPaths)
                        }, completion: { success in
                            if !success {
                                self.spacesCollectionView.reloadData()
                            }
                        })
                    }
                }
            }
        }
    }
    
    private func processRemovedSpaces(_ documentIDs: [String]) {
        spacesQueue.async { [weak self] in
            guard let self = self else { return }
            
            var indexPaths: [IndexPath] = []
            var indicesToRemove: [Int] = []
            
            // Find indices to remove
            for (index, space) in self.spaces.enumerated() {
                if documentIDs.contains(space.roomID) {
                    indicesToRemove.append(index)
                    indexPaths.append(IndexPath(item: index, section: 0))
                }
            }
            
            // Sort indices in descending order to safely remove from array
            let sortedIndices = indicesToRemove.sorted(by: >)
            
            // Remove spaces from array
            for index in sortedIndices {
                if index < self.spaces.count {
                    self.spaces.remove(at: index)
                }
            }
            
            // Update UI on main thread
            if !indexPaths.isEmpty {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self, self.spacesCollectionView != nil else { return }
                    
                    // Sort index paths to ensure correct deletion order
                    let sortedPaths = indexPaths.sorted { $0.item > $1.item }
                    
                    self.spacesCollectionView.performBatchUpdates({
                        self.spacesCollectionView.deleteItems(at: sortedPaths)
                    }, completion: { success in
                        if !success {
                            self.spacesCollectionView.reloadData()
                        }
                    })
                }
            }
        }
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        view.backgroundColor = .white
        createRoomButton.addTarget(self, action: #selector(createRoomTapped), for: .touchUpInside)
    }
    
    // MARK: - Setup Collection View
    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 20
        layout.minimumInteritemSpacing = 10
        layout.sectionInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        
        spacesCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        spacesCollectionView.backgroundColor = .clear
        spacesCollectionView.showsVerticalScrollIndicator = false
        spacesCollectionView.delegate = self
        spacesCollectionView.dataSource = self
        
        // Register the custom cell
        spacesCollectionView.register(SBSpacesCollectionViewCell.self, forCellWithReuseIdentifier: "SpacesCollectionViewCell")
        
        view.addSubview(spacesCollectionView)
        view.addSubview(createRoomButton)
        
        spacesCollectionView.translatesAutoresizingMaskIntoConstraints = false
        createRoomButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            spacesCollectionView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            spacesCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            spacesCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            spacesCollectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            createRoomButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            createRoomButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            createRoomButton.widthAnchor.constraint(equalToConstant: 60),
            createRoomButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    // MARK: - SendBird Setup
    private func setupSendbird() {
        // Skip configuration as it's already done in AppDelegate
        // Only handle authentication if needed
        
        print("ImprovedSBSpaceViewController: Starting SendBird setup")
        
        guard let currentUser = Auth.auth().currentUser else {
            print("ImprovedSBSpaceViewController: No logged-in user.")
            return
        }
        
        // Check if already authenticated with the current user
        if let currentSendbirdUser = SendBirdCall.currentUser, 
           currentSendbirdUser.userId == currentUser.uid {
            print("ImprovedSBSpaceViewController: Already authenticated as: \(currentSendbirdUser.userId)")
            return
        }
        
        print("ImprovedSBSpaceViewController: Fetching SendBird token for user: \(currentUser.uid)")
        
        // Set a flag to indicate authentication is in progress
        isAuthenticating = true
        
        fetchSendbirdTokenFromFirestore(userId: currentUser.uid) { [weak self] token, error in
            guard let self = self else { return }
            
            if let error = error {
                print("ImprovedSBSpaceViewController: Failed to get Sendbird token: \(error.localizedDescription)")
                self.isAuthenticating = false
                return
            }
            
            guard let token = token else {
                print("ImprovedSBSpaceViewController: Token is nil")
                self.isAuthenticating = false
                return
            }
            
            print("ImprovedSBSpaceViewController: Got token, authenticating with SendBird")
            
            SendBirdCall.authenticate(with: AuthenticateParams(userId: currentUser.uid, accessToken: token)) { user, error in
                if let error = error {
                    print("ImprovedSBSpaceViewController: Authentication failed: \(error.localizedDescription)")
                } else {
                    print("ImprovedSBSpaceViewController: Authentication successful as: \(user?.userId ?? "Unknown User")")
                }
                
                // Authentication is complete (successful or not)
                self.isAuthenticating = false
                
                // If authentication was successful, start listening for spaces
                if user != nil {
                    DispatchQueue.main.async {
                        self.startListeningForSpaceChanges()
                    }
                }
            }
        }
    }
    
    private func fetchSendbirdTokenFromFirestore(userId: String, completion: @escaping (String?, Error?) -> Void) {
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { snapshot, error in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let data = snapshot?.data(), let token = data["sendbirdAccessToken"] as? String else {
                completion(nil, NSError(domain: "com.team5app.Reset", code: 404, userInfo: [NSLocalizedDescriptionKey: "Sendbird token not found in Firestore"]))
                return
            }
            
            completion(token, nil)
        }
    }
    
    // MARK: - Room Actions
    @objc private func createRoomTapped() {
        // Dismiss the tip if it's being shown
        if #available(iOS 17.0, *) {
            if let presented = presentedViewController as? TipUIPopoverViewController {
                dismiss(animated: true)
            }
        }
        
        let actionSheetVC = CreateRoomActionSheetViewController()
        let navController = UINavigationController(rootViewController: actionSheetVC)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true)
    }
    
    @objc private func spaceCreated(notification: Notification) {
        guard let newSpaceData = notification.object as? [String: Any],
              let roomID = newSpaceData["roomID"] as? String,
              let title = newSpaceData["title"] as? String,
              let host = newSpaceData["host"] as? String,
              let description = newSpaceData["description"] as? String,
              let listenersCount = newSpaceData["listenersCount"] as? Int,
              let liveDuration = newSpaceData["liveDuration"] as? String else {
            print("Invalid space data received in notification")
            return
        }
        
        // Check if we already have this space
        var spaceExists = false
        spacesQueue.sync {
            spaceExists = self.spaces.contains { $0.roomID == roomID }
        }
        
        if spaceExists {
            print("Space with roomID \(roomID) already exists, ignoring notification")
            return
        }
        
        let space = Space(
            roomID: roomID,
            title: title,
            host: host,
            description: description,
            listenersCount: listenersCount,
            liveDuration: liveDuration
        )
        
        // Add new space to the collection in a thread-safe way
        spacesQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.spaces.append(space)
            let newIndex = self.spaces.count - 1
            
            // Update UI on main thread
            DispatchQueue.main.async {
                guard self.spacesCollectionView != nil else {
                    print("Collection view not initialized, skipping UI update")
                    return
                }
                
                self.spacesCollectionView.performBatchUpdates({
                    self.spacesCollectionView.insertItems(at: [IndexPath(item: newIndex, section: 0)])
                }, completion: { success in
                    if !success {
                        self.spacesCollectionView.reloadData()
                    }
                })
            }
        }
    }
    
    private func presentRoomViewController(room: Room) {
        let roomVC = VoiceRoomViewController(room: room)
        present(roomVC, animated: true)
    }
    
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UICollectionView Delegate & DataSource
extension ImprovedSBSpaceViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var count = 0
        spacesQueue.sync {
            count = spaces.count
        }
        return count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        print("ImprovedSBSpaceViewController: Configuring cell at index \(indexPath.row)")
        
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SpacesCollectionViewCell", for: indexPath) as? SBSpacesCollectionViewCell else {
            print("ImprovedSBSpaceViewController: Failed to dequeue SpacesCollectionViewCell")
            fatalError("Unable to dequeue SpacesCollectionViewCell")
        }
        
        // Safely access the spaces array
        var space: Space?
        spacesQueue.sync {
            // Check if the index is valid to prevent crashes
            if indexPath.row < self.spaces.count {
                space = self.spaces[indexPath.row]
            }
        }
        
        // If we couldn't get a valid space, return the cell with default configuration
        guard let space = space else {
            print("ImprovedSBSpaceViewController: No space found for index \(indexPath.row)")
            cell.configureCell(with: Space(
                roomID: "",
                title: "Loading...",
                host: "",
                description: "",
                listenersCount: 0,
                liveDuration: ""
            ), profileImages: [])
            return cell
        }
        
        print("ImprovedSBSpaceViewController: Configuring cell for space: \(space.roomID)")
        
        // Configure cell with basic info immediately
        cell.configureCell(with: space, profileImages: [])
        
        // Tag the cell with the roomID to prevent wrong image updates
        let roomID = space.roomID
        cell.tag = roomID.hashValue
        
        // Check if we're authenticated before trying to fetch room details
        if SendBirdCall.currentUser == nil {
            print("ImprovedSBSpaceViewController: Not authenticated with SendBird, skipping room fetch for cell")
            return cell
        }
        
        // Use a weak reference to the cell to avoid retain cycles
        let weakCell = WeakRef(cell)
        
        // Use serial queue for SendBird operations
        sendbirdQueue.async { [weak self] in
            print("ImprovedSBSpaceViewController: Fetching room details for cell: \(space.roomID)")
            
            // Double-check authentication before making the call
            guard SendBirdCall.currentUser != nil else {
                print("ImprovedSBSpaceViewController: Not authenticated with SendBird, skipping room fetch for cell")
                return
            }
            
            // Use a try-catch block to handle any unexpected errors
            do {
                SendBirdCall.fetchRoom(by: space.roomID) { room, error in
                    // Check if cell is still valid and showing the same room
                    guard let cell = weakCell.value, cell.tag == roomID.hashValue else {
                        print("ImprovedSBSpaceViewController: Cell no longer valid for \(space.roomID)")
                        return
                    }
                    
                    if let error = error {
                        print("ImprovedSBSpaceViewController: Error fetching room for images: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let room = room else {
                        print("ImprovedSBSpaceViewController: Room is nil for roomID: \(space.roomID)")
                        return
                    }
                    
                    print("ImprovedSBSpaceViewController: Successfully fetched room for cell: \(space.roomID)")
                    
                    // Update participant count in our data model
                    if let self = self {
                        self.spacesQueue.async {
                            if let index = self.spaces.firstIndex(where: { $0.roomID == roomID }) {
                                self.spaces[index].listenersCount = room.participants.count
                            }
                        }
                    }
                    
                    // Load images in background
                    DispatchQueue.global(qos: .userInitiated).async {
                        // Use a try-catch block to handle any unexpected errors
                        do {
                            let participantImages: [UIImage] = room.participants.compactMap { participant in
                                if let profileURL = participant.user.profileURL, let url = URL(string: profileURL) {
                                    do {
                                        let imageData = try Data(contentsOf: url)
                                        return UIImage(data: imageData)
                                    } catch {
                                        print("ImprovedSBSpaceViewController: Error loading image data: \(error)")
                                        return nil
                                    }
                                }
                                return nil
                            }
                            
                            // Update UI on main thread
                            DispatchQueue.main.async {
                                // Check again if the cell is still showing the same room
                                if let cell = weakCell.value, cell.tag == roomID.hashValue {
                                    print("ImprovedSBSpaceViewController: Updating cell with \(participantImages.count) images")
                                    cell.configureCell(with: space, profileImages: participantImages)
                                }
                            }
                        } catch {
                            print("ImprovedSBSpaceViewController: Unexpected error loading images: \(error)")
                        }
                    }
                }
            } catch {
                print("ImprovedSBSpaceViewController: Unexpected error fetching room: \(error)")
            }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width - 40 // Accounting for left and right insets
        return CGSize(width: width, height: 200)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("ImprovedSBSpaceViewController: Selected item at index \(indexPath.row)")
        
        // Check if we're authenticated before proceeding
        if SendBirdCall.currentUser == nil {
            print("ImprovedSBSpaceViewController: Not authenticated with SendBird, cannot select space")
            showErrorAlert(message: "Not authenticated with SendBird. Please try again later.")
            return
        }
        
        // Safely access the spaces array
        var selectedSpace: Space?
        spacesQueue.sync {
            if indexPath.row < self.spaces.count {
                selectedSpace = self.spaces[indexPath.row]
            }
        }
        
        guard let selectedSpace = selectedSpace else {
            print("ImprovedSBSpaceViewController: Error: Could not retrieve selected space")
            showErrorAlert(message: "Could not retrieve selected space. Please try again.")
            return
        }
        
        print("ImprovedSBSpaceViewController: Selected space: \(selectedSpace.roomID)")
        
        // Show loading indicator
        let loadingAlert = UIAlertController(title: nil, message: "Joining room...", preferredStyle: .alert)
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = .medium
        loadingIndicator.startAnimating()
        loadingAlert.view.addSubview(loadingIndicator)
        present(loadingAlert, animated: true)
        
        // Use serial queue for SendBird operations
        sendbirdQueue.async { [weak self] in
            print("ImprovedSBSpaceViewController: Fetching room for selected space: \(selectedSpace.roomID)")
            
            // Double-check authentication before making the call
            guard SendBirdCall.currentUser != nil else {
                print("ImprovedSBSpaceViewController: Not authenticated with SendBird, cannot fetch room")
                DispatchQueue.main.async {
                    self?.dismiss(animated: true) {
                        self?.showErrorAlert(message: "Not authenticated with SendBird. Please try again later.")
                    }
                }
                return
            }
            
            // Use a try-catch block to handle any unexpected errors
            do {
                SendBirdCall.fetchRoom(by: selectedSpace.roomID) { room, error in
                    // Dismiss loading indicator on main thread
                    DispatchQueue.main.async {
                        self?.dismiss(animated: true) {
                            // Handle errors
                            if let error = error {
                                print("ImprovedSBSpaceViewController: Error fetching room: \(error.localizedDescription)")
                                self?.showErrorAlert(message: "Error fetching room: \(error.localizedDescription)")
                                return
                            }
                            
                            guard let room = room else {
                                print("ImprovedSBSpaceViewController: Room not found for: \(selectedSpace.roomID)")
                                self?.showErrorAlert(message: "Room not found")
                                return
                            }
                            
                            print("ImprovedSBSpaceViewController: Successfully fetched room, presenting view controller")
                            
                            // Present the voice room view controller
                            self?.presentRoomViewController(room: room)
                        }
                    }
                }
            } catch {
                print("ImprovedSBSpaceViewController: Unexpected error fetching room: \(error)")
                DispatchQueue.main.async {
                    self?.dismiss(animated: true) {
                        self?.showErrorAlert(message: "Unexpected error: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
}

// Add a helper class to hold weak references
class WeakRef<T: AnyObject> {
    weak var value: T?
    
    init(_ value: T) {
        self.value = value
    }
}
