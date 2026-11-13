import 'package:flutter/widgets.dart';
import 'package:printing/printing.dart';

import '../data/settings_repository.dart';
import '../models/invoice.dart';
import 'receipt_assets.dart';
import 'receipt_builder.dart';

/// Sends receipts to the thermal printer chosen by the user.
class ReceiptPrinter {
  ReceiptPrinter(this._settings);

  final SettingsRepository _settings;
  ReceiptAssets? _assets;

  static const _paperKey = 'paper';
  static const _printerUrlKey = 'printer_url';
  static const _printerNameKey = 'printer_name';

  ReceiptPaper get paper => ReceiptPaper.values.firstWhere(
        (p) => p.name == _settings.get(_paperKey),
        orElse: () => ReceiptPaper.mm80,
      );

  Future<void> setPaper(ReceiptPaper paper) =>
      _settings.set(_paperKey, paper.name);

  String? get printerName => _settings.get(_printerNameKey);

  /// Shows the system printer list. Returns false if cancelled.
  Future<bool> choosePrinter(BuildContext context) async {
    final printer = await Printing.pickPrinter(
      context: context,
      title: 'Choose receipt printer',
    );
    if (printer == null) return false;
    await _settings.set(_printerUrlKey, printer.url);
    await _settings.set(_printerNameKey, printer.name);
    return true;
  }

  /// Prints [invoice]. Returns true if it was sent to the printer.
  Future<bool> printInvoice(BuildContext context, Invoice invoice) async {
    final assets = _assets ??= await ReceiptAssets.load();
    final paper = this.paper;
    final bytes = await buildReceiptPdf(
      invoice: invoice,
      paper: paper,
      assets: assets,
    );
    final name = invoice.invoiceNo!;

    // If this computer can't print directly, use the system print dialog.
    final info = await Printing.info();
    if (!info.directPrint || !info.canListPrinters) {
      return Printing.layoutPdf(
        name: name,
        format: paper.pageFormat,
        onLayout: (_) async => bytes,
      );
    }

    if (_settings.get(_printerUrlKey) == null) {
      if (!context.mounted || !await choosePrinter(context)) return false;
    }
    return Printing.directPrintPdf(
      printer: Printer(url: _settings.get(_printerUrlKey)!, name: printerName),
      name: name,
      format: paper.pageFormat,
      onLayout: (_) async => bytes,
    );
  }
}
