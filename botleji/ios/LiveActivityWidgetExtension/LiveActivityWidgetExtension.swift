import WidgetKit
import SwiftUI
import ActivityKit
import UIKit

// MARK: - App Theme Colors
extension Color {
    // App Primary Green
    static let appPrimary = Color(red: 0.0, green: 0.412, blue: 0.361) // #00695C
    // App Orange
    static let appOrange = Color(red: 1.0, green: 0.596, blue: 0.0) // #FF9800
    // App Secondary Blue
    static let appSecondary = Color(red: 0.0, green: 0.6, blue: 1.0) // #0099FF
}

// MARK: - Helper Functions

// Helper function to load app logo from bundle
@ViewBuilder
func AppLogoView(size: CGFloat, cornerRadius: CGFloat = 4, viewType: LiveActivityViewType = .standard) -> some View {
    Group {
        let imageName: String? = {
            switch viewType {
            case .compact:
                return "live_activity_icon_compact"
            case .expanded:
                return "live_activity_icon_expanded"
            case .minimal:
                return "live_activity_icon_minimal"
            case .standard:
                return "AppLogo"
            }
        }()
        
        if let name = imageName,
           let image = UIImage(named: name, in: Bundle.main, compatibleWith: nil) ?? UIImage(named: name) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
        } else if let fallbackImage = UIImage(named: "AppLogo", in: Bundle.main, compatibleWith: nil) ?? UIImage(named: "AppLogo") {
            Image(uiImage: fallbackImage)
                .resizable()
                .scaledToFit()
        } else {
            Image(systemName: "mappin.circle.fill")
                .foregroundColor(.appPrimary)
                .font(size > 20 ? .title3 : (size > 15 ? .caption : .caption2))
        }
    }
    .frame(width: size, height: size)
    .cornerRadius(cornerRadius)
}

// Enum for Live Activity view types
enum LiveActivityViewType {
    case compact
    case expanded
    case minimal
    case standard
}

// MARK: - Collection Navigation Activity (Collector Mode)

struct CollectionActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var elapsedTime: String  // "12:48" (MM:SS countdown format)
        var distance: String     // "2.5 km"
        var eta: String          // "5 min"
        var progressPercentage: Int  // 65 (0-100)
    }
    
    var dropId: String
    var dropAddress: String
    var transportMode: String
    var estimatedValue: String  // "2.50 TND"
}

