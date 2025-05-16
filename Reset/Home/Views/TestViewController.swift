import UIKit
import SwiftUI
import Charts
import FirebaseAuth
import FirebaseFirestore
import TipKit

struct ProgressTrackerTip: Tip {
    var title: Text {
        Text("Track Your Progress")
    }
    
    var message: Text? {
        Text("See your sobriety progress and milestones here.")
    }
    
    var image: Image? {
        Image(systemName: "chart.bar.fill")
    }
    
    var rules: [Rule] {
        #Rule(ProgressTrackerTip.$shouldShowTip) { _ in true }
    }
    
    @Parameter
    static var shouldShowTip: Bool = true
}

class TestViewController: UIViewController {
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private var progressContainerView: ProgressContainerView?
    private var graphHostingController: UIHostingController<UrgeGraphView>?
    private var statsHostingController: UIHostingController<UrgeStatsView>?
    private var userSoberStreak: Int = 0
    private let progressTrackerTip = ProgressTrackerTip()
    private let progressTipShownKey = "progressTrackerTipShown" // Key to track tip display

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupViews()
        configureTipKit()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchUrgeData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if #available(iOS 17.0, *) {
            // Check if the tip has been shown before
            let tipShown = UserDefaults.standard.bool(forKey: progressTipShownKey)
            
