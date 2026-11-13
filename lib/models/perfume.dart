/// The five sizes sold in the shop, as listed in the price list.
enum PerfumeSize {
  ml10('10ml', 'price_10ml'),
  ml30('30ml', 'price_30ml'),
  ml50('50ml', 'price_50ml'),
  tola('Tola (12ml oil)', 'price_tola'),
  halfTola('Half Tola (6ml oil)', 'price_half_tola');

  const PerfumeSize(this.label, this.column);

  /// Text shown to staff and printed on the invoice.
  final String label;

  /// Matching column name in the `perfumes` database table.
  final String column;
}

class Perfume {
  const Perfume({
    this.id,
    required this.sno,
    required this.name,
    this.brand,
    this.category,
    required this.prices,
  });

  final int? id;

  /// Serial number from the price list PDF.
  final int sno;
  final String name;

  /// e.g. "Dior". Null for house blends listed by category instead.
  final String? brand;

  /// e.g. "Oriental/Arabic" or "Others". Null when a brand is given.
  final String? category;

  /// Price in PKR for each size.
  final Map<PerfumeSize, int> prices;

  int priceFor(PerfumeSize size) => prices[size]!;

  /// "BY Dior" or "Oriental/Arabic" — the small text shown under the name.
  String get subtitle => brand != null ? 'BY $brand' : (category ?? '');

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'sno': sno,
        'name': name,
        'brand': brand,
        'category': category,
        for (final size in PerfumeSize.values) size.column: prices[size],
      };

  factory Perfume.fromMap(Map<String, Object?> map) => Perfume(
        id: map['id'] as int?,
        sno: map['sno'] as int,
        name: map['name'] as String,
        brand: map['brand'] as String?,
        category: map['category'] as String?,
        prices: {
          for (final size in PerfumeSize.values) size: map[size.column] as int,
        },
      );
}
