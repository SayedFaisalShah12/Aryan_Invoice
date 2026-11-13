import 'package:flutter/material.dart';

import '../controllers/invoice_controller.dart';
import '../data/invoice_repository.dart';
import '../models/invoice.dart';
import '../models/perfume.dart';
import '../printing/receipt_builder.dart';
import '../printing/receipt_printer.dart';
import '../utils/money.dart';
import '../widgets/add_item_dialog.dart';
import '../widgets/invoice_panel.dart';
import '../widgets/manual_item_dialog.dart';
import 'history_screen.dart';
import '../widgets/perfume_picker.dart';

/// Main screen: perfume list on the left, current invoice on the right.
class InvoiceScreen extends StatefulWidget {
  const InvoiceScreen({
    super.key,
    required this.perfumes,
    required this.invoiceRepository,
    required this.receiptPrinter,
  });

  final List<Perfume> perfumes;
  final InvoiceRepository invoiceRepository;
  final ReceiptPrinter receiptPrinter;

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  final _invoice = InvoiceController();
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  final _customerName = TextEditingController();
  final _customerPhone = TextEditingController();
  bool _saving = false;
  Invoice? _lastInvoice;
  late ReceiptPaper _paper = widget.receiptPrinter.paper;

  @override
  void dispose() {
    _invoice.dispose();
    _search.dispose();
    _searchFocus.dispose();
    _customerName.dispose();
    _customerPhone.dispose();
    super.dispose();
  }

  Future<void> _addPerfume(Perfume perfume) async {
    final result = await AddItemDialog.show(context, perfume);
    if (result != null) {
      _invoice.addItem(perfume, result.size, quantity: result.quantity);
    }
    // Select the search text so the next perfume can be typed right away.
    _search.selection =
        TextSelection(baseOffset: 0, extentOffset: _search.text.length);
    _searchFocus.requestFocus();
  }

  Future<void> _confirmClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear invoice?'),
        content: const Text('All items on this invoice will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed == true) _startNewInvoice();
  }

  void _startNewInvoice() {
    _invoice.clear();
    _customerName.clear();
    _customerPhone.clear();
    _search.clear();
    _searchFocus.requestFocus();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final saved = await widget.invoiceRepository.save(
        _invoice.buildInvoice(
          customerName: _customerName.text,
          customerPhone: _customerPhone.text,
        ),
      );
      _lastInvoice = saved;
      _startNewInvoice();
      messenger.showSnackBar(SnackBar(
        content: Text(
          'Invoice ${saved.invoiceNo} saved  ·  ${formatPkr(saved.total)}',
        ),
      ));
      await _print(saved);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not save invoice: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _print(Invoice invoice) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final printed = await widget.receiptPrinter.printInvoice(context, invoice);
      if (!printed) {
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

  Future<void> _addManual() async {
    final item = await ManualItemDialog.show(context);
    if (item != null) {
      _invoice.addManualItem(
        name: item.name,
        sizeLabel: item.size,
        unitPrice: item.price,
        quantity: item.quantity,
      );
    }
    _searchFocus.requestFocus();
  }

  void _openHistory() {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => HistoryScreen(
        invoiceRepository: widget.invoiceRepository,
        receiptPrinter: widget.receiptPrinter,
      ),
    ));
  }

  Future<void> _togglePaper() async {
    final next =
        _paper == ReceiptPaper.mm80 ? ReceiptPaper.mm58 : ReceiptPaper.mm80;
    setState(() => _paper = next);
    await widget.receiptPrinter.setPaper(next);
  }

  Future<void> _choosePrinter() async {
    await widget.receiptPrinter.choosePrinter(context);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    const onBar = Colors.white;
    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/images/logo_white.png',
          height: 40,
          semanticLabel: 'AURA',
        ),
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: onBar),
            onPressed: _openHistory,
            icon: const Icon(Icons.history),
            label: const Text('History'),
          ),
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: onBar),
            onPressed: _lastInvoice == null ? null : () => _print(_lastInvoice!),
            icon: const Icon(Icons.replay),
            label: const Text('Reprint last'),
          ),
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: onBar),
            onPressed: _togglePaper,
            icon: const Icon(Icons.receipt_long),
            label: Text('Paper: ${_paper.label}'),
          ),
          IconButton(
            tooltip:
                'Printer: ${widget.receiptPrinter.printerName ?? 'not chosen'}',
            onPressed: _choosePrinter,
            icon: const Icon(Icons.print),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 380,
            child: Material(
              color: Colors.grey.shade50,
              child: PerfumePicker(
                perfumes: widget.perfumes,
                onSelected: _addPerfume,
                searchController: _search,
                searchFocusNode: _searchFocus,
                onAddManual: _addManual,
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Material(
              color: Colors.white,
              child: InvoicePanel(
                controller: _invoice,
                customerName: _customerName,
                customerPhone: _customerPhone,
                saving: _saving,
                onSave: _save,
                onClear: _confirmClear,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
