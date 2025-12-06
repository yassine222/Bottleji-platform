import WidgetKit
import SwiftUI
import ActivityKit

// MARK: - Collection Navigation Activity (Improved UI)
struct CollectionActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var elapsedTime: String  // "12:34"
        var distance: String     // "1.2 km"
        var eta: String          // "5 min"
    }
    
    var dropId: String
    var dropAddress: String
    var transportMode: String
}

@available(iOS 16.1, *)
struct LiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CollectionActivityAttributes.self) { context in
            // Lock screen/banner UI - Improved design with theme support
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(Color(red: 0.0, green: 0.412, blue: 0.361)) // App primary color #00695C
                            .font(.title3)
                        Text("Active Collection")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                    Spacer()
                    // Show ETA countdown instead of elapsed time
                    Text(context.state.eta)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 1.0, green: 0.596, blue: 0.0)) // Orange #FF9800
                }
                
                // Progress indicator
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(Color(red: 0.0, green: 0.412, blue: 0.361)) // App primary color
                        .frame(height: 4)
                        .frame(maxWidth: .infinity)
                    Rectangle()
                        .fill(Color(red: 0.0, green: 0.412, blue: 0.361).opacity(0.3))
                        .frame(height: 4)
                        .frame(maxWidth: .infinity)
                }
                .cornerRadius(2)
                
                // Info row
                HStack(spacing: 20) {
                    HStack(spacing: 6) {
                        Image(systemName: "location.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Text(context.state.distance)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                    
                    HStack(spacing: 6) {
                        Image(systemName: "clock.fill")
                            .font(.caption)
                            .foregroundColor(Color(red: 1.0, green: 0.596, blue: 0.0)) // Orange
                        Text("Arrives in \(context.state.eta)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                }
            }
            .padding()
            .activityBackgroundTint(Color(.systemBackground))
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI - Improved design with app logo
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            // Collection icon - App primary color
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(Color(red: 0.0, green: 0.412, blue: 0.361)) // #00695C
                                .font(.caption)
                            Text("Active Collection")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Text(context.attributes.dropAddress)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                    }
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 6) {
                        Text("Arrives in")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        // Show ETA countdown instead of elapsed time
                        Text(context.state.eta)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color(red: 1.0, green: 0.596, blue: 0.0)) // Orange #FF9800
                    }
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 8) {
                        // Progress bar - App primary color
                        HStack(spacing: 0) {
                            Rectangle()
                                .fill(Color(red: 0.0, green: 0.412, blue: 0.361)) // #00695C
                                .frame(height: 3)
                                .frame(maxWidth: .infinity)
                            Rectangle()
                                .fill(Color(red: 0.0, green: 0.412, blue: 0.361).opacity(0.2))
                                .frame(height: 3)
                                .frame(maxWidth: .infinity)
                        }
                        .cornerRadius(1.5)
                        
                        // Info row
                        HStack(spacing: 20) {
                            HStack(spacing: 4) {
                                Image(systemName: "location.fill")
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                                Text(context.state.distance)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                            }
                            
                            HStack(spacing: 4) {
                                Image(systemName: "clock.fill")
                                    .font(.caption2)
                                    .foregroundColor(Color(red: 1.0, green: 0.596, blue: 0.0)) // Orange
                                Text(context.state.eta)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                }
            } compactLeading: {
                // Compact leading - Collection icon
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(Color(red: 0.0, green: 0.412, blue: 0.361)) // #00695C
                    .font(.caption)
            } compactTrailing: {
                // Compact trailing - ETA countdown
                Text(context.state.eta)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(red: 1.0, green: 0.596, blue: 0.0)) // Orange
            } minimal: {
                // Minimal view - Collection icon
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(Color(red: 0.0, green: 0.412, blue: 0.361)) // #00695C
                    .font(.caption2)
            }
            .widgetURL(URL(string: "botleji://navigation?dropId=\(context.attributes.dropId)"))
        }
    }
}

// MARK: - Drop Timeline Activity (Household Mode)
struct DropTimelineActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var status: String  // "pending", "accepted", "on_way", "collected", "expired", "cancelled"
        var statusText: String  // "Created", "Accepted", "On his way", etc.
        var collectorName: String?  // Collector name if accepted
        var timeAgo: String  // "2 min ago", "Just now"
    }
    
    var dropId: String
    var dropAddress: String
    var estimatedValue: String  // "2.50 TND"
    var createdAt: String  // Timestamp
}

