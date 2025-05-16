//
//  SpacesDataPersistence.swift
//  Reset
//
//  Created by Prasanjit Panda on 15/12/24.
//

import Foundation

import Foundation
import UIKit

class SpacesDataPersistence {
    private let spacesKey = "mockSpacesKey"
    
    static let shared = SpacesDataPersistence()
    private init() {}
    
    // Save spaces to UserDefaults
    func saveSpaces(_ spaces: [Space]) {
        let encoder = JSONEncoder()
        if let encodedSpaces = try? encoder.encode(spaces) {
            UserDefaults.standard.set(encodedSpaces, forKey: spacesKey)
        }
    }
    
    // Load spaces from UserDefaults
    func loadSpaces() -> [Space] {
        let decoder = JSONDecoder()
        if let savedData = UserDefaults.standard.data(forKey: spacesKey),
           let decodedSpaces = try? decoder.decode([Space].self, from: savedData) {
            return decodedSpaces
        }
        return [] // Return an empty array if no data is found
    }
}

