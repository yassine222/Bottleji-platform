import Flutter
import UIKit

@available(iOS 16.1, *)
public class LiveActivityPlugin: NSObject, FlutterPlugin {
    private let liveActivityManager = LiveActivityManager.shared
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.botleji/live_activity",
            binaryMessenger: registrar.messenger()
        )
        let instance = LiveActivityPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "isActivityKitAvailable":
            if #available(iOS 16.1, *) {
                result(liveActivityManager.isActivityKitAvailable())
            } else {
                result(false)
            }
            
        case "startActivity":
            guard let args = call.arguments as? [String: Any],
                  let dropId = args["dropId"] as? String,
                  let dropAddress = args["dropAddress"] as? String,
                  let elapsedTime = args["elapsedTime"] as? String,
                  let distance = args["distance"] as? String,
                  let eta = args["eta"] as? String,
                  let transportMode = args["transportMode"] as? String else {
                result(FlutterError(
                    code: "INVALID_ARGUMENTS",
                    message: "Missing required arguments",
                    details: nil
                ))
                return
            }
            
            if #available(iOS 16.1, *) {
                liveActivityManager.startActivity(
                    dropId: dropId,
                    dropAddress: dropAddress,
                    elapsedTime: elapsedTime,
                    distance: distance,
                    eta: eta,
                    transportMode: transportMode
                )
                result(nil)
            } else {
                result(FlutterError(
                    code: "NOT_SUPPORTED",
                    message: "iOS 16.1+ required",
                    details: nil
                ))
            }
            
        case "updateActivity":
            guard let args = call.arguments as? [String: Any],
                  let elapsedTime = args["elapsedTime"] as? String,
                  let distance = args["distance"] as? String,
                  let eta = args["eta"] as? String else {
                result(FlutterError(
                    code: "INVALID_ARGUMENTS",
                    message: "Missing required arguments",
                    details: nil
                ))
                return
            }
            
            if #available(iOS 16.1, *) {
                liveActivityManager.updateActivity(
                    elapsedTime: elapsedTime,
                    distance: distance,
                    eta: eta
                )
                result(nil)
            } else {
                result(FlutterError(
                    code: "NOT_SUPPORTED",
                    message: "iOS 16.1+ required",
                    details: nil
                ))
            }
            
        case "endActivity":
            if #available(iOS 16.1, *) {
                liveActivityManager.endActivity()
                result(nil)
            } else {
                result(FlutterError(
                    code: "NOT_SUPPORTED",
                    message: "iOS 16.1+ required",
                    details: nil
                ))
            }
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}

