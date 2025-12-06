import WidgetKit
import SwiftUI
import ActivityKit

/// Widget for Dynamic Island and Lock Screen Live Activity
@available(iOS 16.1, *)
struct LiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CollectionActivityAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(.green)
                    Text("Collection in Progress")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                
                HStack(spacing: 12) {
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
                // Compact trailing (right side of Dynamic Island)
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

