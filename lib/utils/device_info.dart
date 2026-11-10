import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import '../services/storage.dart';

/// Stable device id + client-side device lock.
/// device_id format: "flt-and-" + sha256(fingerprint)[0..24]
class DeviceInfo {
  static String? _cachedId;

  /// Returns a *stable* device id that survives app reinstalls.
  static Future<String> deviceId() async {
    if (_cachedId != null) return _cachedId!;

    // 1) already stored?
    final existing = await Store.readDeviceId();
    if (existing != null && existing.isNotEmpty) {
      // ترحيل النسخ القديمة التي كانت تستخدم flt- إلى العقد الحالي flt-and-.
      final migrated = existing.startsWith('flt-') && !existing.startsWith('flt-and-')
          ? 'flt-and-${existing.substring(4)}'
          : existing;
      if (migrated != existing) await Store.saveDeviceId(migrated);
      _cachedId = migrated;
      return migrated;
    }

    // 2) generate from fingerprint
    String raw = 'unknown';
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final a = await DeviceInfoPlugin().androidInfo;
        raw = '${a.id}|${a.model}|${a.device}|${a.fingerprint}';
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final i = await DeviceInfoPlugin().iosInfo;
        raw = '${i.identifierForVendor}|${i.model}|${i.systemVersion}';
      } else {
        final rnd = Random.secure();
        raw = List.generate(16, (_) => rnd.nextInt(256)).join('-');
      }
    } catch (_) {
      final rnd = Random.secure();
      raw = List.generate(16, (_) => rnd.nextInt(256)).join('-');
    }

    final hash = sha256.convert(utf8.encode(raw)).toString();
    final id = 'flt-and-${hash.substring(0, 24)}';
    await Store.saveDeviceId(id);
    _cachedId = id;
    return id;
  }

  static String get platform {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android: return 'android';
      case TargetPlatform.iOS: return 'ios';
      case TargetPlatform.macOS: return 'macos';
      case TargetPlatform.windows: return 'windows';
      case TargetPlatform.linux: return 'linux';
      default: return 'unknown';
    }
  }

  /// Human-readable model name for the /auth body.
  static Future<String> modelName() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final a = await DeviceInfoPlugin().androidInfo;
        return '${a.manufacturer} ${a.model}';
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final i = await DeviceInfoPlugin().iosInfo;
        return i.name;
      }
    } catch (_) {}
    return 'Unknown';
  }

  // ---------------- client-side lock helpers ----------------
  static Future<String?> checkDeviceLock(String username) async {
    final locked = await Store.getLockedUser();
    if (locked == null || locked.isEmpty) return null;
    if (locked.toLowerCase() == username.toLowerCase()) return null;
    return 'هذا الجهاز مسجّل بحساب آخر: $locked';
  }

  static Future<void> lockDeviceTo(String username) async {
    await Store.setLockedUser(username);
  }

  static Future<void> unlockDevice() async {
    await Store.setLockedUser(null);
  }
}
