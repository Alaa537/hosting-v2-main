import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioPlayer _player = AudioPlayer();

  // أصوات واقعية (روابط مباشرة)
  static const _startUrl = 'https://assets.mixkit.co/active_storage/sfx/2013/2013-preview.mp3'; // نجاح / تشغيل
  static const _stopUrl = 'https://assets.mixkit.co/active_storage/sfx/2017/2017-preview.mp3';  // إيقاف
  static const _notifUrl = 'https://assets.mixkit.co/active_storage/sfx/2358/2358-preview.mp3'; // إشعار

  static Future<void> playStart() async {
    try {
      await _player.stop();
      await _player.play(UrlSource(_startUrl), volume: 1.0);
    } catch (_) {}
  }

  static Future<void> playStop() async {
    try {
      await _player.stop();
      await _player.play(UrlSource(_stopUrl), volume: 1.0);
    } catch (_) {}
  }

  static Future<void> playNotification() async {
    try {
      await _player.stop();
      await _player.play(UrlSource(_notifUrl), volume: 1.0);
    } catch (_) {}
  }
}
