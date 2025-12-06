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
    
    // Register Live Activity plugin
    if #available(iOS 16.1, *) {
      if let controller = window?.rootViewController as? FlutterViewController {
        let registrar = controller.engine.registrar(forPlugin: "LiveActivityPlugin")
        LiveActivityPlugin.register(with: registrar)
      }
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
