import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/invoice.dart';

typedef ManualItem = ({String name, String size, int price, int quantity});

/// Lets staff type an item that is not on the price list.
class ManualItemDialog extends StatefulWidget {
  const ManualItemDialog({super.key});

  static Future<ManualItem?> show(BuildContext context) =>
      showDialog<ManualItem>(
        context: context,
        builder: (_) => const ManualItemDialog(),
      );

  @override
  State<ManualItemDialog> createState() => _ManualItemDialogState();
}

class _ManualItemDialogState extends State<ManualItemDialog> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _size = TextEditingController();
  final _price = TextEditingController();
  final _quantity = TextEditingController(text: '1');

  @override
  void dispose() {
    _name.dispose();
    _size.dispose();
    _price.dispose();
    _quantity.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    Navigator.of(context).pop((
      name: _name.text.trim(),
      size: _size.text.trim(),
      price: int.parse(_price.text),
      quantity: int.parse(_quantity.text),
    ));
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  String? _number(String? v, {required int max}) {
    final n = int.tryParse(v ?? '');
    if (n == null || n < 1) return 'Enter a number';
    if (n > max) return 'Too large';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final digits = [FilteringTextInputFormatter.digitsOnly];

    return AlertDialog(
      title: const Text('Add item manually'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Item name'),
                validator: _required,
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _size,
                decoration: const InputDecoration(
                  labelText: 'Size (optional)',
                  hintText: 'e.g. 100ml',
                ),
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _price,
                      decoration:
                          const InputDecoration(labelText: 'Price (PKR)'),
                      keyboardType: TextInputType.number,
                      inputFormatters: digits,
                      validator: (v) => _number(v, max: 10000000),
                      onFieldSubmitted: (_) => _submit(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 110,
                    child: TextFormField(
                      controller: _quantity,
                      decoration: const InputDecoration(labelText: 'Quantity'),
                      keyboardType: TextInputType.number,
                      inputFormatters: digits,
                      validator: (v) => _number(v, max: maxQuantity),
                      onFieldSubmitted: (_) => _submit(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Add to invoice')),
      ],
    );
  }
}
