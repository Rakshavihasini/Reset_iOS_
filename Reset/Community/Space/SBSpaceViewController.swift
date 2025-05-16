//
//  SBSpaceViewController.swift
//  Reset
//
//  Created by Prasanjit Panda on 04/02/25.
//

import UIKit
import SendBirdCalls
import AVFoundation
import FirebaseFirestore
import FirebaseAuth
import FirebaseFunctions
import TipKit
import SwiftUI
import EventKit

protocol RoomCreationDelegate: AnyObject {
    func didCreateRoom(roomId: String)
}

struct CreateRoomTip: Tip {
    var title: Text {
        Text("Create a Voice Room")
    }
    
    var message: Text? {
        Text("Tap here to create your own voice room and start connecting with others")
    }
    
    var image: Image? {
        Image(systemName: "plus.circle.fill")
    }
    
    var rules: [Rule] {
        #Rule(CreateRoomTip.$shouldShowTip) { _ in
            true // Always eligible to show based on internal logic
        }
    }
    
    @Parameter
    static var shouldShowTip: Bool = true
}

// MARK: - Section Enum
enum SpaceSection: Int, CaseIterable {
    case live = 0
    case upcoming = 1
    
    var title: String {
        switch self {
        case .live: return "Live Now"
        case .upcoming: return "Upcoming Spaces"
        }
    }
    
    var icon: String {
        switch self {
        case .live: return "waveform.circle.fill"
        case .upcoming: return "calendar"
        }
    }
}

class SBSpaceViewController: UIViewController {
    
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
    
    // MARK: - Properties
    
    // Queue for thread-safe access to spaces array
    private let spacesQueue = DispatchQueue(label: "com.reset.spacesQueue", attributes: .concurrent)
    
    // Serial queue for SendBird operations
    private let sendbirdQueue = DispatchQueue(label: "com.reset.sendbirdQueue")
    
    // Flag to track authentication state
    private var isAuthenticating = false
    
    // Add a new property to manage serial processing of SendBird operations
    private var roomFetchQueue = DispatchQueue(label: "com.reset.roomFetchQueue")
    private var roomFetchOperations = [String]()
    private var isProcessingRoomFetch = false
    
    // Refresh control for pull-to-refresh
    private let refreshControl = UIRefreshControl()
    
    // Timer to check for spaces that need to be moved from scheduled to live
    private var scheduleCheckTimer: Timer?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        print("SBSpaceViewController: viewDidLoad called")
        
        // Initialize variables
        spaces = []
        // Don't reassign queue variables since they are already initialized
        
        // Setup UI components
        setupUI()
        print("SBSpaceViewController: UI setup completed")
        
        // Setup collection view
        setupCollectionView()
        
        // Setup SendBird
        setupSendbird()
        
        print("SBSpaceViewController: View setup completed - Collection view frame: \(spacesCollectionView.frame)")
        
        NotificationCenter.default.addObserver(self, selector: #selector(spaceCreated(notification:)), name: NSNotification.Name("SpaceCreated"), object: nil)
        
        // Configure Tips
        Task {
            if #available(iOS 17.0, *) {
                try? Tips.configure([
                    .displayFrequency(.immediate),
                    .datastoreLocation(.applicationDefault)
                ])
                print("TipKit configured successfully")
            } else {
                print("TipKit requires iOS 17.0 or later")
            }
        }
        
        // Start timer to check scheduled spaces
        startScheduleCheckTimer()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Print debug info about spaces array and collection view
        print("SBSpaceViewController: viewDidAppear - Current spaces count: \(spaces.count)")
        print("SBSpaceViewController: viewDidAppear - Collection view frame: \(spacesCollectionView.frame)")
        print("SBSpaceViewController: viewDidAppear - Collection view is hidden: \(spacesCollectionView.isHidden)")
        print("SBSpaceViewController: viewDidAppear - Collection view alpha: \(spacesCollectionView.alpha)")
        
        // Restart timer if needed
        startScheduleCheckTimer()
        
        if #available(iOS 17.0, *) {
            // Check if the tip has been shown before
            let tipShown = UserDefaults.standard.bool(forKey: tipShownKey)
            
            if !tipShown {
                Task { @MainActor in
                    if createRoomButton.superview != nil {
                        print("Attempting to show tip for createRoomButton")
                        
                        let shouldDisplay = await createRoomTip.shouldDisplay
                        print("Tip should display: \(shouldDisplay)")
                        
                        let popoverController = TipUIPopoverViewController(createRoomTip, sourceItem: createRoomButton)
                        popoverController.backgroundColor = .systemBrown.withAlphaComponent(0.9)
                        popoverController.imageStyle = .brown
                        present(popoverController, animated: true) {
                            print("Tip popover presented")
                            
                            // Mark the tip as shown after it's displayed
                            UserDefaults.standard.set(true, forKey: self.tipShownKey)
                        }
                    } else {
                        print("Error: createRoomButton is not in view hierarchy")
                    }
                }
            } else {
                print("Tip already shown, skipping display.")
            }
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        // Ensure button is properly rounded during layout
        createRoomButton.layer.cornerRadius = createRoomButton.bounds.width / 2
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("SBSpaceViewController: viewWillAppear")
        
        // Check if we need to initialize SendBird
        if !isAuthenticating && SendBirdCall.currentUser == nil {
            print("SBSpaceViewController: Not authenticated, calling setupSendbird")
            setupSendbird()
        } else if !isAuthenticating && SendBirdCall.currentUser != nil {
            // If already authenticated but spaces listener isn't active, start it
            if spacesListener == nil {
                print("SBSpaceViewController: Already authenticated but spaces listener is nil, restarting")
                startListeningForSpaceChanges()
            } else {
                print("SBSpaceViewController: SendBird already set up and listener active")
            }
        } else {
            print("SBSpaceViewController: Authentication in progress, waiting...")
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        stopListeningForSpaceChanges()
    }
    
    // In viewWillDisappear:
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Cancel the observation task
        tipObservationTask?.cancel()
        tipObservationTask = nil
        stopListeningForSpaceChanges() // Add this line
        
