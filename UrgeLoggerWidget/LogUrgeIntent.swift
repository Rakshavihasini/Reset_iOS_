//
//  LogUrgeIntent.swift
//  UrgeLoggerWidgetExtension
//
//  Created by Prasanjit Panda on 05/02/25.
//

import Foundation
import AppIntents

struct LogUrgeIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Urge"

    func perform() async -> some IntentResult {
        print("INVOKED")

        let sharedDefaults = UserDefaults(suiteName: "group.com.reset.urges")

        // Retrieve existing timestamps or initialize an empty array
        var urgeTimestamps = sharedDefaults?.array(forKey: "urgeTimestamps") as? [Date] ?? []
        
        // Append the new timestamp
        urgeTimestamps.append(Date())

        // Save updated array
        sharedDefaults?.set(urgeTimestamps, forKey: "urgeTimestamps")

        print("Logged timestamp: \(Date())")

        return .result()
    }
}


