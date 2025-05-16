//
//  Activity.swift
//  Reset
//
//  Created by System on Date.
//

import Foundation
import UIKit

struct Activity: Codable, Identifiable, Equatable {
    var id: String // UUID as string
    var title: String
    var description: String
    var iconName: String
    var color: String // UIColor as hex string
    var isDefault: Bool
    var createdAt: Date
    
    // Computed property for the icon (not stored)
    var icon: UIImage? {
        return UIImage(systemName: iconName)
    }
    
    // Computed property to convert string to UIColor (not stored)
    var uiColor: UIColor {
        return hexStringToUIColor(hex: color)
    }
    
    static func == (lhs: Activity, rhs: Activity) -> Bool {
        return lhs.id == rhs.id
    }
    
    // Default activities
    static let defaultActivities: [Activity] = [
        Activity(id: UUID().uuidString, 
                title: "Go for a Run", 
                description: "Clear your mind with a quick run", 
                iconName: "figure.run", 
                color: "#FF9500", 
                isDefault: true,
                createdAt: Date()),
        
        Activity(id: UUID().uuidString, 
                title: "Meditate", 
                description: "Take 5 minutes to center yourself", 
                iconName: "brain.head.profile", 
                color: "#5856D6", 
                isDefault: true,
                createdAt: Date()),
        
        Activity(id: UUID().uuidString, 
                title: "Go for a Walk", 
                description: "A short walk can help clear your mind", 
                iconName: "figure.walk", 
                color: "#34C759", 
                isDefault: true,
                createdAt: Date()),
        
        Activity(id: UUID().uuidString, 
                title: "Read a Book", 
                description: "Distract yourself with a good book", 
                iconName: "book.fill", 
                color: "#FF3B30", 
                isDefault: true,
                createdAt: Date()),
        
        Activity(id: UUID().uuidString, 
                title: "Call a Friend", 
                description: "Reach out to someone who supports you", 
                iconName: "phone.fill", 
                color: "#007AFF", 
                isDefault: true,
                createdAt: Date()),
        
        Activity(id: UUID().uuidString, 
                title: "Deep Breathing", 
                description: "Take 10 deep breaths to calm your nerves", 
                iconName: "lungs.fill", 
                color: "#AF52DE", 
                isDefault: true,
                createdAt: Date()),
        
        Activity(id: UUID().uuidString, 
                title: "Drink Water", 
                description: "Stay hydrated to reduce cravings", 
                iconName: "drop.fill", 
                color: "#5AC8FA", 
                isDefault: true,
                createdAt: Date()),
        
        Activity(id: UUID().uuidString, 
                title: "Play a Game", 
                description: "Distract yourself with a quick game", 
                iconName: "gamecontroller.fill", 
                color: "#FFCC00", 
                isDefault: true,
                createdAt: Date())
    ]
    
    // Helper function to convert hex string to UIColor
    private func hexStringToUIColor(hex: String) -> UIColor {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if hexString.hasPrefix("#") {
            hexString.remove(at: hexString.startIndex)
        }
        
        if hexString.count != 6 {
            return .gray // Default color if invalid hex
        }
        
        var rgbValue: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&rgbValue)
        
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: 1.0
        )
    }
} 