import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ERPProductSearchDialog extends StatefulWidget {
  final String companyId;
  final Function(Map<String, dynamic> docData, String docId) onProductSelected;
  final Function(String query) onManualAdd;

  const ERPProductSearchDialog({
    super.key,
    required this.companyId,
    required this.onProductSelected,
    required this.onManualAdd,
  });

  @override
  State<ERPProductSearchDialog> createState() => ERPProductSearchDialogState();
}

class ERPProductSearchDialogState extends State<ERPProductSearchDialog> {
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<DocumentSnapshot> _allItems = [];
  List<DocumentSnapshot> _items = [];
  bool _isLoading = false;
  bool _hasMore = true;
  String _currentQuery = '';
  Timer? _debounce;
  int _searchEpoch = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchItems();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_currentQuery.isNotEmpty) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _fetchItems(loadMore: true);
    }
  }

  bool _matchesQuery(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final q = _currentQuery.trim().toLowerCase();
    if (q.isEmpty) return true;

    final fields = [
      data['itemName'],
      data['name'],
      data['category'],
      data['subCategory'],
      data['sku'],
      data['itemCode'],
      data['brand'],
      data['model'],
    ];

    return fields.any(
      (value) => (value ?? '').toString().toLowerCase().contains(q),
    );
  }

  void _applyLocalFilter() {
    final filtered = _currentQuery.isEmpty
        ? List<DocumentSnapshot>.from(_allItems)
        : _allItems.where(_matchesQuery).toList();

    if (!mounted) return;
    setState(() {
      _items = filtered;
    });
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final q = query.toLowerCase().trim();
      if (q != _currentQuery) {
        setState(() {
          _currentQuery = q;
        });
        _applyLocalFilter();
        if (_currentQuery.isNotEmpty && _items.isEmpty && _hasMore) {
          _fetchItems(loadMore: true);
        }
      }
    });
  }

  Future<void> _fetchItems({bool loadMore = false}) async {
    if (_isLoading || !_hasMore) return;
    if (loadMore && _allItems.isEmpty) return;

    final epoch = ++_searchEpoch;
    setState(() => _isLoading = true);

    try {
      Query<Map<String, dynamic>> ref = FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.companyId)
          .collection('products')
          .where('isActive', isEqualTo: true);

      ref = ref.limit(80);

      if (loadMore && _allItems.isNotEmpty) {
        ref = ref.startAfterDocument(_allItems.last);
      }

      final snap = await ref.get();

      if (epoch != _searchEpoch) return;

      final fetchedDocs = snap.docs
          .where((doc) => !_allItems.any((existing) => existing.id == doc.id))
          .toList();

      if (!mounted) return;
      setState(() {
        if (!loadMore) {
          _allItems = fetchedDocs;
        } else {
          _allItems.addAll(fetchedDocs);
        }
        _hasMore = snap.docs.length == 80;
        _items = _currentQuery.isEmpty
            ? List<DocumentSnapshot>.from(_allItems)
            : _allItems.where(_matchesQuery).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      title: const Text(
        'Select Product',
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
      ),
      content: SizedBox(
        width: 600,
        height: 500,
        child: Column(
          children: [
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                labelText: 'Search by Name, Category or SKU...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _onSearchChanged,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _items.isEmpty && !_isLoading
                  ? Center(
                      child: Text(
                        'No products found matching "$_currentQuery".\nYou can add manually below.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    )
                  : ListView.separated(
                      controller: _scrollController,
                      itemCount: _items.length + (_hasMore ? 1 : 0),
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      itemBuilder: (context, index) {
                        if (index == _items.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        final doc = _items[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final name =
                            (data['itemName'] ?? data['name'] ?? 'Unknown')
                                .toString();
                        final sku = (data['sku'] ?? data['itemCode'] ?? '')
                            .toString();
                        final price =
                            double.tryParse(
                              data['sellingPrice']?.toString() ??
                                  data['price']?.toString() ??
                                  '0',
                            ) ??
                            0.0;
                        final category = (data['category'] ?? '').toString();

                        return ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.inventory_2,
                              color: Colors.blue,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text('Cat: $category | SKU: $sku'),
                          trailing: Text(
                            '₹$price',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onTap: () => widget.onProductSelected(data, doc.id),
                        );
                      },
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
        FilledButton.icon(
          onPressed: () => widget.onManualAdd(_searchCtrl.text),
          icon: const Icon(Icons.edit_note, size: 18),
          label: const Text('Add Manually'),
        ),
      ],
    );
  }
}
