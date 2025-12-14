//
//  BottlejiLiveActivityWidgetLiveActivity.swift
//  BottlejiLiveActivityWidget
//
//  Created by Yassine Romdhane on 14.12.25.
//

import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Activity Attributes
public struct BottlejiLiveActivityWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties
        public var status: String?              // "pending", "accepted", "on_way", "collected", "cancelled", "expired"
        public var statusText: String?          // "Created", "Accepted", "On his way", "Collected", etc.
        public var collectorName: String?       // Collector's name (only when accepted)
        public var timeAgo: String?             // "Just now", "1 min ago", "5 min ago"
        public var distanceRemaining: Double?   // Distance in meters for collector pin position (optional)
        
        public init(
            status: String? = nil,
            statusText: String? = nil,
            collectorName: String? = nil,
            timeAgo: String? = nil,
            distanceRemaining: Double? = nil
        ) {
            self.status = status
            self.statusText = statusText
            self.collectorName = collectorName
            self.timeAgo = timeAgo
            self.distanceRemaining = distanceRemaining
        }
    }

    // Fixed non-changing properties
    public var dropId: String
    public var dropAddress: String
    public var estimatedValue: String
    public var createdAt: String?
    
    public init(
        dropId: String,
        dropAddress: String,
        estimatedValue: String,
        createdAt: String? = nil
    ) {
        self.dropId = dropId
        self.dropAddress = dropAddress
        self.estimatedValue = estimatedValue
        self.createdAt = createdAt
    }
}

// MARK: - Live Activity Widget
struct BottlejiLiveActivityWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: BottlejiLiveActivityWidgetAttributes.self) { context in
            // Debug logging
            let _ = print("🔄 [Widget] Rendering with attributes - dropId: \(context.attributes.dropId), address: \(context.attributes.dropAddress), value: \(context.attributes.estimatedValue)")
            let _ = print("🔄 [Widget] ContentState - status: \(context.state.status ?? "nil"), statusText: \(context.state.statusText ?? "nil"), timeAgo: \(context.state.timeAgo ?? "nil")")
            
            // Lock screen/banner UI
            DropTimelineLockScreenView(context: context)
                .activityBackgroundTint(Color.black.opacity(0.85))
                .activitySystemActionForegroundColor(Color.white)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 16))
                            Text("Bottleji")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    }
                    .padding(EdgeInsets(top: 4, leading: 12, bottom: 0, trailing: 12))
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(context.attributes.estimatedValue)
                            .font(.headline)
                            .foregroundColor(.white)
                        Text(context.state.statusText ?? "Created")
                            .font(.caption)
                            .foregroundColor(statusColor(for: context.state.status))
                    }
                    .padding(EdgeInsets(top: 4, leading: 12, bottom: 0, trailing: 12))
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    DropTimelineProgressView(
                        status: context.state.status,
                        distanceRemaining: context.state.distanceRemaining
                    )
                    .padding(EdgeInsets(top: 8, leading: 42, bottom: 8, trailing: 42))
                }
            } compactLeading: {
                // Compact leading (left side of Dynamic Island)
                Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 12))
            } compactTrailing: {
                // Compact trailing (right side of Dynamic Island)
                Text(context.state.statusText ?? "Created")
                    .font(.caption2)
                    .foregroundColor(statusColor(for: context.state.status))
            } minimal: {
                // Minimal view (when multiple activities)
                Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 10))
            }
        }
    }
    
    // Helper function to get status color
    private func statusColor(for status: String?) -> Color {
        guard let status = status else { return .gray }
        switch status {
        case "pending":
            return .gray
        case "accepted", "on_way":
            return .orange
        case "collected":
            return .green
        case "cancelled", "expired":
            return .red
        default:
            return .gray
        }
    }
}

// MARK: - Lock Screen View
struct DropTimelineLockScreenView: View {
    let context: ActivityViewContext<BottlejiLiveActivityWidgetAttributes>
    
