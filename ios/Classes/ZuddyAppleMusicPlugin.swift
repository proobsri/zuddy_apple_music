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
      if #available(iOS 15.0, *) {
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
      } else {
        result("ios_version_not_supported")
      }

    case "canPlayCatalogContent":
      if #available(iOS 15.0, *) {
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
      } else {
        result(false)
      }

    case "searchSongs":
      guard let args = call.arguments as? [String: Any],
            let term = args["term"] as? String else {
        result(FlutterError(
          code: "BAD_ARGS",
          message: "Missing term",
          details: nil
        ))
        return
      }

      if #available(iOS 15.0, *) {
        Task {
          do {
            var request = MusicCatalogSearchRequest(term: term, types: [Song.self])
            request.limit = 20
            let response = try await request.response()

            let songs: [[String: Any]] = response.songs.map { song in
              let artworkUrl = song.artwork?.url(width: 300, height: 300)?.absoluteString ?? ""
              let albumTitle = song.albumTitle ?? ""

              return [
                "id": song.id.rawValue,
                "title": song.title,
                "artist": song.artistName,
                "albumTitle": albumTitle,
                "artworkUrl": artworkUrl,
                "provider": "apple_music"
              ]
            }

            result(songs)
          } catch {
            result(FlutterError(
              code: "SEARCH_ERROR",
              message: error.localizedDescription,
              details: nil
            ))
          }
        }
      } else {
        result([])
      }

    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
