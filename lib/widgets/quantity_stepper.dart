import 'package:flutter/material.dart';

import '../models/invoice.dart';

/// [ - ]  2  [ + ]
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Decrease',
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.remove),
          onPressed: value > 1 ? () => onChanged(value - 1) : null,
        ),
        SizedBox(
          width: 36,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
        IconButton(
          tooltip: 'Increase',
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.add),
          onPressed: value < maxQuantity ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }
}
