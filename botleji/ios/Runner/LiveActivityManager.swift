//
//  LiveActivityManager.swift
//  Runner
//
//  Live Activity Manager for ActivityKit operations
//  Follows the article's implementation pattern
//

import Foundation
import ActivityKit

@available(iOS 16.2, *)
class LiveActivityManager {
    static let shared = LiveActivityManager()
    
    private init() {}
    
    // Store activities by dropId (one activity per drop)
    private var liveActivities: [String: Activity<BottlejiLiveActivityWidgetAttributes>] = [:]
    
    // Store push tokens by activityId
    private var activityTokens: [String: String] = [:] // activityId -> pushToken
    
    // MARK: - Start Drop Timeline Activity
    
    func startDropTimelineActivity(data: [String: Any]?) {
        guard let info = data else {
            print("❌ No data provided for starting Live Activity")
            return
        }
        
        print("🔄 [LiveActivityManager] Received data: \(info)")
        
        // Extract attributes (static, don't change)
        let dropId = info["dropId"] as? String ?? ""
        let dropAddress = info["dropAddress"] as? String ?? ""
        let estimatedValue = info["estimatedValue"] as? String ?? ""
        let createdAt = info["createdAt"] as? String
        
        print("🔄 [LiveActivityManager] Attributes - dropId: \(dropId), address: \(dropAddress), value: \(estimatedValue)")
        
        // Create attributes
        let attributes = BottlejiLiveActivityWidgetAttributes(
            dropId: dropId,
            dropAddress: dropAddress,
            estimatedValue: estimatedValue,
            createdAt: createdAt
        )
        
        // Extract content state (dynamic, changes with updates)
        let status = info["status"] as? String
        let statusText = info["statusText"] as? String
        let collectorName = info["collectorName"] as? String
        let timeAgo = info["timeAgo"] as? String ?? ""
        let distanceRemaining = info["distanceRemaining"] as? Double
        
        print("🔄 [LiveActivityManager] ContentState - status: \(status ?? "nil"), statusText: \(statusText ?? "nil"), timeAgo: \(timeAgo)")
        
        let state = BottlejiLiveActivityWidgetAttributes.ContentState(
            status: status,
            statusText: statusText,
            collectorName: collectorName,
            timeAgo: timeAgo,
            distanceRemaining: distanceRemaining
        )
        
        Task {
            do {
                let activity = try await Activity<BottlejiLiveActivityWidgetAttributes>.request(
                    attributes: attributes,
                    content: ActivityContent(state: state, staleDate: nil),
                    pushType: .token
                )
                
                let activityId = activity.id
                liveActivities[dropId] = activity
                
                print("✅ Live Activity started: \(activityId) for drop: \(dropId)")
                
                // IMPORTANT: Observe pushTokenUpdates immediately after creating the activity
                // This ensures we capture the token as soon as it's available (asynchronously)
                // The pushTokenUpdates async sequence will emit the first token when ready,
                // and any subsequent token updates
                Task {
                    await updatePushToken(for: activityId, activity: activity, dropId: dropId)
                }
            } catch {
                print("❌ Error starting Live Activity: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Update Drop Timeline Activity
    
    func updateDropTimelineActivity(data: [String: Any]?) {
        guard let info = data else {
            print("❌ No data provided for updating Live Activity")
            return
        }
        
        // Get dropId to find the activity
        guard let dropId = info["dropId"] as? String,
              let activity = liveActivities[dropId] else {
            print("❌ Activity not found for dropId")
            return
        }
        
        // Extract updated content state
        let status = info["status"] as? String
        let statusText = info["statusText"] as? String
        let collectorName = info["collectorName"] as? String
        let timeAgo = info["timeAgo"] as? String ?? ""
        let distanceRemaining = info["distanceRemaining"] as? Double
        
        let updatedState = BottlejiLiveActivityWidgetAttributes.ContentState(
            status: status,
            statusText: statusText,
            collectorName: collectorName,
            timeAgo: timeAgo,
            distanceRemaining: distanceRemaining
        )
        
        Task {
            await activity.update(using: updatedState)
            print("✅ Live Activity updated for drop: \(dropId)")
        }
    }
    
    // MARK: - End Drop Timeline Activity
    
    func endDropTimelineActivity(dropId: String? = nil) {
        if let dropId = dropId, let activity = liveActivities[dropId] {
            // End specific activity
            Task {
                await activity.end(dismissalPolicy: .immediate)
                liveActivities.removeValue(forKey: dropId)
                print("✅ Live Activity ended for drop: \(dropId)")
            }
        } else {
            // End all activities
            Task {
                for (id, activity) in liveActivities {
                    await activity.end(dismissalPolicy: .immediate)
                    print("✅ Live Activity ended for drop: \(id)")
                }
                liveActivities.removeAll()
            }
        }
    }
    
    // MARK: - Get Push Token
    
    func getPushToken(activityId: String) -> String? {
        return activityTokens[activityId]
    }
    
    // MARK: - Get Activity ID by Drop ID
    
    func getActivityId(dropId: String) -> String? {
        return liveActivities[dropId]?.id
    }
    
    // MARK: - Get All Activity IDs
    
    func getAllActivitiesIds() -> [String] {
        return Array(liveActivities.keys)
    }
    
    // MARK: - Check ActivityKit Availability
    
    func isActivityKitAvailable() -> Bool {
        return ActivityAuthorizationInfo().areActivitiesEnabled
    }
    
    // MARK: - Private Helpers
    
    // Callback to send push tokens to Flutter (set by AppDelegate)
    var pushTokenCallback: ((String, String, String) -> Void)? // (activityId, token, dropId)
    
    private func updatePushToken(for activityId: String, activity: Activity<BottlejiLiveActivityWidgetAttributes>, dropId: String) async {
        // Observe pushTokenUpdates - this async sequence will emit the first token when available
        // and any subsequent token updates
        for await tokenData in activity.pushTokenUpdates {
            // Convert Data to hex string
            let tokenString = tokenData.hexString
            activityTokens[activityId] = tokenString
            print("📱 [LiveActivityManager] Push token received for activity \(activityId), dropId: \(dropId)")
            print("📱 [LiveActivityManager] Token: \(tokenString)")
            
            // Send token to Flutter immediately via callback (handled by AppDelegate)
            pushTokenCallback?(activityId, tokenString, dropId)
        }
    }
}

// MARK: - Data Extension for Hex String

extension Data {
    var hexString: String {
        return map { String(format: "%02x", $0) }.joined()
    }
}
