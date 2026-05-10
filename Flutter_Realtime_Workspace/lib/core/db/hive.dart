import 'package:hive_flutter/hive_flutter.dart';

/// Hive TTL-aware cache service.
/// All cache writes include an `_expiry` companion key.
class HiveService {
  HiveService._();

  static const String _userBox = 'user';
  static const String _projectBox = 'projects';
  static const String _teamBox = 'teams';
  static const String _taskBox = 'tasks';
  static const String _notificationBox = 'notifications';
  static const String _scheduleBox = 'schedule';
  static const String _settingsBox = 'settings';

  static const Duration _defaultTtl = Duration(hours: 24);

  // ── Initialise ───────────────────────────────────────────────
  static Future<void> init() async {
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox(_userBox),
      Hive.openBox(_projectBox),
      Hive.openBox(_teamBox),
      Hive.openBox(_taskBox),
      Hive.openBox(_notificationBox),
      Hive.openBox(_scheduleBox),
      Hive.openBox(_settingsBox),
    ]);
  }

  // ── Read / Write ─────────────────────────────────────────────
  static Box _box(String name) => Hive.box(name);

  static Future<void> write(
    String boxName,
    String key,
    dynamic value, {
    Duration ttl = _defaultTtl,
  }) async {
    final box = _box(boxName);
    await box.put(key, value);
    await box.put('${key}_expiry', DateTime.now().add(ttl).toIso8601String());
  }

  static T? read<T>(String boxName, String key) {
    final box = _box(boxName);
    final expiryStr = box.get('${key}_expiry') as String?;
    if (expiryStr != null) {
      final expiry = DateTime.tryParse(expiryStr);
      if (expiry != null && DateTime.now().isAfter(expiry)) {
        box.delete(key);
        box.delete('${key}_expiry');
        return null;
      }
    }
    return box.get(key) as T?;
  }

  static Future<void> delete(String boxName, String key) async {
    final box = _box(boxName);
    await box.delete(key);
    await box.delete('${key}_expiry');
  }

  static Future<void> clearBox(String boxName) async {
    await _box(boxName).clear();
  }

  // ── TTL pruning ──────────────────────────────────────────────
  static Future<void> pruneExpired() async {
    for (final name in [
      _userBox,
      _projectBox,
      _teamBox,
      _taskBox,
      _notificationBox,
      _scheduleBox,
    ]) {
      final box = _box(name);
      final expiredKeys = <String>[];
      for (final key in box.keys.whereType<String>()) {
        if (key.endsWith('_expiry')) continue;
        final expiryStr = box.get('${key}_expiry') as String?;
        if (expiryStr != null) {
          final expiry = DateTime.tryParse(expiryStr);
          if (expiry != null && DateTime.now().isAfter(expiry)) {
            expiredKeys.add(key);
          }
        }
      }
      for (final k in expiredKeys) {
        await box.delete(k);
        await box.delete('${k}_expiry');
      }
    }
  }

  // ── Box name constants ───────────────────────────────────────
  static String get user => _userBox;
  static String get projects => _projectBox;
  static String get teams => _teamBox;
  static String get tasks => _taskBox;
  static String get notifications => _notificationBox;
  static String get schedule => _scheduleBox;
  static String get settings => _settingsBox;
}
