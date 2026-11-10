import 'package:shared_preferences/shared_preferences.dart';

/// Client-side device lock.
///
/// Stores the FIRST username that successfully logged in on this device.
/// After that, any attempt to log in or register with a *different*
/// username is refused.
///
/// NOTE: this is a client-side guard. Real enforcement requires server
/// support (device fingerprint table). This is best-effort.
class DeviceLock {
  static const _kLocked = 'device_locked_username';
  static const _kDeviceId = 'device_id';

  /// Returns the locked username, or null if the device is free.
  static Future<String?> lockedUser() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kLocked);
  }

  /// Locks the device to [username] (idempotent).
  static Future<void> lock(String username) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kLocked, username);
  }

  /// Check whether [username] may use this device.
  /// Returns null if OK, or an error message.
  static Future<String?> check(String username) async {
    final locked = await lockedUser();
    if (locked == null) return null;
    if (locked.toLowerCase() == username.toLowerCase()) return null;
    return 'هذا الجهاز مربوط بحساب "$locked" بالفعل.\n'
           'لا يمكن استخدام حساب آخر من نفس الجهاز.';
  }

  /// Admin-only escape hatch.
  static Future<void> unlock() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kLocked);
  }

  /// Stable per-install id.
  static Future<String> deviceId() async {
    final p = await SharedPreferences.getInstance();
    var id = p.getString(_kDeviceId);
    if (id == null) {
      id = DateTime.now().microsecondsSinceEpoch.toRadixString(36) +
           '-' + (identityHashCode(Object()).toRadixString(36));
      await p.setString(_kDeviceId, id);
    }
    return id;
  }
}
