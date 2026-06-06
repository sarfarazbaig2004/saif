import 'package:flutter/material.dart';
import '../helpers/quotation_local_constants.dart';

class QuotationBottomActionBar extends StatelessWidget {
  final double finalTotal;
  final bool canConvertToSo;
  final bool canConvertToCustomerPo;
  final bool canSave;
  final bool isLoading;
  final VoidCallback onConvertToSo;
  final VoidCallback onConvertToCustomerPo;
  final VoidCallback onSave;

  const QuotationBottomActionBar({
    super.key,
    required this.finalTotal,
    required this.canConvertToSo,
    required this.canConvertToCustomerPo,
    required this.canSave,
    required this.isLoading,
    required this.onConvertToSo,
    required this.onConvertToCustomerPo,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Final Total',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                Text(
                  '₹ ${finalTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                if (canConvertToSo)
                  OutlinedButton(
                    onPressed: onConvertToSo,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: primaryColor),
                      foregroundColor: primaryColor,
                    ),
                    child: const Text('Convert to SO'),
                  ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: canConvertToCustomerPo ? onConvertToCustomerPo : null,
                  icon: const Icon(Icons.assignment_turned_in_outlined),
                  label: const Text('Convert to Customer PO'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: primaryColor),
                    foregroundColor: primaryColor,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: canSave ? onSave : null,
                  icon: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: const Text('Save Quotation'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
