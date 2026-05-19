import 'package:QUIK/modules/customer_po/models/customer_po_model.dart';
import 'package:QUIK/modules/customer_po/screens/form_services/customer_po_form_builder.dart';
import 'package:QUIK/modules/customer_po/screens/form_services/customer_po_form_controllers.dart';
import 'package:QUIK/modules/customer_po/screens/form_services/customer_po_form_draft.dart';
import 'package:QUIK/modules/customer_po/widgets/customer_po_item_row.dart';

class CustomerPoFormDraftFactory {
  const CustomerPoFormDraftFactory._();

  static CustomerPoModel build({
    required bool isEditMode,
    required String existingId,
    required String companyId,
    required CustomerPoFormControllers controllers,
    required DateTime poDate,
    required String customerId,
    required String customerName,
    required String customerEmail,
    required String customerMobile,
    required String customerAddress,
    required String customerGstNumber,
    required double basicValue,
    required double gstAmount,
    required double totalValue,
    required String existingStatus,
    required List<CustomerPoItemRow> items,
    required String? poDocumentUrl,
    required String? poFileName,
    required DateTime? uploadedAt,
  }) {
    final id = isEditMode
        ? existingId
        : DateTime.now().millisecondsSinceEpoch.toString();

    return CustomerPoFormBuilder.build(
      CustomerPoFormDraft(
        id: id,
        companyId: companyId,
        poNumber: controllers.poNumber.text.trim(),
        poDate: poDate,
        customerId: customerId,
        customerName: customerName,
        customerEmail: customerEmail,
        customerMobile: customerMobile,
        customerAddress: customerAddress,
        customerGstNumber: customerGstNumber,
        projectName: controllers.projectName.text.trim(),
        siteLocation: controllers.siteLocation.text.trim(),
        subject: controllers.subject.text.trim(),
        basicValue: basicValue,
        gstPercent: double.tryParse(controllers.gstPercent.text.trim()) ?? 0,
        gstAmount: gstAmount,
        totalValue: totalValue,
        paymentTerms: controllers.paymentTerms.text.trim(),
        deliveryTerms: controllers.deliveryTerms.text.trim(),
        inspectionRequirement: controllers.inspectionRequirement.text.trim(),
        warranty: controllers.warranty.text.trim(),
        ldClause: controllers.ldClause.text.trim(),
        status: isEditMode ? existingStatus : 'Draft',
        items: items,
        poDocumentUrl: poDocumentUrl,
        poFileName: poFileName,
        uploadedAt: uploadedAt,
      ),
    );
  }
}