    var body: some View {
        // Debug: Print received data
        let _ = print("🔄 [Widget View] dropId: \(context.attributes.dropId)")
        let _ = print("🔄 [Widget View] address: \(context.attributes.dropAddress)")
        let _ = print("🔄 [Widget View] value: \(context.attributes.estimatedValue)")
        let _ = print("🔄 [Widget View] status: \(context.state.status ?? "nil")")
        let _ = print("🔄 [Widget View] statusText: \(context.state.statusText ?? "nil")")
        let _ = print("🔄 [Widget View] timeAgo: \(context.state.timeAgo ?? "nil")")
        
        return VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 20))
                        Text("Bottleji")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    Text("Drop Status")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Text(context.attributes.estimatedValue)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            
            // Status Section
            HStack(spacing: 12) {
                // Status Circle
                Circle()
                    .fill(statusColor(for: context.state.status))
                    .frame(width: 10, height: 10)
                
                // Status Text
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.state.statusText ?? "Created")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    if let collectorName = context.state.collectorName, !collectorName.isEmpty {
                        HStack(spacing: 4) {
                            Text("•")
                                .foregroundColor(.gray)
                            Text(collectorName)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Spacer()
                
                // Time Ago
                if let timeAgo = context.state.timeAgo {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(timeAgo)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            // Timeline Progress Bar
            DropTimelineProgressView(
                status: context.state.status,
                distanceRemaining: context.state.distanceRemaining
            )
        }
        .padding(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
    }
    
    // Helper function to get status color
    private func statusColor(for status: String?) -> Color {
        guard let status = status else { return .gray }
        switch status {
        case "pending":
            return .gray
        case "accepted", "on_way":
            return .orange
        case "collected":
            return .green
        case "cancelled", "expired":
            return .red
        default:
            return .gray
        }
    }
}

// MARK: - Timeline Progress View
struct DropTimelineProgressView: View {
    let status: String?
    let distanceRemaining: Double?
    
    // Calculate current stage (0 = Created, 1 = Accepted, 2 = On Way, 3 = Collected)
    private var currentStage: Int {
        guard let status = status else { return 0 }
        switch status {
        case "pending":
            return 0
        case "accepted":
            return 1
        case "on_way":
            return 2
        case "collected":
            return 3
        default:
            return 0
        }
    }
    
    // Calculate collector pin position (0.0 to 1.0) between Accepted (0.25) and Collected (1.0)
    private var collectorPinPosition: CGFloat? {
        guard let distanceRemaining = distanceRemaining, distanceRemaining > 0 else { return nil }
        // Assuming max distance is 1000 meters, adjust as needed
        let maxDistance: Double = 1000.0
        let normalizedDistance = min(distanceRemaining / maxDistance, 1.0)
        // Position between Accepted (0.25) and Collected (1.0)
        return 0.25 + (normalizedDistance * 0.75)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background line
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 2)
                
                // Progress line
                if currentStage > 0 {
                    Rectangle()
                        .fill(progressColor)
                        .frame(width: progressWidth(for: geometry.size.width), height: 2)
                }
                
                // Stage dots
                HStack(spacing: 0) {
                    ForEach(0..<4) { index in
                        Circle()
                            .fill(dotColor(for: index))
                            .frame(width: 12, height: 12)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                            )
                        
                        if index < 3 {
                            Spacer()
                        }
                    }
                }
                
                // Collector pin (if distanceRemaining is provided and status is accepted or on_way)
                if let pinPosition = collectorPinPosition,
                   (status == "accepted" || status == "on_way") {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 20))
                        .offset(x: pinPosition * geometry.size.width - 10)
                }
            }
        }
        .frame(height: 20)
    }
    
    private func progressWidth(for totalWidth: CGFloat) -> CGFloat {
        let spacing = totalWidth / 3.0 // 3 spaces between 4 dots
        return spacing * CGFloat(currentStage)
    }
    
    private var progressColor: Color {
        guard let status = status else { return .gray }
        switch status {
        case "pending":
            return .gray
        case "accepted", "on_way":
            return .orange
        case "collected":
            return .green
        case "cancelled", "expired":
            return .red
        default:
            return .gray
        }
    }
    
    private func dotColor(for index: Int) -> Color {
        if index < currentStage {
            return progressColor
        } else if index == currentStage {
            return progressColor
        } else {
            return Color.gray.opacity(0.5)
        }
    }
}

// MARK: - Preview Extensions
extension BottlejiLiveActivityWidgetAttributes {
    fileprivate static var preview: BottlejiLiveActivityWidgetAttributes {
        BottlejiLiveActivityWidgetAttributes(
            dropId: "preview-drop-id",
            dropAddress: "123 Main Street",
            estimatedValue: "2.50 TND",
            createdAt: nil
        )
    }
}

extension BottlejiLiveActivityWidgetAttributes.ContentState {
    fileprivate static var pending: BottlejiLiveActivityWidgetAttributes.ContentState {
        BottlejiLiveActivityWidgetAttributes.ContentState(
            status: "pending",
            statusText: "Created",
            collectorName: nil,
            timeAgo: "Just now",
            distanceRemaining: nil
        )
    }
    
    fileprivate static var accepted: BottlejiLiveActivityWidgetAttributes.ContentState {
        BottlejiLiveActivityWidgetAttributes.ContentState(
            status: "accepted",
            statusText: "Accepted",
            collectorName: "Yassine Romdhane",
            timeAgo: "2 min ago",
            distanceRemaining: 500.0
        )
    }
    
    fileprivate static var onWay: BottlejiLiveActivityWidgetAttributes.ContentState {
        BottlejiLiveActivityWidgetAttributes.ContentState(
            status: "on_way",
            statusText: "On his way",
            collectorName: "Yassine Romdhane",
            timeAgo: "5 min ago",
            distanceRemaining: 250.0
        )
    }
    
    fileprivate static var collected: BottlejiLiveActivityWidgetAttributes.ContentState {
        BottlejiLiveActivityWidgetAttributes.ContentState(
            status: "collected",
            statusText: "Collected",
            collectorName: nil,
            timeAgo: "10 min ago",
            distanceRemaining: nil
        )
    }
}

// Preview for iOS 17+ (commented out for iOS 16.2 compatibility)
// Uncomment when targeting iOS 17+
/*
#Preview("Notification", as: .content, using: BottlejiLiveActivityWidgetAttributes.preview) {
   BottlejiLiveActivityWidgetLiveActivity()
} contentStates: {
    BottlejiLiveActivityWidgetAttributes.ContentState.pending
    BottlejiLiveActivityWidgetAttributes.ContentState.accepted
    BottlejiLiveActivityWidgetAttributes.ContentState.onWay
    BottlejiLiveActivityWidgetAttributes.ContentState.collected
}
*/
