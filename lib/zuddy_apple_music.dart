import 'package:flutter/services.dart';

class ZuddyAppleMusic {
  static const MethodChannel _channel = MethodChannel('zuddy_apple_music');

  static Future<String> requestAuthorization() async {
    final result = await _channel.invokeMethod<String>('requestAuthorization');
    return result ?? 'unknown';
  }

  static Future<bool> canPlayCatalogContent() async {
    final result = await _channel.invokeMethod<bool>('canPlayCatalogContent');
    return result ?? false;
  }

  static Future<List<dynamic>> searchSongs(
    String term, {
    int limit = 30,
  }) async {
    final result = await _channel.invokeMethod<List<dynamic>>('searchSongs', {
      'term': term,
      'limit': limit,
    });
    return result ?? [];
  }

  static Future<String> playSong(String songId) async {
    final result = await _channel.invokeMethod<String>('playSong', {
      'songId': songId,
    });
    return result ?? 'failed';
  }

  static Future<void> pausePlayback() async {
    await _channel.invokeMethod('pausePlayback');
  }

  static Future<void> stopPlayback() async {
    await _channel.invokeMethod('stopPlayback');
  }
}
