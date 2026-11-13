import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Simple key/value settings (paper size, printer) kept in SQLite.
class SettingsRepository {
  SettingsRepository._(this._db, this._values);

  final Database _db;
  final Map<String, String> _values;

  static Future<SettingsRepository> load(Database db) async {
    final rows = await db.query('settings');
    return SettingsRepository._(db, {
      for (final row in rows) row['key'] as String: row['value'] as String,
    });
  }

  String? get(String key) => _values[key];

  Future<void> set(String key, String value) async {
    _values[key] = value;
    await _db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
