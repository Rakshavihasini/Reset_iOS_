//
//  Space.swift
//  Reset
//
//  Created by Prasanjit Panda on 10/12/24.
//

import Foundation

struct Space: Codable {
    var roomID: String
    var title: String
    var host: String
    var description: String
    var listenersCount: Int
    var liveDuration: String
    var isLive: Bool = false // Default to false since spaces can be scheduled
    var scheduledDate: Date?
    var scheduledDuration: Int?
    var addedToCalendar: Bool = false // Track if added to calendar
    var creatorID: String? // Store the user ID of the creator
    
    enum CodingKeys: String, CodingKey {
        case roomID, title, host, description, listenersCount, liveDuration, isLive, scheduledDate, scheduledDuration, addedToCalendar, creatorID
    }
    
    init(roomID: String, title: String, host: String, description: String, listenersCount: Int, liveDuration: String, isLive: Bool = false, scheduledDate: Date? = nil, scheduledDuration: Int? = nil, addedToCalendar: Bool = false, creatorID: String? = nil) {
        self.roomID = roomID
        self.title = title
        self.host = host
        self.description = description
        self.listenersCount = listenersCount
        self.liveDuration = liveDuration
        self.isLive = isLive
        self.scheduledDate = scheduledDate
        self.scheduledDuration = scheduledDuration
        self.addedToCalendar = addedToCalendar
        self.creatorID = creatorID
    }
}

var mockSpaces: [Space] = SpacesDataPersistence.shared.loadSpaces()


