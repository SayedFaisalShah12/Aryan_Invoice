import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../controllers/invoice_controller.dart';
import '../models/invoice.dart';
import '../utils/money.dart';
import 'quantity_stepper.dart';

// Column layout shared by the header and item rows.
const _itemFlex = 5;
const _sizeFlex = 3;
const _qtyWidth = 130.0;
const _priceFlex = 2;
const _totalFlex = 2;
const _removeWidth = 48.0;

/// Right side of the screen: customer details, items table, totals
/// and Save/Clear buttons.
class InvoicePanel extends StatelessWidget {
  const InvoicePanel({
    super.key,
    required this.controller,
    required this.customerName,
    required this.customerPhone,
    required this.saving,
    required this.onSave,
    required this.onClear,
  });

  final InvoiceController controller;
  final TextEditingController customerName;
  final TextEditingController customerPhone;
  final bool saving;
  final VoidCallback onSave;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final items = controller.items;
        final canAct = items.isNotEmpty && !saving;

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    'Invoice',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat('d MMMM yyyy').format(DateTime.now()),
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: customerName,
                      decoration: const InputDecoration(
                        labelText: 'Customer name (optional)',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 220,
                    child: TextField(
                      controller: customerPhone,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone (optional)',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const _HeaderRow(),
              const Divider(height: 1, thickness: 1.5, color: Colors.black),
              Expanded(
                child: items.isEmpty
                    ? const _EmptyState()
                    : ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) => _ItemRow(
                          item: items[index],
                          onQuantityChanged: (q) =>
                              controller.setQuantity(index, q),
                          onRemove: () => controller.removeAt(index),
                        ),
                      ),
              ),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Text('Subtotal', style: TextStyle(fontSize: 15)),
                    const Spacer(),
                    Text(
                      formatPkr(controller.subtotal),
                      style: const TextStyle(fontSize: 15),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _TotalBar(total: controller.total),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: canAct ? onClear : null,
                    icon: const Icon(Icons.delete_sweep_outlined),
                    label: const Text('Clear'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: canAct ? onSave : null,
                    icon: saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.print_outlined),
                    label: const Text('Save & print'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontWeight: FontWeight.bold, fontSize: 13);
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(flex: _itemFlex, child: Text('Item', style: style)),
          Expanded(flex: _sizeFlex, child: Text('Size', style: style)),
          SizedBox(
            width: _qtyWidth,
            child: Text('Quantity', style: style, textAlign: TextAlign.center),
          ),
          Expanded(
            flex: _priceFlex,
            child: Text('Price (PKR)', style: style, textAlign: TextAlign.right),
          ),
          Expanded(
            flex: _totalFlex,
            child: Text('Total (PKR)', style: style, textAlign: TextAlign.right),
          ),
          SizedBox(width: _removeWidth),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.item,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  final InvoiceItem item;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: _itemFlex,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.perfumeName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (item.perfumeSubtitle.isNotEmpty)
                  Text(
                    item.perfumeSubtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
              ],
            ),
          ),
          Expanded(flex: _sizeFlex, child: Text(item.sizeLabel)),
          SizedBox(
            width: _qtyWidth,
            child: Center(
              child: QuantityStepper(
                value: item.quantity,
                onChanged: onQuantityChanged,
              ),
            ),
          ),
          Expanded(
            flex: _priceFlex,
            child: Text(
              formatNumber(item.unitPrice),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: _totalFlex,
            child: Text(
              formatNumber(item.lineTotal),
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            width: _removeWidth,
            child: IconButton(
              tooltip: 'Remove',
              icon: const Icon(Icons.close, size: 20),
              onPressed: onRemove,
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalBar extends StatelessWidget {
  const _TotalBar({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      color: Colors.white,
      fontSize: 22,
      fontWeight: FontWeight.bold,
    );
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          const Text('Total', style: style),
          const Spacer(),
          Text(formatPkr(total), style: style),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final grey = Colors.grey.shade600;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined, size: 48, color: grey),
          const SizedBox(height: 8),
          Text('No items yet', style: TextStyle(color: grey, fontSize: 16)),
          const SizedBox(height: 4),
          Text(
            'Search for a perfume on the left and click it to add.',
            style: TextStyle(color: grey),
          ),
        ],
      ),
    );
  }
}
