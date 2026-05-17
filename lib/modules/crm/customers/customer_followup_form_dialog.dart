import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'customer_followup_model.dart';

class CustomerFollowupFormDialog extends StatefulWidget {
  final DocumentReference<Map<String, dynamic>> customerRef;
  final DocumentSnapshot<Map<String, dynamic>>? existingDoc;
  final String currentUserName;

  const CustomerFollowupFormDialog({
    super.key,
    required this.customerRef,
    required this.currentUserName,
    this.existingDoc,
  });

  static Future<void> show(
    BuildContext context, {
    required DocumentReference<Map<String, dynamic>> customerRef,
    required String currentUserName,
    DocumentSnapshot<Map<String, dynamic>>? existingDoc,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => CustomerFollowupFormDialog(
        customerRef: customerRef,
        currentUserName: currentUserName,
        existingDoc: existingDoc,
      ),
    );
  }

  @override
  State<CustomerFollowupFormDialog> createState() =>
      _CustomerFollowupFormDialogState();
}

class _CustomerFollowupFormDialogState
    extends State<CustomerFollowupFormDialog> {
  final _formKey = GlobalKey<FormState>();

  final _title = TextEditingController();
  final _description = TextEditingController();
  final _assignedTo = TextEditingController();
  final _nextAction = TextEditingController();

  String _followUpType = CustomerFollowupModel.followUpTypes.first;
  String _priority = 'Medium';
  String _status = 'Open';
  DateTime _followUpDate = DateTime.now();
  DateTime? _reminderDate;
  bool _saving = false;

  bool get _isEdit => widget.existingDoc != null;

  CollectionReference<Map<String, dynamic>> get _ref =>
      widget.customerRef.collection('followUps');

  @override
  void initState() {
    super.initState();
    final doc = widget.existingDoc;
    if (doc != null) {
      final d = doc.data() ?? {};
      _title.text = (d['title'] ?? '').toString();
      _description.text = (d['description'] ?? '').toString();
      _assignedTo.text = (d['assignedTo'] ?? '').toString();
      _nextAction.text = (d['nextAction'] ?? '').toString();

      final type = (d['followUpType'] ?? '').toString();
      _followUpType = CustomerFollowupModel.followUpTypes.contains(type)
          ? type
          : CustomerFollowupModel.followUpTypes.first;

      final priority = (d['priority'] ?? '').toString();
      _priority = CustomerFollowupModel.priorities.contains(priority)
          ? priority
          : 'Medium';

      final status = (d['status'] ?? '').toString();
      _status = CustomerFollowupModel.statuses.contains(status)
          ? status
          : 'Open';

      final fud = d['followUpDate'];
      if (fud is Timestamp) _followUpDate = fud.toDate();

      final rd = d['reminderDate'];
      if (rd is Timestamp) _reminderDate = rd.toDate();
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _assignedTo.dispose();
    _nextAction.dispose();
    super.dispose();
  }

  Future<void> _pickFollowUpDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _followUpDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_followUpDate),
    );
    if (!mounted) return;
    setState(() {
      _followUpDate = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? _followUpDate.hour,
        time?.minute ?? _followUpDate.minute,
      );
    });
  }

  Future<void> _pickReminderDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _reminderDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (!mounted) return;
    setState(() => _reminderDate = date);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _saving = true);
    try {
      final followup = CustomerFollowupModel(
        id: widget.existingDoc?.id ?? '',
        title: _title.text.trim(),
        description: _description.text.trim(),
        followUpDate: _followUpDate,
        followUpType: _followUpType,
        priority: _priority,
        status: _status,
        assignedTo: _assignedTo.text.trim(),
        reminderDate: _reminderDate,
        nextAction: _nextAction.text.trim(),
        createdBy: widget.currentUserName,
        createdByUid: uid,
      );

      if (_isEdit) {
        await widget.existingDoc!.reference.update({
          ...followup.toMap(),
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedByUid': uid,
        });
      } else {
        await _ref.add({
          ...followup.toMap(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'createdByUid': uid,
          'updatedByUid': uid,
        });
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEdit ? 'Follow-up updated' : 'Follow-up added'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _dropdown<T>(
    String label,
    T value,
    List<T> items,
    ValueChanged<T?> onChanged,
  ) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
      items: items
          .map((e) => DropdownMenuItem<T>(value: e, child: Text(e.toString())))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _dateTile(String label, DateTime? date, VoidCallback onTap,
      {bool clearable = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                date != null
                    ? DateFormat('dd MMM yyyy, hh:mm a').format(date)
                    : label,
                style: TextStyle(
                  fontSize: 14,
                  color: date != null ? Colors.black87 : Colors.grey.shade500,
                ),
              ),
            ),
            if (clearable && date != null)
              GestureDetector(
                onTap: () => setState(() => _reminderDate = null),
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: Colors.grey.shade500,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: screenHeight - 80,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 12, 0),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue.shade50,
                    child: Icon(
                      Icons.phone_in_talk_outlined,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isEdit ? 'Edit Follow-up' : 'Add Follow-up',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _saving ? null : () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 16),
            // Scrollable body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _field(
                        'Title *',
                        _title,
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Title is required'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      _field('Description', _description, maxLines: 3),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _dropdown<String>(
                              'Type',
                              _followUpType,
                              CustomerFollowupModel.followUpTypes,
                              (v) =>
                                  setState(() => _followUpType = v ?? _followUpType),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _dropdown<String>(
                              'Priority',
                              _priority,
                              CustomerFollowupModel.priorities,
                              (v) => setState(() => _priority = v ?? _priority),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _dropdown<String>(
                              'Status',
                              _status,
                              CustomerFollowupModel.statuses,
                              (v) => setState(() => _status = v ?? _status),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _field('Assigned To', _assignedTo),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _LabelText('Follow-up Date *'),
                      const SizedBox(height: 6),
                      _dateTile(
                        'Select date & time',
                        _followUpDate,
                        _pickFollowUpDate,
                      ),
                      const SizedBox(height: 12),
                      _LabelText('Reminder Date (optional)'),
                      const SizedBox(height: 6),
                      _dateTile(
                        'Select reminder date',
                        _reminderDate,
                        _pickReminderDate,
                        clearable: true,
                      ),
                      const SizedBox(height: 12),
                      _field('Next Action', _nextAction, maxLines: 2),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            // Footer
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(_isEdit ? 'Update' : 'Add Follow-up'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LabelText extends StatelessWidget {
  final String text;
  const _LabelText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade700,
      ),
    );
  }
}
