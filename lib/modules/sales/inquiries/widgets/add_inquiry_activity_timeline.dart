part of '../screens_add_inquiry.dart';

extension _AddInquiryActivityTimeline on _ScreensAddInquiryState {
  Widget _buildActivityTimeline() {
    List<dynamic> logs = _existingRawData?['activityLog'] ?? [];
    if (logs.isEmpty) {
      return const Text(
        'No activity yet.',
        style: TextStyle(color: Colors.grey),
      );
    }

    logs.sort((a, b) {
      final tA = a['timestamp'] as Timestamp?;
      final tB = b['timestamp'] as Timestamp?;
      if (tA == null || tB == null) return 0;
      return tB.compareTo(tA);
    });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          ...logs.take(5).map((log) {
            final time = log['timestamp'] as Timestamp?;
            final dateStr = time != null
                ? DateFormat('dd MMM yy, hh:mm a').format(time.toDate())
                : '';
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 4.0),
                    child: Icon(
                      Icons.circle,
                      size: 8,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          log['action'] ?? 'Action',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        if (log['description'] != null)
                          Text(
                            log['description'],
                            style: const TextStyle(
                              color: Color(0xFF475569),
                              fontSize: 12,
                            ),
                          ),
                        Text(
                          dateStr,
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          if (logs.length > 5)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  _showFullTimelineDialog(logs);
                },
                child: const Text('View All Activity'),
              ),
            ),
        ],
      ),
    );
  }

  void _showFullTimelineDialog(List<dynamic> logs) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Full Activity Timeline'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: logs.length,
            itemBuilder: (ctx, i) {
              final log = logs[i];
              final time = log['timestamp'] as Timestamp?;
              final dateStr = time != null
                  ? DateFormat('dd MMM yy, hh:mm a').format(time.toDate())
                  : '';
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.check_circle_outline,
                  color: Color(0xFF2563EB),
                ),
                title: Text(
                  log['action'] ?? 'Action',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (log['description'] != null) Text(log['description']),
                    Text(
                      dateStr,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
