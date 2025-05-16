//
//  UrgeGraphView.swift
//  Reset
//
//  Created by Prasanjit Panda on 06/02/25.
//


import SwiftUI
import Charts

struct UrgeGraphView: View {
    let timestamps: [Date: String]
    var onTap: ([(Date, String)]) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Today's Urges")
                .font(.system(.headline, design: .rounded))
                .foregroundColor(.secondary)
            
            if timestamps.isEmpty {
                EmptyGraphView()
            } else {
                Chart(timestamps.keys.sorted(), id: \.self) { timestamp in
                    LineMark(
                        x: .value("Time", timestamp),
                        y: .value("Count", timestamps.keys.filter { $0 <= timestamp }.count)
                    )
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                    .foregroundStyle(
                        LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
                    )
                    
                    AreaMark(
                        x: .value("Time", timestamp),
                        y: .value("Count", timestamps.keys.filter { $0 <= timestamp }.count)
                    )
                    .foregroundStyle(
                        LinearGradient(colors: [.blue.opacity(0.2), .purple.opacity(0.1)], startPoint: .top, endPoint: .bottom)
                    )
                }
                .frame(height: 120)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .onTapGesture {
            onTap(Array(timestamps.sorted(by: { $0.key < $1.key })))
        }
    }
}



struct EmptyGraphView: View {
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.largeTitle)
                .foregroundColor(.gray.opacity(0.3))
            Text("No data yet")
                .font(.system(.caption, design: .rounded))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
    }
}
