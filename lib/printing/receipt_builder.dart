import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../config/shop_info.dart';
import '../models/invoice.dart';
import '../utils/money.dart';
import 'receipt_assets.dart';

const _mm = PdfPageFormat.mm;

/// Thermal paper rolls the app supports.
enum ReceiptPaper {
  // Printable area is about 48mm on 58mm rolls and 72mm on 80mm rolls.
  mm58('58mm', widthMm: 58, sideMarginMm: 5, fontSize: 8, logoWidthMm: 30),
  mm80('80mm', widthMm: 80, sideMarginMm: 4, fontSize: 9.5, logoWidthMm: 40);

  const ReceiptPaper(
    this.label, {
    required this.widthMm,
    required this.sideMarginMm,
    required this.fontSize,
    required this.logoWidthMm,
  });

  final String label;
  final double widthMm;
  final double sideMarginMm;
  final double fontSize;
  final double logoWidthMm;

  /// Roll paper: fixed width, page height grows with the content.
  PdfPageFormat get pageFormat => PdfPageFormat(
        widthMm * _mm,
        double.infinity,
        marginLeft: sideMarginMm * _mm,
        marginRight: sideMarginMm * _mm,
        marginTop: 2 * _mm,
        marginBottom: 10 * _mm, // room to tear off
      );
}

/// Builds the receipt for a saved [invoice] as a PDF.
///
/// Layout follows the shop template: logo, invoice number and date,
/// billed-to, items, subtotal, black Total bar, "Thank You!".
/// Pure black and white only, because thermal printers cannot print grey.
Future<Uint8List> buildReceiptPdf({
  required Invoice invoice,
  required ReceiptPaper paper,
  required ReceiptAssets assets,
  ShopInfo shop = shopInfo,
}) {
  final logoPng = assets.logoPng;
  final invoiceNo = invoice.invoiceNo;
  if (invoiceNo == null) {
    throw ArgumentError('Only saved invoices (with a number) can be printed.');
  }

  final fs = paper.fontSize;
  final regular = pw.TextStyle(fontSize: fs);
  final small = pw.TextStyle(fontSize: fs * 0.85);
  final bold = pw.TextStyle(fontSize: fs, fontWeight: pw.FontWeight.bold);

  final doc = pw.Document(title: 'Invoice $invoiceNo', author: shop.name);

  doc.addPage(pw.Page(
    pageFormat: paper.pageFormat,
    theme: pw.ThemeData.withFont(
      base: assets.regular,
      bold: assets.bold,
      boldItalic: assets.boldItalic,
    ),
    build: (context) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        // ---- Shop header ----
        pw.Center(
          child: logoPng != null
              ? pw.Image(pw.MemoryImage(logoPng), width: paper.logoWidthMm * _mm)
              : pw.Text(
                  shop.name,
                  style: pw.TextStyle(
                    fontSize: fs * 2.4,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 3,
                  ),
                ),
        ),
        for (final line in shop.headerLines)
          pw.Text(line, style: small, textAlign: pw.TextAlign.center),
        pw.SizedBox(height: 4),
        _rule(),
        pw.SizedBox(height: 4),

        // ---- Invoice details ----
        pw.Center(
          child: pw.Text(
            'INVOICE',
            style: pw.TextStyle(
              fontSize: fs * 1.3,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ),
        pw.SizedBox(height: 4),
        _pair('Invoice No.', invoiceNo, regular),
        _pair(
          'Date',
          DateFormat('d MMM yyyy, h:mm a').format(invoice.createdAt),
          regular,
        ),
        if (invoice.customerName != null || invoice.customerPhone != null) ...[
          pw.SizedBox(height: 4),
          pw.Text('Billed to:', style: bold),
          if (invoice.customerName != null)
            pw.Text(invoice.customerName!, style: regular),
          if (invoice.customerPhone != null)
            pw.Text(invoice.customerPhone!, style: regular),
        ],
        pw.SizedBox(height: 6),

        // ---- Items ----
        pw.Row(children: [
          pw.Expanded(child: pw.Text('Item', style: bold)),
          pw.Text('Total (PKR)', style: bold),
        ]),
        _rule(thickness: 1),
        for (var i = 0; i < invoice.items.length; i++) ...[
          if (i > 0) _rule(thickness: 0.3),
          _item(invoice.items[i], regular: regular, small: small, bold: bold),
        ],
        _rule(thickness: 1),
        pw.SizedBox(height: 4),

        // ---- Totals ----
        _pair('Subtotal', formatPkr(invoice.subtotal), regular),
        pw.SizedBox(height: 4),
        pw.Container(
          color: PdfColors.black,
          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: pw.Row(children: [
            pw.Expanded(
              child: pw.Text('Total', style: _totalStyle(fs)),
            ),
            pw.Text(formatPkr(invoice.total), style: _totalStyle(fs)),
          ]),
        ),
        pw.SizedBox(height: 12),

        // ---- Footer ----
        pw.Center(
          child: pw.Text(
            'Thank You!',
            style: pw.TextStyle(
              fontSize: fs * 1.7,
              fontWeight: pw.FontWeight.bold,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
        ),
        if (shop.phone.trim().isNotEmpty) ...[
          pw.SizedBox(height: 4),
          pw.Text(
            'Contact: ${shop.phone.trim()}',
            style: bold,
            textAlign: pw.TextAlign.center,
          ),
        ],
        if (shop.footerNote.trim().isNotEmpty) ...[
          pw.SizedBox(height: 4),
          pw.Text(
            shop.footerNote.trim(),
            style: small,
            textAlign: pw.TextAlign.center,
          ),
        ],
      ],
    ),
  ));

  return doc.save();
}

pw.TextStyle _totalStyle(double fs) => pw.TextStyle(
      color: PdfColors.white,
      fontSize: fs * 1.3,
      fontWeight: pw.FontWeight.bold,
    );

pw.Widget _rule({double thickness = 0.5}) =>
    pw.Divider(height: thickness + 2, thickness: thickness, color: PdfColors.black);

pw.Widget _pair(String label, String value, pw.TextStyle style) => pw.Row(
      children: [
        pw.Expanded(child: pw.Text(label, style: style)),
        pw.Text(value, style: style),
      ],
    );

/// Hope                       <- name (bold)
/// BY Fraderic Malle          <- brand / category (small)
/// 30ml   2 x 3,500     7,000 <- size, qty x price, line total
pw.Widget _item(
  InvoiceItem item, {
  required pw.TextStyle regular,
  required pw.TextStyle small,
  required pw.TextStyle bold,
}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 2),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(item.perfumeName, style: bold),
        if (item.perfumeSubtitle.isNotEmpty)
          pw.Text(item.perfumeSubtitle, style: small),
        pw.Row(children: [
          pw.Expanded(
            child: pw.Text(
              '${item.sizeLabel.isEmpty ? '' : '${item.sizeLabel}   '}'
              '${item.quantity} x ${formatNumber(item.unitPrice)}',
              style: regular,
            ),
          ),
          pw.Text(formatNumber(item.lineTotal), style: bold),
        ]),
      ],
    ),
  );
}