@available(iOS 16.1, *)
struct DropTimelineWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DropTimelineActivityAttributes.self) { context in
            // Lock screen/banner UI with theme support
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "tray.and.arrow.down.fill")
                            .foregroundColor(statusColor(context.state.status))
                            .font(.title3)
                        Text("Drop Status")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                    Spacer()
                    Text(context.attributes.estimatedValue)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 0.0, green: 0.412, blue: 0.361)) // App primary #00695C
                }
                
                // Status text
                HStack {
                    Text(context.state.statusText)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(statusColor(context.state.status))
                    if let collectorName = context.state.collectorName {
                        Text("• \(collectorName)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Timeline progress
                timelineProgressView(status: context.state.status)
                
                // Time ago
                HStack {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(context.state.timeAgo)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .activityBackgroundTint(Color(.systemBackground))
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: "tray.and.arrow.down.fill")
                                .foregroundColor(statusColor(context.state.status))
                                .font(.caption)
                            Text("Drop Status")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Text(context.attributes.dropAddress)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                    }
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 6) {
                        Text(context.attributes.estimatedValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(context.state.statusText)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(statusColor(context.state.status))
                    }
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 8) {
                        // Timeline progress
                        timelineProgressView(status: context.state.status)
                        
                        // Collector info if available
                        if let collectorName = context.state.collectorName {
                            HStack {
                                Image(systemName: "person.fill")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text(collectorName)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                }
            } compactLeading: {
                // Compact leading - Status icon
                Image(systemName: statusIcon(context.state.status))
                    .foregroundColor(statusColor(context.state.status))
                    .font(.caption)
            } compactTrailing: {
                // Compact trailing - Status text
                Text(context.state.statusText)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
            } minimal: {
                // Minimal view
                Image(systemName: statusIcon(context.state.status))
                    .foregroundColor(statusColor(context.state.status))
                    .font(.caption2)
            }
        }
    }
    
    // Helper function for status color - uses app theme colors
    private func statusColor(_ status: String) -> Color {
        switch status {
        case "pending":
            return Color(red: 0.0, green: 0.478, blue: 1.0) // System blue
        case "accepted", "on_way":
            return Color(red: 1.0, green: 0.596, blue: 0.0) // Orange #FF9800
        case "collected":
            return Color(red: 0.0, green: 0.412, blue: 0.361) // App primary #00695C
        case "expired", "cancelled":
            return Color(red: 0.827, green: 0.184, blue: 0.184) // Red #D32F2F
        default:
            return Color(.systemGray)
        }
    }
    
    // Helper function for status icon
    private func statusIcon(_ status: String) -> String {
        switch status {
        case "pending":
            return "clock.fill"
        case "accepted":
            return "checkmark.circle.fill"
        case "on_way":
            return "car.fill"
        case "collected":
            return "checkmark.circle.fill"
        case "expired":
            return "exclamationmark.triangle.fill"
        case "cancelled":
            return "xmark.circle.fill"
        default:
            return "circle.fill"
        }
    }
    
    // Timeline progress view
    @ViewBuilder
    private func timelineProgressView(status: String) -> some View {
        let stages = ["Created", "Accepted", "On his way", "Outcome"]
        
                HStack(spacing: 8) {
                    ForEach(Array(stages.enumerated()), id: \.offset) { index, stage in
                        let isActive = isStageActive(status: status, stageIndex: index)
                        let isCompleted = isStageCompleted(status: status, stageIndex: index)
                        
                        HStack(spacing: 4) {
                            // Circle indicator - uses theme-aware colors
                            Circle()
                                .fill(isCompleted ? statusColor(status) : (isActive ? statusColor(status) : Color(.systemGray4)))
                                .frame(width: 8, height: 8)
                            
                            if index < stages.count - 1 {
                                // Connector line - uses theme-aware colors
                                Rectangle()
                                    .fill(isCompleted ? statusColor(status) : Color(.systemGray4))
                                    .frame(height: 2)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                }
    }
    
    private func isStageActive(status: String, stageIndex: Int) -> Bool {
        switch (status, stageIndex) {
        case ("pending", 0): return true
        case ("accepted", 1): return true
        case ("on_way", 2): return true
        case ("collected", 3), ("expired", 3), ("cancelled", 3): return true
        default: return false
        }
    }
    
    private func isStageCompleted(status: String, stageIndex: Int) -> Bool {
        switch (status, stageIndex) {
        case ("accepted", 0), ("on_way", 0), ("collected", 0), ("expired", 0), ("cancelled", 0): return true
        case ("on_way", 1), ("collected", 1), ("expired", 1), ("cancelled", 1): return true
        case ("collected", 2), ("expired", 2), ("cancelled", 2): return true
        default: return false
        }
    }
}

// MARK: - Widget Bundle
@main
struct LiveActivityWidgetExtension: WidgetBundle {
    var body: some Widget {
        if #available(iOS 16.1, *) {
            LiveActivityWidget()
            DropTimelineWidget()
        }
    }
}
