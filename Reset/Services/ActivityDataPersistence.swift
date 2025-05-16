//
//  ActivityDataPersistence.swift
//  Reset
//
//  Created by System on Date.
//

import Foundation

class ActivityDataPersistence {
    static let shared = ActivityDataPersistence()
    
    private let activitiesKey = "savedActivities"
    
    private init() {
        // Initialize with default activities if no activities are saved yet
        if getActivities().isEmpty {
            saveDefaultActivities()
        }
    }
    
    // Get all activities
    func getActivities() -> [Activity] {
        guard let data = UserDefaults.standard.data(forKey: activitiesKey) else {
            return []
        }
        
        do {
            let activities = try JSONDecoder().decode([Activity].self, from: data)
            return activities
        } catch {
            print("Error decoding activities: \(error)")
            return []
        }
    }
    
    // Save activities
    func saveActivities(_ activities: [Activity]) {
        do {
            let data = try JSONEncoder().encode(activities)
            UserDefaults.standard.set(data, forKey: activitiesKey)
        } catch {
            print("Error encoding activities: \(error)")
        }
    }
    
    // Add a new activity
    func addActivity(_ activity: Activity) {
        var activities = getActivities()
        activities.append(activity)
        saveActivities(activities)
    }
    
    // Delete an activity
    func deleteActivity(withID id: String) {
        var activities = getActivities()
        activities.removeAll { $0.id == id && !$0.isDefault }
        saveActivities(activities)
    }
    
    // Reset to default activities
    func resetToDefaultActivities() {
        saveDefaultActivities()
    }
    
    // Save default activities (preserving user's custom activities)
    func saveDefaultActivities() {
        // Get existing activities to preserve custom ones
        let existingActivities = getActivities()
        let customActivities = existingActivities.filter { !$0.isDefault }
        
        // Combine default activities with custom ones
        let combinedActivities = Activity.defaultActivities + customActivities
        saveActivities(combinedActivities)
    }
} 