import UIKit
import SendbirdUIKit
import SendbirdChatSDK
import FirebaseAuth
import TipKit


struct GrowSupportTip: Tip {
    var title: Text {
        Text("Grow Your Support Group")
    }
    
    var message: Text? {
        Text("Find and connect with new people to strengthen your journey together.")
    }
    
    var image: Image? {
        Image(systemName: "person.3.fill")
    }
    
    var rules: [Rule] {
        #Rule(GrowSupportTip.$shouldShowTip) { _ in true }
    }
    
    @Parameter
    static var shouldShowTip: Bool = true
}

class ChatListViewController: UIViewController, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource {

    private let searchBar = UISearchBar()
    private let tableView = UITableView()
    private let channelListVC = SBUGroupChannelListViewController()
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    private var searchWorkItem: DispatchWorkItem?
    private let searchDebounceTime: TimeInterval = 0.5

    private let supportGroupLabel: UILabel = {
        let label = UILabel()
        label.text = "Grow Your Support Group\nThe journey together is better."
        label.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        label.textColor = .darkGray
        label.textAlignment = .center
        label.numberOfLines = 2
        label.alpha = 0.7
        return label
    }()
    
    private let noResultsLabel: UILabel = {
        let label = UILabel()
        label.text = "No users found"
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .gray
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()

    private var users: [SBUUser] = []
    private var filteredUsers: [SBUUser] = []
    private var isSearching = false
    private let growSupportTip = GrowSupportTip()
    private let tipShownKey = "growSupportTipShown" // Key to track tip display

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        setupSearchBar()
        setupActivityIndicator()
        addTapGestureToDismissKeyboard()
        configureTipKit()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if #available(iOS 17.0, *) {
            // Check if the tip has been shown before
            let tipShown = UserDefaults.standard.bool(forKey: tipShownKey)
            
            if !tipShown {
                Task { @MainActor in
                    let shouldDisplay = await growSupportTip.shouldDisplay
                    print("Tip should display: \(shouldDisplay)")
                    
                    let popoverController = TipUIPopoverViewController(growSupportTip, sourceItem: searchBar)
                    popoverController.backgroundColor = .systemGray.withAlphaComponent(0.9)
                    popoverController.imageStyle = .brown
                    present(popoverController, animated: true) {
                        print("Tip popover presented")
                        
                        // Mark the tip as shown after it's displayed
                        UserDefaults.standard.set(true, forKey: self.tipShownKey)
                    }
                }
            } else {
                print("Tip already shown, skipping display.")
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
                growSupportTip.invalidate(reason: .tipClosed)
                print("TipKit configured successfully")
            }
        }
    }
    
    private func setupSearchBar() {
        searchBar.placeholder = "Search users..."
        searchBar.delegate = self
        searchBar.showsCancelButton = true
        searchBar.autocapitalizationType = .none
        searchBar.returnKeyType = .search
        
        // Set cancel button tint color to systemBrown
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).tintColor = .systemBrown
        
        navigationItem.titleView = searchBar
    }

    private func setupActivityIndicator() {
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = .gray
        view.addSubview(activityIndicator)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func addTapGestureToDismissKeyboard() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        tapGesture.cancelsTouchesInView = false
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)
    }

    @objc private func handleTapGesture(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: view)
        if !tableView.frame.contains(location) {
            searchBar.resignFirstResponder()
        }
    }

    private func dismissKeyboardAndResetSearch() {
        searchBar.resignFirstResponder()
    }

    private func resetSearch() {
        if isSearching {
            searchBar.text = ""
            isSearching = false
            filteredUsers.removeAll()
            tableView.isHidden = true
            channelListVC.view.isHidden = false
            supportGroupLabel.isHidden = false
            noResultsLabel.isHidden = true
            tableView.reloadData()
        }
    }

    private func setupUI() {
        view.backgroundColor = .white

        // Add TableView for Search Results
        tableView.isHidden = true
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add Channel List VC
        addChild(channelListVC)
        view.addSubview(channelListVC.view)
        channelListVC.view.translatesAutoresizingMaskIntoConstraints = false
        channelListVC.didMove(toParent: self)
        
        // Add Support Group Label
        view.addSubview(supportGroupLabel)
        supportGroupLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Add No Results Label
        view.addSubview(noResultsLabel)
        noResultsLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Constraints
        NSLayoutConstraint.activate([
            // TableView constraints
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Channel List VC constraints
            channelListVC.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            channelListVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            channelListVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            channelListVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Support Group Label constraints
            supportGroupLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            supportGroupLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            supportGroupLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            supportGroupLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
            // No Results Label constraints
            noResultsLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            noResultsLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UserSearchCell.self, forCellReuseIdentifier: "UserCell")
        tableView.separatorStyle = .singleLine
        tableView.backgroundColor = .clear
        tableView.keyboardDismissMode = .onDrag
    }

    // MARK: - Search Bar Delegates
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchBar.text = ""
        resetSearch()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        if let searchText = searchBar.text, !searchText.isEmpty {
            performSearch(with: searchText)
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // Cancel previous search if any
        searchWorkItem?.cancel()
        
        if searchText.isEmpty {
            resetSearch()
            return
        }
        
        // Create a new work item for the search
        let workItem = DispatchWorkItem { [weak self] in
            self?.performSearch(with: searchText)
        }
        
        // Save the work item for potential cancellation
        searchWorkItem = workItem
        
        // Schedule the work item after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + searchDebounceTime, execute: workItem)
    }
    
    private func performSearch(with query: String) {
        guard !query.isEmpty else {
            resetSearch()
            return
        }
        
        isSearching = true
        supportGroupLabel.isHidden = true
        channelListVC.view.isHidden = true
        tableView.isHidden = false
        noResultsLabel.isHidden = true
        
        // Show activity indicator
        activityIndicator.startAnimating()
        
        fetchUsers(query: query)
    }

    private func fetchUsers(query: String) {
        guard let currentUser = Auth.auth().currentUser else { 
            activityIndicator.stopAnimating()
            return 
        }

        let params = ApplicationUserListQueryParams()
        // Use the nickname property directly without any specific filter method
        // This will fetch all users and we'll filter them client-side
        
        let userQuery = SendbirdChat.createApplicationUserListQuery(params: params)
        userQuery.loadNextPage { [weak self] users, error in
            guard let self = self, error == nil else { 
                DispatchQueue.main.async {
                    self?.activityIndicator.stopAnimating()
                    self?.showNoResults()
                }
                return 
            }

            self.getExistingChannels { existingUserIds in
                // Filter out current user and existing contacts
                self.filteredUsers = (users ?? [])
                    .filter { $0.userId != currentUser.uid && !existingUserIds.contains($0.userId) }
                    .map { SBUUser(user: $0) }
                
                // Client-side filtering to find nicknames containing the query
                if !query.isEmpty {
                    self.filteredUsers = self.filteredUsers.filter { user in
                        guard let nickname = user.nickname?.lowercased() else { return false }
                        return nickname.contains(query.lowercased())
                    }
                }
                
                self.showSearchResults()
            }
        }
    }

    private func getExistingChannels(completion: @escaping ([String]) -> Void) {
        let query = GroupChannel.createMyGroupChannelListQuery { params in
            params.includeEmptyChannel = false
        }
        query.loadNextPage { channels, error in
            guard let channels = channels, error == nil else {
                completion([])
                return
            }

            let existingUserIds = channels.flatMap { $0.members.map { $0.userId } }
            completion(Set(existingUserIds).map { $0 })
        }
    }

    private func showSearchResults() {
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating()
            
            if self.filteredUsers.isEmpty {
                self.showNoResults()
                return
            }
            
            self.channelListVC.view.isHidden = true
            self.supportGroupLabel.isHidden = true
            self.tableView.isHidden = false
            self.noResultsLabel.isHidden = true
            self.tableView.reloadData()
        }
    }
    
    private func showNoResults() {
        DispatchQueue.main.async {
            self.noResultsLabel.isHidden = false
            self.tableView.reloadData()
        }
    }

    // MARK: - TableView Delegates
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredUsers.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserCell", for: indexPath) as! UserSearchCell
        let user = filteredUsers[indexPath.row]
        cell.configure(with: user)
        
        cell.onAddButtonTapped = { [weak self] in
            self?.addUserToSupportGroup(user)
        }
        
        return cell
    }
    
    private func addUserToSupportGroup(_ user: SBUUser) {
        // Show loading
        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.center = view.center
        activityIndicator.startAnimating()
        view.addSubview(activityIndicator)
        
        // Create a group channel with the selected user
        let currentUserId = SendbirdChat.getCurrentUser()?.userId ?? ""
        let params = GroupChannelCreateParams()
        params.userIds = [currentUserId, user.userId]
        params.name = user.nickname ?? "Chat"
        params.isDistinct = true
        
        GroupChannel.createChannel(params: params) { channel, error in
            // Remove loading indicator
            DispatchQueue.main.async {
                activityIndicator.removeFromSuperview()
                
                if let error = error {
                    // Show error alert
                    let alert = UIAlertController(
                        title: "Error",
                        message: "Failed to add user: \(error.localizedDescription)",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                    return
                }
                
                guard let channel = channel else { return }
                
                // Success - open the created channel
                let vc = SBUGroupChannelViewController(channelURL: channel.channelURL)
                self.navigationController?.pushViewController(vc, animated: true)
                
                // Reset search when navigating to new channel
                self.resetSearch()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let selectedUser = filteredUsers[indexPath.row]
        
        // Only dismiss keyboard without resetting search
        searchBar.resignFirstResponder()
        
        let userDetailVC = UserDetailViewController(userId: selectedUser.userId)
        navigationController?.pushViewController(userDetailVC, animated: true)
    }
}

// MARK: - UIGestureRecognizerDelegate
extension ChatListViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // Only handle taps outside the table view and search bar
        let location = touch.location(in: view)
        if tableView.frame.contains(location) {
            return false
        }
        
        if let searchBarView = searchBar.superview, searchBarView.frame.contains(touch.location(in: searchBarView)) {
            return false
        }
        
        return true
    }
}

