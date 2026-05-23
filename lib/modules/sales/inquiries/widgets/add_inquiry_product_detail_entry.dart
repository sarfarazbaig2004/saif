// ignore_for_file: invalid_use_of_protected_member

part of '../screens_add_inquiry.dart';

extension _AddInquiryProductDetailEntry on _ScreensAddInquiryState {
  void _showProductDetailEntry({
    required String productId,
    required String name,
    required String sku,
    required double defaultPrice,
    required String unit,
    required String category,
    required String subCategory,
    required String brand,
    required String model,
    required double costPrice,
    int? editIndex,
  }) {
    final nameCtrl = TextEditingController(text: name);
    final qtyCtrl = TextEditingController(
      text: editIndex != null
          ? _structuredProducts[editIndex]['quantity'].toString()
          : '1',
    );
    final priceCtrl = TextEditingController(
      text: editIndex != null
          ? _structuredProducts[editIndex]['price'].toString()
          : defaultPrice.toString(),
    );
    final unitCtrl = TextEditingController(
      text: editIndex != null ? _structuredProducts[editIndex]['unit'] : unit,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          editIndex != null ? 'Edit Product' : 'Add to Inquiry',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: _dec('Product / Description *'),
                enabled: productId == 'manual' || editIndex != null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: qtyCtrl,
                      decoration: _dec('Quantity *'),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: unitCtrl,
                      decoration: _dec('Unit (e.g. Nos, Kg)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceCtrl,
                decoration: _dec('Expected Unit Price (₹)'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty || qtyCtrl.text.trim().isEmpty) {
                return;
              }

              double sPrice = double.tryParse(priceCtrl.text.trim()) ?? 0.0;
              double margin = sPrice - costPrice;

              double parsedQty = double.tryParse(qtyCtrl.text.trim()) ?? 0.0;
              if (parsedQty <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Quantity must be greater than 0.'),
                  ),
                );
                return;
              }

              final productMap = {
                'productId': productId,
                'name': nameCtrl.text.trim(),
                'sku': sku,
                'quantity': parsedQty,
                'unit': unitCtrl.text.trim(),
                'price': sPrice,
                'costPrice': costPrice,
                'margin': margin,
                'category': category,
                'subCategory': subCategory,
                'brand': brand,
                'model': model,
              };

              setState(() {
                if (editIndex != null) {
                  _structuredProducts[editIndex] = productMap;
                } else {
                  _structuredProducts.add(productMap);
                }
              });
              _calculateDealScore();
              Navigator.pop(context);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
