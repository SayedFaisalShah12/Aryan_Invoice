import 'package:intl/intl.dart';

final _number = NumberFormat('#,##0', 'en_US');

/// 1550 -> "1,550"
String formatNumber(int amount) => _number.format(amount);

/// 1550 -> "PKR 1,550"
String formatPkr(int amount) => 'PKR ${formatNumber(amount)}';