// MARK: - Custom Cell for User Search Results
class UserSearchCell: UITableViewCell {
    private let profileImageView = UIImageView()
    private let nameLabel = UILabel()
    private let addButton = UIButton(type: .system)
    
    var onAddButtonTapped: (() -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        // Profile Image View
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.clipsToBounds = true
        profileImageView.layer.cornerRadius = 20
        profileImageView.backgroundColor = .lightGray
        contentView.addSubview(profileImageView)
        
        // Name Label
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        contentView.addSubview(nameLabel)
        
        // Add Button
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.setImage(UIImage(systemName: "person.badge.plus"), for: .normal)
        addButton.tintColor = .systemBrown
        addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        contentView.addSubview(addButton)
        
        NSLayoutConstraint.activate([
            // Profile Image View
            profileImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            profileImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 40),
            profileImageView.heightAnchor.constraint(equalToConstant: 40),
            
            // Name Label
            nameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 12),
            nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: addButton.leadingAnchor, constant: -12),
            
            // Add Button
            addButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            addButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            addButton.widthAnchor.constraint(equalToConstant: 44),
            addButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    @objc private func addButtonTapped() {
        onAddButtonTapped?()
    }
    
    func configure(with user: SBUUser) {
        nameLabel.text = user.nickname
        
        // Load profile image if available
        if let profileURL = user.profileURL, !profileURL.isEmpty {
            // Use a proper image loading library like SDWebImage or Kingfisher in a real app
            DispatchQueue.global().async {
                if let url = URL(string: profileURL), let data = try? Data(contentsOf: url) {
                    DispatchQueue.main.async {
                        self.profileImageView.image = UIImage(data: data)
                    }
                }
            }
        } else {
            // Set default profile image
            profileImageView.image = UIImage(systemName: "person.circle.fill")
            profileImageView.tintColor = .gray
        }
    }
}
