import Flutter
import UIKit
import GoogleMaps
import FirebaseAuth
import ActivityKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterStreamHandler {
  // EventChannel for push tokens (for backend API usage)
  var eventSink: FlutterEventSink?
  let eventChannelName = "com.botleji/live_activity_events"
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyCwq4Iy4ieyeEX-i7HVsBS_PfbdJnA300E")
    GeneratedPluginRegistrant.register(with: self)
    
    // Set up notification center delegate for push notifications
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }
    
    // Register Live Activity plugin with MethodChannel
    if #available(iOS 16.2, *) {
      if let controller = window?.rootViewController as? FlutterViewController {
        // MethodChannel for Live Activity operations
        let liveActivityChannel = FlutterMethodChannel(
          name: "com.botleji/live_activity",
          binaryMessenger: controller.binaryMessenger
        )
        let liveActivityPlugin = LiveActivityPlugin()
        liveActivityChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
          liveActivityPlugin.handle(call, result: result)
        }
        print("✅ Live Activity MethodChannel registered successfully")
        
        // EventChannel for push tokens (for backend API)
        let eventChannel = FlutterEventChannel(
          name: eventChannelName,
          binaryMessenger: controller.binaryMessenger
        )
        eventChannel.setStreamHandler(self)
        print("✅ Live Activity EventChannel registered successfully")
        
        // Observe push tokens for backend API
        observePushTokens()
      }
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // MARK: - FlutterStreamHandler (for EventChannel)
  
  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    self.eventSink = events
    print("✅ Live Activity EventChannel listener started")
    return nil
  }
  
  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    self.eventSink = nil
    print("✅ Live Activity EventChannel listener cancelled")
    return nil
  }
  
  private func sendEvent(value: [String: Any?]) {
    guard let eventSink = self.eventSink else { return }
    eventSink(value)
  }
  
  // MARK: - Push Token Observation (for backend API)
  
  @available(iOS 16.2, *)
  private func observePushTokens() {
    // Observe pushToStartToken (iOS 17.2+) - token for starting activities
    if #available(iOS 17.2, *) {
      Task {
        for await tokenData in Activity<BottlejiLiveActivityWidgetAttributes>.pushToStartTokenUpdates {
          let token = tokenData.map { String(format: "%02x", $0) }.joined()
          print("📱 pushToStartToken -> \(token)")
          sendEvent(value: [
            "eventType": "pushToStartToken",
            "value": token,
          ])
        }
      }
    }
    
    // Observe pushToUpdateToken - tokens from each activity
    Task {
      for await activityData in Activity<BottlejiLiveActivityWidgetAttributes>.activityUpdates {
        Task {
          for await tokenData in activityData.pushTokenUpdates {
            let token = tokenData.map { String(format: "%02x", $0) }.joined()
            let activityId = activityData.id
            let dropId = activityData.attributes.dropId // Get dropId from attributes
            print("📱 pushToUpdateToken -> \(token) for activity: \(activityId), dropId: \(dropId)")
            sendEvent(value: [
              "eventType": "pushToUpdateToken",
              "value": token,
              "activityId": activityId,
              "dropId": dropId, // Include dropId in the event
            ])
          }
        }
      }
    }
  }
  
  // MARK: - Push Notification Handling (for backend API)
  
  @available(iOS 10.0, *)
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    // Show notification even when app is in foreground
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .list, .sound, .badge])
    } else {
      completionHandler([.alert, .sound, .badge])
    }
  }
  
  @available(iOS 10.0, *)
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    // Handle notification tap
    let userInfo = response.notification.request.content.userInfo
    print("📱 Notification tapped: \(userInfo)")
    completionHandler()
  }
  
  // Handle URL schemes (for deep linking from Live Activity and Firebase Auth reCAPTCHA)
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    print("🔗 AppDelegate: Received URL: \(url.absoluteString)")
    print("🔗 AppDelegate: URL scheme: \(url.scheme ?? "nil")")
    
    // Handle Firebase Auth reCAPTCHA URLs (app-1-414913880297-ios-4621c0674928dcfb8a9078://...)
    if url.scheme == "app-1-414913880297-ios-4621c0674928dcfb8a9078" {
      print("🔗 AppDelegate: Firebase Auth reCAPTCHA URL detected")
      // Firebase should handle this automatically with FirebaseAppDelegateProxyEnabled = true
      // But explicitly handle it as a safety measure
      if Auth.auth().canHandle(url) {
        print("🔗 AppDelegate: Firebase Auth can handle this URL, returning true")
        return true
      }
    }
    
    // Handle botleji://navigation?dropId=xxx URLs from Live Activity
    if url.scheme == "botleji" && url.host == "navigation" {
      print("🔗 AppDelegate: botleji deep link detected")
      let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
      if let dropId = components?.queryItems?.first(where: { $0.name == "dropId" })?.value {
        // Send to Flutter via method channel
        if let controller = window?.rootViewController as? FlutterViewController {
          let channel = FlutterMethodChannel(
            name: "com.botleji/deep_link",
            binaryMessenger: controller.engine.binaryMessenger
          )
          channel.invokeMethod("navigateToNavigation", arguments: ["dropId": dropId])
        }
        return true
      }
    }
    
    // Let parent class handle other URLs (Firebase proxy should handle Firebase Auth URLs)
    let handled = super.application(app, open: url, options: options)
    print("🔗 AppDelegate: Parent class handled URL: \(handled)")
    return handled
  }
}
