import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:campus_connect/services/admin_report_service.dart';

class AdminReportsScreen extends StatelessWidget {
  AdminReportsScreen({super.key});

  final AdminReportService _reportService = AdminReportService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gemeldete Beiträge')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _reportService.getOpenReports(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Meldungen konnten nicht geladen werden.\n'
                  '${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final reports = snapshot.data?.docs.toList() ?? [];

          reports.sort((a, b) {
            final aCreatedAt = a.data()['createdAt'] as Timestamp?;
            final bCreatedAt = b.data()['createdAt'] as Timestamp?;

            if (aCreatedAt == null && bCreatedAt == null) return 0;
            if (aCreatedAt == null) return 1;
            if (bCreatedAt == null) return -1;

            return bCreatedAt.compareTo(aCreatedAt);
          });
          if (reports.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_outlined, size: 56),
                  SizedBox(height: 12),
                  Text('Keine offenen Meldungen.'),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final report = reports[index];
              final data = report.data();

              final reason = (data['reason'] ?? '').toString();

              final postId = (data['postId'] ?? '').toString();

              final reportedUserId = (data['reportedUserId'] ?? '').toString();

              final createdAt = data['createdAt'] as Timestamp?;

              final formattedDate =
                  createdAt == null
                      ? 'Unbekannter Zeitpunkt'
                      : _formatDate(createdAt.toDate());

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.flag_outlined),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _reasonLabel(reason),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Text('Gemeldet am $formattedDate'),

                      const SizedBox(height: 8),

                      Text(
                        'Post-ID: $postId',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),

                      Text(
                        'Nutzer-ID: $reportedUserId',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),

                      const SizedBox(height: 16),

                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.icon(
                          onPressed: () async {
                            await _resolveReport(context, report.id);
                          },
                          icon: const Icon(Icons.check_outlined),
                          label: const Text('Als erledigt markieren'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _resolveReport(BuildContext context, String reportId) async {
    try {
      await _reportService.markAsResolved(reportId);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meldung wurde als erledigt markiert.')),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Meldung konnte nicht bearbeitet werden: $e')),
      );
    }
  }

  String _reasonLabel(String reason) {
    switch (reason) {
      case 'spam':
        return 'Spam';

      case 'harassment':
        return 'Beleidigung oder Belästigung';

      case 'inappropriate':
        return 'Unangemessener Inhalt';

      case 'other':
        return 'Sonstiges';

      default:
        return 'Unbekannter Meldegrund';
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day.$month.${date.year}, '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }
}
