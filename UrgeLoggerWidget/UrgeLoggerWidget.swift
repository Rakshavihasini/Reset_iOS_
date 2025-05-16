import WidgetKit
import SwiftUI
import AppIntents
import Charts

struct UrgeLoggerWidgetEntry: TimelineEntry {
    let date: Date
    let urgeTimestamps: [Date]  // Store timestamps
}

struct UrgeLoggerWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> UrgeLoggerWidgetEntry {
        UrgeLoggerWidgetEntry(date: Date(), urgeTimestamps: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (UrgeLoggerWidgetEntry) -> Void) {
        let timestamps = fetchUrgeTimestamps()
        completion(UrgeLoggerWidgetEntry(date: Date(), urgeTimestamps: timestamps))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<UrgeLoggerWidgetEntry>) -> Void) {
        let timestamps = fetchUrgeTimestamps()
        let entry = UrgeLoggerWidgetEntry(date: Date(), urgeTimestamps: timestamps)
        completion(Timeline(entries: [entry], policy: .never))
    }

    private func fetchUrgeTimestamps() -> [Date] {
        let sharedDefaults = UserDefaults(suiteName: "group.com.reset.urges")
        let timestamps = sharedDefaults?.array(forKey: "urgeTimestamps") as? [Date] ?? []
        let lastSynced = sharedDefaults?.object(forKey: "lastSynced") as? Date ?? Date.distantPast

        // If urges were recently synced (within last 30 seconds), keep showing the last data
        if timestamps.isEmpty && Date().timeIntervalSince(lastSynced) < 30 {
            // Return the last synced timestamp to maintain visual continuity
            return [lastSynced]
        }

        // If we have timestamps, return them
        if !timestamps.isEmpty {
            return timestamps
        }

        // If we're in a truly empty state (no recent sync), return empty array
        return []
    }
}

struct UrgeLoggerWidgetView: View {
    var entry: UrgeLoggerWidgetEntry
    
    private var todayUrges: [Date] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        return entry.urgeTimestamps.filter { $0 >= startOfDay }
    }
    
    private var totalUrges: Int {
        todayUrges.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header Section
            HStack {
                Text("Urge Tracker")
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
                Button(intent: LogUrgeIntent()) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                        Text("Log")
                            .font(.system(.subheadline, design: .rounded, weight: .medium))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color(red: 0.95, green: 0.35, blue: 0.3))
                    )
                    .foregroundColor(.white)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Subtitle
            Text("Today's Progress")
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(.secondary)
                .padding(.top, -4)
            
            // Chart Section
            if todayUrges.isEmpty {
                GeometryReader { geometry in
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            VStack(spacing: 8) {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.system(size: 36))
                                    .foregroundColor(.gray.opacity(0.3))
                                Text("No data yet")
                                    .font(.system(.body, design: .rounded))
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                        }
                        Spacer()
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                }
                .frame(height: 120)
            } else {
                Chart {
                    ForEach(todayUrges, id: \.self) { timestamp in
                        LineMark(
                            x: .value("Time", timestamp),
                            y: .value("Count", todayUrges.filter { $0 <= timestamp }.count)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        
                        AreaMark(
                            x: .value("Time", timestamp),
                            y: .value("Count", todayUrges.filter { $0 <= timestamp }.count)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue.opacity(0.2), .purple.opacity(0.1)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                            .foregroundStyle(.gray.opacity(0.2))
                        AxisValueLabel()
                            .foregroundStyle(.secondary)
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisGridLine()
                            .foregroundStyle(.gray.opacity(0.2))
                    }
                }
                .frame(height: 120)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .widgetBackground()
    }
}

// Extension for older iOS versions
extension View {
    @ViewBuilder
    func widgetBackground() -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            self.containerBackground(.fill.tertiary, for: .widget)
        } else {
            self.background(Color(.systemBackground))
        }
    }
}

@main
struct UrgeLoggerWidget: Widget {
    let kind: String = "UrgeLoggerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: UrgeLoggerWidgetProvider()) { entry in
            UrgeLoggerWidgetView(entry: entry)
        }
        .configurationDisplayName("Urge Logger")
        .description("Tap to log an urge and track your progress over time.")
        .supportedFamilies([.systemLarge])
    }
}
