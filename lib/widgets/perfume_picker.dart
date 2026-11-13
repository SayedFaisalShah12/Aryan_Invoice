import 'package:flutter/material.dart';

import '../models/perfume.dart';

/// Search box + list of perfumes. Clicking a perfume (or pressing Enter
/// in the search box) calls [onSelected].
class PerfumePicker extends StatefulWidget {
  const PerfumePicker({
    super.key,
    required this.perfumes,
    required this.onSelected,
    required this.searchController,
    required this.searchFocusNode,
    required this.onAddManual,
  });

  final List<Perfume> perfumes;
  final ValueChanged<Perfume> onSelected;
  final VoidCallback onAddManual;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;

  @override
  State<PerfumePicker> createState() => _PerfumePickerState();
}

class _PerfumePickerState extends State<PerfumePicker> {
  late List<Perfume> _results = widget.perfumes;

  @override
  void initState() {
    super.initState();
    widget.searchController.addListener(_filter);
  }

  @override
  void dispose() {
    widget.searchController.removeListener(_filter);
    super.dispose();
  }

  /// Matches name, brand, category, or the exact S.No from the price list.
  void _filter() {
    final query = widget.searchController.text.trim().toLowerCase();
    final results = query.isEmpty
        ? widget.perfumes
        : widget.perfumes.where((p) {
            return p.sno.toString() == query ||
                p.name.toLowerCase().contains(query) ||
                (p.brand?.toLowerCase().contains(query) ?? false) ||
                (p.category?.toLowerCase().contains(query) ?? false);
          }).toList();
    if (results.length != _results.length || !_sameList(results)) {
      setState(() => _results = results);
    }
  }

  bool _sameList(List<Perfume> other) {
    for (var i = 0; i < other.length; i++) {
      if (!identical(other[i], _results[i])) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final grey = Colors.grey.shade600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: widget.searchController,
            focusNode: widget.searchFocusNode,
            autofocus: true,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search name, brand or S.No',
            ),
            onSubmitted: (_) {
              if (_results.isNotEmpty) widget.onSelected(_results.first);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: OutlinedButton.icon(
            onPressed: widget.onAddManual,
            icon: const Icon(Icons.edit_note),
            label: const Text('Add item manually'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '${_results.length} perfumes',
            style: TextStyle(fontSize: 12, color: grey),
          ),
        ),
        const SizedBox(height: 8),
        const Divider(height: 1),
        Expanded(
          child: _results.isEmpty
              ? Center(
                  child: Text('No perfume found', style: TextStyle(color: grey)),
                )
              : ListView.separated(
                  itemCount: _results.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final perfume = _results[index];
                    return ListTile(
                      dense: true,
                      leading: SizedBox(
                        width: 32,
                        child: Text(
                          '${perfume.sno}',
                          style: TextStyle(fontSize: 12, color: grey),
                        ),
                      ),
                      title: Text(
                        perfume.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(perfume.subtitle),
                      trailing: const Icon(Icons.add_circle_outline),
                      onTap: () => widget.onSelected(perfume),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
