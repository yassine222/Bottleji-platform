import WidgetKit
import SwiftUI
import ActivityKit

// IMPORTANT: This must match the attributes in LiveActivityManager.swift exactly
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
            // Lock screen/banner UI
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(.green)
                    Text("Collection in Progress")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                
                HStack(spacing: 16) {
                    Label(context.state.elapsedTime, systemImage: "timer")
                    Label(context.state.distance, systemImage: "location.fill")
                    Label(context.state.eta, systemImage: "clock.fill")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding()
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Collection")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(context.attributes.dropAddress)
                            .font(.headline)
                            .lineLimit(1)
                    }
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Timer")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(context.state.elapsedTime)
                            .font(.headline)
                    }
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.caption)
                            Text(context.state.distance)
                                .font(.subheadline)
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.caption)
                            Text(context.state.eta)
                                .font(.subheadline)
                        }
                    }
                    .foregroundColor(.secondary)
                }
            } compactLeading: {
                // Compact leading (left side of Dynamic Island)
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(.green)
            } compactTrailing: {
                // Compact trailing (right side of Dynamic Island) - Shows timer
                Text(context.state.elapsedTime)
                    .font(.caption2)
                    .foregroundColor(.primary)
            } minimal: {
                // Minimal view (when multiple activities)
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(.green)
            }
        }
    }
}

// REQUIRED: @main struct for Widget Extension
@main
struct LiveActivityWidgetExtension: WidgetBundle {
    var body: some Widget {
        if #available(iOS 16.1, *) {
            LiveActivityWidget()
        }
    }
}
