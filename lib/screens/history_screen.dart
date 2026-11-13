import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/invoice_repository.dart';
import '../models/invoice.dart';
import '../printing/receipt_printer.dart';
import '../utils/money.dart';

final _dateFormat = DateFormat('d MMM yyyy, h:mm a');

/// List of saved invoices. Click one to see it and reprint.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({
    super.key,
    required this.invoiceRepository,
    required this.receiptPrinter,
  });

  final InvoiceRepository invoiceRepository;
  final ReceiptPrinter receiptPrinter;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _search = TextEditingController();
  List<InvoiceSummary>? _invoices;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final list = await widget.invoiceRepository.list(search: _search.text);
    if (mounted) setState(() => _invoices = list);
  }

  Future<void> _open(InvoiceSummary summary) async {
    final invoice = await widget.invoiceRepository.getById(summary.id);
    if (invoice == null || !mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => _InvoiceDetailsDialog(
        invoice: invoice,
        onReprint: () => _reprint(invoice),
      ),
    );
  }

  Future<void> _reprint(Invoice invoice) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final ok = await widget.receiptPrinter.printInvoice(context, invoice);
      if (!ok) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Receipt was not printed.')),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Printing failed. Check the printer. ($e)')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final invoices = _invoices;
    const bold = TextStyle(fontWeight: FontWeight.bold);

    return Scaffold(
      appBar: AppBar(title: const Text('Invoice History')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 400,
              child: TextField(
                controller: _search,
                autofocus: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search invoice no., customer name or phone',
                ),
                onChanged: (_) => _load(),
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  SizedBox(width: 120, child: Text('Invoice No.', style: bold)),
                  SizedBox(width: 200, child: Text('Date', style: bold)),
                  Expanded(child: Text('Customer', style: bold)),
                  SizedBox(width: 80, child: Text('Items', style: bold)),
                  SizedBox(
                    width: 140,
                    child: Text('Total', style: bold, textAlign: TextAlign.right),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1.5, color: Colors.black),
            Expanded(
              child: invoices == null
                  ? const Center(child: CircularProgressIndicator())
                  : invoices.isEmpty
                      ? const Center(child: Text('No invoices found'))
                      : ListView.separated(
                          itemCount: invoices.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, i) =>
                              _row(invoices[i], bold),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(InvoiceSummary inv, TextStyle bold) {
    final customer = [inv.customerName, inv.customerPhone]
        .whereType<String>()
        .join('  ·  ');
    return InkWell(
      onTap: () => _open(inv),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            SizedBox(width: 120, child: Text(inv.invoiceNo, style: bold)),
            SizedBox(width: 200, child: Text(_dateFormat.format(inv.createdAt))),
            Expanded(child: Text(customer.isEmpty ? 'Walk-in' : customer)),
            SizedBox(width: 80, child: Text('${inv.itemCount}')),
            SizedBox(
              width: 140,
              child: Text(
                formatPkr(inv.total),
                style: bold,
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InvoiceDetailsDialog extends StatelessWidget {
  const _InvoiceDetailsDialog({required this.invoice, required this.onReprint});

  final Invoice invoice;
  final VoidCallback onReprint;

  @override
  Widget build(BuildContext context) {
    const bold = TextStyle(fontWeight: FontWeight.bold);
    final customer = [invoice.customerName, invoice.customerPhone]
        .whereType<String>()
        .join('  ·  ');

    return AlertDialog(
      title: Text('Invoice ${invoice.invoiceNo}'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_dateFormat.format(invoice.createdAt)),
            Text(customer.isEmpty ? 'Walk-in customer' : customer),
            const Divider(height: 24),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final item in invoice.items)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              [
                                item.perfumeName,
                                if (item.sizeLabel.isNotEmpty) item.sizeLabel,
                              ].join('  ·  '),
                            ),
                          ),
                          Text(
                            '${item.quantity} x ${formatNumber(item.unitPrice)}',
                          ),
                          SizedBox(
                            width: 110,
                            child: Text(
                              formatNumber(item.lineTotal),
                              style: bold,
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 24),
            Row(
              children: [
                const Text('Total', style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                )),
                const Spacer(),
                Text(formatPkr(invoice.total), style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                )),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        FilledButton.icon(
          onPressed: onReprint,
          icon: const Icon(Icons.print),
          label: const Text('Reprint'),
        ),
      ],
    );
  }
}
