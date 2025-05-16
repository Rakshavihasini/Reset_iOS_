//
//  UrgeStatsView.swift
//  Reset
//
//  Created by Prasanjit Panda on 07/02/25.
//

import SwiftUICore
import SwiftUI


struct UrgeStatsView: View {
    let timestamps: [TimeInterval: String]
    
    private var dateList: [Date] {
        timestamps.keys.map { Date(timeIntervalSince1970: $0) }
    }
    
    private var todayUrges: Int {
        let calendar = Calendar.current
        return dateList.filter { calendar.isDateInToday($0) }.count
    }
    
    private var weeklyAverage: Double {
        let calendar = Calendar.current
        let lastWeek = calendar.date(byAdding: .day, value: -7, to: Date())!
        let weekUrges = dateList.filter { $0 >= lastWeek }.count
        return Double(weekUrges) / 7.0
    }
    
    private var mostFrequentHour: Int {
        let hours = dateList.map { Calendar.current.component(.hour, from: $0) }
        return hours.reduce(into: [:]) { counts, hour in counts[hour, default: 0] += 1 }
            .max(by: { $0.value < $1.value })?.key ?? 0
    }
    
    private var longestStreakWithoutUrges: Int {
        guard !dateList.isEmpty else { return 0 }
        let calendar = Calendar.current
        let sortedDates = dateList.map { calendar.startOfDay(for: $0) }.sorted()
        
        var maxStreak = 0
        var lastDate: Date? = nil
        var currentStreak = 0
        
        for date in sortedDates {
            if let last = lastDate, let daysBetween = calendar.dateComponents([.day], from: last, to: date).day {
                if daysBetween > 1 {
                    currentStreak = daysBetween - 1
                    maxStreak = max(maxStreak, currentStreak)
                }
            }
            lastDate = date
        }
        
        return maxStreak
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Urge Statistics")
                .font(.system(.title2, design: .rounded))
                .fontWeight(.bold)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                StatCard(title: "Today", value: "\(todayUrges)", subtitle: "urges")
                StatCard(title: "Weekly Avg", value: String(format: "%.1f", weeklyAverage), subtitle: "urges/day")
                StatCard(title: "Peak Hour", value: "\(mostFrequentHour):00", subtitle: "most frequent")
                StatCard(title: "Best Streak", value: "\(longestStreakWithoutUrges)", subtitle: "days without urges")
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 24).fill(Color(.systemBackground)).shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2))
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(.caption, design: .rounded))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(.title2, design: .rounded))
                .fontWeight(.bold)
            Text(subtitle)
                .font(.system(.caption, design: .rounded))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))
    }
}
