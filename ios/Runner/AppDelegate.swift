import Flutter
import UIKit
import CoreLocation
import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Required for flutter_local_notifications background isolate handler.
    // Must be called before GeneratedPluginRegistrant.register.
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }

    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }

    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "template_app/location_service",
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { (call, result) in
        switch call.method {
        case "requestService":
          // iOS has no in-app GPS enable dialog; report current state.
          // Dispatch off main thread — locationServicesEnabled() can block.
          DispatchQueue.global(qos: .userInitiated).async {
            let enabled = CLLocationManager.locationServicesEnabled()
            DispatchQueue.main.async { result(enabled) }
          }
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
