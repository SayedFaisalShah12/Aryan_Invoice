import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'price_list_parser.dart';

/// Opens the local SQLite database file (aura.db).
///
/// On first run it creates the tables and fills `perfumes` from
/// `assets/data/price_list.csv`.
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  static const _fileName = 'aura.db';
  static const _version = 1;
  static const priceListAsset = 'assets/data/price_list.csv';

  Database? _db;

  Database get db {
    final db = _db;
    if (db == null) {
      throw StateError('Database not opened. Call open() first.');
    }
    return db;
  }

  /// [path] and [loadPriceList] can be overridden in tests.
  Future<void> open({
    String? path,
    Future<String> Function()? loadPriceList,
  }) async {
    if (_db != null) return;

    // Desktop (Windows/macOS) needs the FFI version of SQLite.
    sqfliteFfiInit();
    final factory = databaseFactoryFfi;

    path ??= p.join((await getApplicationSupportDirectory()).path, _fileName);
    final loader =
        loadPriceList ?? () => rootBundle.loadString(priceListAsset);

    _db = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: _version,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, version) async {
          await _createTables(db);
          await _createSettingsTable(db);
          await _seedPerfumes(db, await loader());
        },
      ),
    );
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  static Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE perfumes (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        sno             INTEGER NOT NULL UNIQUE,
        name            TEXT    NOT NULL,
        brand           TEXT,
        category        TEXT,
        price_10ml      INTEGER NOT NULL,
        price_30ml      INTEGER NOT NULL,
        price_50ml      INTEGER NOT NULL,
        price_tola      INTEGER NOT NULL,
        price_half_tola INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE invoices (
        id             INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_no     TEXT    NOT NULL UNIQUE,
        created_at     TEXT    NOT NULL,
        customer_name  TEXT,
        customer_phone TEXT,
        subtotal       INTEGER NOT NULL,
        total          INTEGER NOT NULL
      )
    ''');

    // Name, size and price are copied onto each line so old invoices
    // stay correct even if prices change later.
    await db.execute('''
      CREATE TABLE invoice_items (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_id    INTEGER NOT NULL
                        REFERENCES invoices(id) ON DELETE CASCADE,
        perfume_id    INTEGER REFERENCES perfumes(id),
        perfume_name     TEXT    NOT NULL,
        perfume_subtitle TEXT,
        size          TEXT    NOT NULL,
        unit_price    INTEGER NOT NULL,
        quantity      INTEGER NOT NULL,
        line_total    INTEGER NOT NULL
      )
    ''');
  }

  static Future<void> _createSettingsTable(Database db) => db.execute('''
      CREATE TABLE settings (
        key   TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

  static Future<void> _seedPerfumes(Database db, String csv) async {
    final batch = db.batch();
    for (final perfume in parsePriceList(csv)) {
      batch.insert('perfumes', perfume.toMap());
    }
    await batch.commit(noResult: true);
  }
}
