import Flutter
import UIKit
import GoogleMaps

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
  
  // Handle URL schemes (for deep linking from Live Activity)
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    // Handle botleji://navigation?dropId=xxx URLs from Live Activity
    if url.scheme == "botleji" && url.host == "navigation" {
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
    return super.application(app, open: url, options: options)
  }
}
