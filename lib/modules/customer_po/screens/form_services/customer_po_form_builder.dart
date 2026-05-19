import 'package:QUIK/modules/customer_po/models/customer_po_model.dart';
import 'package:QUIK/modules/customer_po/screens/form_services/customer_po_form_draft.dart';

class CustomerPoFormBuilder {
  const CustomerPoFormBuilder._();

  static CustomerPoModel build(CustomerPoFormDraft draft) {
    return CustomerPoModel(
      id: draft.id,
      companyId: draft.companyId,
      poNumber: draft.poNumber,
      poDate: draft.poDate,
      customerId: draft.customerId,
      customerName: draft.customerName,
      customerEmail: draft.customerEmail,
      customerMobile: draft.customerMobile,
      customerAddress: draft.customerAddress,
      customerGstNumber: draft.customerGstNumber,
      projectName: draft.projectName,
      siteLocation: draft.siteLocation,
      subject: draft.subject,
      basicValue: draft.basicValue,
      gstPercent: draft.gstPercent,
      gstAmount: draft.gstAmount,
      totalValue: draft.totalValue,
      paymentTerms: draft.paymentTerms,
      deliveryTerms: draft.deliveryTerms,
      inspectionRequirement: draft.inspectionRequirement,
      warranty: draft.warranty,
      ldClause: draft.ldClause,
      status: draft.status,
      items: draft.items,
      poDocumentUrl: draft.poDocumentUrl,
      poFileName: draft.poFileName,
      uploadedAt: draft.uploadedAt,
    );
  }
}
