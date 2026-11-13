import 'dart:io';

import 'package:aura/data/app_database.dart';
import 'package:aura/data/perfume_repository.dart';
import 'package:aura/data/price_list_parser.dart';
import 'package:aura/models/perfume.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  final csv = File(AppDatabase.priceListAsset).readAsStringSync();
  final perfumes = parsePriceList(csv);
  Perfume bySno(int sno) => perfumes.singleWhere((p) => p.sno == sno);

  test('price list has all 268 perfumes, numbered 1..268', () {
    expect(perfumes.length, 268);
    expect(perfumes.map((p) => p.sno), List.generate(268, (i) => i + 1));
  });

  test('every perfume has a brand or a category', () {
    for (final p in perfumes) {
      expect(p.brand != null || p.category != null, isTrue, reason: p.name);
    }
  });

  // Spot checks against Price List.pdf (first/last of each page + specials).
  final expected = <int, (String, String, List<int>)>{
    1: ('1881-Cerrutti', 'BY Cerrutti', [350, 1150, 1800, 800, 400]),
    5: ('Al Bakhoor ***', 'Oriental/Arabic', [300, 1000, 1550, 800, 400]),
    16: ('Aqua Sapphire', 'BY Boadicea the Victorious',
        [850, 2700, 4350, 2400, 1200]),
    57: ('Champion David Off', 'BY Davidoff', [350, 1100, 1700, 800, 400]),
    79: ('Deep Blue Sea', 'Others', [300, 1000, 1550, 600, 400]),
    103: ('Fleur De’ Mate’', 'BY Versace', [450, 1350, 2100, 1000, 600]),
    129: ('Hope', 'BY Fraderic Malle', [1150, 3500, 5750, 3200, 1600]),
    180: ('Motia', 'Oriental/Arabic', [250, 750, 1100, 400, 200]),
    247: ('Toabacco Vanille', 'BY Tom Ford', [400, 1250, 1950, 1000, 600]),
    260: ('White Musk', 'Oriental/Arabic', [250, 850, 1300, 600, 400]),
    261: ('White Musk', 'BY J.', [450, 1450, 2250, 1200, 600]),
    268: ('Zarar', 'BY J.', [350, 1100, 1700, 800, 400]),
  };

  expected.forEach((sno, e) {
    test('#$sno ${e.$1} matches the PDF', () {
      final p = bySno(sno);
      expect(p.name, e.$1);
      expect(p.subtitle, e.$2);
      expect(PerfumeSize.values.map(p.priceFor).toList(), e.$3);
    });
  });

  test('database is created and filled from the price list', () async {
    sqfliteFfiInit();
    final db = AppDatabase.instance;
    await db.open(path: inMemoryDatabasePath, loadPriceList: () async => csv);
    addTearDown(db.close);

    final repo = PerfumeRepository(db.db);
    expect((await repo.getAll()).length, 268);

    final musks = await repo.search('white musk');
    expect(musks.map((p) => p.sno), [260, 261]);
  });
}
