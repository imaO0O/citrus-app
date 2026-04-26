import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let controller = window?.rootViewController as? FlutterViewController
    let channel = FlutterMethodChannel(
      name: "com.citrus.app/dynamic_icon",
      binaryMessenger: controller?.binaryMessenger ?? engineBridge.binaryMessenger
    )

    channel.setMethodCallHandler { (call, result) in
      switch call.method {
      case "setIcon":
        let isDark = call.arguments as? [String: Any]?? ?? nil
        let darkValue = call.arguments as? [String: Any]
        let isDarkMode = darkValue?["isDark"] as? Bool ?? false

        if isDarkMode {
          UIApplication.shared.setAlternateIconName("AppIconDark") { error in
            if let error = error {
              result(FlutterError(code: "ICON_ERROR", message: error.localizedDescription, details: nil))
            } else {
              result(nil)
            }
          }
        } else {
          UIApplication.shared.setAlternateIconName(nil) { error in
            if let error = error {
              result(FlutterError(code: "ICON_ERROR", message: error.localizedDescription, details: nil))
            } else {
              result(nil)
            }
          }
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
