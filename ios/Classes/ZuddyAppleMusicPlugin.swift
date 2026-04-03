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
      handleRequestAuthorization(result: result)

    case "canPlayCatalogContent":
      handleCanPlayCatalogContent(result: result)

    case "searchSongs":
      handleSearchSongs(call: call, result: result)

    case "playSong":
      handlePlaySong(call: call, result: result)

    case "pausePlayback":
      handlePausePlayback(result: result)

    case "stopPlayback":
      handleStopPlayback(result: result)

    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

// MARK: - Private handlers
private extension ZuddyAppleMusicPlugin {
  func handleRequestAuthorization(result: @escaping FlutterResult) {
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
  }

  func handleCanPlayCatalogContent(result: @escaping FlutterResult) {
    if #available(iOS 15.0, *) {
      Task {
        do {
          let subscription = try await MusicSubscription.current
          result(subscription.canPlayCatalogContent)
        } catch {
          result(
            FlutterError(
              code: "SUBSCRIPTION_ERROR",
              message: "Failed to read MusicSubscription.current: \(error.localizedDescription)",
              details: String(describing: error)
            )
          )
        }
      }
    } else {
      result(false)
    }
  }

  func handleSearchSongs(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let term = args["term"] as? String else {
      result(
        FlutterError(
          code: "BAD_ARGS",
          message: "Missing term",
          details: nil
        )
      )
      return
    }

    let trimmedTerm = term.trimmingCharacters(in: .whitespacesAndNewlines)
    let limit = args["limit"] as? Int ?? 30

    if trimmedTerm.isEmpty {
      result([])
      return
    }

    if #available(iOS 15.0, *) {
      Task {
        do {
          let authStatus = MusicAuthorization.currentStatus
          guard authStatus == .authorized else {
            result(
              FlutterError(
                code: "SEARCH_ERROR",
                message: "Music authorization not authorized: \(authStatus.rawValue)",
                details: nil
              )
            )
            return
          }

          let subscription = try await MusicSubscription.current
          guard subscription.canPlayCatalogContent else {
            result(
              FlutterError(
                code: "SEARCH_ERROR",
                message: "User cannot play catalog content",
                details: nil
              )
            )
            return
          }

          var request = MusicCatalogSearchRequest(term: trimmedTerm, types: [Song.self])
          request.limit = max(1, limit)

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
          result(
            FlutterError(
              code: "SEARCH_ERROR",
              message: "MusicCatalogSearchRequest failed: \(error.localizedDescription)",
              details: String(describing: error)
            )
          )
        }
      }
    } else {
      result(
        FlutterError(
          code: "SEARCH_ERROR",
          message: "iOS version not supported",
          details: nil
        )
      )
    }
  }

  func handlePlaySong(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let songId = args["songId"] as? String else {
      result(
        FlutterError(
          code: "BAD_ARGS",
          message: "Missing songId",
          details: nil
        )
      )
      return
    }

    let trimmedSongId = songId.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmedSongId.isEmpty {
      result(
        FlutterError(
          code: "BAD_ARGS",
          message: "songId is empty",
          details: nil
        )
      )
      return
    }

    if #available(iOS 15.0, *) {
      Task {
        do {
          let request = MusicCatalogResourceRequest<Song>(
            matching: \.id,
            equalTo: MusicItemID(trimmedSongId)
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
          result(
            FlutterError(
              code: "PLAY_ERROR",
              message: "Failed to play song: \(error.localizedDescription)",
              details: String(describing: error)
            )
          )
        }
      }
    } else {
      result("ios_version_not_supported")
    }
  }

  func handlePausePlayback(result: @escaping FlutterResult) {
    if #available(iOS 15.0, *) {
      ApplicationMusicPlayer.shared.pause()
      result(nil)
    } else {
      result(nil)
    }
  }

  func handleStopPlayback(result: @escaping FlutterResult) {
    if #available(iOS 15.0, *) {
      ApplicationMusicPlayer.shared.stop()
      result(nil)
    } else {
      result(nil)
    }
  }
}
