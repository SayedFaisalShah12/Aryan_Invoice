import 'dart:io';

import 'package:aura/config/shop_info.dart';
import 'package:aura/data/app_database.dart';
import 'package:aura/data/price_list_parser.dart';
import 'package:aura/models/invoice.dart';
import 'package:aura/models/perfume.dart';
import 'package:aura/printing/receipt_assets.dart';
import 'package:aura/printing/receipt_builder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;

/// Builds sample receipts and saves them to build/receipt_samples/
/// so the design can be checked without a printer.
void main() {
  final perfumes =
      parsePriceList(File(AppDatabase.priceListAsset).readAsStringSync());
  Perfume bySno(int sno) => perfumes.singleWhere((p) => p.sno == sno);

  InvoiceItem line(int sno, PerfumeSize size, int qty) {
    final p = bySno(sno);
    return InvoiceItem(
      perfumeName: p.name,
      perfumeSubtitle: p.subtitle,
      sizeLabel: size.label,
      unitPrice: p.priceFor(size),
      quantity: qty,
    );
  }

  final invoice = Invoice(
    id: 1,
    invoiceNo: 'INV-00001',
    createdAt: DateTime(2026, 11, 11, 15, 45),
    customerName: 'Sample Customer',
    customerPhone: '0300-0000000',
    items: [
      line(129, PerfumeSize.ml30, 2), // Hope
      line(74, PerfumeSize.ml50, 1), // longest name
      line(103, PerfumeSize.tola, 1), // Fleur De’ Mate’ (curly quote)
      line(163, PerfumeSize.ml10, 3), // BY Lancôme (accent)
      line(261, PerfumeSize.halfTola, 1), // White Musk BY J.
      line(5, PerfumeSize.ml10, 1), // Al Bakhoor ***
    ],
  );

  pw.Font font(String path) =>
      pw.Font.ttf(File(path).readAsBytesSync().buffer.asByteData());
  final assets = ReceiptAssets(
    regular: font(ReceiptAssets.regularPath),
    bold: font(ReceiptAssets.boldPath),
    boldItalic: font(ReceiptAssets.boldItalicPath),
    logoPng: File(ReceiptAssets.logoPath).readAsBytesSync(),
  );
  final noLogo = ReceiptAssets(
    regular: assets.regular,
    bold: assets.bold,
    boldItalic: assets.boldItalic,
  );

  final outDir = Directory('build/receipt_samples')..createSync(recursive: true);

  for (final paper in ReceiptPaper.values) {
    test('builds a ${paper.label} receipt', () async {
      final bytes = await buildReceiptPdf(
        invoice: invoice,
        paper: paper,
        assets: assets,
        shop: const ShopInfo(
          name: 'AURA',
          address: 'Shop address goes here',
          phone: '0300-0000000',
        ),
      );
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
      File('${outDir.path}/receipt_${paper.label}.pdf').writeAsBytesSync(bytes);
    });
  }

  test('a walk-in receipt without logo or customer still builds', () async {
    final walkIn = Invoice(
      id: 2,
      invoiceNo: 'INV-00002',
      createdAt: DateTime(2026, 11, 11, 16, 0),
      items: [line(180, PerfumeSize.ml10, 1)],
    );
    final bytes = await buildReceiptPdf(
      invoice: walkIn,
      paper: ReceiptPaper.mm58,
      assets: noLogo,
    );
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    File('${outDir.path}/receipt_walk_in_58mm.pdf').writeAsBytesSync(bytes);
  });

  test('an unsaved invoice cannot be printed', () {
    final unsaved = Invoice(createdAt: DateTime.now(), items: const []);
    expect(
      () => buildReceiptPdf(
        invoice: unsaved,
        paper: ReceiptPaper.mm80,
        assets: assets,
      ),
      throwsArgumentError,
    );
  });
}
