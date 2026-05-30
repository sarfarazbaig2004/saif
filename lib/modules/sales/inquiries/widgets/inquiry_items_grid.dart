import 'package:flutter/material.dart';

part 'inquiry_items_table.dart';
part 'inquiry_items_empty.dart';

typedef InquiryBomAction =
    void Function(Map<String, dynamic> item, {required bool readOnly});

class InquiryItemsGrid extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final ValueChanged<List<Map<String, dynamic>>> onChanged;
  final VoidCallback? onImportBoq;
  final VoidCallback? onUploadBom;
  final VoidCallback? onUploadDrawing;
  final InquiryBomAction? onOpenBom;

  const InquiryItemsGrid({
    super.key,
    required this.items,
    required this.onChanged,
    this.onImportBoq,
    this.onUploadBom,
    this.onUploadDrawing,
    this.onOpenBom,
  });

  static const _borderColor = Color(0xFFE2E8F0);
  static const _mutedText = Color(0xFF64748B);
  static const _primary = Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.icon(
              onPressed: () => _openItemDialog(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Inquiry Item'),
            ),
            _outlineAction(
              icon: Icons.table_chart_outlined,
              label: 'Import BOQ',
              onPressed: onImportBoq,
            ),
            _outlineAction(
              icon: Icons.account_tree_outlined,
              label: 'Upload BOM',
              onPressed: onUploadBom,
            ),
            _outlineAction(
              icon: Icons.architecture_outlined,
              label: 'Upload Drawing',
              onPressed: onUploadDrawing,
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (items.isEmpty)
          _EmptyInquiryItems(onAdd: () => _openItemDialog(context))
        else
          _InquiryItemsTable(
            items: items,
            onEdit: (index) => _openItemDialog(context, editIndex: index),
            onDelete: _deleteItem,
            onOpenBom: onOpenBom,
          ),
      ],
    );
  }

  Widget _outlineAction({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: _primary,
        side: const BorderSide(color: _primary),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _deleteItem(int index) {
    final next = List<Map<String, dynamic>>.from(items)..removeAt(index);
    onChanged(next);
  }

  void _openItemDialog(BuildContext context, {int? editIndex}) {
    final existing = editIndex == null ? null : items[editIndex];
    final descriptionCtrl = TextEditingController(
      text: _string(existing?['name'] ?? existing?['description']),
    );
    final hsnCtrl = TextEditingController(text: _string(existing?['hsn']));
    final qtyCtrl = TextEditingController(
      text: existing == null ? '1' : _numberText(existing['quantity']),
    );
    final unitCtrl = TextEditingController(
      text: _string(existing?['unit']).isEmpty
          ? 'KG'
          : _string(existing?['unit']),
    );
    final rateCtrl = TextEditingController(
      text: existing == null ? '' : _numberText(existing['price']),
    );

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            editIndex == null ? 'Add Inquiry Item' : 'Edit Inquiry Item',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 520,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: descriptionCtrl,
                    decoration: _dec('Description *'),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: hsnCtrl,
                          decoration: _dec('HSN'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: unitCtrl,
                          decoration: _dec('Unit'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: qtyCtrl,
                          decoration: _dec('Qty *'),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: rateCtrl,
                          decoration: _dec('Rate'),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
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
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final description = descriptionCtrl.text.trim();
                final qty = double.tryParse(qtyCtrl.text.trim()) ?? 0;
                if (description.isEmpty || qty <= 0) return;

                final item = {
                  'productId': existing?['productId'] ?? 'manual_inquiry_item',
                  'name': description,
                  'description': description,
                  'hsn': hsnCtrl.text.trim(),
                  'quantity': qty,
                  'unit': unitCtrl.text.trim().isEmpty
                      ? 'KG'
                      : unitCtrl.text.trim(),
                  'price': double.tryParse(rateCtrl.text.trim()) ?? 0.0,
                  'sku': existing?['sku'] ?? '',
                  'category': existing?['category'] ?? 'Engineering Scope',
                  'subCategory': existing?['subCategory'] ?? '',
                  'brand': existing?['brand'] ?? '',
                  'model': existing?['model'] ?? '',
                  'costPrice': existing?['costPrice'] ?? 0.0,
                  'margin': existing?['margin'] ?? 0.0,
                  'estimatedWeight': existing?['estimatedWeight'],
                  'inquiryItemId': existing?['inquiryItemId'] ?? newItemId(),
                  'bomId': existing?['bomId'] ?? '',
                  'bomNumber': existing?['bomNumber'] ?? '',
                  'bomStatus': existing?['bomStatus'] ?? '',
                  'bomLinked': existing?['bomLinked'] ?? false,
                  'drawingRevision': existing?['drawingRevision'] ?? '',
                };

                final next = List<Map<String, dynamic>>.from(items);
                if (editIndex == null) {
                  next.add(item);
                } else {
                  next[editIndex] = item;
                }
                onChanged(next);
                Navigator.pop(dialogContext);
              },
              child: const Text('Save Item'),
            ),
          ],
        );
      },
    );
  }

  InputDecoration _dec(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _borderColor),
      ),
    );
  }

  static String _string(dynamic value) => value?.toString() ?? '';

  static String newItemId() =>
      'inq_item_${DateTime.now().microsecondsSinceEpoch}';

  static String _numberText(dynamic value) {
    final parsed = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '');
    if (parsed == null) return '';
    if (parsed == parsed.roundToDouble()) return parsed.toInt().toString();
    return parsed.toString();
  }
}
