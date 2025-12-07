import WidgetKit
import SwiftUI
import ActivityKit
import UIKit

// Enum for Live Activity view types
enum LiveActivityViewType {
    case compact
    case expanded
    case minimal
    case standard  // For lock screen and default views
}

// Helper function to load app logo from bundle with view-specific images
@ViewBuilder
func AppLogoView(size: CGFloat, cornerRadius: CGFloat = 4, viewType: LiveActivityViewType = .standard) -> some View {
    Group {
        // Try loading view-specific image first
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
        
        // Try loading image - Widget Extensions use Bundle.main for their own assets
        if let name = imageName {
            // Try loading from Widget Extension bundle (Bundle.main in Widget Extension context)
            if let image = UIImage(named: name, in: Bundle.main, compatibleWith: nil) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else if let image = UIImage(named: name) {
                // Fallback to default bundle lookup
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else if let image = UIImage(named: "AppLogo", in: Bundle.main, compatibleWith: nil) {
                // Fallback to default AppLogo
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else if let image = UIImage(named: "AppLogo") {
                // Fallback to default bundle
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                // Fallback to system icon
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(Color(red: 0.0, green: 0.412, blue: 0.361))
                    .font(size > 20 ? .title3 : (size > 15 ? .caption : .caption2))
            }
        } else {
            // Fallback to system icon if no image name
            Image(systemName: "mappin.circle.fill")
                .foregroundColor(Color(red: 0.0, green: 0.412, blue: 0.361))
                .font(size > 20 ? .title3 : (size > 15 ? .caption : .caption2))
        }
    }
    .frame(width: size, height: size)
    .cornerRadius(cornerRadius)
}

// MARK: - Collection Navigation Activity (Improved UI)
struct CollectionActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var elapsedTime: String  // "03:12" (MM:SS format)
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
            // Lock screen/banner UI - Optimized per Apple's HIG
            VStack(alignment: .leading, spacing: 10) {
                // Header with clear hierarchy
                HStack(alignment: .center, spacing: 8) {
                    // App branding
                    HStack(spacing: 8) {
                        AppLogoView(size: 24, cornerRadius: 6, viewType: .standard)
                        Text("Bottleji")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    // Primary info: Countdown timer (most important)
                    Text(context.state.elapsedTime)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .monospacedDigit()
                }
                
                // Progress bar - functional and visible
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(.systemGray5))
                            .frame(height: 3)
                        
                        // Progress fill
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(red: 0.0, green: 0.412, blue: 0.361))
                            .frame(width: geometry.size.width * CGFloat(context.state.progressPercentage) / 100, height: 3)
                    }
                }
                .frame(height: 3)
                
                // Secondary info row - scannable at a glance
                HStack(spacing: 16) {
                    // Distance
                    Label {
                        Text(context.state.distance)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    } icon: {
                        Image(systemName: "location.fill")
                            .font(.caption)
                            .foregroundColor(.systemBlue)
                    }
                    
                    // Value
                    Label {
                        Text(context.attributes.estimatedValue)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    } icon: {
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.caption)
                            .foregroundColor(Color(red: 0.0, green: 0.412, blue: 0.361))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .activityBackgroundTint(Color(.systemBackground))
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI - Optimized per Apple's HIG
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 3) {
                        // App branding
                        HStack(spacing: 6) {
                            AppLogoView(size: 20, cornerRadius: 4, viewType: .expanded)
                        }
                        
                        // Primary title
                        Text("Bottleji")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        // Secondary status
                        Text("Drop in progress")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    .padding(.leading, 4)
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    // Primary metric: Countdown timer
                    Text(context.state.elapsedTime)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .monospacedDigit()
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 6) {
                        // Info row with proper spacing
                        HStack(spacing: 12) {
                            // Distance
                            Label {
                                Text(context.state.distance)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                            } icon: {
                                Image(systemName: "location.fill")
                                    .font(.caption2)
                                    .foregroundColor(.systemBlue)
                            }
                            
                            // Value
                            Label {
                                Text(context.attributes.estimatedValue)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                            } icon: {
                                Image(systemName: "dollarsign.circle.fill")
                                    .font(.caption2)
                                    .foregroundColor(Color(red: 0.0, green: 0.412, blue: 0.361))
                            }
                            
                            Spacer()
                            
                            // Progress indicator
                            HStack(spacing: 4) {
                                Circle()
                                    .stroke(Color.primary.opacity(0.3), lineWidth: 1.5)
                                    .frame(width: 14, height: 14)
                                Text("\(context.state.progressPercentage)%")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                            }
                        }
                        
                        // Progress bar - optimized height and styling
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 1.5)
                                    .fill(Color(.systemGray5))
                                    .frame(height: 3)
                                
                                RoundedRectangle(cornerRadius: 1.5)
                                    .fill(Color(red: 0.0, green: 0.412, blue: 0.361))
                                    .frame(width: geometry.size.width * CGFloat(context.state.progressPercentage) / 100, height: 3)
                            }
                        }
                        .frame(height: 3)
                    }
                }
            } compactLeading: {
                // Compact leading - App logo (16x16 per HIG)
                AppLogoView(size: 16, cornerRadius: 3, viewType: .compact)
            } compactTrailing: {
                // Compact trailing - Countdown timer (most important info)
                Text(context.state.elapsedTime)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                    .monospacedDigit()
                    .lineLimit(1)
            } minimal: {
                // Minimal view - App logo only (12x12 per HIG)
                AppLogoView(size: 12, cornerRadius: 2, viewType: .minimal)
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
            // Lock screen/banner UI - Optimized per Apple's HIG
            VStack(alignment: .leading, spacing: 10) {
                // Header with clear hierarchy
                HStack(alignment: .center, spacing: 8) {
                    HStack(spacing: 8) {
                        AppLogoView(size: 24, cornerRadius: 6, viewType: .standard)
                        Text("Drop Status")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    // Primary metric: Estimated value
                    Text(context.attributes.estimatedValue)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 0.0, green: 0.412, blue: 0.361))
                }
                
                // Status with collector info
                HStack(spacing: 6) {
                    Text(context.state.statusText)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(statusColor(context.state.status))
                        .lineLimit(1)
                    
                    if let collectorName = context.state.collectorName {
                        Text("• \(collectorName)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                // Timeline progress
                timelineProgressView(status: context.state.status)
                
                // Time ago
                Label {
                    Text(context.state.timeAgo)
                        .font(.caption)
                        .foregroundColor(.secondary)
                } icon: {
                    Image(systemName: "clock")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .activityBackgroundTint(Color(.systemBackground))
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI - Optimized per Apple's HIG
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            AppLogoView(size: 20, cornerRadius: 4, viewType: .expanded)
                        }
                        
                        Text("Bottleji")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Text("Drop Status")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    .padding(.leading, 4)
                }
                
                DynamicIslandExpandedRegion(.trailing) {
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
                
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 6) {
                        // Timeline progress
                        timelineProgressView(status: context.state.status)
                        
                        // Collector info if available
                        if let collectorName = context.state.collectorName {
                            Label {
                                Text(collectorName)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                            } icon: {
                                Image(systemName: "person.fill")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            } compactLeading: {
                // Compact leading - App logo (16x16 per HIG)
                AppLogoView(size: 16, cornerRadius: 3, viewType: .compact)
            } compactTrailing: {
                // Compact trailing - Status text (most important info)
                Text(context.state.statusText)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(statusColor(context.state.status))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            } minimal: {
                // Minimal view - App logo only (12x12 per HIG)
                AppLogoView(size: 12, cornerRadius: 2, viewType: .minimal)
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
