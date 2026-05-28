part of '../screens_add_inquiry.dart';

extension _AddInquiryInsightsSection on _ScreensAddInquiryState {
  Widget _buildSmartInsightsPanel() {
    final warnings = <String>[];
    if (_nextFollowUpDate == null &&
        _selectedStage != 'Won' &&
        _selectedStage != 'Lost') {
      warnings.add('⚠ No follow-up scheduled');
    }
    if (_controllers.decisionMaker.text.trim().isEmpty) {
      warnings.add('⚠ No decision maker identified');
    }
    double expVal =
        double.tryParse(_controllers.expectedValue.text.trim()) ?? 0;
    if (expVal > 500000) {
      warnings.add('🔥 High value deal');
    }
    if (_structuredProducts.isEmpty) {
      warnings.add('⚠ No inquiry items linked');
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Inquiry Intelligence',
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInsightMetric(
                      'Inquiry Readiness',
                      '$_inquiryReadinessScore/100',
                      Icons.score,
                      _inquiryReadinessScore > 70
                          ? Colors.greenAccent
                          : (_inquiryReadinessScore > 40
                                ? Colors.orangeAccent
                                : Colors.redAccent),
                    ),
                    _buildInsightMetric(
                      'Win Prob.',
                      '${_probability.toInt()}%',
                      Icons.trending_up,
                      Colors.white,
                    ),
                    _buildInsightMetric(
                      'Exp. Value',
                      expVal > 0
                          ? '₹${NumberFormat.compact().format(expVal)}'
                          : 'TBD',
                      Icons.currency_rupee,
                      Colors.white,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (warnings.isNotEmpty) ...[
            Container(
              width: 1,
              height: 60,
              color: Colors.white24,
              margin: const EdgeInsets.symmetric(horizontal: 24),
            ),
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: warnings
                    .map(
                      (w) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          w,
                          style: TextStyle(
                            color: w.contains('🔥')
                                ? Colors.orangeAccent
                                : Colors.redAccent.shade100,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInsightMetric(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey.shade400),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
