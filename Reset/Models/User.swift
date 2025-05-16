//
//  User.swift
//  Reset
//
//  Created by Prasanjit Panda on 04/01/25.
//


import Foundation

struct User {
    let username: String
    let email: String
    let userUID: String
    let imageURL: String
    let dateOfRegistration: Date
    let soberSince: Date?
    var numberOfResets: Double
    var soberStreak: Double
    var averageSpend: Double
    var drinksPerWeek: Double
}

