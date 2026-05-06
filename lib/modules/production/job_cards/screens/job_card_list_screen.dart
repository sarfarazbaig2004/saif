import 'package:flutter/material.dart';

import 'package:QUIK/core/theme/app_theme.dart';
import 'package:QUIK/modules/production/job_cards/models/job_card_model.dart';
import 'package:QUIK/modules/production/job_cards/repositories/job_card_repository.dart';
import 'package:QUIK/modules/production/job_cards/screens/job_card_detail_screen.dart';
import 'package:QUIK/modules/production/job_cards/screens/job_card_form_screen.dart';

class JobCardListScreen extends StatelessWidget {
  final String tenantId;

  const JobCardListScreen({super.key, required this.tenantId});

  Future<void> _openForm(BuildContext context, String activeTenantId) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => JobCardFormScreen(tenantId: activeTenantId),
      ),
    );

    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Job card saved successfully')),
        );
    }
  }

  void _openDetail(
    BuildContext context,
    String activeTenantId,
    JobCardModel jobCard,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            JobCardDetailScreen(tenantId: activeTenantId, jobCard: jobCard),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeTenantId = tenantId.trim();
    if (activeTenantId.isEmpty) {
      return const Center(child: Text('Select a company workspace first.'));
    }

    final repository = JobCardRepository(tenantId: activeTenantId);

    return StreamBuilder<List<JobCardModel>>(
      stream: repository.watchJobCards(),
      builder: (context, snapshot) {
        final jobCards = snapshot.data ?? const <JobCardModel>[];

        return Container(
          color: zCanvasBg,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(
                count: jobCards.length,
                onCreate: () => _openForm(context, activeTenantId),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _JobCardBody(
                  loading: snapshot.connectionState == ConnectionState.waiting,
                  error: snapshot.error?.toString(),
                  jobCards: jobCards,
                  onOpen: (jobCard) =>
                      _openDetail(context, activeTenantId, jobCard),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final int count;
  final VoidCallback onCreate;

  const _Header({required this.count, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: zBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 420,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Job Cards',
                  style: TextStyle(
                    color: zText,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$count AMAN production job cards',
                  style: const TextStyle(
                    color: zMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add),
            label: const Text('New Job Card'),
          ),
        ],
      ),
    );
  }
}

class _JobCardBody extends StatelessWidget {
  final bool loading;
  final String? error;
  final List<JobCardModel> jobCards;
  final ValueChanged<JobCardModel> onOpen;

  const _JobCardBody({
    required this.loading,
    required this.error,
    required this.jobCards,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    if (loading && jobCards.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null && error!.isNotEmpty) {
      return Center(child: Text('Failed to load job cards: $error'));
    }

    if (jobCards.isEmpty) {
      return const Center(
        child: Text('No job cards yet. Create the first AMAN job card.'),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 760) {
          return ListView.separated(
            itemCount: jobCards.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              return _JobCardMobileCard(
                jobCard: jobCards[index],
                onTap: () => onOpen(jobCards[index]),
              );
            },
          );
        }

        return _JobCardTable(jobCards: jobCards, onOpen: onOpen);
      },
    );
  }
}

class _JobCardTable extends StatelessWidget {
  final List<JobCardModel> jobCards;
  final ValueChanged<JobCardModel> onOpen;

  const _JobCardTable({required this.jobCards, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: zBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(zSurfaceSoft),
              columnSpacing: 24,
              columns: const [
                DataColumn(label: Text('Job Card No')),
                DataColumn(label: Text('Item')),
                DataColumn(label: Text('Qty')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Contractor')),
                DataColumn(label: Text('Target Date')),
              ],
              rows: jobCards
                  .map((jobCard) {
                    return DataRow(
                      onSelectChanged: (_) => onOpen(jobCard),
                      cells: [
                        DataCell(Text(jobCard.jobCardNo)),
                        DataCell(Text(_safe(jobCard.itemDisplayName))),
                        DataCell(Text(_qty(jobCard))),
                        DataCell(_StatusPill(status: jobCard.status)),
                        DataCell(Text(_safe(jobCard.contractor))),
                        DataCell(Text(_date(jobCard.targetDate))),
                      ],
                    );
                  })
                  .toList(growable: false),
            ),
          ),
        ),
      ),
    );
  }
}

class _JobCardMobileCard extends StatelessWidget {
  final JobCardModel jobCard;
  final VoidCallback onTap;

  const _JobCardMobileCard({required this.jobCard, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: zBorder),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    jobCard.jobCardNo,
                    style: const TextStyle(
                      color: zText,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _StatusPill(status: jobCard.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _safe(jobCard.itemDisplayName),
              style: const TextStyle(color: zText, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              '${_qty(jobCard)} • ${_safe(jobCard.contractor)} • Target ${_date(jobCard.targetDate)}',
              style: const TextStyle(color: zMuted, fontSize: 12.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: zBlueSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _safe(status),
        style: const TextStyle(
          color: zBlue,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

String _safe(String value) => value.trim().isEmpty ? '-' : value.trim();

String _qty(JobCardModel jobCard) {
  return '${jobCard.plannedQty.toStringAsFixed(jobCard.plannedQty == jobCard.plannedQty.roundToDouble() ? 0 : 2)} ${_safe(jobCard.unit)}';
}

String _date(DateTime? value) {
  if (value == null) return '-';
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${value.day} ${months[value.month - 1]} ${value.year}';
}
