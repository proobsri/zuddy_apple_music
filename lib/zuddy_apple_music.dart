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

  static Future<List<dynamic>> searchSongs(String term) async {
    final result = await _channel.invokeMethod<List<dynamic>>('searchSongs', {
      'term': term,
    });
    return result ?? [];
  }
}
