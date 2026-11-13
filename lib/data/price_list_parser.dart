import '../models/perfume.dart';

/// Reads `assets/data/price_list.csv` (copied from Price List.pdf).
///
/// Columns: sno, name, brand, category, price_10ml, price_30ml,
/// price_50ml, price_tola, price_half_tola. Names must not contain commas.
List<Perfume> parsePriceList(String csv) {
  final lines = csv
      .replaceFirst('﻿', '') // remove BOM if Excel added one
      .split(RegExp(r'\r?\n'))
      .where((line) => line.trim().isNotEmpty)
      .toList();

  final perfumes = <Perfume>[];
  // Skip the header row.
  for (var i = 1; i < lines.length; i++) {
    final cells = lines[i].split(',');
    if (cells.length != 9) {
      throw FormatException(
        'Price list line ${i + 1} should have 9 columns but has '
        '${cells.length}: "${lines[i]}"',
      );
    }
    String? optional(String v) => v.trim().isEmpty ? null : v.trim();
    int price(String v) => int.parse(v.trim());

    perfumes.add(Perfume(
      sno: int.parse(cells[0].trim()),
      name: cells[1].trim(),
      brand: optional(cells[2]),
      category: optional(cells[3]),
      prices: {
        PerfumeSize.ml10: price(cells[4]),
        PerfumeSize.ml30: price(cells[5]),
        PerfumeSize.ml50: price(cells[6]),
        PerfumeSize.tola: price(cells[7]),
        PerfumeSize.halfTola: price(cells[8]),
      },
    ));
  }
  return perfumes;
}
