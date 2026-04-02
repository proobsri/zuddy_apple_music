import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'zuddy_apple_music_platform_interface.dart';

/// An implementation of [ZuddyAppleMusicPlatform] that uses method channels.
class MethodChannelZuddyAppleMusic extends ZuddyAppleMusicPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('zuddy_apple_music');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
