import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:QUIK/modules/crm/customers/screens_add_customer.dart';
import 'package:QUIK/modules/crm/customers/screens_customer_followup_list.dart';
import 'package:QUIK/modules/crm/contacts/customer_contact_form_dialog.dart';
import 'package:QUIK/modules/crm/contacts/customer_contact_model.dart';
import 'package:QUIK/modules/crm/addresses/customer_address_form_dialog.dart';
import 'package:QUIK/modules/crm/addresses/customer_address_model.dart';
import 'package:QUIK/modules/customer_po/screens/customer_po_detail_screen.dart';

class CustomerDetailWorkspace extends StatelessWidget {
  final DocumentReference<Map<String, dynamic>> customerRef;
  final String companyId;
  final String currentUserUid;
  final String currentUserRole;
  final String currentUserName;
  final bool canEdit;
  final bool canDelete;

  const CustomerDetailWorkspace({
    super.key,
    required this.customerRef,
    required this.companyId,
    required this.currentUserUid,
    required this.currentUserRole,
    required this.currentUserName,
    required this.canEdit,
    required this.canDelete,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 8,
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: customerRef.snapshots(),
        builder: (context, snap) {
          final data = snap.data?.data() ?? {};
          final customerName = _str(data['companyName'] ?? data['name']);
          final gst = _str(data['gst']);
          final city = _str(data['city']);
          final state = _str(data['state']);
          final industry = _str(data['industry']);
          final customerType = _str(data['customerType']);
          final customerStage = _str(data['customerStage']);
          final status = _str(data['status']);
          final phone = _str(data['companyPhone'] ?? data['phone']);
          final email = _str(data['businessEmail'] ?? data['email']);
          final website = _str(data['website']);
          final notes = _str(data['notes']);

          final locationParts = [city, state].where((e) => e.isNotEmpty);
          final location = locationParts.join(', ');

          return Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            appBar: AppBar(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customerName.isNotEmpty ? customerName : 'Customer Detail',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (location.isNotEmpty)
                    Text(
                      location,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                ],
              ),
              actions: [
                if (canEdit)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Edit Customer',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ScreensAddCustomer(
                          existingDoc: customerRef,
                          companyId: companyId,
                          currentUserUid: currentUserUid,
                          currentUserRole: currentUserRole,
                        ),
                      ),
                    ),
                  ),
              ],
              bottom: const TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: Color(0xFF2563EB),
                labelColor: Color(0xFF2563EB),
                unselectedLabelColor: Colors.black54,
                labelStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                tabs: [
                  Tab(text: 'Overview'),
                  Tab(text: 'Contacts'),
                  Tab(text: 'Addresses'),
                  Tab(text: 'Follow-ups'),
                  Tab(text: 'Visits'),
                  Tab(text: 'Communication'),
                  Tab(text: 'Quotations'),
                  Tab(text: 'Customer POs'),
                ],
              ),
            ),
            body: Column(
              children: [
                _HeaderCard(
                  customerName: customerName,
                  gst: gst,
                  location: location,
                  industry: industry,
                  customerType: customerType,
                  customerStage: customerStage,
                  status: status,
                  customerRef: customerRef,
                  canEdit: canEdit,
                  companyId: companyId,
                  currentUserUid: currentUserUid,
                  currentUserRole: currentUserRole,
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _OverviewTab(
                        data: data,
                        phone: phone,
                        email: email,
                        website: website,
                        notes: notes,
                        customerRef: customerRef,
                      ),
                      _ContactsTab(customerRef: customerRef, canEdit: canEdit),
                      _AddressesTab(customerRef: customerRef, canEdit: canEdit),
                      _FollowUpsTab(
                        customerRef: customerRef,
                        companyId: companyId,
                        currentUserUid: currentUserUid,
                        currentUserName: currentUserName,
                        customerName: customerName,
                      ),
                      _VisitsTab(customerRef: customerRef),
                      _CommunicationTab(customerRef: customerRef),
                      _QuotationsTab(
                        companyId: companyId,
                        customerName: customerName,
                      ),
                      _CustomerPOsTab(
                        companyId: companyId,
                        customerId: customerRef.id,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static String _str(dynamic v) => (v ?? '').toString().trim();
}

// ─────────────────────────────────────────────────────────────────────────────
// Header Card
// ─────────────────────────────────────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  final String customerName;
  final String gst;
  final String location;
  final String industry;
  final String customerType;
  final String customerStage;
  final String status;
  final DocumentReference<Map<String, dynamic>> customerRef;
  final bool canEdit;
  final String companyId;
  final String currentUserUid;
  final String currentUserRole;

  const _HeaderCard({
    required this.customerName,
    required this.gst,
    required this.location,
    required this.industry,
    required this.customerType,
    required this.customerStage,
    required this.status,
    required this.customerRef,
    required this.canEdit,
    required this.companyId,
    required this.currentUserUid,
    required this.currentUserRole,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: const Color(0xFFDBEAFE),
            child: Text(
              customerName.isNotEmpty ? customerName[0].toUpperCase() : '?',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E40AF),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customerName.isNotEmpty ? customerName : '—',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (gst.isNotEmpty)
                      _MiniChip(label: 'GST: $gst', color: Colors.grey),
                    if (location.isNotEmpty)
                      _MiniChip(
                        label: location,
                        color: Colors.blueGrey,
                        icon: Icons.location_on_outlined,
                      ),
                    if (customerStage.isNotEmpty)
                      _MiniChip(
                        label: customerStage,
                        color:
                            customerStage.toLowerCase() == 'existing customer'
                            ? Colors.green
                            : Colors.orange,
                      ),
                    if (status.isNotEmpty)
                      _MiniChip(label: status, color: Colors.indigo),
                    if (industry.isNotEmpty)
                      _MiniChip(label: industry, color: Colors.teal),
                    if (customerType.isNotEmpty)
                      _MiniChip(label: customerType, color: Colors.purple),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _CountBadge(
                label: 'Contacts',
                stream: customerRef.collection('contacts').snapshots(),
              ),
              const SizedBox(height: 4),
              _CountBadge(
                label: 'Addresses',
                stream: customerRef.collection('addresses').snapshots(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final String label;
  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;

  const _CountBadge({required this.label, required this.stream});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snap) {
        final count = snap.data?.docs.length ?? 0;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$label: $count',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade800,
            ),
          ),
        );
      },
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  final MaterialColor color;
  final IconData? icon;

  const _MiniChip({required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color.shade700),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color.shade800,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab: Overview
// ─────────────────────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final Map<String, dynamic> data;
  final String phone;
  final String email;
  final String website;
  final String notes;
  final DocumentReference<Map<String, dynamic>> customerRef;

  const _OverviewTab({
    required this.data,
    required this.phone,
    required this.email,
    required this.website,
    required this.notes,
    required this.customerRef,
  });

  @override
  Widget build(BuildContext context) {
    final pan = _str(data['pan']);
    final leadSource = _str(data['leadSource']);
    final priority = _str(data['priority']);
    final assignedToName = _str(data['assignedToName']);
    final street = _str(data['street']);
    final pincode = _str(data['pincode']);
    final country = _str(data['country']);
    final remarks = _str(data['remarks']);

    final addressParts = [street, pincode, country].where((e) => e.isNotEmpty);
    final fullAddress = addressParts.join(', ');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Section(
          title: 'Contact Information',
          icon: Icons.contact_phone_outlined,
          emptyMessage: 'No contact info recorded',
          children: [
            if (phone.isNotEmpty) _InfoRow(label: 'Phone', value: phone),
            if (email.isNotEmpty) _InfoRow(label: 'Email', value: email),
            if (website.isNotEmpty) _InfoRow(label: 'Website', value: website),
          ],
        ),
        const SizedBox(height: 12),
        _Section(
          title: 'Company Details',
          icon: Icons.business_outlined,
          emptyMessage: 'No company details recorded',
          children: [
            if (pan.isNotEmpty) _InfoRow(label: 'PAN', value: pan),
            if (leadSource.isNotEmpty)
              _InfoRow(label: 'Lead Source', value: leadSource),
            if (priority.isNotEmpty)
              _InfoRow(label: 'Priority', value: priority),
            if (assignedToName.isNotEmpty)
              _InfoRow(label: 'Assigned To', value: assignedToName),
          ],
        ),
        const SizedBox(height: 12),
        if (fullAddress.isNotEmpty)
          _Section(
            title: 'Address',
            icon: Icons.location_on_outlined,
            emptyMessage: '',
            children: [_InfoRow(label: 'Address', value: fullAddress)],
          ),
        if (fullAddress.isNotEmpty) const SizedBox(height: 12),
        _Section(
          title: 'Primary Contact Person',
          icon: Icons.person_outline,
          emptyMessage: '',
          customContent: _PrimaryContactWidget(customerRef: customerRef),
          children: const [],
        ),
        const SizedBox(height: 12),
        if (notes.isNotEmpty || remarks.isNotEmpty)
          _Section(
            title: 'Notes & Remarks',
            icon: Icons.note_outlined,
            emptyMessage: '',
            children: [
              if (notes.isNotEmpty) _InfoRow(label: 'Notes', value: notes),
              if (remarks.isNotEmpty)
                _InfoRow(label: 'Remarks', value: remarks),
            ],
          ),
      ],
    );
  }

  static String _str(dynamic v) => (v ?? '').toString().trim();
}

class _PrimaryContactWidget extends StatelessWidget {
  final DocumentReference<Map<String, dynamic>> customerRef;

  const _PrimaryContactWidget({required this.customerRef});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: customerRef
          .collection('contacts')
          .where('isPrimary', isEqualTo: true)
          .limit(1)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Loading...',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          );
        }
        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              'No primary contact set',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
          );
        }
        final d = docs.first.data();
        final contact = CustomerContactModel.fromMap(docs.first.id, d);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoRow(label: 'Name', value: contact.name),
            if (contact.designation.isNotEmpty)
              _InfoRow(label: 'Designation', value: contact.designation),
            if (contact.department.isNotEmpty)
              _InfoRow(label: 'Department', value: contact.department),
            if (contact.mobile.isNotEmpty)
              _InfoRow(label: 'Mobile', value: contact.mobile),
            if (contact.email.isNotEmpty)
              _InfoRow(label: 'Email', value: contact.email),
          ],
        );
      },
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  final String emptyMessage;
  final Widget? customContent;

  const _Section({
    required this.title,
    required this.icon,
    required this.children,
    required this.emptyMessage,
    this.customContent,
  });

  @override
  Widget build(BuildContext context) {
    final hasContent = children.isNotEmpty || customContent != null;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Icon(icon, size: 16, color: const Color(0xFF2563EB)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: hasContent
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...children,
                      if (customContent != null) customContent!,
                    ],
                  )
                : Text(
                    emptyMessage,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab: Contacts
// ─────────────────────────────────────────────────────────────────────────────

class _ContactsTab extends StatelessWidget {
  final DocumentReference<Map<String, dynamic>> customerRef;
  final bool canEdit;

  const _ContactsTab({required this.customerRef, required this.canEdit});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: customerRef
          .collection('contacts')
          .orderBy('createdAt')
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        return Stack(
          children: [
            docs.isEmpty
                ? _EmptyTabState(
                    icon: Icons.person_outline,
                    message: 'No contacts added for this customer',
                    action: canEdit
                        ? _AddButton(
                            label: 'Add Contact',
                            onTap: () => CustomerContactFormDialog.show(
                              context,
                              customerRef: customerRef,
                            ),
                          )
                        : null,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final doc = docs[i];
                      final d = doc.data();
                      final contact = CustomerContactModel.fromMap(doc.id, d);
                      return _ContactCard(
                        contact: contact,
                        doc: doc,
                        customerRef: customerRef,
                        canEdit: canEdit,
                      );
                    },
                  ),
            if (canEdit && docs.isNotEmpty)
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton.extended(
                  heroTag: 'add_contact_fab',
                  onPressed: () => CustomerContactFormDialog.show(
                    context,
                    customerRef: customerRef,
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Contact'),
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ContactCard extends StatelessWidget {
  final CustomerContactModel contact;
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final DocumentReference<Map<String, dynamic>> customerRef;
  final bool canEdit;

  const _ContactCard({
    required this.contact,
    required this.doc,
    required this.customerRef,
    required this.canEdit,
  });

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Contact'),
        content: Text('Delete "${contact.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await doc.reference.delete();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Contact deleted'),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: contact.isPrimary
              ? Colors.green.shade200
              : Colors.grey.shade200,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.blue.shade50,
              child: Text(
                contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.blue.shade700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          contact.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (contact.isPrimary)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Text(
                            'Primary',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (contact.designation.isNotEmpty ||
                      contact.department.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      [
                        contact.designation,
                        contact.department,
                      ].where((e) => e.isNotEmpty).join(' • '),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [
                      if (contact.mobile.isNotEmpty)
                        _ContactBadge(
                          icon: Icons.phone_outlined,
                          label: contact.mobile,
                        ),
                      if (contact.email.isNotEmpty)
                        _ContactBadge(
                          icon: Icons.email_outlined,
                          label: contact.email,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (canEdit) ...[
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                onPressed: () => CustomerContactFormDialog.show(
                  context,
                  customerRef: customerRef,
                  contactDoc: doc,
                ),
                tooltip: 'Edit',
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: Colors.red.shade400,
                ),
                onPressed: () => _delete(context),
                tooltip: 'Delete',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ContactBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ContactBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab: Addresses
// ─────────────────────────────────────────────────────────────────────────────

class _AddressesTab extends StatelessWidget {
  final DocumentReference<Map<String, dynamic>> customerRef;
  final bool canEdit;

  const _AddressesTab({required this.customerRef, required this.canEdit});

  static const Map<String, Color> _typeColors = {
    'Head Office': Color(0xFF1E40AF),
    'Billing': Color(0xFF065F46),
    'Dispatch': Color(0xFF92400E),
    'Plant': Color(0xFF4C1D95),
    'Site': Color(0xFF134E4A),
  };

  static Color _colorFor(String type) =>
      _typeColors[type] ?? const Color(0xFF374151);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: customerRef
          .collection('addresses')
          .orderBy('createdAt')
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        return Stack(
          children: [
            docs.isEmpty
                ? _EmptyTabState(
                    icon: Icons.location_on_outlined,
                    message: 'No addresses added for this customer',
                    action: canEdit
                        ? _AddButton(
                            label: 'Add Address',
                            onTap: () => CustomerAddressFormDialog.show(
                              context,
                              customerRef: customerRef,
                            ),
                          )
                        : null,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final doc = docs[i];
                      final d = doc.data();
                      final address = CustomerAddressModel.fromMap(doc.id, d);
                      return _AddressCard(
                        address: address,
                        doc: doc,
                        customerRef: customerRef,
                        canEdit: canEdit,
                        typeColor: _colorFor(address.addressType),
                      );
                    },
                  ),
            if (canEdit && docs.isNotEmpty)
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton.extended(
                  heroTag: 'add_address_fab',
                  onPressed: () => CustomerAddressFormDialog.show(
                    context,
                    customerRef: customerRef,
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Address'),
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _AddressCard extends StatelessWidget {
  final CustomerAddressModel address;
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final DocumentReference<Map<String, dynamic>> customerRef;
  final bool canEdit;
  final Color typeColor;

  const _AddressCard({
    required this.address,
    required this.doc,
    required this.customerRef,
    required this.canEdit,
    required this.typeColor,
  });

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Address'),
        content: const Text('Delete this address? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await doc.reference.delete();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Address deleted'),
        backgroundColor: Colors.red,
      ),
    );
  }

  String get _fullAddress {
    final parts = [
      address.addressLine1,
      address.addressLine2,
      address.city,
      address.state,
      address.pincode,
      address.country,
    ].where((e) => e.isNotEmpty);
    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: address.isPrimary
              ? Colors.green.shade200
              : Colors.grey.shade200,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    address.addressType,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: typeColor,
                    ),
                  ),
                ),
                if (address.isPrimary) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Text(
                      'Primary',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                if (canEdit) ...[
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    onPressed: () => CustomerAddressFormDialog.show(
                      context,
                      customerRef: customerRef,
                      addressDoc: doc,
                    ),
                    tooltip: 'Edit',
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: Colors.red.shade400,
                    ),
                    onPressed: () => _delete(context),
                    tooltip: 'Delete',
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _fullAddress.isNotEmpty ? _fullAddress : '—',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            if (address.gstNumber.isNotEmpty ||
                address.contactPerson.isNotEmpty ||
                address.mobile.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (address.gstNumber.isNotEmpty)
                    _ContactBadge(
                      icon: Icons.receipt_outlined,
                      label: 'GST: ${address.gstNumber}',
                    ),
                  if (address.contactPerson.isNotEmpty)
                    _ContactBadge(
                      icon: Icons.person_outline,
                      label: address.contactPerson,
                    ),
                  if (address.mobile.isNotEmpty)
                    _ContactBadge(
                      icon: Icons.phone_outlined,
                      label: address.mobile,
                    ),
                  if (address.email.isNotEmpty)
                    _ContactBadge(
                      icon: Icons.email_outlined,
                      label: address.email,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab: Follow-ups
// ─────────────────────────────────────────────────────────────────────────────

class _FollowUpsTab extends StatelessWidget {
  final DocumentReference<Map<String, dynamic>> customerRef;
  final String companyId;
  final String currentUserUid;
  final String currentUserName;
  final String customerName;

  const _FollowUpsTab({
    required this.customerRef,
    required this.companyId,
    required this.currentUserUid,
    required this.currentUserName,
    required this.customerName,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: customerRef
          .collection('followUps')
          .orderBy('followUpDate', descending: true)
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Text(
                    '${docs.length} Follow-up${docs.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    icon: const Icon(Icons.open_in_new, size: 15),
                    label: const Text(
                      'Open Full View',
                      style: TextStyle(fontSize: 13),
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ScreensCustomerFollowUpList(
                          customerRef: customerRef,
                          companyId: companyId,
                          currentUserUid: currentUserUid,
                          currentUserName: currentUserName,
                          customerName: customerName,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: docs.isEmpty
                  ? _EmptyTabState(
                      icon: Icons.phone_in_talk_outlined,
                      message: 'No follow-ups recorded',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final d = docs[i].data();
                        return _FollowUpCard(data: d);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _FollowUpCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _FollowUpCard({required this.data});

  String _formatDate(dynamic v) {
    if (v == null) return '—';
    if (v is Timestamp) {
      return DateFormat('dd MMM yyyy, hh:mm a').format(v.toDate());
    }
    return '—';
  }

  @override
  Widget build(BuildContext context) {
    final mode = (data['followUpMode'] ?? '').toString();
    final outcome = (data['outcome'] ?? '').toString();
    final notes = (data['notes'] ?? '').toString();
    final date = _formatDate(data['followUpDate']);
    final nextDate = _formatDate(data['nextFollowUpDate']);
    final contactName = (data['contactName'] ?? '').toString();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (mode.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    mode,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              Text(
                date,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(notes, style: const TextStyle(fontSize: 13)),
          ],
          if (outcome.isNotEmpty || contactName.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [
                if (outcome.isNotEmpty)
                  _ContactBadge(
                    icon: Icons.check_circle_outline,
                    label: outcome,
                  ),
                if (contactName.isNotEmpty)
                  _ContactBadge(icon: Icons.person_outline, label: contactName),
              ],
            ),
          ],
          if (nextDate != '—') ...[
            const SizedBox(height: 6),
            _ContactBadge(
              icon: Icons.calendar_today_outlined,
              label: 'Next: $nextDate',
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab: Visits
// ─────────────────────────────────────────────────────────────────────────────

class _VisitsTab extends StatelessWidget {
  final DocumentReference<Map<String, dynamic>> customerRef;

  const _VisitsTab({required this.customerRef});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: customerRef.collection('visits').snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const _EmptyTabState(
            icon: Icons.directions_car_outlined,
            message: 'No visits recorded for this customer',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final d = docs[i].data();
            final title = (d['title'] ?? d['subject'] ?? 'Visit').toString();
            final date = d['visitDate'];
            final dateStr = date is Timestamp
                ? DateFormat('dd MMM yyyy').format(date.toDate())
                : '—';
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(
                    Icons.directions_car_outlined,
                    color: Colors.teal.shade400,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          dateStr,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab: Communication
// ─────────────────────────────────────────────────────────────────────────────

class _CommunicationTab extends StatelessWidget {
  final DocumentReference<Map<String, dynamic>> customerRef;

  const _CommunicationTab({required this.customerRef});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: customerRef.collection('communication').snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const _EmptyTabState(
            icon: Icons.chat_outlined,
            message: 'No communication history for this customer',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final d = docs[i].data();
            final type = (d['type'] ?? 'Message').toString();
            final message = (d['message'] ?? d['notes'] ?? '').toString();
            final ts = d['createdAt'];
            final dateStr = ts is Timestamp
                ? DateFormat('dd MMM yyyy').format(ts.toDate())
                : '—';
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.chat_outlined, color: Colors.indigo.shade400),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          type,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (message.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(message, style: const TextStyle(fontSize: 13)),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          dateStr,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab: Quotations
// ─────────────────────────────────────────────────────────────────────────────

class _QuotationsTab extends StatelessWidget {
  final String companyId;
  final String customerName;

  const _QuotationsTab({required this.companyId, required this.customerName});

  @override
  Widget build(BuildContext context) {
    final lowerName = customerName.toLowerCase();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('companies')
          .doc(companyId)
          .collection('quotations')
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final allDocs = snap.data?.docs ?? [];
        final docs = lowerName.isEmpty
            ? allDocs
            : allDocs.where((doc) {
                final client = (doc.data()['clientName'] ?? '')
                    .toString()
                    .toLowerCase();
                return client.contains(lowerName) ||
                    lowerName.contains(client) && client.isNotEmpty;
              }).toList();

        if (docs.isEmpty) {
          return const _EmptyTabState(
            icon: Icons.description_outlined,
            message: 'No quotations found for this customer',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final d = docs[i].data();
            final quoteNo = (d['quotationNumber'] ?? d['quoteNo'] ?? '—')
                .toString();
            final client = (d['clientName'] ?? '').toString();
            final status = (d['status'] ?? '').toString();
            final date = d['date'];
            final dateStr = date is Timestamp
                ? DateFormat('dd MMM yyyy').format(date.toDate())
                : '—';
            final total = (d['totalAmount'] ?? d['total'] ?? 0);
            final totalStr = total is num
                ? '₹${NumberFormat('#,##,###').format(total)}'
                : '—';

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(Icons.description_outlined, color: Colors.blue.shade400),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quoteNo,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (client.isNotEmpty)
                          Text(
                            client,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          children: [
                            Text(
                              dateStr,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            if (totalStr != '—')
                              Text(
                                totalStr,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (status.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _quotationStatusColor(
                          status,
                        ).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _quotationStatusColor(status),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static Color _quotationStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'sent':
        return Colors.blue;
      case 'rejected':
        return Colors.red;
      case 'draft':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab: Customer POs
// ─────────────────────────────────────────────────────────────────────────────

class _CustomerPOsTab extends StatelessWidget {
  final String companyId;
  final String customerId;

  const _CustomerPOsTab({required this.companyId, required this.customerId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('companies')
          .doc(companyId)
          .collection('customer_pos')
          .where('customerId', isEqualTo: customerId)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data?.docs ?? [];

        if (docs.isEmpty) {
          return const _EmptyTabState(
            icon: Icons.assignment_outlined,
            message: 'No customer POs for this customer',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final d = docs[i].data();
            final poNumber = (d['poNumber'] ?? '—').toString();
            final status = (d['status'] ?? '').toString();
            final total = (d['totalValue'] ?? 0);
            final totalStr = total is num
                ? '₹${NumberFormat('#,##,###').format(total)}'
                : '—';
            final dateRaw = d['poDate'];
            String dateStr = '—';
            if (dateRaw is Timestamp) {
              dateStr = DateFormat('dd MMM yyyy').format(dateRaw.toDate());
            } else if (dateRaw is String && dateRaw.isNotEmpty) {
              final parsed = DateTime.tryParse(dateRaw);
              if (parsed != null) {
                dateStr = DateFormat('dd MMM yyyy').format(parsed);
              }
            }
            final project = (d['projectName'] ?? '').toString();

            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CustomerPoDetailScreen(
                    companyId: companyId,
                    docId: docs[i].id,
                  ),
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(
                      Icons.assignment_outlined,
                      color: Colors.deepPurple.shade400,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            poNumber,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (project.isNotEmpty)
                            Text(
                              project,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            children: [
                              Text(
                                dateStr,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                              if (totalStr != '—')
                                Text(
                                  totalStr,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (status.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _poStatusColor(status).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _poStatusColor(status),
                          ),
                        ),
                      ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right, color: Colors.grey.shade400),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  static Color _poStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'completed':
        return Colors.teal;
      case 'rejected':
        return Colors.red;
      case 'draft':
        return Colors.orange;
      case 'submitted':
        return Colors.blue;
      case 'in production':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared Utilities
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyTabState extends StatelessWidget {
  final IconData icon;
  final String message;
  final Widget? action;

  const _EmptyTabState({
    required this.icon,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _AddButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
      onPressed: onTap,
      icon: const Icon(Icons.add),
      label: Text(label),
    );
  }
}
