import Foundation
import ActivityKit

/// Activity attributes for collection live activity
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

/// Activity attributes for drop timeline (household mode)
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

/// Manager for Dynamic Island and Live Activities
@available(iOS 16.1, *)
class LiveActivityManager {
    static let shared = LiveActivityManager()
    private var currentActivity: Activity<CollectionActivityAttributes>?
    private var currentDropTimelineActivity: Activity<DropTimelineActivityAttributes>?
    
    private init() {}
    
    /// Check if ActivityKit is available
    func isActivityKitAvailable() -> Bool {
        if #available(iOS 16.1, *) {
            let authInfo = ActivityAuthorizationInfo()
            let isEnabled = authInfo.areActivitiesEnabled
            
            print("🔵 ActivityKit Authorization Info:")
            print("   - Activities enabled: \(isEnabled)")
            
            if #available(iOS 16.2, *) {
                let isFrequentPushesEnabled = authInfo.frequentPushesEnabled
                print("   - Frequent pushes enabled: \(isFrequentPushesEnabled)")
            }
            
            if !isEnabled {
                print("⚠️ Live Activities are disabled in Settings")
                print("⚠️ Go to Settings → Face ID & Passcode → Allow Live Activities")
            }
            
            return isEnabled
        }
        print("⚠️ iOS version is below 16.1")
        return false
    }
    
    /// Start live activity
    func startActivity(
        dropId: String,
        dropAddress: String,
        elapsedTime: String,
        distance: String,
        eta: String,
        transportMode: String,
        estimatedValue: String,
        progressPercentage: Int
    ) {
        guard isActivityKitAvailable() else {
            print("⚠️ ActivityKit not available or not enabled")
            return
        }
        
        // End any existing activity first
        endActivity()
        
        let attributes = CollectionActivityAttributes(
            dropId: dropId,
            dropAddress: dropAddress,
            transportMode: transportMode,
            estimatedValue: estimatedValue
        )
        
        let contentState = CollectionActivityAttributes.ContentState(
            elapsedTime: elapsedTime,
            distance: distance,
            eta: eta,
            progressPercentage: progressPercentage
        )
        
        do {
            let activity = try Activity<CollectionActivityAttributes>.request(
                attributes: attributes,
                contentState: contentState,
                pushType: nil
            )
            
            currentActivity = activity
            print("✅ Live Activity started: \(dropId)")
            print("✅ Activity ID: \(activity.id)")
            print("✅ Activity state: \(activity.activityState)")
            
            // Important: Widget Extension is required for UI to display
            print("⚠️ NOTE: Widget Extension must be set up for activity to display")
            print("⚠️ Without Widget Extension, activity exists but won't show UI")
        } catch {
            print("❌ Error starting Live Activity: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            print("❌ Error type: \(type(of: error))")
        }
    }
    
    /// Update live activity
    func updateActivity(
        elapsedTime: String,
        distance: String,
        eta: String,
        progressPercentage: Int
    ) {
        guard let activity = currentActivity else {
            print("⚠️ No active activity to update")
            return
        }
        
        let contentState = CollectionActivityAttributes.ContentState(
            elapsedTime: elapsedTime,
            distance: distance,
            eta: eta,
            progressPercentage: progressPercentage
        )
        
        Task {
            await activity.update(using: contentState)
            print("✅ Live Activity updated")
        }
    }
    
    /// End live activity
    func endActivity() {
        guard let activity = currentActivity else {
            return
        }
        
        Task {
            await activity.end(dismissalPolicy: .immediate)
            currentActivity = nil
            print("✅ Live Activity ended")
        }
    }
    
    // MARK: - Drop Timeline Activity (Household Mode)
    
    /// Start drop timeline activity
    func startDropTimelineActivity(
        dropId: String,
        dropAddress: String,
        estimatedValue: String,
        status: String,
        statusText: String,
        collectorName: String?,
        timeAgo: String,
        createdAt: String
    ) {
        guard isActivityKitAvailable() else {
            print("⚠️ ActivityKit not available or not enabled")
            return
        }
        
        // End any existing drop timeline activity for this drop
        if let existing = currentDropTimelineActivity, existing.attributes.dropId == dropId {
            endDropTimelineActivity()
        }
        
        let attributes = DropTimelineActivityAttributes(
            dropId: dropId,
            dropAddress: dropAddress,
            estimatedValue: estimatedValue,
            createdAt: createdAt
        )
        
        let contentState = DropTimelineActivityAttributes.ContentState(
            status: status,
            statusText: statusText,
            collectorName: collectorName,
            timeAgo: timeAgo
        )
        
        do {
            let activity = try Activity<DropTimelineActivityAttributes>.request(
                attributes: attributes,
                contentState: contentState,
                pushType: nil
            )
            
            currentDropTimelineActivity = activity
            print("✅ Drop Timeline Activity started: \(dropId)")
            print("✅ Status: \(statusText)")
        } catch {
            print("❌ Error starting Drop Timeline Activity: \(error)")
        }
    }
    
    /// Update drop timeline activity
    func updateDropTimelineActivity(
        status: String,
        statusText: String,
        collectorName: String?,
        timeAgo: String
    ) {
        guard let activity = currentDropTimelineActivity else {
            print("⚠️ No active drop timeline activity to update")
            return
        }
        
        let contentState = DropTimelineActivityAttributes.ContentState(
            status: status,
            statusText: statusText,
            collectorName: collectorName,
            timeAgo: timeAgo
        )
        
        Task {
            await activity.update(using: contentState)
            print("✅ Drop Timeline Activity updated: \(statusText)")
        }
    }
    
    /// End drop timeline activity
    func endDropTimelineActivity() {
        guard let activity = currentDropTimelineActivity else {
            return
        }
        
        Task {
            await activity.end(dismissalPolicy: .immediate)
            currentDropTimelineActivity = nil
            print("✅ Drop Timeline Activity ended")
        }
    }
    
    /// End drop timeline activity for specific drop
    func endDropTimelineActivity(dropId: String) {
        guard let activity = currentDropTimelineActivity,
              activity.attributes.dropId == dropId else {
            return
        }
        
        endDropTimelineActivity()
    }
}

