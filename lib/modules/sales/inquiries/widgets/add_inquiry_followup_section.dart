// ignore_for_file: invalid_use_of_protected_member

part of '../screens_add_inquiry.dart';

extension _AddInquiryFollowupSection on _ScreensAddInquiryState {
  Widget _buildFollowUpSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildResponsiveFields([
          _buildDateSelector(
            label: 'Next Follow-up Date *',
            value: _nextFollowUpDate,
            onTap: () async => await _pickDate(
              initialValue: _nextFollowUpDate,
              onPicked: (d) => setState(() {
                _nextFollowUpDate = d;
                _calculateInquiryReadiness();
              }),
            ),
            onClear: () => setState(() {
              _nextFollowUpDate = null;
              _calculateInquiryReadiness();
            }),
          ),
          DropdownButtonFormField<String>(
            initialValue: _followUpType,
            decoration: _dec(
              'Follow-up Type',
              prefixIcon: const Icon(Icons.event_outlined),
            ),
            items: [
              'Call',
              'Email',
              'Visit',
              'Meeting',
              'WhatsApp',
            ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setState(() => _followUpType = v ?? 'Call'),
          ),
        ]),
        const SizedBox(height: 16),
        const Text(
          'Priority Level',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: ['Cold', 'Warm', 'Hot'].map((p) {
            final isSelected = _selectedPriority == p;
            final color = p == 'Hot'
                ? Colors.red
                : (p == 'Warm' ? Colors.orange : Colors.blue);
            return Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: ChoiceChip(
                label: Text(
                  p,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                selected: isSelected,
                onSelected: (v) {
                  if (v) {
                    setState(() => _selectedPriority = p);
                    _calculateInquiryReadiness();
                  }
                },
                selectedColor: color,
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: isSelected ? color : Colors.grey.shade300,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (_inquiryReadinessScore > 70 &&
            _selectedPriority != 'Hot' &&
            _suggestedPriority == 'Hot')
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              '💡 High deal score! Consider marking as Hot.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        if (_inquiryReadinessScore < 40 &&
            _selectedPriority != 'Cold' &&
            _structuredProducts.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              '💡 Low deal score. Consider marking as Cold until better qualified.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _controllers.lastFollowUpNote,
          maxLines: 2,
          decoration: _dec(
            'Latest Follow-up Remarks',
            hint: 'E.g. Called client, asked for quote.',
            prefixIcon: const Icon(Icons.history_edu),
          ),
        ),
        if (_selectedStage == 'Lost') ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: _controllers.lossReason,
            maxLines: 2,
            decoration: _dec(
              'Loss Reason *',
              hint: 'E.g. Lost on price, competitor preference, no budget',
              prefixIcon: const Icon(Icons.cancel_outlined),
            ),
            validator: (value) {
              if (_selectedStage == 'Lost' &&
                  (value == null || value.trim().isEmpty)) {
                return 'Required for lost inquiries';
              }
              return null;
            },
          ),
        ],
        const SizedBox(height: 16),
        _buildDateSelector(
          label: 'Expected Closure Date',
          value: _expectedClosureDate,
          onTap: () async => await _pickDate(
            initialValue: _expectedClosureDate,
            onPicked: (d) {
              setState(() {
                _expectedClosureDate = d;
                _calculateInquiryReadiness();
              });
            },
          ),
          onClear: () => setState(() {
            _expectedClosureDate = null;
            _calculateInquiryReadiness();
          }),
        ),
        if (_isEditing && _existingRawData?['activityLog'] != null) ...[
          const SizedBox(height: 24),
          const Text(
            'Activity Timeline',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          _buildActivityTimeline(),
        ],
      ],
    );
  }
}
