import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'zuddy_apple_music_method_channel.dart';

abstract class ZuddyAppleMusicPlatform extends PlatformInterface {
  /// Constructs a ZuddyAppleMusicPlatform.
  ZuddyAppleMusicPlatform() : super(token: _token);

  static final Object _token = Object();

  static ZuddyAppleMusicPlatform _instance = MethodChannelZuddyAppleMusic();

  /// The default instance of [ZuddyAppleMusicPlatform] to use.
  ///
  /// Defaults to [MethodChannelZuddyAppleMusic].
  static ZuddyAppleMusicPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [ZuddyAppleMusicPlatform] when
  /// they register themselves.
  static set instance(ZuddyAppleMusicPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