        // Stop the timer when view disappears
        stopScheduleCheckTimer()
    }
    
    private var spacesListener: ListenerRegistration?
    private var isProcessingUpdate = false
    
    private func startListeningForSpaceChanges() {
        print("SBSpaceViewController: Starting to listen for space changes")
        
        // Check if authentication is in progress
        if isAuthenticating {
            print("SBSpaceViewController: Authentication in progress, delaying space listening")
            // Try again after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.startListeningForSpaceChanges()
            }
            return
        }
        
        // Check if we're authenticated before proceeding
        if SendBirdCall.currentUser == nil {
            print("SBSpaceViewController: Not authenticated with SendBird, cannot listen for spaces")
            return
        }
        
        // Stop any existing listener first
        stopListeningForSpaceChanges()
        
        let db = Firestore.firestore()
        let spacesRef = db.collection("spaces")
        
        print("SBSpaceViewController: Setting up Firestore listener on 'spaces' collection")
        
        // Debug: List all documents in spaces collection
        spacesRef.getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("SBSpaceViewController: Error getting spaces documents: \(error)")
                
                // End refreshing if it's active
                DispatchQueue.main.async { 
                    self.refreshControl.endRefreshing()
                }
                return
            }
            
            if let snapshot = snapshot {
                print("SBSpaceViewController: Found \(snapshot.documents.count) documents in spaces collection")
                
                // If no spaces found, make sure we update the UI
                if snapshot.documents.isEmpty {
                    print("SBSpaceViewController: No spaces found in Firestore")
                    
                    DispatchQueue.main.async {
                        // Clear spaces array if needed
                        self.spacesQueue.sync(flags: .barrier) {
                            if !self.spaces.isEmpty {
                                self.spaces.removeAll()
                                self.spacesCollectionView.reloadData()
                            }
                        }
                        
                        // End refreshing if it's active
                        self.refreshControl.endRefreshing()
                    }
                }
                
                for doc in snapshot.documents {
                    print("SBSpaceViewController: Document ID: \(doc.documentID), data: \(doc.data())")
                }
            }
        }

        spacesListener = spacesRef.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("SBSpaceViewController: Error in snapshot listener: \(error.localizedDescription)")
                
                // End refreshing if it's active
                DispatchQueue.main.async {
                    self.refreshControl.endRefreshing()
                }
                return
            }
            
            guard let snapshot = snapshot else {
                print("SBSpaceViewController: Error fetching spaces: empty snapshot")
                
                // End refreshing if it's active
                DispatchQueue.main.async {
                    self.refreshControl.endRefreshing()
                }
                return
            }
            
            print("SBSpaceViewController: Received snapshot with \(snapshot.documentChanges.count) changes and \(snapshot.documents.count) total documents")
            
            // Process changes in a background queue
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else { return }
                
                var updatedSpaces = [Space]()
                self.spacesQueue.sync {
                    updatedSpaces = self.spaces
                }
                
                print("SBSpaceViewController: Processing changes, current spaces count: \(updatedSpaces.count)")
                
                for change in snapshot.documentChanges {
                    if let spaceData = change.document.data() as? [String: Any],
                       let title = spaceData["title"] as? String,
                       let description = spaceData["description"] as? String,
                       let roomID = spaceData["roomID"] as? String {
                        
                        // Infer isLive from liveDuration if not present
                        let liveDuration = spaceData["liveDuration"] as? String ?? "Not Live"
                        let isLive = spaceData["isLive"] as? Bool ?? (liveDuration.lowercased() == "live")
                        
                        let host = spaceData["host"] as? String ?? "Unknown Host"
                        let listenersCount = spaceData["listenersCount"] as? Int ?? 0
                        
                        // Handle scheduled date if available
                        var scheduledDate: Date? = nil
                        if let timestamp = spaceData["scheduledDate"] as? Timestamp {
                            scheduledDate = timestamp.dateValue()
                        }
                        
                        // Handle scheduled duration if available
                        let scheduledDuration = spaceData["scheduledDuration"] as? Int
                        
                        // Get creator ID if available
                        let creatorID = spaceData["creatorID"] as? String
                        
                        // Read addedToCalendar status
                        let addedToCalendar = spaceData["addedToCalendar"] as? Bool ?? false
                        
                        let space = Space(
                            roomID: roomID,
                            title: title,
                            host: host,
                            description: description,
                            listenersCount: listenersCount,
                            liveDuration: liveDuration,
                            isLive: isLive,
                            scheduledDate: scheduledDate,
                            scheduledDuration: scheduledDuration,
                            addedToCalendar: addedToCalendar,
                            creatorID: creatorID
                        )
                        
                        switch change.type {
                        case .added:
                            print("SBSpaceViewController: Added space - Title: \(space.title), RoomID: \(space.roomID)")
                            if !updatedSpaces.contains(where: { $0.roomID == space.roomID }) {
                                updatedSpaces.append(space)
                            }
                        case .modified:
                            print("SBSpaceViewController: Modified space - Title: \(space.title), RoomID: \(space.roomID)")
                            if let index = updatedSpaces.firstIndex(where: { $0.roomID == space.roomID }) {
                                updatedSpaces[index] = space
                            }
                        case .removed:
                            print("SBSpaceViewController: Removed space - Title: \(space.title), RoomID: \(space.roomID)")
                            updatedSpaces.removeAll(where: { $0.roomID == space.roomID })
                        @unknown default:
                            print("SBSpaceViewController: Unknown change type for space - RoomID: \(space.roomID)")
                            break
                        }
                    } else {
                        print("SBSpaceViewController: Failed to parse space data: \(change.document.data())")
                    }
                }
                
                print("SBSpaceViewController: After processing changes, updated spaces count: \(updatedSpaces.count)")
                
                // Update the spaces array and reload collection view on main thread
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    
                    self.spacesQueue.sync {
                        self.spaces = updatedSpaces
                        print("SBSpaceViewController: Updated spaces array, new count: \(self.spaces.count)")
                    }
                    
                    print("SBSpaceViewController: Reloading collection view...")
                    self.spacesCollectionView.reloadData()
                    print("SBSpaceViewController: Collection view reloaded")
                    
                    // End refreshing if it's active
                    self.refreshControl.endRefreshing()
                }
            }
        }
    }
    
    private func stopListeningForSpaceChanges() {
        spacesListener?.remove()
        spacesListener = nil
    }
    
    // Process spaces in batches for better performance and reliability
    private func processAddedSpaces(_ documents: [DocumentSnapshot], completion: @escaping () -> Void) {
        print("SBSpaceViewController: Processing \(documents.count) added spaces")
        
        guard !documents.isEmpty else {
            completion()
            return
        }
        
        // Create a dispatch group to track when all spaces have been added to our array
        let dispatchGroup = DispatchGroup()
        var newSpaces: [(Space, Int)] = []
        
        // Process each document - this part just creates the spaces without fetching room details
        for document in documents {
            dispatchGroup.enter()
            
            // Extract data from document
            guard let data = document.data(),
                  let roomID = data["roomID"] as? String else {
                dispatchGroup.leave()
                continue
            }
            
            // Skip if this space is already in our array
            var exists = false
            spacesQueue.sync {
                exists = spaces.contains { $0.roomID == roomID }
            }
            
            if exists {
                dispatchGroup.leave()
                continue
            }
            
            // Determine if space is live based on liveDuration field
            let liveDuration = data["liveDuration"] as? String ?? "N/A"
            let isLive = data["isLive"] as? Bool ?? (liveDuration.lowercased() == "live")
            
            // Handle scheduled date if available
            var scheduledDate: Date? = nil
            if let timestamp = data["scheduledDate"] as? Timestamp {
                scheduledDate = timestamp.dateValue()
            }
            
            // Handle scheduled duration if available
            let scheduledDuration = data["scheduledDuration"] as? Int
            
            // Get creator ID if available
            let creatorID = data["creatorID"] as? String
            
            // Read addedToCalendar status
            let addedToCalendar = data["addedToCalendar"] as? Bool ?? false
            
            // Create the space with default values
            let newSpace = Space(
                roomID: roomID,
                title: data["title"] as? String ?? "Untitled",
                host: data["host"] as? String ?? "Unknown Host",
                description: data["description"] as? String ?? "",
                listenersCount: data["listenersCount"] as? Int ?? 0,
                liveDuration: liveDuration,
                isLive: isLive,
                scheduledDate: scheduledDate,
                scheduledDuration: scheduledDuration,
                addedToCalendar: addedToCalendar,
                creatorID: creatorID
            )
            
            // Thread-safe access to spaces array
            spacesQueue.sync(flags: .barrier) {
                self.spaces.append(newSpace)
                newSpaces.append((newSpace, self.spaces.count - 1))
            }
            
            // Add this roomID to the fetch queue for serial processing
            roomFetchQueue.async {
                self.roomFetchOperations.append(roomID)
                self.processNextRoomFetch()
            }
            
            dispatchGroup.leave()
        }
        
        // When all spaces are added to our array, update UI
        dispatchGroup.notify(queue: .main) { [weak self] in
            guard let self = self else {
                completion()
                return
            }
            
            // Create index paths for new spaces
            var indexPaths: [IndexPath] = []
            for (_, index) in newSpaces {
                indexPaths.append(IndexPath(item: index, section: 0))
            }
            
            // Update collection view if we have new spaces
            if !indexPaths.isEmpty && self.spacesCollectionView != nil {
                self.spacesCollectionView.performBatchUpdates({
                    self.spacesCollectionView.insertItems(at: indexPaths)
                }, completion: { success in
                    if !success {
                        print("SBSpaceViewController: Failed to update collection view, reloading data")
                        self.spacesCollectionView.reloadData()
                    }
                    completion()
                })
            } else {
                completion()
            }
        }
    }
    
    // Process room fetch operations one at a time
    private func processNextRoomFetch() {
        roomFetchQueue.async { [weak self] in
            guard let self = self else { return }
            
            // If already processing or no operations, exit
            if self.isProcessingRoomFetch || self.roomFetchOperations.isEmpty {
                return
            }
            
            // Mark as processing
            self.isProcessingRoomFetch = true
            
            // Get the next roomID to process
            let roomID = self.roomFetchOperations.removeFirst()
            
            // Skip if not authenticated
            guard SendBirdCall.currentUser != nil else {
                print("SBSpaceViewController: Not authenticated with SendBird, skipping room fetch")
                self.isProcessingRoomFetch = false
                self.processNextRoomFetch()
                return
            }
            
            // Process on the SendBird queue
            self.sendbirdQueue.async {
                print("SBSpaceViewController: Serially fetching room details for: \(roomID)")
                
                // Insert a small delay to avoid overwhelming SendBird
                Thread.sleep(forTimeInterval: 0.1)
                
                SendBirdCall.fetchRoom(by: roomID) { [weak self] room, error in
                    guard let self = self else { return }
                    
                    if let error = error {
                        print("SBSpaceViewController: Error fetching room details: \(error)")
                        
                        // Mark as done and process next
                        self.roomFetchQueue.async {
                            self.isProcessingRoomFetch = false
                            self.processNextRoomFetch()
                        }
                        return
                    }
                    
                    guard let room = room else {
                        print("SBSpaceViewController: Room not found for: \(roomID)")
                        
                        // Mark as done and process next
                        self.roomFetchQueue.async {
                            self.isProcessingRoomFetch = false
                            self.processNextRoomFetch()
                        }
                        return
                    }
                    
                    print("SBSpaceViewController: Successfully fetched room: \(roomID)")
                    
                    // Get the updated space data
                    var updatedSpace: Space?
                    var spaceIndex: Int?
                    
                    // Thread-safe update to our space
                    self.spacesQueue.sync(flags: .barrier) {
                        if let index = self.spaces.firstIndex(where: { $0.roomID == roomID }) {
                            self.spaces[index].listenersCount = room.participants.count
                            updatedSpace = self.spaces[index]
                            spaceIndex = index
                        }
                    }
                    
                    // If we have a valid space and index, load participant images
                    if let space = updatedSpace, let index = spaceIndex {
                        // Load participant images in background
                        DispatchQueue.global(qos: .userInitiated).async {
                            let participantImages: [UIImage] = room.participants.compactMap { participant in
                                if let profileURL = participant.user.profileURL, let url = URL(string: profileURL) {
                                    do {
                                        let imageData = try Data(contentsOf: url)
                                        return UIImage(data: imageData)
                                    } catch {
                                        print("SBSpaceViewController: Error loading image data: \(error)")
                                        return nil
                                    }
                                }
                                return nil
                            }.prefix(3).compactMap { $0 } // Filter out nil images and limit to 3
                            
                            // Update UI on main thread
                            DispatchQueue.main.async {
                                // Find cells for this space and update them
                                if let collectionView = self.spacesCollectionView {
                                    for visibleCell in collectionView.visibleCells {
                                        if let cell = visibleCell as? SBSpacesCollectionViewCell, 
                                           cell.tag == roomID.hashValue {
                                            print("SBSpaceViewController: Updating cell with \(participantImages.count) participant images")
                                            cell.configureCell(with: space, profileImages: participantImages)
                                            break
                                        }
                                    }
                                }
                                
                                // Mark as done and process next
                                self.roomFetchQueue.async {
                                    self.isProcessingRoomFetch = false
                                    self.processNextRoomFetch()
                                }
                            }
                        }
                    } else {
                        // Mark as done and process next if we couldn't find the space
                        self.roomFetchQueue.async {
                            self.isProcessingRoomFetch = false
                            self.processNextRoomFetch()
                        }
                    }
                }
            }
        }
    }
    
    private func processModifiedSpaces(_ documents: [DocumentSnapshot]) {
        let dispatchGroup = DispatchGroup()
        var updatedIndexPaths: [IndexPath] = []
        
        for document in documents {
            guard let data = document.data(),
                  let roomID = data["roomID"] as? String else { continue }
            
            dispatchGroup.enter()
            
            // Find the space in our array
            spacesQueue.sync { [weak self] in
                guard let self = self,
                      let index = self.spaces.firstIndex(where: { $0.roomID == roomID }) else {
                    dispatchGroup.leave()
                    return
                }
                
                // Determine if space is live based on liveDuration field
                let liveDuration = data["liveDuration"] as? String ?? self.spaces[index].liveDuration
                let isLive = data["isLive"] as? Bool ?? (liveDuration.lowercased() == "live")
                
                // Update the space with new data
                self.spaces[index].title = data["title"] as? String ?? self.spaces[index].title
                self.spaces[index].host = data["host"] as? String ?? self.spaces[index].host
                self.spaces[index].description = data["description"] as? String ?? self.spaces[index].description
                self.spaces[index].liveDuration = liveDuration
                self.spaces[index].isLive = isLive
                
                // Use serial queue for SendBird operations
                self.sendbirdQueue.async {
                    // Skip if not authenticated
                    guard SendBirdCall.currentUser != nil else {
                        print("SBSpaceViewController: Not authenticated with SendBird, cannot fetch room details")
                        dispatchGroup.leave()
                        
                        // Still update UI for this item
                        DispatchQueue.main.async {
                            updatedIndexPaths.append(IndexPath(item: index, section: 0))
                        }
                        return
                    }
                    
                    SendBirdCall.fetchRoom(by: roomID) { room, error in
                        defer { dispatchGroup.leave() }
                        
                        if let error = error {
                            print("SBSpaceViewController: Error fetching room details: \(error)")
                            return
                        }
                        
                        // Update participant count if room was fetched successfully
                        if let room = room {
                            self.spacesQueue.sync(flags: .barrier) {
                                if let index = self.spaces.firstIndex(where: { $0.roomID == roomID }) {
                                    self.spaces[index].listenersCount = room.participants.count
                                    
                                    // Update UI for this item
                                    DispatchQueue.main.async {
                                        updatedIndexPaths.append(IndexPath(item: index, section: 0))
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        // When all operations are complete, update UI
        dispatchGroup.notify(queue: .main) { [weak self] in
            guard let self = self, !updatedIndexPaths.isEmpty, self.spacesCollectionView != nil else { return }
            
            // Remove duplicates (in case an item was updated multiple times)
            let uniqueIndexPaths = Array(Set(updatedIndexPaths))
            
            print("SBSpaceViewController: Updating \(uniqueIndexPaths.count) modified spaces")
            
            self.spacesCollectionView.performBatchUpdates({
                self.spacesCollectionView.reloadItems(at: uniqueIndexPaths)
            }, completion: { success in
                if !success {
                    print("SBSpaceViewController: Failed to update collection view, reloading data")
                    self.spacesCollectionView.reloadData()
                }
            })
        }
    }
    
    private func processRemovedSpaces(_ documentIDs: [String]) {
        var indexPaths: [IndexPath] = []
        var indicesToRemove: [Int] = []
        
        // Find indices to remove in a thread-safe way
        spacesQueue.sync { [weak self] in
            guard let self = self else { return }
            
            for documentID in documentIDs {
                if let index = self.spaces.firstIndex(where: { $0.roomID == documentID }) {
                    indicesToRemove.append(index)
                    indexPaths.append(IndexPath(item: index, section: 0))
                }
            }
        }
        
        // Sort indices in descending order to safely remove from array
        let sortedIndices = indicesToRemove.sorted(by: >)
        
        // Remove spaces from our array
        spacesQueue.sync(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            for index in sortedIndices {
                if index < self.spaces.count {
                    self.spaces.remove(at: index)
                }
            }
        }
        
        // Update UI on main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self, !indexPaths.isEmpty else { return }
            
            // Sort index paths to ensure correct deletion order
            let sortedPaths = indexPaths.sorted { $0.item > $1.item }
            
            self.spacesCollectionView.performBatchUpdates({
                self.spacesCollectionView.deleteItems(at: sortedPaths)
            }) { completed in
                if !completed {
                    // If batch update failed, fall back to reloading the entire collection view
                    self.spacesCollectionView.reloadData()
                }
            }
        }
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        view.backgroundColor = .white
        createRoomButton.addTarget(self, action: #selector(createRoomTapped), for: .touchUpInside)
    }
    
    // MARK: - SendBird Setup
    func setupSendbird() {
        // Skip configuration as it's already done in AppDelegate
        // Only handle authentication if needed
        
        print("SBSpaceViewController: Starting SendBird setup")

        guard let currentUser = Auth.auth().currentUser else {
            print("SBSpaceViewController: No logged-in user.")
            return
        }
        
        // Check if already authenticated with the current user
        if let currentSendbirdUser = SendBirdCall.currentUser, 
           currentSendbirdUser.userId == currentUser.uid {
            print("SBSpaceViewController: Already authenticated as: \(currentSendbirdUser.userId)")
            
            // If already authenticated, start listening for spaces
            startListeningForSpaceChanges()
            return
        }
        
        print("SBSpaceViewController: Fetching SendBird token for user: \(currentUser.uid)")
        
        // Set a flag to indicate authentication is in progress
        isAuthenticating = true

        fetchSendbirdTokenFromFirestore(userId: currentUser.uid) { [weak self] token, error in
            guard let self = self else { return }
            
            if let error = error {
                print("SBSpaceViewController: Failed to get Sendbird token: \(error.localizedDescription)")
                self.isAuthenticating = false
                return
            }
            
            guard let token = token else {
                print("SBSpaceViewController: Token is nil")
                self.isAuthenticating = false
                return
            }
            
            print("SBSpaceViewController: Got token, authenticating with SendBird")

            SendBirdCall.authenticate(with: AuthenticateParams(userId: currentUser.uid, accessToken: token)) { user, error in
                if let error = error {
                    print("SBSpaceViewController: Authentication failed: \(error.localizedDescription)")
                } else {
                    print("SBSpaceViewController: Authentication successful as: \(user?.userId ?? "Unknown User")")
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
    
    func fetchSendbirdTokenFromFirestore(userId: String, completion: @escaping (String?, Error?) -> Void) {
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
        // Dismiss the tip when button is tapped
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
    
    
    @objc private func joinRoomTapped() {
        let alert = UIAlertController(title: "Join Room", message: "Enter Room ID", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "Room ID"
        }
        
        alert.addAction(UIAlertAction(title: "Join", style: .default, handler: { [weak self] _ in
            guard let roomId = alert.textFields?.first?.text, !roomId.isEmpty else { return }
            
            SendBirdCall.fetchRoom(by: roomId) { room, error in
                guard let room = room, error == nil else {
                    print("Failed to fetch room: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                room.enter(with: Room.EnterParams(isAudioEnabled: true)) { error in
                    if let error = error {
                        print("Error joining room: \(error.localizedDescription)")
                    } else {
                        print("Joined room: \(room.roomId)")
                        self?.presentRoomViewController(room: room)
                    }
                }
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func presentRoomViewController(room: Room) {
        print("SBSpaceViewController: Presenting voice room view controller")
        let voiceRoomVC = VoiceRoomViewController(room: room)
        self.present(voiceRoomVC, animated: true)
    }
    
    private func setupCollectionView() {
        print("SBSpaceViewController: Setting up collection view")
        
        // Create a compositional layout
        let layout = createCompositionalLayout()
        
        // Debug frame calculation
        let viewFrame = view.frame
        print("SBSpaceViewController: View frame for collection view: \(viewFrame)")
        
        spacesCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        spacesCollectionView.backgroundColor = .clear
        spacesCollectionView.showsVerticalScrollIndicator = false
        spacesCollectionView.delegate = self
        spacesCollectionView.dataSource = self
        
        // Set up pull-to-refresh
        refreshControl.tintColor = .systemBrown
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: #selector(refreshSpaces), for: .valueChanged)
        spacesCollectionView.refreshControl = refreshControl
        
        // Register the custom cells
        print("SBSpaceViewController: Registering cell classes")
        spacesCollectionView.register(SBSpacesCollectionViewCell.self, forCellWithReuseIdentifier: "SpacesCollectionViewCell")
        spacesCollectionView.register(ScheduledSpaceCollectionViewCell.self, forCellWithReuseIdentifier: "ScheduledSpaceCollectionViewCell")
        
        // Register header view
        spacesCollectionView.register(SpaceSectionHeaderView.self, 
                                      forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, 
                                      withReuseIdentifier: "SpaceSectionHeader")
        
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
        
        // Make sure the collection view is visible
        spacesCollectionView.isHidden = false
        spacesCollectionView.alpha = 1.0
        
        // Force layout to ensure frame is calculated
        view.layoutIfNeeded()
        
        print("SBSpaceViewController: Collection view setup complete - isHidden: \(spacesCollectionView.isHidden), alpha: \(spacesCollectionView.alpha), frame: \(spacesCollectionView.frame)")
    }
    
    private func createCompositionalLayout() -> UICollectionViewCompositionalLayout {
        return UICollectionViewCompositionalLayout { [weak self] (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
            guard let self = self else { return nil }
            
            // Configure the layout for each section
            guard let section = SpaceSection(rawValue: sectionIndex) else { return nil }
            
            // Item
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(200)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            
            // Group
            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(200)
            )
            let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
            group.interItemSpacing = .fixed(16)
            
            // Section
            let layoutSection = NSCollectionLayoutSection(group: group)
            layoutSection.interGroupSpacing = 16
            layoutSection.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
            
            // Header
            let headerSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(50)
            )
            let header = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: headerSize,
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: .top
            )
            layoutSection.boundarySupplementaryItems = [header]
            
            return layoutSection
        }
    }

    // MARK: - Handle Notification when a New Space is Created
    @objc private func spaceCreated(notification: Notification) {
        guard let newSpaceData = notification.object as? [String: Any],
              let roomID = newSpaceData["roomID"] as? String,
              let title = newSpaceData["title"] as? String else {
            print("Invalid space data received in notification")
            return
        }
        
        // Extract other fields with defaults
        let host = newSpaceData["host"] as? String ?? "Unknown Host"
        let description = newSpaceData["description"] as? String ?? ""
        let listenersCount = newSpaceData["listenersCount"] as? Int ?? 0
        let liveDuration = newSpaceData["liveDuration"] as? String ?? "Not Live"
        let isLive = newSpaceData["isLive"] as? Bool ?? false
        
        // Handle scheduled date if available
        var scheduledDate: Date? = nil
        if let timestamp = newSpaceData["scheduledDate"] as? Timestamp {
            scheduledDate = timestamp.dateValue()
        }
        
        // Handle scheduled duration if available
        let scheduledDuration = newSpaceData["scheduledDuration"] as? Int
        
        // Get creator ID - use current user ID if not provided
        let currentUserID = Auth.auth().currentUser?.uid
        let creatorID = newSpaceData["creatorID"] as? String ?? currentUserID
        
        // Get addedToCalendar status - if user is creator, automatically mark as added
        let addedToCalendar = newSpaceData["addedToCalendar"] as? Bool ?? (creatorID == currentUserID)
        
        // Check if we already have this space
        var spaceExists = false
        spacesQueue.sync {
            spaceExists = self.spaces.contains(where: { $0.roomID == roomID })
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
            liveDuration: liveDuration,
            isLive: isLive,
            scheduledDate: scheduledDate,
            scheduledDuration: scheduledDuration,
            addedToCalendar: addedToCalendar,
            creatorID: creatorID
        )
        
        // Add new space to the collection in a thread-safe way
        spacesQueue.sync(flags: .barrier) {
            self.spaces.append(space)
        }
        
        // Update UI on main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.spacesCollectionView != nil else { return }
            
            print("SBSpaceViewController: Adding new space from notification")
            
            // Determine which section needs to be reloaded
            let section = space.isLive ? SpaceSection.live.rawValue : 
                         (space.scheduledDate != nil ? SpaceSection.upcoming.rawValue : SpaceSection.live.rawValue)
            
            // Force layout update before reloading section
            self.spacesCollectionView.layoutIfNeeded()
            
            // Reload the specific section
            self.spacesCollectionView.reloadSections(IndexSet(integer: section))
            
            // Force layout again after reloading
            self.spacesCollectionView.layoutIfNeeded()
            
            // For scheduled spaces, ensure they're visible by scrolling if needed
            if !space.isLive && space.scheduledDate != nil {
                // Scroll to make the section visible if not already
                if let attributes = self.spacesCollectionView.layoutAttributesForSupplementaryElement(
                    ofKind: UICollectionView.elementKindSectionHeader,
                    at: IndexPath(item: 0, section: section)
                ) {
                    // Disable animations temporarily to ensure immediate visibility
                    CATransaction.begin()
                    CATransaction.setDisableActions(true)
                    self.spacesCollectionView.scrollRectToVisible(attributes.frame, animated: false)
                    CATransaction.commit()
                }
            }
            
            // Force a final layout update to ensure everything is visible
            self.spacesCollectionView.layoutIfNeeded()
        }
    }

    // Helper method to show error alerts
    private func showErrorAlert(message: String) {
        print("SBSpaceViewController: Showing error alert: \(message)")
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true)
    }

    // MARK: - Pull-to-refresh
    @objc private func refreshSpaces() {
        print("SBSpaceViewController: Pull-to-refresh triggered")
        
        // Make sure we're authenticated before refreshing
        if SendBirdCall.currentUser == nil {
            print("SBSpaceViewController: Not authenticated, attempting to set up SendBird")
            setupSendbird()
            
            // End refreshing after a short delay to prevent hanging
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.refreshControl.endRefreshing()
                
                // If still not authenticated, show an error
                if SendBirdCall.currentUser == nil {
                    self?.showErrorAlert(message: "Unable to refresh: Not authenticated with SendBird")
                }
            }
            return
        }
        
        // Stop existing listener and start a new one to get fresh data
        stopListeningForSpaceChanges()
        
        // Clear existing spaces to ensure we get fresh data
        spacesQueue.sync(flags: .barrier) {
            self.spaces.removeAll()
        }
        
        // Start listening for space changes again
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            
            self.startListeningForSpaceChanges()
            
            // End refreshing after a short delay to ensure some data has loaded
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.refreshControl.endRefreshing()
            }
        }
    }
    
    // MARK: - Timer Functions
    
    private func startScheduleCheckTimer() {
        // Stop any existing timer first
        stopScheduleCheckTimer()
        
        // Create a new timer that fires every minute
        scheduleCheckTimer = Timer.scheduledTimer(
            timeInterval: 60.0, // Check every minute
            target: self,
            selector: #selector(checkScheduledSpaces),
            userInfo: nil,
            repeats: true
        )
        
        // Run it once immediately
        checkScheduledSpaces()
    }
    
    private func stopScheduleCheckTimer() {
        scheduleCheckTimer?.invalidate()
        scheduleCheckTimer = nil
    }
    
    @objc private func checkScheduledSpaces() {
        print("SBSpaceViewController: Checking for scheduled spaces that should be live now")
        
        let now = Date()
        var spacesToUpdate: [String] = []
        print("SBSpaceViewController: Current time: \(formatDate(now))")
        
        // Dump all scheduled spaces for debugging
        spacesQueue.sync {
            print("SBSpaceViewController: Total spaces count: \(self.spaces.count)")
            for (index, space) in self.spaces.enumerated() {
                if let scheduledDate = space.scheduledDate {
                    print("SBSpaceViewController: Space \(index): \(space.title), scheduled: \(formatDate(scheduledDate)), isLive: \(space.isLive)")
                }
            }
        }
        
        // Find spaces that should be live now
        spacesQueue.sync {
            for (index, space) in self.spaces.enumerated() {
                if !space.isLive, // Not already live
                   let scheduledDate = space.scheduledDate,
                   scheduledDate <= now { // Scheduled time has passed
                    
                    print("SBSpaceViewController: Space \(space.title) should be live - scheduled: \(formatDate(scheduledDate))")
                    
                    // Mark space as needing update
                    spacesToUpdate.append(space.roomID)
                    
                    // Update locally
                    self.spaces[index].isLive = true
                    self.spaces[index].liveDuration = "Live"
                }
            }
        }
        
        // If we found spaces to update, update them in Firestore
        if !spacesToUpdate.isEmpty {
            print("SBSpaceViewController: Found \(spacesToUpdate.count) spaces to update to live")
            
            let db = Firestore.firestore()
            
            // For each space, first find its document ID by querying for the roomID field
            let dispatchGroup = DispatchGroup()
            
            for roomID in spacesToUpdate {
                dispatchGroup.enter()
                
                // Query for the document with this roomID
                db.collection("spaces").whereField("roomID", isEqualTo: roomID).getDocuments { snapshot, error in
                    defer { dispatchGroup.leave() }
                    
                    if let error = error {
                        print("SBSpaceViewController: Error finding space document: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let documents = snapshot?.documents, !documents.isEmpty else {
                        print("SBSpaceViewController: No document found with roomID: \(roomID)")
                        return
                    }
                    
                    // Update each matching document
                    for document in documents {
                        let docID = document.documentID
                        print("SBSpaceViewController: Updating document ID: \(docID) for roomID: \(roomID)")
                        
                        // Update the document
                        db.collection("spaces").document(docID).updateData([
                            "isLive": true,
                            "liveDuration": "Live"
                        ]) { error in
                            if let error = error {
                                print("SBSpaceViewController: Error updating space: \(error.localizedDescription)")
                            } else {
                                print("SBSpaceViewController: Successfully updated space: \(roomID)")
                            }
                        }
                    }
                }
            }
            
            // After all updates are complete, reload the UI
            dispatchGroup.notify(queue: .main) {
                self.spacesCollectionView.reloadData()
                print("SBSpaceViewController: UI updated after scheduled spaces check")
            }
        }
    }
    
    // Helper method to format date for display
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func spaceAlreadyAddedToCalendar(_ space: Space) -> Bool {
        // First check if it's marked in the space object
        if space.addedToCalendar {
            return true
        }
        
        // Also check in user defaults as a backup
        let key = "space_calendar_\(space.roomID)_\(Auth.auth().currentUser?.uid ?? "")"
        return UserDefaults.standard.bool(forKey: key)
    }
    
    private func markSpaceAddedToCalendar(_ space: Space) {
        // Also store in user defaults as a backup
        let key = "space_calendar_\(space.roomID)_\(Auth.auth().currentUser?.uid ?? "")"
        UserDefaults.standard.set(true, forKey: key)
    }

    private func addSpaceToCalendar(_ space: Space) {
        guard let scheduledDate = space.scheduledDate else {
            showErrorAlert(message: "Missing scheduled date information")
            return
        }
        
        // Check if already added using our helper method
        if spaceAlreadyAddedToCalendar(space) {
            showSuccessAlert(title: "Already Added", message: "This space is already in your calendar")
            return
        }
        
        // Create event store instance
        let eventStore = EKEventStore()
        
        // Request calendar access
        eventStore.requestAccess(to: .event) { [weak self] granted, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if granted && error == nil {
                    // Create new event
                    let event = EKEvent(eventStore: eventStore)
                    event.title = space.title
                    event.notes = space.description
                    event.startDate = scheduledDate
                    
                    // Calculate end date (default 30 min or use scheduledDuration)
                    let duration = space.scheduledDuration ?? 30
                    event.endDate = scheduledDate.addingTimeInterval(TimeInterval(duration * 60))
                    
                    // Set calendar to default calendar
                    event.calendar = eventStore.defaultCalendarForNewEvents
                    
                    // Add a URL to open the app (if applicable)
                    // This would require a custom URL scheme for your app
                    // event.url = URL(string: "yourapp://space/\(space.roomID)")
                    
                    do {
                        try eventStore.save(event, span: .thisEvent)
                        
                        // Mark space as added to calendar in both local state and UserDefaults
                        self.markSpaceAddedToCalendar(space)
                        
                        // Mark this space as added to calendar
                        self.spacesQueue.sync(flags: .barrier) {
                            if let index = self.spaces.firstIndex(where: { $0.roomID == space.roomID }) {
                                self.spaces[index].addedToCalendar = true
                                
                                // Update Firestore by first finding the document with this roomID
                                let db = Firestore.firestore()
                                db.collection("spaces").whereField("roomID", isEqualTo: space.roomID).getDocuments { snapshot, error in
                                    if let error = error {
                                        print("Error finding space document: \(error.localizedDescription)")
                                        return
                                    }
                                    
                                    guard let documents = snapshot?.documents, !documents.isEmpty else {
                                        print("No document found with roomID: \(space.roomID)")
                                        return
                                    }
                                    
                                    // Update each matching document
                                    for document in documents {
                                        let docID = document.documentID
                                        print("Updating document ID: \(docID) for roomID: \(space.roomID)")
                                        
                                        // Update the document
                                        db.collection("spaces").document(docID).updateData([
                                            "addedToCalendar": true
                                        ]) { error in
                                            if let error = error {
                                                print("Error updating space in Firestore: \(error.localizedDescription)")
                                            } else {
                                                print("Successfully marked space as added to calendar: \(space.roomID)")
                                            }
                                        }
                                    }
                                }
                                
                                // Reload the collection view to update the UI
                                DispatchQueue.main.async {
                                    self.spacesCollectionView.reloadData()
                                }
                            }
                        }
                        
                        self.showSuccessAlert(title: "Added to Calendar", message: "This space has been added to your calendar")
                    } catch {
                        self.showErrorAlert(message: "Failed to add to calendar: \(error.localizedDescription)")
                    }
                } else {
                    self.showErrorAlert(message: "Calendar access denied. Please enable calendar access in Settings.")
                }
            }
        }
    }
    
    // Helper method to show success alerts
    private func showSuccessAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true)
    }
    
    // MARK: - Helper Methods for Section Data
    
    private func getSpacesForSection(_ section: SpaceSection) -> [Space] {
        spacesQueue.sync {
            switch section {
            case .live:
                return spaces.filter { $0.isLive }
            case .upcoming:
                return spaces.filter { !$0.isLive && $0.scheduledDate != nil }
            }
        }
    }
    
    private func numberOfSections() -> Int {
        return SpaceSection.allCases.count
    }
    
    private func numberOfItems(in section: Int) -> Int {
        guard let spaceSection = SpaceSection(rawValue: section) else { return 0 }
        return getSpacesForSection(spaceSection).count
    }
    
    private func space(for indexPath: IndexPath) -> Space? {
        guard let section = SpaceSection(rawValue: indexPath.section) else { return nil }
        let sectionSpaces = getSpacesForSection(section)
        guard indexPath.item < sectionSpaces.count else { return nil }
        return sectionSpaces[indexPath.item]
    }
}

extension SBSpaceViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return numberOfSections()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let count = numberOfItems(in: section)
        print("SBSpaceViewController: numberOfItemsInSection \(section) called, returning \(count) items")
        return count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        print("SBSpaceViewController: cellForItemAt called for indexPath \(indexPath)")
        
        guard let section = SpaceSection(rawValue: indexPath.section),
              let space = space(for: indexPath) else {
            return UICollectionViewCell()
        }
        
        // Choose cell type based on section
        switch section {
        case .live:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SpacesCollectionViewCell", for: indexPath) as? SBSpacesCollectionViewCell else {
                print("SBSpaceViewController: Failed to dequeue SBSpacesCollectionViewCell")
                return UICollectionViewCell()
            }
            
            cell.configureCell(with: space, profileImages: [])
            
            // Tag the cell with the roomID to prevent wrong image updates
            cell.tag = space.roomID.hashValue
            
            // Add to the room fetch queue for participant images
            roomFetchQueue.async { [weak self] in
                guard let self = self else { return }
                if !self.roomFetchOperations.contains(space.roomID) {
                    self.roomFetchOperations.append(space.roomID)
                    self.processNextRoomFetch()
                }
            }
            return cell
            
        case .upcoming:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ScheduledSpaceCollectionViewCell", for: indexPath) as? ScheduledSpaceCollectionViewCell else {
                print("SBSpaceViewController: Failed to dequeue ScheduledSpaceCollectionViewCell")
                return UICollectionViewCell()
            }
            
            cell.configure(with: space)
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            guard let headerView = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: "SpaceSectionHeader",
                for: indexPath) as? SpaceSectionHeaderView,
                  let section = SpaceSection(rawValue: indexPath.section) else {
                return UICollectionReusableView()
            }
            
            headerView.configure(with: section.title, iconName: section.icon)
            return headerView
        }
        
        return UICollectionReusableView()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("SBSpaceViewController: didSelectItemAt called for indexPath \(indexPath)")
        
        // Check if we're authenticated before proceeding
        if SendBirdCall.currentUser == nil {
            print("SBSpaceViewController: Not authenticated with SendBird, cannot select space")
            showErrorAlert(message: "Not authenticated with SendBird. Please try again later.")
            return
        }
        
        guard let selectedSpace = space(for: indexPath) else {
            print("SBSpaceViewController: Error: Could not retrieve selected space")
            showErrorAlert(message: "Could not retrieve selected space. Please try again.")
            return
        }
        
        print("SBSpaceViewController: Selected space: \(selectedSpace.roomID)")
        
        // Check if space is scheduled for future
        if let scheduledDate = selectedSpace.scheduledDate, scheduledDate > Date() {
            print("SBSpaceViewController: Space is scheduled for future: \(scheduledDate)")
            
            // Get current user ID
            let currentUserId = Auth.auth().currentUser?.uid
            
            // Debug info
            print("SBSpaceViewController: Space creator ID: \(selectedSpace.creatorID ?? "nil"), Current user ID: \(currentUserId ?? "nil")")
            print("SBSpaceViewController: Space already added to calendar: \(selectedSpace.addedToCalendar)")
            
            // Skip calendar alert if user is the creator or has already added to calendar
            let isCreator = (selectedSpace.creatorID != nil) && (selectedSpace.creatorID == currentUserId)
            
            let spaceAlreadyAdded = spaceAlreadyAddedToCalendar(selectedSpace)
            
            if isCreator {
                print("SBSpaceViewController: User is creator, showing basic info alert")
                
                // Just show info alert without add to calendar option
                let infoAlert = UIAlertController(
                    title: "Scheduled Space",
                    message: "This space is scheduled to start on \(formatDate(scheduledDate)).",
                    preferredStyle: .alert
                )
                
                infoAlert.addAction(UIAlertAction(title: "OK", style: .default))
                
                present(infoAlert, animated: true)
                return
            } else if spaceAlreadyAdded {
                print("SBSpaceViewController: Space already added to calendar, showing already added alert")
                
                // Show alert indicating already added
                let infoAlert = UIAlertController(
                    title: "Already Added",
                    message: "This space has already been added to your calendar. It starts on \(formatDate(scheduledDate)).",
                    preferredStyle: .alert
                )
                
                infoAlert.addAction(UIAlertAction(title: "OK", style: .default))
                
                present(infoAlert, animated: true)
                return
            }
            
            // Show alert to add to calendar for regular users
            print("SBSpaceViewController: Showing Add to Calendar option")
            let alert = UIAlertController(
                title: "Scheduled Space",
                message: "This space is scheduled to start on \(formatDate(scheduledDate)). Would you like to add it to your calendar?",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "Add to Calendar", style: .default) { [weak self] _ in
                self?.addSpaceToCalendar(selectedSpace)
            })
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            
            present(alert, animated: true)
            return
        }
        
        // Handle live space joining - show loading and fetch room
        let roomID = selectedSpace.roomID
        
        // Show loading indicator
        let loadingAlert = UIAlertController(title: nil, message: "Joining room...", preferredStyle: .alert)
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = .medium
        loadingIndicator.startAnimating()
        loadingAlert.view.addSubview(loadingIndicator)
        present(loadingAlert, animated: true)
        
        // Pause all other room fetches to prioritize this one
        roomFetchQueue.async { [weak self] in
            guard let self = self else { return }
            // Temporarily stop processing other fetches
            self.isProcessingRoomFetch = true
        }
        
        // Use serial queue for SendBird operations, but with a slight delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }
            
            // Use serial queue for SendBird operations
            self.sendbirdQueue.async { [weak self] in
                guard let self = self else { return }
                
                print("SBSpaceViewController: Fetching room for selected space: \(selectedSpace.roomID)")
                
                // Double-check authentication before making the call
                guard SendBirdCall.currentUser != nil else {
                    print("SBSpaceViewController: Not authenticated with SendBird, cannot fetch room")
                    
                    // Resume other room fetches
                    self.roomFetchQueue.async {
                        self.isProcessingRoomFetch = false
                        self.processNextRoomFetch()
                    }
                    
                    DispatchQueue.main.async {
                        self.dismiss(animated: true) {
                            self.showErrorAlert(message: "Not authenticated with SendBird. Please try again later.")
                        }
                    }
                    return
                }
                
                // Use a try-catch block to handle any unexpected errors
                do {
                    SendBirdCall.fetchRoom(by: selectedSpace.roomID) { room, error in
                        // Resume other room fetches
                        self.roomFetchQueue.async {
                            self.isProcessingRoomFetch = false
                            self.processNextRoomFetch()
                        }
                        
                        // Dismiss loading indicator on main thread
                        DispatchQueue.main.async {
                            self.dismiss(animated: true) {
                                // Handle errors
                                if let error = error {
                                    print("SBSpaceViewController: Error fetching room: \(error.localizedDescription)")
                                    self.showErrorAlert(message: "Error fetching room: \(error.localizedDescription)")
                                    return
                                }
                                
                                guard let room = room else {
                                    print("SBSpaceViewController: Room not found for: \(selectedSpace.roomID)")
                                    self.showErrorAlert(message: "Room not found")
                                    return
                                }
                                
                                print("SBSpaceViewController: Successfully fetched room, presenting view controller")
                                
                                // Present the voice room view controller
                                self.presentRoomViewController(room: room)
                            }
                        }
                    }
                } catch {
                    // Resume other room fetches
                    self.roomFetchQueue.async {
                        self.isProcessingRoomFetch = false
                        self.processNextRoomFetch()
                    }
                    
                    print("SBSpaceViewController: Unexpected error fetching room: \(error)")
                    DispatchQueue.main.async {
                        self.dismiss(animated: true) {
                            self.showErrorAlert(message: "Unexpected error: \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
    }
}

