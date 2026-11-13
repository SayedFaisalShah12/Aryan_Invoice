import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/perfume.dart';

/// Reads perfumes from the database.
class PerfumeRepository {
  PerfumeRepository(this._db);

  final Database _db;

  /// All perfumes in price-list order.
  Future<List<Perfume>> getAll() async {
    final rows = await _db.query('perfumes', orderBy: 'sno');
    return rows.map(Perfume.fromMap).toList();
  }

  /// Perfumes whose name or brand contains [text] (case-insensitive).
  Future<List<Perfume>> search(String text) async {
    final pattern = '%${text.trim()}%';
    final rows = await _db.query(
      'perfumes',
      where: 'name LIKE ? OR brand LIKE ? OR category LIKE ?',
      whereArgs: [pattern, pattern, pattern],
      orderBy: 'sno',
    );
    return rows.map(Perfume.fromMap).toList();
  }
}
