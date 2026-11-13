import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;

/// Logo and fonts used on the receipt.
///
/// Roboto is bundled because the PDF built-in fonts cannot print some
/// characters in the price list (e.g. the ’ in "Fleur De’ Mate’").
class ReceiptAssets {
  const ReceiptAssets({
    required this.regular,
    required this.bold,
    required this.boldItalic,
    this.logoPng,
  });

  static const logoPath = 'assets/images/logo.png';
  static const regularPath = 'assets/fonts/Roboto-Regular.ttf';
  static const boldPath = 'assets/fonts/Roboto-Bold.ttf';
  static const boldItalicPath = 'assets/fonts/Roboto-BoldItalic.ttf';

  final pw.Font regular;
  final pw.Font bold;
  final pw.Font boldItalic;

  /// Black-on-white logo. If null, the shop name is printed instead.
  final Uint8List? logoPng;

  /// Loads everything from the app's bundled assets.
  static Future<ReceiptAssets> load() async {
    Future<pw.Font> font(String path) async =>
        pw.Font.ttf(await rootBundle.load(path));

    return ReceiptAssets(
      regular: await font(regularPath),
      bold: await font(boldPath),
      boldItalic: await font(boldItalicPath),
      logoPng: (await rootBundle.load(logoPath)).buffer.asUint8List(),
    );
  }
}