@available(iOS 16.1, *)
struct LiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CollectionActivityAttributes.self) { context in
            // MARK: - Lock Screen View
            lockScreenView(context: context)
                .activityBackgroundTint(Color(.systemBackground))
        } dynamicIsland: { context in
            DynamicIsland {
                // MARK: - Expanded Presentation
                DynamicIslandExpandedRegion(.leading) {
                    expandedLeadingView(context: context)
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    expandedTrailingView(context: context)
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    expandedBottomView(context: context)
                }
            } compactLeading: {
                // MARK: - Compact Presentation (Leading)
                compactLeadingView(context: context)
            } compactTrailing: {
                // MARK: - Compact Presentation (Trailing)
                compactTrailingView(context: context)
            } minimal: {
                // MARK: - Minimal Presentation
                minimalView(context: context)
            }
            .widgetURL(URL(string: "botleji://navigation?dropId=\(context.attributes.dropId)"))
        }
    }
    
    // MARK: - Lock Screen View
    @ViewBuilder
    private func lockScreenView(context: ActivityViewContext<CollectionActivityAttributes>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header Row
            HStack(alignment: .center, spacing: 10) {
                // App Branding
                HStack(spacing: 8) {
                    AppLogoView(size: 28, cornerRadius: 7, viewType: .standard)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Bottleji")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        Text("Active Collection")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Countdown Timer (Primary Metric)
                VStack(alignment: .trailing, spacing: 2) {
                    Text(context.state.elapsedTime)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.appOrange)
                        .monospacedDigit()
                    Text("remaining")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(.systemGray5))
                        .frame(height: 4)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [Color.appPrimary, Color.appPrimary.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(context.state.progressPercentage) / 100, height: 4)
                }
            }
            .frame(height: 4)
            
            // Info Row
            HStack(spacing: 20) {
                // Distance
                HStack(spacing: 6) {
                    Image(systemName: "location.fill")
                        .font(.caption)
                        .foregroundColor(.appSecondary)
                        .frame(width: 16)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Distance")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(context.state.distance)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                }
                
                // Value
                HStack(spacing: 6) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.caption)
                        .foregroundColor(.appPrimary)
                        .frame(width: 16)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Value")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(context.attributes.estimatedValue)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                }
                
                Spacer()
                
                // Progress
                VStack(alignment: .trailing, spacing: 1) {
                    Text("Progress")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(context.state.progressPercentage)%")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.appPrimary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
    
    // MARK: - StandBy View (Same as Lock Screen)
    // Note: StandBy uses the same view as Lock Screen in ActivityKit
    
    // MARK: - Expanded Presentation Views
    @ViewBuilder
    private func expandedLeadingView(context: ActivityViewContext<CollectionActivityAttributes>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            // App Logo and Name - Horizontally aligned (smaller to free space)
            HStack(alignment: .center, spacing: 4) {
                AppLogoView(size: 18, cornerRadius: 4, viewType: .expanded)
                Text("Bottleji")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            
            // Status - Positioned below the logo/text row with proper spacing
             // Ensure no extra leading padding
        }
        .padding(.leading, 2)
        .frame(maxWidth: .infinity, alignment: .leading) // Ensure proper alignment
    }
    
    @ViewBuilder
    private func expandedTrailingView(context: ActivityViewContext<CollectionActivityAttributes>) -> some View {
        // Countdown Timer
        Text(context.state.elapsedTime)
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .foregroundColor(.appOrange)
            .monospacedDigit()
            .lineLimit(1)
    }
    
    @ViewBuilder
    private func expandedBottomView(context: ActivityViewContext<CollectionActivityAttributes>) -> some View {
        VStack(spacing: 8) {
            // Status - Right aligned
            HStack {
                Spacer()
                Text("Active Collection")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .padding(.trailing, 4)
            }
            
            // Info Row
            HStack(spacing: 16) {
                // Distance
                HStack(spacing: 5) {
                    Image(systemName: "location.fill")
                        .font(.caption2)
                        .foregroundColor(.appSecondary)
                    Text(context.state.distance)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
                
                // Value
                HStack(spacing: 5) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.caption2)
                        .foregroundColor(.appPrimary)
                    Text(context.attributes.estimatedValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                // Progress
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.appPrimary.opacity(0.2))
                        .frame(width: 12, height: 12)
                    Text("\(context.state.progressPercentage)%")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(.systemGray5))
                        .frame(height: 3)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                colors: [Color.appPrimary, Color.appPrimary.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(context.state.progressPercentage) / 100, height: 3)
                }
            }
            .frame(height: 3)
        }
    }
    
    // MARK: - Compact Presentation Views
    @ViewBuilder
    private func compactLeadingView(context: ActivityViewContext<CollectionActivityAttributes>) -> some View {
        AppLogoView(size: 16, cornerRadius: 3, viewType: .compact)
    }
    
    @ViewBuilder
    private func compactTrailingView(context: ActivityViewContext<CollectionActivityAttributes>) -> some View {
        Text(context.state.elapsedTime)
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .foregroundColor(.appOrange)
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }
    
    // MARK: - Minimal Presentation View
    @ViewBuilder
    private func minimalView(context: ActivityViewContext<CollectionActivityAttributes>) -> some View {
        AppLogoView(size: 12, cornerRadius: 2, viewType: .minimal)
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
            // MARK: - Lock Screen View (Household)
            dropTimelineLockScreenView(context: context)
                .activityBackgroundTint(Color(.systemBackground))
        } dynamicIsland: { context in
            DynamicIsland {
                // MARK: - Expanded Presentation (Household)
                DynamicIslandExpandedRegion(.leading) {
                    dropTimelineExpandedLeadingView(context: context)
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    dropTimelineExpandedTrailingView(context: context)
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    dropTimelineExpandedBottomView(context: context)
                }
            } compactLeading: {
                // MARK: - Compact Presentation (Household)
                AppLogoView(size: 16, cornerRadius: 3, viewType: .compact)
            } compactTrailing: {
                // MARK: - Compact Trailing (Household)
                Text(context.state.statusText)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(statusColor(context.state.status))
                    .lineLimit(1)
            } minimal: {
                // MARK: - Minimal Presentation (Household)
                AppLogoView(size: 12, cornerRadius: 2, viewType: .minimal)
            }
        }
    }
    
    // MARK: - Drop Timeline Lock Screen View
    @ViewBuilder
    private func dropTimelineLockScreenView(context: ActivityViewContext<DropTimelineActivityAttributes>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(alignment: .center, spacing: 10) {
                HStack(spacing: 8) {
                    AppLogoView(size: 28, cornerRadius: 7, viewType: .standard)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Bottleji")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        Text("Drop Status")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Text(context.attributes.estimatedValue)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.appPrimary)
            }
            
            // Status
            HStack(spacing: 8) {
                Circle()
                    .fill(statusColor(context.state.status))
                    .frame(width: 10, height: 10)
                Text(context.state.statusText)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(statusColor(context.state.status))
                
                if let collectorName = context.state.collectorName {
                    Text("• \(collectorName)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            // Timeline Progress
            timelineProgressView(status: context.state.status)
            
            // Time Ago
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(context.state.timeAgo)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
    
    // MARK: - Drop Timeline Expanded Views
    @ViewBuilder
    private func dropTimelineExpandedLeadingView(context: ActivityViewContext<DropTimelineActivityAttributes>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            // App Logo and Name - Horizontally aligned
            HStack(alignment: .center, spacing: 6) {
                AppLogoView(size: 22, cornerRadius: 5, viewType: .expanded)
                Text("Bottleji")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            
            Text("Drop Status")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(.leading, 4)
    }
    
    @ViewBuilder
    private func dropTimelineExpandedTrailingView(context: ActivityViewContext<DropTimelineActivityAttributes>) -> some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(context.attributes.estimatedValue)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            Text(context.state.statusText)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(statusColor(context.state.status))
                .lineLimit(1)
        }
    }
    
    @ViewBuilder
    private func dropTimelineExpandedBottomView(context: ActivityViewContext<DropTimelineActivityAttributes>) -> some View {
        VStack(spacing: 6) {
            timelineProgressView(status: context.state.status)
            
            if let collectorName = context.state.collectorName {
                HStack(spacing: 4) {
                    Image(systemName: "person.fill")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(collectorName)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    private func statusColor(_ status: String) -> Color {
        switch status {
        case "pending":
            return .appSecondary
        case "accepted", "on_way":
            return .appOrange
        case "collected":
            return .appPrimary
        case "expired", "cancelled":
            return Color(.systemRed)
        default:
            return Color(.systemGray)
        }
    }
    
    @ViewBuilder
    private func timelineProgressView(status: String) -> some View {
        let stages = ["Created", "Accepted", "On his way", "Outcome"]
        
        HStack(spacing: 8) {
            ForEach(Array(stages.enumerated()), id: \.offset) { index, stage in
                let isActive = isStageActive(status: status, stageIndex: index)
                let isCompleted = isStageCompleted(status: status, stageIndex: index)
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(isCompleted ? statusColor(status) : (isActive ? statusColor(status) : Color(.systemGray4)))
                        .frame(width: 8, height: 8)
                    
                    if index < stages.count - 1 {
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