            if !tipShown {
                Task { @MainActor in
                    let shouldDisplay = await progressTrackerTip.shouldDisplay
                    print("Progress Tip should display: \(shouldDisplay)")
                    
                    if let progressView = progressContainerView {
                        let popoverController = TipUIPopoverViewController(progressTrackerTip, sourceItem: progressView)
                        popoverController.backgroundColor = .systemGray.withAlphaComponent(0.9)
                        popoverController.imageStyle = .brown
                        present(popoverController, animated: true) {
                            print("Progress Tip popover presented")
                            
                            // Mark the tip as shown after it's displayed
                            UserDefaults.standard.set(true, forKey: self.progressTipShownKey)
                        }
                    }
                }
            } else {
                print("Progress Tip already shown, skipping display.")
            }
        }
    }
    
    private func configureTipKit() {
        if #available(iOS 17.0, *) {
            Task {
                try? Tips.configure([
                    .displayFrequency(.immediate),
                    .datastoreLocation(.applicationDefault)
                ])
                progressTrackerTip.invalidate(reason: .tipClosed)
                print("Progress TipKit configured successfully")
            }
        }
    }

    private func setupViews() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.isUserInteractionEnabled = true
        view.addSubview(scrollView)

        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)

        let headerView = SummaryHeaderView()
        headerView.parentViewController = self
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)

        let trackerView = ProgressContainerView()
        self.progressContainerView = trackerView
        trackerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(trackerView)
        addTapGestureRecognizers(to: trackerView)

        let graphView = UrgeGraphView(timestamps: [:]) { [weak self] urges in
                    self?.showUrgeList(urges: urges)
            }
        let hostingController = UIHostingController(rootView: graphView)
        self.graphHostingController = hostingController
        addChild(hostingController)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)

        let statsView = UrgeStatsView(timestamps: [:])
        let statsHostingController = UIHostingController(rootView: statsView)
        self.statsHostingController = statsHostingController
        addChild(statsHostingController)
        statsHostingController.view.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(statsHostingController.view)
        statsHostingController.didMove(toParent: self)

        setupConstraints(headerView: headerView, trackerView: trackerView, graphView: hostingController.view, statsView: statsHostingController.view)

        fetchUserData()
        fetchUrgeData()
    }

    private func fetchUserData() {
        AuthService.shared.fetchUser { [weak self] user, error in
            if let error = error {
                print("Error fetching user: \(error)")
                return
            }
            
            if let user = user {
                DispatchQueue.main.async {
                    self?.updateProgress(days: Int(user.soberStreak))
                    self?.userSoberStreak = Int(user.soberStreak)
                    self?.progressContainerView?.milestoneLabel.text = "You are \(30 - Int(user.soberStreak)) days away from next milestone"
                }
            }
        }
    }

    private func fetchUrgeData() {
        let sharedDefaults = UserDefaults(suiteName: "group.com.reset.urges")
        let localTimestamps = sharedDefaults?.dictionary(forKey: "urgeTimestamps") as? [TimeInterval: String] ?? [:]

        guard let currentUser = Auth.auth().currentUser else {
            updateGraph(with: localTimestamps)
            return
        }

        let db = Firestore.firestore()
        let userId = currentUser.uid

        db.collection("users").document(userId).collection("urges")
            .order(by: "timestamp", descending: false)
            .getDocuments { [weak self] snapshot, error in
                if let error = error {
                    print("Error fetching urges: \(error.localizedDescription)")
                    self?.updateGraph(with: localTimestamps)
                    return
                }

                guard let documents = snapshot?.documents else {
                    self?.updateGraph(with: localTimestamps)
                    return
                }

                var firebaseUrges: [TimeInterval: String] = [:]

                for document in documents {
                    let data = document.data()
                    if let timestamp = data["timestamp"] as? Timestamp {
                        let timeInterval = timestamp.dateValue().timeIntervalSince1970
                        let reason = data["reason"] as? String ?? ""
                        firebaseUrges[timeInterval] = reason
                    }
                }

                let mergedUrges = localTimestamps.merging(firebaseUrges) { _, new in new }
                self?.updateGraph(with: mergedUrges)

                if !localTimestamps.isEmpty {
                    self?.syncUrgesWithFirebase()
                }
            }
    }

    private func updateProgress(days: Int) {
        let totalDays = 30
        progressContainerView?.updateProgress(days, totalDays: totalDays)
    }

    private func syncUrgesWithFirebase() {
        guard let currentUser = Auth.auth().currentUser else {
            print("No logged-in user. Cannot sync urges.")
            return
        }

        let sharedDefaults = UserDefaults(suiteName: "group.com.reset.urges")
        let timestamps = sharedDefaults?.dictionary(forKey: "urgeTimestamps") as? [TimeInterval: String] ?? [:]

        guard !timestamps.isEmpty else {
            print("No new urges to sync")
            return
        }

        let db = Firestore.firestore()
        let userId = currentUser.uid
        let urgesRef = db.collection("users").document(userId).collection("urges")

        let batch = db.batch()
        for (timeInterval, reason) in timestamps {
            let docRef = urgesRef.document("\(timeInterval)")
            batch.setData([
                "timestamp": Timestamp(date: Date(timeIntervalSince1970: timeInterval)),
                "reason": reason,
                "createdAt": FieldValue.serverTimestamp()
            ], forDocument: docRef)
        }

        batch.commit { [weak self] error in
            if let error = error {
                print("Error syncing urges: \(error.localizedDescription)")
            } else {
                print("Urges synced successfully!")
                sharedDefaults?.removeObject(forKey: "urgeTimestamps")
                sharedDefaults?.synchronize()
                self?.fetchUrgeData()
            }
        }
    }

    private func showUrgeList(urges: [(Date, String)]) {
        let urgeListView = UrgeListView(urges: urges)
        let hostingController = UIHostingController(rootView: urgeListView)
        hostingController.modalPresentationStyle = .fullScreen  // Optional: for full-screen presentation
        present(hostingController, animated: true)
    }
    
    private func updateGraph(with timestamps: [TimeInterval: String]) {
            let urges = timestamps.map { (Date(timeIntervalSince1970: $0.key), $0.value) }
            
            let updatedGraphView = UrgeGraphView(timestamps: Dictionary(uniqueKeysWithValues: urges)) { [weak self] urges in
                self?.showUrgeList(urges: urges)
            }
            graphHostingController?.rootView = updatedGraphView

            let updatedStatsView = UrgeStatsView(timestamps: Dictionary(uniqueKeysWithValues: urges.map { ($0.0.timeIntervalSince1970, $0.1) }))
            statsHostingController?.rootView = updatedStatsView
    }

    private func addTapGestureRecognizers(to trackerView: UIView) {
        let singleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap(_:)))
        singleTapGesture.numberOfTapsRequired = 1
        trackerView.addGestureRecognizer(singleTapGesture)

        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        trackerView.addGestureRecognizer(doubleTapGesture)

        singleTapGesture.require(toFail: doubleTapGesture)
    }

    @objc private func handleSingleTap(_ sender: UITapGestureRecognizer) {
        let storyboard = UIStoryboard(name: "Milestone", bundle: nil)
        if let milestoneVC = storyboard.instantiateViewController(withIdentifier: "MilestoneViewController") as? MilestoneViewController {
            milestoneVC.days = self.userSoberStreak
            present(milestoneVC, animated: true, completion: nil)
        } else {
            // Handle the case where MilestoneViewController cannot be instantiated or cast
            print("Error: Could not instantiate MilestoneViewController.")
        }
    }

    @objc private func handleDoubleTap(_ sender: UITapGestureRecognizer) {
        print("RESET")
        self.showRestartSheet()
        AuthService.shared.updateSoberStreak(to: 0) { [weak self] error in
            if let error = error {
                print("Error updating sober streak: \(error)")
                return
            }
            AuthService.shared.updateSoberSince(to: Date()) { error in
                if let error = error {
                    print("Error updating sober since: \(error)")
                    return
                }
                DispatchQueue.main.async {
                    self?.fetchUserData()
                    
                }
            }
        }
    }
    private func showRestartSheet() {
        
        let restartSheet = UIHostingController(rootView: RestartSobrietySheetView())
        if let sheet = restartSheet.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
        }
        present(restartSheet, animated: true)
    }

    private func setupConstraints(headerView: SummaryHeaderView, trackerView: ProgressContainerView, graphView: UIView,statsView: UIView) {
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 120),
            
            scrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            
            trackerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            trackerView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            trackerView.widthAnchor.constraint(equalToConstant: 350),
            trackerView.heightAnchor.constraint(equalToConstant: 500),
            
            graphView.topAnchor.constraint(equalTo: trackerView.bottomAnchor, constant: 20),
            graphView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            graphView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            statsView.topAnchor.constraint(equalTo: graphView.bottomAnchor, constant: 20),
            statsView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            statsView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            statsView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
}
