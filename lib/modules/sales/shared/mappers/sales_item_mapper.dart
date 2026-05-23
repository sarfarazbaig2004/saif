import 'package:QUIK/modules/customer_po/models/customer_po_item_model.dart';
import 'package:QUIK/modules/sales/inquiries/models/inquiry_item_model.dart';
import 'package:QUIK/modules/sales/quotations/models/quotation_item_model.dart';

class SalesItemMapper {
  const SalesItemMapper._();

  static QuotationItemModel inquiryToQuotationItem({
    required InquiryItemModel item,
    required double unitRate,
    double gstPercent = 18,
  }) {
    return QuotationItemModel(
      id: item.id,
      inquiryItemId: item.id,
      itemName: item.itemName,
      description: item.description,
      quantity: item.quantity,
      uom: item.uom,
      weightKg: item.weightKg,
      unitRate: unitRate,
      gstPercent: gstPercent,
      material: item.material,
      finish: item.finish,
      remarks: item.remarks,
    );
  }

  static CustomerPoItemModel quotationToCustomerPoItem({
    required QuotationItemModel item,
  }) {
    return CustomerPoItemModel(
      id: item.id,
      quotationItemId: item.id,
      itemName: item.itemName,
      description: item.description,
      quantity: item.quantity,
      uom: item.uom,
      unitRate: item.unitRate,
      gstPercent: item.gstPercent,
      weightKg: item.weightKg,
      material: item.material,
      finish: item.finish,
      remarks: item.remarks,
    );
  }
}
