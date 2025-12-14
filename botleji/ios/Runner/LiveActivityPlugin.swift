//
//  LiveActivityPlugin.swift
//  Runner
//
//  Flutter MethodChannel plugin for Live Activities
//  Follows the article's implementation pattern
//

import Flutter
import UIKit

public class LiveActivityPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.botleji/live_activity",
            binaryMessenger: registrar.messenger()
        )
        let instance = LiveActivityPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if #available(iOS 16.2, *) {
            let manager = LiveActivityManager.shared
            
            switch call.method {
            case "isActivityKitAvailable":
                result(manager.isActivityKitAvailable())
                
            case "startDropTimelineActivity":
                manager.startDropTimelineActivity(data: call.arguments as? [String: Any])
                // Return dropId as identifier (actual activityId will be available later via getActivityId)
                // This matches the article's pattern where startLiveActivity doesn't return a value
                if let dropId = (call.arguments as? [String: Any])?["dropId"] as? String {
                    result(dropId)
                } else {
                    result(nil)
                }
                
            case "updateDropTimelineActivity":
                manager.updateDropTimelineActivity(data: call.arguments as? [String: Any])
                result("updated")
                
            case "endDropTimelineActivity":
                if let args = call.arguments as? [String: Any],
                   let dropId = args["dropId"] as? String {
                    manager.endDropTimelineActivity(dropId: dropId)
                    result("ended")
                } else {
                    // End all activities
                    manager.endDropTimelineActivity()
                    result("ended_all")
                }
                
            case "getPushToken":
                guard let args = call.arguments as? [String: Any],
                      let activityId = args["activityId"] as? String else {
                    result(FlutterError(code: "INVALID_ARGUMENTS", message: "activityId is required", details: nil))
                    return
                }
                
                // If activityId is actually a dropId, get the real activityId first
                if let realActivityId = manager.getActivityId(dropId: activityId) {
                    let pushToken = manager.getPushToken(activityId: realActivityId)
                    result(pushToken)
                } else {
                    // Try as activityId directly
                    let pushToken = manager.getPushToken(activityId: activityId)
                    result(pushToken)
                }
                
            case "getAllActivitiesIds":
                let ids = manager.getAllActivitiesIds()
                result(ids)
                
            default:
                result(FlutterMethodNotImplemented)
            }
        } else {
            // iOS < 16.1 - Live Activities not supported
            result(FlutterError(code: "NOT_SUPPORTED", message: "Live Activities require iOS 16.1+", details: nil))
        }
    }
    
}

