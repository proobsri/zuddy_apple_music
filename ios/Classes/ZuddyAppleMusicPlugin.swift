import Flutter
import UIKit
import MusicKit

public class ZuddyAppleMusicPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "zuddy_apple_music",
      binaryMessenger: registrar.messenger()
    )
    let instance = ZuddyAppleMusicPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "requestAuthorization":
      Task {
        let status = await MusicAuthorization.request()
        switch status {
        case .authorized:
          result("authorized")
        case .denied:
          result("denied")
        case .restricted:
          result("restricted")
        case .notDetermined:
          result("notDetermined")
        @unknown default:
          result("unknown")
        }
      }

    case "canPlayCatalogContent":
      Task {
        do {
          let subscription = try await MusicSubscription.current
          result(subscription.canPlayCatalogContent)
        } catch {
          result(FlutterError(
            code: "SUBSCRIPTION_ERROR",
            message: error.localizedDescription,
            details: nil
          ))
        }
      }

    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
