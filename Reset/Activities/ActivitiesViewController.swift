//
//  ActivitiesViewController.swift
//  Reset
//
//  Created by System on Date.
//

import UIKit
import TipKit

struct ActivityTip: Tip {
    var title: Text {
        Text("Distract Yourself")
    }
    
    var message: Text? {
        Text("Use these activities when you feel an urge. Tap to get more information.")
    }
    
    var image: Image? {
        Image(systemName: "brain.head.profile")
    }
    
    var rules: [Rule] {
        #Rule(ActivityTip.$shouldShowTip) { _ in true }
    }
    
    @Parameter
    static var shouldShowTip: Bool = true
}

class ActivitiesViewController: UIViewController {
    
    // MARK: - Properties
    private var activities: [Activity] = []
    private let activityTip = ActivityTip()
    private let tipShownKey = "activityTipShown"
    
    // MARK: - UI Components
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Activities"
        label.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Distract yourself from urges"
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var addButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        let plusImage = UIImage(systemName: "plus.circle.fill", withConfiguration: config)
        button.setImage(plusImage, for: .normal)
        button.setTitle(" Add Activity", for: .normal)
        button.tintColor = .systemBrown
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.addTarget(self, action: #selector(addActivityTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .systemBackground
        collectionView.register(ActivityCell.self, forCellWithReuseIdentifier: ActivityCell.identifier)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.showsVerticalScrollIndicator = false
        collectionView.contentInset = UIEdgeInsets(top: 10, left: 16, bottom: 20, right: 16)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadActivities()
        configureTipKit()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if #available(iOS 17.0, *) {
            // Check if the tip has been shown before
            let tipShown = UserDefaults.standard.bool(forKey: tipShownKey)
            
            if !tipShown {
                Task { @MainActor in
                    let shouldDisplay = await activityTip.shouldDisplay
                    print("Activity tip should display: \(shouldDisplay)")
                    
                    let popoverController = TipUIPopoverViewController(activityTip, sourceItem: collectionView)
                    popoverController.backgroundColor = .systemGray.withAlphaComponent(0.9)
                    popoverController.imageStyle = .brown
                    present(popoverController, animated: true) {
                        print("Activity tip popover presented")
                        // Mark the tip as shown after it's displayed
                        UserDefaults.standard.set(true, forKey: self.tipShownKey)
                    }
                }
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
                activityTip.invalidate(reason: .tipClosed)
                print("TipKit configured successfully")
            }
        }
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(addButton)
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            
            addButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            addButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            collectionView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 20),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func loadActivities() {
        activities = ActivityDataPersistence.shared.getActivities()
        collectionView.reloadData()
    }
    
    // MARK: - Action Methods
    @objc private func addActivityTapped() {
        showAddActivityAlert()
    }
    
    private func showAddActivityAlert() {
        let alertController = UIAlertController(title: "Add New Activity", message: "Create an activity to help distract yourself during urges", preferredStyle: .alert)
        
        alertController.addTextField { textField in
            textField.placeholder = "Activity Name"
            textField.autocapitalizationType = .words
        }
        
        alertController.addTextField { textField in
            textField.placeholder = "Brief Description"
        }
        
        // Add actions
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        let addAction = UIAlertAction(title: "Add", style: .default) { [weak self] _ in
            guard let self = self,
                  let title = alertController.textFields?[0].text, !title.isEmpty,
                  let description = alertController.textFields?[1].text, !description.isEmpty else {
                return
            }
            
            self.showIconPickerAlert(title: title, description: description)
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(addAction)
        
        present(alertController, animated: true)
    }
    
    private func showIconPickerAlert(title: String, description: String) {
        let iconOptions = [
            "figure.walk": "Walking",
            "figure.run": "Running",
            "figure.mind.and.body": "Mind & Body",
            "book.fill": "Reading",
            "gamecontroller.fill": "Gaming",
            "music.note": "Music",
            "camera.fill": "Photography",
            "pencil.and.paintbrush": "Art",
            "leaf.fill": "Nature",
            "cup.and.saucer.fill": "Drinking",
            "phone.fill": "Phone Call",
            "message.fill": "Messaging",
            "heart.fill": "Health",
            "brain.head.profile": "Mindfulness"
        ]
        
        let alertController = UIAlertController(title: "Select an Icon", message: nil, preferredStyle: .actionSheet)
        
        for (iconName, displayName) in iconOptions {
            let action = UIAlertAction(title: displayName, style: .default) { [weak self] _ in
                guard let self = self else { return }
                self.showColorPickerAlert(title: title, description: description, iconName: iconName)
            }
            alertController.addAction(action)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(cancelAction)
        
        // For iPad support
        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = view
            popoverController.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        
        present(alertController, animated: true)
    }
    
    private func showColorPickerAlert(title: String, description: String, iconName: String) {
        let colorOptions = [
            "#FF3B30": "Red",
            "#FF9500": "Orange",
            "#FFCC00": "Yellow",
            "#34C759": "Green",
            "#5AC8FA": "Light Blue",
            "#007AFF": "Blue",
            "#5856D6": "Purple",
            "#AF52DE": "Magenta",
            "#FF2D55": "Pink",
            "#8E8E93": "Gray"
        ]
        
        let alertController = UIAlertController(title: "Select a Color", message: nil, preferredStyle: .actionSheet)
        
        for (colorHex, displayName) in colorOptions {
            let action = UIAlertAction(title: displayName, style: .default) { [weak self] _ in
                guard let self = self else { return }
                
                // Create and save the new activity
                let newActivity = Activity(
                    id: UUID().uuidString,
                    title: title,
                    description: description,
                    iconName: iconName,
                    color: colorHex,
                    isDefault: false,
                    createdAt: Date()
                )
                
                ActivityDataPersistence.shared.addActivity(newActivity)
                self.loadActivities()
            }
            alertController.addAction(action)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(cancelAction)
        
        // For iPad support
        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = view
            popoverController.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        
        present(alertController, animated: true)
    }
    
    // MARK: - Activity Selection
    private func showActivityDetailAlert(for activity: Activity) {
        let timeSelectionVC = ActivityTimeSelectionViewController(activity: activity)
        timeSelectionVC.delegate = self
        present(timeSelectionVC, animated: true)
    }
}

// MARK: - UICollectionViewDelegate & UICollectionViewDataSource
extension ActivitiesViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return activities.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ActivityCell.identifier, for: indexPath) as? ActivityCell else {
            return UICollectionViewCell()
        }
        
        let activity = activities[indexPath.item]
        cell.configure(with: activity)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let activity = activities[indexPath.item]
        showActivityDetailAlert(for: activity)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension ActivitiesViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.bounds.width - 48) / 2 // 2 cells per row with padding
        return CGSize(width: width, height: 120)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 16
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 16
    }
}

// MARK: - ActivityTimeSelectionDelegate
extension ActivitiesViewController: ActivityTimeSelectionDelegate {
    func didSelectTime(_ minutes: Int, for activity: Activity) {
        let timerVC = ActivityTimerViewController(activity: activity, duration: minutes)
        timerVC.modalPresentationStyle = .fullScreen
        present(timerVC, animated: true)
    }
} 