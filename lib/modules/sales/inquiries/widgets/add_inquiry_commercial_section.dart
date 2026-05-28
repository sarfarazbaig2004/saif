// ignore_for_file: invalid_use_of_protected_member

part of '../screens_add_inquiry.dart';

extension _AddInquiryCommercialSection on _ScreensAddInquiryState {
  Widget _buildCommercialSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pipeline Stage',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 12),
        _buildPipelineIndicator(),
        const SizedBox(height: 8),
        const Text(
          'Move one stage at a time. Mark as Won only after quotation confirmation, and capture a loss reason for Lost.',
          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _controllers.expectedValue,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: _dec(
                  'Estimated Project Value (₹)',
                  prefixIcon: const Icon(Icons.monetization_on_outlined),
                ),
                onChanged: (v) => _calculateDealScore(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _controllers.budget,
                decoration: _dec(
                  'Customer Budget Range',
                  hint: 'E.g. 50k - 60k',
                  prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Win Probability: ${_probability.toInt()}%',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                    ),
                  ),
                  Slider(
                    value: _probability,
                    min: 0,
                    max: 100,
                    divisions: 10,
                    activeColor: const Color(0xFF2563EB),
                    inactiveColor: const Color(0xFFE2E8F0),
                    onChanged: (v) {
                      setState(() => _probability = v);
                      _calculateDealScore();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _controllers.competitor,
                decoration: _dec(
                  'Known Competitors',
                  prefixIcon: const Icon(Icons.shield_outlined),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _controllers.decisionMaker,
                decoration: _dec(
                  'Decision Maker Name / Info',
                  prefixIcon: const Icon(Icons.how_to_reg_outlined),
                ),
                onChanged: (v) => _calculateDealScore(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _controllers.projectSiteLocation,
                decoration: _dec(
                  'Project / Site Location',
                  hint: 'E.g. Mumbai Plant',
                  prefixIcon: const Icon(Icons.location_on_outlined),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
