import SwiftUI
import Charts
import FirebaseAuth
import FirebaseFirestore

// MARK: - Time Period Enum
enum TimePeriod: String, CaseIterable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
    case year = "Year"
}

// MARK: - Stat Card Component
//struct StatCardGraph: View {
//    let title: String
//    let value: String
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 8) {
//            Text(title)
//                .font(.subheadline)
//                .foregroundStyle(.secondary)
//            
//            Text(value)
//                .font(.system(.title2, design: .rounded))
//                .fontWeight(.semibold)
//        }
//        .frame(maxWidth: .infinity, alignment: .leading)
//        .padding()
//        .background(
//            RoundedRectangle(cornerRadius: 16)
//                .fill(Color(.systemBackground))
//                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
//        )
//    }
//}

// MARK: - Main UrgeListView
struct UrgeListView: View {
    let urges: [(Date, String)]
    @Environment(\.dismiss) private var dismiss
    @State private var selectedUrge: (Date, String)?
    @State private var showingEditSheet = false
    @State private var selectedPeriod: TimePeriod = .week
    
    // MARK: - Computed Properties
    private var filteredUrges: [(Date, String)] {
        let calendar = Calendar.current
        let now = Date()
        
        return urges.filter { date, _ in
            switch selectedPeriod {
            case .day:
                return calendar.isDate(date, inSameDayAs: now)
            case .week:
                let weekStart = calendar.date(byAdding: .day, value: -7, to: now)!
                return date >= weekStart && date <= now
            case .month:
                let monthStart = calendar.date(byAdding: .month, value: -1, to: now)!
                return date >= monthStart && date <= now
            case .year:
                let yearStart = calendar.date(byAdding: .year, value: -1, to: now)!
                return date >= yearStart && date <= now
            }
        }
    }
    
    private var groupedUrges: [(String, Int)] {
        let calendar = Calendar.current
        var grouped: [String: Int] = [:]
        
        for (date, _) in filteredUrges {
            let key: String
            switch selectedPeriod {
            case .day:
                let hour = calendar.component(.hour, from: date)
                key = "\(hour):00"
            case .week:
                let weekday = calendar.component(.weekday, from: date)
                let weekdaySymbol = calendar.shortWeekdaySymbols[weekday - 1]
                key = weekdaySymbol
            case .month:
                let day = calendar.component(.day, from: date)
                key = "\(day)"
            case .year:
                let month = calendar.component(.month, from: date)
                let monthSymbol = calendar.shortMonthSymbols[month - 1]
                key = monthSymbol
            }
            
            grouped[key, default: 0] += 1
        }
        
        return grouped.sorted { pair1, pair2 in
            switch selectedPeriod {
            case .day:
                return Int(pair1.0.split(separator: ":")[0])! < Int(pair2.0.split(separator: ":")[0])!
            case .week:
                let weekdays = calendar.shortWeekdaySymbols
                return weekdays.firstIndex(of: pair1.0)! < weekdays.firstIndex(of: pair2.0)!
            case .month:
                return Int(pair1.0)! < Int(pair2.0)!
            case .year:
                let months = calendar.shortMonthSymbols
                return months.firstIndex(of: pair1.0)! < months.firstIndex(of: pair2.0)!
            }
        }
    }
    
    private var reasonAnalysis: [(String, Int)] {
        var reasonCounts: [String: Int] = [:]
        
        for (_, reason) in filteredUrges {
            let trimmedReason = reason.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedReason.isEmpty {
                reasonCounts[trimmedReason, default: 0] += 1
            }
        }
        
        return reasonCounts.sorted { $0.1 > $1.1 }
    }
    
    private var peakTime: String {
        guard let peak = groupedUrges.max(by: { $0.1 < $1.1 }) else {
            return "N/A"
        }
        return peak.0
    }
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Time period picker
                    Picker("Time Period", selection: $selectedPeriod) {
                        ForEach(TimePeriod.allCases, id: \.self) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // Chart
                    Chart {
                        ForEach(groupedUrges, id: \.0) { label, count in
                            BarMark(
                                x: .value("Time", label),
                                y: .value("Count", count)
                            )
                            .foregroundStyle(Color.blue.opacity(0.8))
                        }
                    }
                    .frame(height: 200)
                    .padding()
                    
                    // Stats summary
                    VStack(spacing: 20) {
                        HStack(spacing: 20) {
                            StatCardGraph(title: "Total Urges", value: "\(filteredUrges.count)")
                            StatCardGraph(title: "Peak Time", value: peakTime)
                        }
                        
                        // Reason Analysis Card
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Top Reasons")
                                .font(.headline)
                                .padding(.bottom, 4)
                            
                            ForEach(reasonAnalysis.prefix(3), id: \.0) { reason, count in
                                HStack {
                                    Text(reason)
                                        .lineLimit(2)
                                        .font(.system(.body, design: .rounded))
                                    Spacer()
                                    Text("\(count)")
                                        .font(.system(.body, design: .rounded))
                                        .foregroundColor(.blue)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
                        )
                        .padding(.horizontal)
                    }
                    
                    // Urge list
                    LazyVStack(spacing: 16) {
                        ForEach(filteredUrges.sorted(by: { $0.0 > $1.0 }), id: \.0) { urge in
                            UrgeCard(date: urge.0, reason: urge.1)
                                .onTapGesture {
                                    selectedUrge = urge
                                    DispatchQueue.main.async {
                                        showingEditSheet = true
                                    }
                                }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Urge History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.gray)
                    }
                }
            }
            .sheet(
                isPresented: Binding(
                    get: { showingEditSheet && selectedUrge != nil },
                    set: { newValue in 
                        showingEditSheet = newValue
                        if !newValue {
                            selectedUrge = nil
                        }
                    }
                )
            ) {
                if let urge = selectedUrge {
                    UrgeEditView(date: urge.0, currentReason: urge.1) { newReason in
                        updateUrgeReason(for: urge.0, with: newReason)
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private func updateUrgeReason(for date: Date, with newReason: String) {
        guard let currentUser = Auth.auth().currentUser else {
            print("No logged-in user")
            return
        }
        
        let db = Firestore.firestore()
        let userId = currentUser.uid
        let timestamp = date.timeIntervalSince1970
        
        db.collection("users").document(userId).collection("urges")
            .document("\(timestamp)")
            .updateData([
                "reason": newReason
            ]) { error in
                if let error = error {
                    print("Error updating urge reason: \(error.localizedDescription)")
                } else {
                    print("Urge reason updated successfully")
                }
            }
        
        if let sharedDefaults = UserDefaults(suiteName: "group.com.reset.urges") {
            if var timestamps = sharedDefaults.dictionary(forKey: "urgeTimestamps") as? [TimeInterval: String] {
                timestamps[timestamp] = newReason
                sharedDefaults.set(timestamps, forKey: "urgeTimestamps")
                sharedDefaults.synchronize()
            }
        }
    }
}

// MARK: - UrgeEditView
struct UrgeEditView: View {
    let date: Date
    let currentReason: String
    let onSave: (String) -> Void
    
    @State private var reason: String
    @Environment(\.dismiss) private var dismiss
    
    init(date: Date, currentReason: String, onSave: @escaping (String) -> Void) {
        self.date = date
        self.currentReason = currentReason
        self.onSave = onSave
        _reason = State(initialValue: currentReason)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Time").font(.subheadline)) {
                    Text(timeString)
                        .font(.system(.body, design: .rounded))
                }
                
                Section(header: Text("Reason").font(.subheadline)) {
                    TextEditor(text: $reason)
                        .frame(minHeight: 100)
                        .font(.system(.body, design: .rounded))
                }
            }
            .navigationTitle("Edit Urge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(reason)
                        dismiss()
                    }
                    .bold()
                }
            }
        }
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
    }
}

// MARK: - UrgeCard
struct UrgeCard: View {
    let date: Date
    let reason: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(timeString)
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(dateString)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            
            if !reason.isEmpty {
                Text(reason)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            // Visual indicator for editability
            HStack {
                Spacer()
                Image(systemName: "square.and.pencil")
                    .font(.caption)
                    .foregroundStyle(.gray.opacity(0.6))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
        )
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}
