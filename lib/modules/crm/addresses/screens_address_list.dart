import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'customer_address_form_dialog.dart';
import 'customer_address_model.dart';

Color _typeColor(String type) {
  switch (type) {
    case 'Head Office':
      return Colors.blue.shade700;
    case 'Billing':
      return Colors.green.shade700;
    case 'Dispatch':
      return Colors.orange.shade800;
    case 'Plant':
      return Colors.purple.shade700;
    case 'Site':
      return Colors.teal.shade700;
    default:
      return Colors.grey.shade600;
  }
}

Color _typeBg(String type) {
  switch (type) {
    case 'Head Office':
      return Colors.blue.shade50;
    case 'Billing':
      return Colors.green.shade50;
    case 'Dispatch':
      return Colors.orange.shade50;
    case 'Plant':
      return Colors.purple.shade50;
    case 'Site':
      return Colors.teal.shade50;
    default:
      return Colors.grey.shade100;
  }
}

class ScreensAddressList extends StatefulWidget {
  final DocumentReference<Map<String, dynamic>> customerRef;
  final String companyName;

  const ScreensAddressList({
    super.key,
    required this.customerRef,
    required this.companyName,
  });

  @override
  State<ScreensAddressList> createState() => _ScreensAddressListState();
}

class _ScreensAddressListState extends State<ScreensAddressList> {
  final _search = TextEditingController();
  String _typeFilter = '';
  bool _onlyPrimary = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  CollectionReference<Map<String, dynamic>> get _addressesRef =>
      widget.customerRef.collection('addresses');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F7),
      appBar: AppBar(
        title: Text('Addresses — ${widget.companyName}'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: _goAdd,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Address'),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _addressesRef
            .orderBy('createdAt', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading addresses: ${snapshot.error}'),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          final all = docs.map((d) => _AddressRow.fromDoc(d)).toList();

          final q = _search.text.trim().toLowerCase();
          var filtered = all.where((r) {
            if (_typeFilter.isNotEmpty && r.addressType != _typeFilter) {
              return false;
            }
            if (_onlyPrimary && !r.isPrimary) return false;
            if (q.isEmpty) return true;
            return r.addressLine1.toLowerCase().contains(q) ||
                r.city.toLowerCase().contains(q) ||
                r.state.toLowerCase().contains(q) ||
                r.pincode.toLowerCase().contains(q) ||
                r.gstNumber.toLowerCase().contains(q) ||
                r.contactPerson.toLowerCase().contains(q);
          }).toList();

          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 940;

              if (isWide) {
                return Row(
                  children: [
                    SizedBox(width: 300, child: _filterPanel(all)),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 12, 14, 14),
                        child: Column(
                          children: [
                            _header(all, filtered),
                            const SizedBox(height: 10),
                            Expanded(child: _body(filtered)),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }

              return Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    _header(all, filtered),
                    const SizedBox(height: 10),
                    _mobileFilterBar(),
                    const SizedBox(height: 10),
                    Expanded(child: _body(filtered)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _body(List<_AddressRow> rows) {
    if (rows.isEmpty) return _emptyState();
    return _addressList(rows);
  }

  Widget _header(List<_AddressRow> all, List<_AddressRow> visible) {
    final primaryCount = all.where((r) => r.isPrimary).length;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE4E8F0)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF0FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.location_on_outlined,
                  color: Color(0xFF3F51B5),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.companyName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Manage delivery, billing and site addresses',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, c) {
              final pills = [
                _Pill(label: 'Visible', value: '${visible.length}'),
                _Pill(label: 'Total', value: '${all.length}'),
                _Pill(label: 'Primary', value: '$primaryCount'),
              ];
              if (c.maxWidth < 540) {
                return Wrap(spacing: 8, runSpacing: 8, children: pills);
              }
              return Row(
                children: [
                  Expanded(child: pills[0]),
                  const SizedBox(width: 8),
                  Expanded(child: pills[1]),
                  const SizedBox(width: 8),
                  Expanded(child: pills[2]),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _filterPanel(List<_AddressRow> all) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE4E8F0)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.filter_alt_outlined, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Filters',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search addresses...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _search.text.trim().isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _search.clear();
                            setState(() {});
                          },
                        ),
                  isDense: true,
                  filled: true,
                  fillColor: const Color(0xFFF7F8FB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Address Type',
                style: TextStyle(
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: _typeFilter.isEmpty,
                    onSelected: (_) => setState(() => _typeFilter = ''),
                  ),
                  ...CustomerAddressModel.addressTypes.map(
                    (t) => ChoiceChip(
                      label: Text(t),
                      selected: _typeFilter == t,
                      onSelected: (_) => setState(
                        () => _typeFilter = _typeFilter == t ? '' : t,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: _onlyPrimary,
                onChanged: (v) => setState(() => _onlyPrimary = v ?? false),
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: const Text('Primary Only'),
              ),
              const Spacer(),
              Row(
                children: [
                  TextButton(
                    onPressed: () => setState(() {
                      _typeFilter = '';
                      _onlyPrimary = false;
                      _search.clear();
                    }),
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mobileFilterBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE4E8F0)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search addresses...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _search.text.trim().isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _search.clear();
                        setState(() {});
                      },
                    ),
              isDense: true,
              filled: true,
              fillColor: const Color(0xFFF7F8FB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _typeFilter.isEmpty,
                  onSelected: (_) => setState(() => _typeFilter = ''),
                ),
                const SizedBox(width: 6),
                ...CustomerAddressModel.addressTypes.map(
                  (t) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(t),
                      selected: _typeFilter == t,
                      onSelected: (_) => setState(
                        () => _typeFilter = _typeFilter == t ? '' : t,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                FilterChip(
                  label: const Text('Primary'),
                  selected: _onlyPrimary,
                  onSelected: (v) => setState(() => _onlyPrimary = v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _addressList(List<_AddressRow> rows) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE4E8F0)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListView.separated(
        itemCount: rows.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final r = rows[i];
          return _AddressCard(
            row: r,
            onEdit: () => _goEdit(r),
            onDelete: () => _confirmDelete(r),
          );
        },
      ),
    );
  }

  Widget _emptyState() {
    final hasFilters =
        _search.text.trim().isNotEmpty ||
        _typeFilter.isNotEmpty ||
        _onlyPrimary;

    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 560),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE4E8F0)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: const Color(0xFFEEF0FF),
              child: Icon(
                hasFilters ? Icons.search_off : Icons.location_off_outlined,
                size: 32,
                color: const Color(0xFF3F51B5),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              hasFilters
                  ? 'No matching addresses found'
                  : 'No addresses added for this customer',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              hasFilters
                  ? 'Try adjusting the search or filters.'
                  : 'Add billing, dispatch, site and other address locations for this customer.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 14),
            if (hasFilters)
              OutlinedButton(
                onPressed: () => setState(() {
                  _typeFilter = '';
                  _onlyPrimary = false;
                  _search.clear();
                }),
                child: const Text('Reset Filters'),
              )
            else
              FilledButton.icon(
                onPressed: _goAdd,
                icon: const Icon(Icons.add),
                label: const Text('Add Address'),
              ),
          ],
        ),
      ),
    );
  }

  void _goAdd() {
    CustomerAddressFormDialog.show(context, customerRef: widget.customerRef);
  }

  void _goEdit(_AddressRow r) {
    CustomerAddressFormDialog.show(
      context,
      customerRef: widget.customerRef,
      addressDoc: r.doc,
    );
  }

  Future<void> _confirmDelete(_AddressRow r) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete address?'),
        content: Text(
          'Delete "${r.addressType}" at ${r.addressLine1.isNotEmpty ? r.addressLine1 : r.city}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    try {
      await r.doc.reference.delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Address deleted'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// ── Address card ──────────────────────────────────────────────────────────────

class _AddressCard extends StatelessWidget {
  final _AddressRow row;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AddressCard({
    required this.row,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final fullAddress = [
      row.addressLine1,
      if (row.addressLine2.isNotEmpty) row.addressLine2,
      [row.city, row.state, row.pincode].where((s) => s.isNotEmpty).join(', '),
      if (row.country.isNotEmpty && row.country != 'India') row.country,
    ].where((s) => s.isNotEmpty).join('\n');

    return InkWell(
      onTap: onEdit,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _typeBg(row.addressType),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.location_on_outlined,
                size: 20,
                color: _typeColor(row.addressType),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _typeBg(row.addressType),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: _typeColor(
                              row.addressType,
                            ).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          row.addressType,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: _typeColor(row.addressType),
                          ),
                        ),
                      ),
                      if (row.isPrimary)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Text(
                            'Primary',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    fullAddress.isEmpty ? '—' : fullAddress,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                    ),
                  ),
                  if (row.gstNumber.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _InfoBadge(
                      icon: Icons.receipt_outlined,
                      text: 'GST: ${row.gstNumber}',
                    ),
                  ],
                  if (row.contactPerson.isNotEmpty ||
                      row.mobile.isNotEmpty ||
                      row.email.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        if (row.contactPerson.isNotEmpty)
                          _InfoBadge(
                            icon: Icons.person_outline,
                            text: row.contactPerson,
                          ),
                        if (row.mobile.isNotEmpty)
                          _InfoBadge(
                            icon: Icons.phone_outlined,
                            text: row.mobile,
                          ),
                        if (row.email.isNotEmpty)
                          _InfoBadge(
                            icon: Icons.email_outlined,
                            text: row.email,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Actions',
              onSelected: (v) {
                if (v == 'edit') {
                  onEdit();
                } else if (v == 'delete') {
                  onDelete();
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit Address')),
                PopupMenuItem(value: 'delete', child: Text('Delete Address')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoBadge({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FB),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE4E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.blueGrey.shade700),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat pill ──────────────────────────────────────────────────────────────────

class _Pill extends StatelessWidget {
  final String label;
  final String value;

  const _Pill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Row model (local) ──────────────────────────────────────────────────────────

class _AddressRow {
  final DocumentSnapshot<Map<String, dynamic>> doc;
  final String addressType;
  final String addressLine1;
  final String addressLine2;
  final String city;
  final String state;
  final String country;
  final String pincode;
  final String gstNumber;
  final String contactPerson;
  final String mobile;
  final String email;
  final bool isPrimary;

  _AddressRow({
    required this.doc,
    required this.addressType,
    required this.addressLine1,
    required this.addressLine2,
    required this.city,
    required this.state,
    required this.country,
    required this.pincode,
    required this.gstNumber,
    required this.contactPerson,
    required this.mobile,
    required this.email,
    required this.isPrimary,
  });

  factory _AddressRow.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? {};
    return _AddressRow(
      doc: doc,
      addressType: (m['addressType'] ?? 'Head Office').toString(),
      addressLine1: (m['addressLine1'] ?? '').toString(),
      addressLine2: (m['addressLine2'] ?? '').toString(),
      city: (m['city'] ?? '').toString(),
      state: (m['state'] ?? '').toString(),
      country: (m['country'] ?? 'India').toString(),
      pincode: (m['pincode'] ?? '').toString(),
      gstNumber: (m['gstNumber'] ?? '').toString(),
      contactPerson: (m['contactPerson'] ?? '').toString(),
      mobile: (m['mobile'] ?? '').toString(),
      email: (m['email'] ?? '').toString(),
      isPrimary: m['isPrimary'] == true,
    );
  }
}
