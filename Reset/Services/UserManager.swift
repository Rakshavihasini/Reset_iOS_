//
//  UserManager.swift
//  Reset
//
//  Created by Prasanjit Panda on 16/12/24.
//

import Foundation

class UserManager {
    static let shared = UserManager()
    private let userDefaultsKey = "currentUser"
    private var currentUser: Contact?

    private init() {
        // Load the current user from UserDefaults when UserManager is initialized
        loadCurrentUser()
    }

    // Set and persist the current user
    func setCurrentUser(_ user: Contact) {
        currentUser = user
        saveCurrentUser() // Save the user data to UserDefaults
    }

    // Retrieve the current user (in-memory)
    func getCurrentUser() -> Contact? {
        return currentUser
    }

    // MARK: - Private Persistence Methods

    private func saveCurrentUser() {
        guard let user = currentUser else { return }
        do {
            // Encode the Contact object to JSON
            let jsonData = try JSONEncoder().encode(user)
            UserDefaults.standard.set(jsonData, forKey: userDefaultsKey)
        } catch {
            print("Failed to save current user: \(error.localizedDescription)")
        }
    }

    private func loadCurrentUser() {
        guard let jsonData = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            return // No user data found in UserDefaults
        }
        do {
            // Decode the JSON data into a Contact object
            let user = try JSONDecoder().decode(Contact.self, from: jsonData)
            currentUser = user
        } catch {
            print("Failed to load current user: \(error.localizedDescription)")
        }
    }
}


