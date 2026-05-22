// ignore_for_file: invalid_use_of_protected_member

part of '../screens_add_inquiry.dart';

extension _AddInquiryProductsSection on _ScreensAddInquiryState {
  Widget _buildProductsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_structuredProducts.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
                style: BorderStyle.solid,
              ),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 32,
                  color: Color(0xFF94A3B8),
                ),
                SizedBox(height: 12),
                Text(
                  'No products added yet.',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Click \'Add Product from Inventory\' to continue.',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _structuredProducts.length,
            separatorBuilder: (c, i) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = _structuredProducts[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.widgets_outlined,
                        color: Color(0xFF2563EB),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Category: ${item['category'] ?? 'N/A'}  •  Unit: ${item['unit'] ?? 'Nos'}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Qty: ${item['quantity']}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '₹${item['price'] ?? 0}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF10B981),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: Color(0xFF64748B),
                        size: 20,
                      ),
                      onPressed: () => _editProduct(index),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() => _structuredProducts.removeAt(index));
                        _calculateDealScore();
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) {
                return ERPProductSearchDialog(
                  companyId: widget.companyId,
                  onProductSelected: (docData, docId) {
                    Navigator.pop(context);
                    _showProductDetailEntry(
                      productId: docId,
                      name:
                          (docData['itemName'] ?? docData['name'] ?? 'Unknown')
                              .toString(),
                      sku: (docData['sku'] ?? docData['itemCode'] ?? '')
                          .toString(),
                      defaultPrice:
                          double.tryParse(
                            docData['sellingPrice']?.toString() ??
                                docData['price']?.toString() ??
                                '0',
                          ) ??
                          0.0,
                      unit: (docData['unit'] ?? 'Nos').toString(),
                      category: (docData['category'] ?? '').toString(),
                      subCategory: (docData['subCategory'] ?? '').toString(),
                      brand: (docData['brand'] ?? '').toString(),
                      model: (docData['model'] ?? '').toString(),
                      costPrice:
                          double.tryParse(
                            docData['costPrice']?.toString() ?? '0',
                          ) ??
                          0.0,
                    );
                  },
                  onManualAdd: (String query) {
                    Navigator.pop(context);
                    _showProductDetailEntry(
                      productId: 'manual',
                      name: query,
                      sku: '',
                      defaultPrice: 0.0,
                      unit: 'Nos',
                      category: 'General',
                      subCategory: '',
                      brand: '',
                      model: '',
                      costPrice: 0.0,
                    );
                  },
                );
              },
            );
          },
          icon: const Icon(Icons.add_shopping_cart, size: 18),
          label: const Text('Add Product from Inventory'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF2563EB),
            side: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }

  void _editProduct(int index) {
    final item = _structuredProducts[index];
    _showProductDetailEntry(
      productId: item['productId'] ?? 'manual',
      name: item['name'],
      sku: item['sku'] ?? '',
      defaultPrice: double.tryParse(item['price'].toString()) ?? 0.0,
      unit: item['unit'] ?? 'Nos',
      category: item['category'] ?? 'General',
      subCategory: item['subCategory'] ?? '',
      brand: item['brand'] ?? '',
      model: item['model'] ?? '',
      costPrice: double.tryParse(item['costPrice']?.toString() ?? '0') ?? 0.0,
      editIndex: index,
    );
  }
}
