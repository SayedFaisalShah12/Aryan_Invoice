import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  test('SQLite works on this desktop', () async {
    sqfliteFfiInit();
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    final result = await db.rawQuery('SELECT sqlite_version() AS v');
    expect(result.first['v'], isNotNull);
    await db.close();
  });
}
