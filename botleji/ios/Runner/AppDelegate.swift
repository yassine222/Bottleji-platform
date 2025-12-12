import Flutter
import UIKit
import GoogleMaps
import FirebaseAuth

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyCwq4Iy4ieyeEX-i7HVsBS_PfbdJnA300E")
    GeneratedPluginRegistrant.register(with: self)
    
    // Register Live Activity plugin after launch
    if #available(iOS 16.1, *) {
      DispatchQueue.main.async {
        if let controller = self.window?.rootViewController as? FlutterViewController,
           let registrar = controller.engine.registrar(forPlugin: "LiveActivityPlugin") {
          LiveActivityPlugin.register(with: registrar)
        }
      }
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
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
