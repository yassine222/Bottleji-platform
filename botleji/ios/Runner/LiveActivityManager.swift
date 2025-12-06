import Foundation
import ActivityKit

/// Activity attributes for collection live activity
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

/// Manager for Dynamic Island and Live Activities
@available(iOS 16.1, *)
class LiveActivityManager {
    static let shared = LiveActivityManager()
    private var currentActivity: Activity<CollectionActivityAttributes>?
    
    private init() {}
    
    /// Check if ActivityKit is available
    func isActivityKitAvailable() -> Bool {
        if #available(iOS 16.1, *) {
            return ActivityAuthorizationInfo().areActivitiesEnabled
        }
        return false
    }
    
    /// Start live activity
    func startActivity(
        dropId: String,
        dropAddress: String,
        elapsedTime: String,
        distance: String,
        eta: String,
        transportMode: String
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
            transportMode: transportMode
        )
        
        let contentState = CollectionActivityAttributes.ContentState(
            elapsedTime: elapsedTime,
            distance: distance,
            eta: eta
        )
        
        do {
            let activity = try Activity<CollectionActivityAttributes>.request(
                attributes: attributes,
                contentState: contentState,
                pushType: nil
            )
            
            currentActivity = activity
            print("✅ Live Activity started: \(dropId)")
        } catch {
            print("❌ Error starting Live Activity: \(error)")
        }
    }
    
    /// Update live activity
    func updateActivity(
        elapsedTime: String,
        distance: String,
        eta: String
    ) {
        guard let activity = currentActivity else {
            print("⚠️ No active activity to update")
            return
        }
        
        let contentState = CollectionActivityAttributes.ContentState(
            elapsedTime: elapsedTime,
            distance: distance,
            eta: eta
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
}

