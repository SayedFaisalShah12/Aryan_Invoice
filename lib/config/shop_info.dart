/// Shop details printed at the top and bottom of every receipt.
/// Leave a value empty ('') and that line is simply not printed.
class ShopInfo {
  const ShopInfo({
    required this.name,
    this.address = '',
    this.phone = '',
    this.footerNote = '',
  });

  final String name;
  final String address;
  final String phone;

  /// Optional small line under "Thank You!", e.g. an exchange policy.
  final String footerNote;

  /// Printed under the logo. The phone is printed at the bottom instead.
  List<String> get headerLines => [
        if (address.trim().isNotEmpty) address.trim(),
      ];
}

const shopInfo = ShopInfo(
  name: 'AURA',
  address: '',
  phone: '+92331549456',
  footerNote: '',
);
