import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/perfume.dart';
import '../utils/money.dart';
import 'quantity_stepper.dart';

typedef AddItemResult = ({PerfumeSize size, int quantity});

/// Asks for size and quantity of a perfume. Enter adds it to the invoice.
class AddItemDialog extends StatefulWidget {
  const AddItemDialog({super.key, required this.perfume});

  final Perfume perfume;

  static Future<AddItemResult?> show(BuildContext context, Perfume perfume) {
    return showDialog<AddItemResult>(
      context: context,
      builder: (_) => AddItemDialog(perfume: perfume),
    );
  }

  @override
  State<AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<AddItemDialog> {
  PerfumeSize _size = PerfumeSize.ml10;
  int _quantity = 1;

  void _submit() =>
      Navigator.of(context).pop((size: _size, quantity: _quantity));

  @override
  Widget build(BuildContext context) {
    final perfume = widget.perfume;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter): _submit,
        const SingleActivator(LogicalKeyboardKey.numpadEnter): _submit,
      },
      child: AlertDialog(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(perfume.name),
            Text(
              perfume.subtitle,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Size', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              for (final size in PerfumeSize.values)
                _SizeOption(
                  label: size.label,
                  price: perfume.priceFor(size),
                  selected: size == _size,
                  onTap: () => setState(() => _size = size),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text(
                    'Quantity',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  QuantityStepper(
                    value: _quantity,
                    onChanged: (v) => setState(() => _quantity = v),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  const Text(
                    'Line total',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const Spacer(),
                  Text(
                    formatPkr(perfume.priceFor(_size) * _quantity),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            autofocus: true,
            onPressed: _submit,
            child: const Text('Add to invoice'),
          ),
        ],
      ),
    );
  }
}

class _SizeOption extends StatelessWidget {
  const _SizeOption({
    required this.label,
    required this.price,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int price;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.grey.shade100 : null,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: selected ? Colors.black : Colors.grey.shade300,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(label, overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              Text(
                formatPkr(price),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
