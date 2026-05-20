import 'package:flutter/material.dart';

import 'package:QUIK/modules/customer_po/screens/form_services/customer_po_form_controllers.dart';
import 'package:QUIK/modules/customer_po/screens/form_widgets/keep_alive_page.dart';
import 'package:QUIK/modules/customer_po/screens/form_widgets/po_attachments_tab.dart';
import 'package:QUIK/modules/customer_po/screens/form_widgets/po_commercial_tab.dart';
import 'package:QUIK/modules/customer_po/screens/form_widgets/po_engineering_tab.dart';
import 'package:QUIK/modules/customer_po/screens/form_widgets/po_form_section_card.dart';
import 'package:QUIK/modules/customer_po/screens/form_widgets/po_overview_tab.dart';
import 'package:QUIK/modules/customer_po/screens/form_widgets/po_pdf_upload_card.dart';
import 'package:QUIK/modules/customer_po/screens/form_widgets/po_project_split_tab.dart';
import 'package:QUIK/modules/customer_po/screens/form_widgets/po_terms_tab.dart';
import 'package:QUIK/modules/customer_po/widgets/customer_po_item_row.dart';
import 'package:url_launcher/url_launcher.dart';

class PoFormTabs extends StatelessWidget {
  final CustomerPoFormControllers controllers;
  final bool isEditMode;
  final bool customerErrorVisible;
  final String customerId;
  final bool isLoadingCustomers;
  final String customerName;
  final String customerEmail;
  final String customerMobile;
  final String customerGstNumber;
  final String customerAddress;
  final VoidCallback showCustomerPicker;
  final Widget Function(
    String label,
    TextEditingController controller, {
    int maxLines,
    TextInputType keyboardType,
    bool required,
    bool readOnly,
  })
  fieldBuilder;
  final Widget Function(String label, String value, {bool bold}) summaryRow;
  final double basicValue;
  final double gstAmount;
  final double totalValue;
  final List<CustomerPoItemRow> items;
  final ValueChanged<List<CustomerPoItemRow>> onItemsChanged;
  final String? poFileName;
  final String? poDocumentUrl;
  final bool isUploading;
  final VoidCallback pickAndUploadPdf;
  final VoidCallback? uploadAmendedPdf;
  final VoidCallback removePdf;

  const PoFormTabs({
    super.key,
    required this.controllers,
    required this.isEditMode,
    required this.customerErrorVisible,
    required this.customerId,
    required this.isLoadingCustomers,
    required this.customerName,
    required this.customerEmail,
    required this.customerMobile,
    required this.customerGstNumber,
    required this.customerAddress,
    required this.showCustomerPicker,
    required this.fieldBuilder,
    required this.summaryRow,
    required this.basicValue,
    required this.gstAmount,
    required this.totalValue,
    required this.items,
    required this.onItemsChanged,
    required this.poFileName,
    required this.poDocumentUrl,
    required this.isUploading,
    required this.pickAndUploadPdf,
    this.uploadAmendedPdf,
    required this.removePdf,
  });

  @override
  Widget build(BuildContext context) {
    return TabBarView(
      children: [
        KeepAlivePage(
          child: PoOverviewTab(
            poNumber: controllers.poNumber,
            isEditMode: isEditMode,
            customerErrorVisible: customerErrorVisible,
            customerId: customerId,
            isLoadingCustomers: isLoadingCustomers,
            customerName: customerName,
            customerEmail: customerEmail,
            customerMobile: customerMobile,
            customerGstNumber: customerGstNumber,
            customerAddress: customerAddress,
            showCustomerPicker: showCustomerPicker,
            fieldBuilder: fieldBuilder,
          ),
        ),
        KeepAlivePage(
          child: PoCommercialTab(
            gstPercent: controllers.gstPercent,
            basicValue: basicValue,
            gstAmount: gstAmount,
            totalValue: totalValue,
            fieldBuilder: fieldBuilder,
            summaryRow: summaryRow,
            sectionCard: ({required title, required child}) =>
                PoFormSectionCard(title: title, child: child),
          ),
        ),
        KeepAlivePage(
          child: PoProjectSplitTab(
            projectName: controllers.projectName,
            siteLocation: controllers.siteLocation,
            subject: controllers.subject,
            fieldBuilder: fieldBuilder,
          ),
        ),
        KeepAlivePage(
          child: PoEngineeringTab(items: items, onChanged: onItemsChanged),
        ),
        KeepAlivePage(
          child: PoTermsTab(
            paymentTerms: controllers.paymentTerms,
            deliveryTerms: controllers.deliveryTerms,
            inspectionRequirement: controllers.inspectionRequirement,
            warranty: controllers.warranty,
            ldClause: controllers.ldClause,
            fieldBuilder: fieldBuilder,
          ),
        ),
        KeepAlivePage(
          child: PoAttachmentsTab(
            pdfUploadWidget: PoPdfUploadCard(
              fileName: poFileName,
              isUploading: isUploading,
              onPickPdf: pickAndUploadPdf,
              onUploadAmendedPdf: uploadAmendedPdf,
              onOpenPdf: poDocumentUrl == null
                  ? null
                  : () => launchUrl(
                      Uri.parse(poDocumentUrl!),
                      mode: LaunchMode.externalApplication,
                    ),
              onRemovePdf: removePdf,
            ),
          ),
        ),
      ],
    );
  }
}
