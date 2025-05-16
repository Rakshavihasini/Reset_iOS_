//
//  Contact.swift
//  Reset
//
//  Created by Prasanjit Panda on 30/11/24.
//

import Foundation
import UIKit


struct Contact:Codable {
    var name: String
    var phone: String
    var email: String
    var profile: String
    var age: Int
    var joinDate: String
    var soberDuration: String
    var soberSince: String
    var numOfResets: Int
    var longestStreak: Int
    var daysPerWeek: Int
    var averageSpend: Int
}

class ContactManager {
    static let shared = ContactManager()
    
    private init() {
        loadSupportFromStorage()
    }
    
    // Updated mock data with new properties
    var contacts: [Contact] = [
        Contact(name: "John Doe", phone: "555-1234", email: "john.doe@example.com", profile: "JohnImage", age: 29, joinDate: "2022-05-12", soberDuration: "1 year, 3 months", soberSince: "2023-09-01", numOfResets: 5, longestStreak: 90, daysPerWeek: 5, averageSpend: 100),
        Contact(name: "Emily Johnson", phone: "555-5678", email: "jane.smith@example.com", profile: "Emily", age: 35, joinDate: "2021-07-22", soberDuration: "2 years, 2 months", soberSince: "2022-10-15", numOfResets: 8, longestStreak: 150,daysPerWeek: 5, averageSpend: 100),
        Contact(name: "Alice Johnson", phone: "555-9012", email: "alice.johnson@example.com", profile: "AliceImg", age: 26, joinDate: "2023-03-18", soberDuration: "8 months", soberSince: "2024-04-05", numOfResets: 3, longestStreak: 60,daysPerWeek: 5, averageSpend: 100),
        Contact(name: "Bob Williams", phone: "555-3456", email: "bob.williams@example.com", profile: "BobImage", age: 40, joinDate: "2020-11-01", soberDuration: "4 years", soberSince: "2020-11-01", numOfResets: 12, longestStreak: 180,daysPerWeek: 5, averageSpend: 100),
//        Contact(name: "Emma Brown", phone: "555-7890", email: "emma.brown@example.com", profile: "Emily", age: 33, joinDate: "2022-08-09", soberDuration: "6 months", soberSince: "2024-06-01", numOfResets: 2, longestStreak: 45),
        Contact(name: "Michael Davis", phone: "555-2345", email: "michael.davis@example.com", profile: "MichaelImage", age: 28, joinDate: "2023-01-10", soberDuration: "1 year", soberSince: "2023-06-01", numOfResets: 4, longestStreak: 120,daysPerWeek: 5, averageSpend: 100),
//        Contact(name: "Sarah Miller", phone: "555-6789", email: "sarah.miller@example.com", profile: "Emily", age: 31, joinDate: "2022-11-30", soberDuration: "9 months", soberSince: "2023-03-15", numOfResets: 6, longestStreak: 80)
    ]
    
    var support: [Contact] = [] {
            didSet {
                saveSupportToStorage()
                print("Saved")
            }
        
        }
        
        // Save support array to UserDefaults
        private func saveSupportToStorage() {
            let encoder = JSONEncoder()
            if let encoded = try? encoder.encode(support) {
                UserDefaults.standard.set(encoded, forKey: "supportContacts")
            }
        }
        
        // Load support array from UserDefaults
        private func loadSupportFromStorage() {
            let decoder = JSONDecoder()
            if let savedData = UserDefaults.standard.data(forKey: "supportContacts"),
               let decoded = try? decoder.decode([Contact].self, from: savedData) {
                support = decoded
            }
        }
    
    // Save image and return its path
    func saveImage(image: UIImage) -> String {
        // Save the image to the documents directory
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let imagePath = documentsDirectory.appendingPathComponent(UUID().uuidString + ".png")
        
        if let imageData = image.pngData() {
            do {
                try imageData.write(to: imagePath)
            } catch {
                print("Error saving image: \(error)")
            }
        }
        
        return imagePath.path  // Return the image path
    }
    
    // Retrieve image from saved path (if needed)
    func retrieveImage(fromPath path: String) -> UIImage? {
        let fileManager = FileManager.default
        let fileURL = URL(fileURLWithPath: path)
        
        if fileManager.fileExists(atPath: fileURL.path) {
            return UIImage(contentsOfFile: fileURL.path)
        }
        return nil
    }
    
    func searchContacts(with searchText: String) -> [Contact] {
        guard !searchText.isEmpty else { return contacts }
        
        return contacts.filter { contact in
            contact.name.localizedCaseInsensitiveContains(searchText) ||
            contact.phone.contains(searchText) ||
            contact.email.localizedCaseInsensitiveContains(searchText)
        }
    }
}

