//
//  DeviceCapabilitiesDetector.swift
//  Runner
//
//  Detects device capabilities for unified notification routing
//

import Foundation
import UIKit
import ActivityKit

@available(iOS 16.2, *)
class DeviceCapabilitiesDetector {
    static func detectCapabilities() -> [String: Any] {
        var capabilities: [String: Any] = [:]
        
        // Check Live Activity support (iOS 16.2+)
        let liveActivitySupported = ActivityAuthorizationInfo().areActivitiesEnabled
        capabilities["liveActivitySupported"] = liveActivitySupported
        
        // Check Dynamic Island support (iPhone 14 Pro and later)
        // Dynamic Island is hardware-dependent, not just iOS version
        let dynamicIslandSupported = UIDevice.current.userInterfaceIdiom == .phone && 
                                     UIScreen.main.bounds.height >= 932 // iPhone 14 Pro and later have this screen height
        capabilities["dynamicIslandSupported"] = dynamicIslandSupported
        
        // Get iOS version
        let iosVersion = UIDevice.current.systemVersion
        capabilities["iosVersion"] = iosVersion
        
        return capabilities
    }
}

