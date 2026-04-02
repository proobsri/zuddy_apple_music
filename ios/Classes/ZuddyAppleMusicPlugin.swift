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

      let limit = args["limit"] as? Int ?? 30

      if #available(iOS 15.0, *) {
        Task {
          do {
            var request = MusicCatalogSearchRequest(term: term, types: [Song.self])
            request.limit = limit
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

    case "playSong":
      guard let args = call.arguments as? [String: Any],
            let songId = args["songId"] as? String else {
        result(FlutterError(
          code: "BAD_ARGS",
          message: "Missing songId",
          details: nil
        ))
        return
      }

      if #available(iOS 15.0, *) {
        Task {
          do {
            let request = MusicCatalogResourceRequest<Song>(
              matching: \.id,
              equalTo: MusicItemID(songId)
            )
            let response = try await request.response()
            guard let song = response.items.first else {
              result("not_found")
              return
            }

            let player = ApplicationMusicPlayer.shared
            player.queue = [song]
            try await player.play()

            result("playing")
          } catch {
            result(FlutterError(
              code: "PLAY_ERROR",
              message: error.localizedDescription,
              details: nil
            ))
          }
        }
      } else {
        result("ios_version_not_supported")
      }

    case "pausePlayback":
      if #available(iOS 15.0, *) {
        Task {
          do {
            try await ApplicationMusicPlayer.shared.pause()
            result(nil)
          } catch {
            result(FlutterError(
              code: "PAUSE_ERROR",
              message: error.localizedDescription,
              details: nil
            ))
          }
        }
      } else {
        result(nil)
      }

    case "stopPlayback":
      if #available(iOS 15.0, *) {
        Task {
          do {
            try await ApplicationMusicPlayer.shared.stop()
            result(nil)
          } catch {
            result(FlutterError(
              code: "STOP_ERROR",
              message: error.localizedDescription,
              details: nil
            ))
          }
        }
      } else {
        result(nil)
      }

    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
