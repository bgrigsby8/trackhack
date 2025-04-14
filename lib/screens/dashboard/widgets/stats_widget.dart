// lib/screens/dashboard/widgets/stats_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/project_provider.dart';
import '../../../models/project_model.dart';

class StatsWidget extends StatelessWidget {
  const StatsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final projectProvider = Provider.of<ProjectProvider>(context);
    final projects = projectProvider.projects;

    // Count projects by main status
    final statusCounts = <ProjectMainStatus, int>{};
    for (final status in ProjectMainStatus.values) {
      statusCounts[status] = 0;
    }

    // Count by sub-status for specific categories
    final subStatusCounts = <String, int>{};

    for (final project in projects) {
      // Update main status counts
      statusCounts[project.mainStatus] =
          (statusCounts[project.mainStatus] ?? 0) + 1;

      // Update sub-status counts
      subStatusCounts[project.subStatus] =
          (subStatusCounts[project.subStatus] ?? 0) + 1;
    }

    // Calculate deadlines
    final now = DateTime.now();
    final upcomingDeadlines = projects
        .where((p) => p.deadline.isAfter(now))
        .toList()
      ..sort((a, b) => a.deadline.compareTo(b.deadline));

    final missedDeadlines =
        projects.where((p) => p.deadline.isBefore(now)).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overview',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildStatCard(
                context,
                title: 'Total Projects',
                value: projects.length.toString(),
                icon: Icons.book,
                color: Theme.of(context).colorScheme.primary,
              ),
              _buildStatCard(
                context,
                title: 'In Progress',
                value: statusCounts[ProjectMainStatus.proofing].toString(),
                icon: Icons.pending_actions,
                color: Colors.orange,
              ),
              _buildStatCard(
                context,
                title: 'Published',
                value: subStatusCounts['published']?.toString() ?? '0',
                icon: Icons.check_circle,
                color: Colors.green,
              ),
              _buildStatCard(
                context,
                title: 'Missed Deadlines',
                value: missedDeadlines.toString(),
                icon: Icons.warning,
                color: Theme.of(context).colorScheme.error,
              ),
            ],
          ),
        ),
        if (upcomingDeadlines.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'Upcoming Deadlines',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    upcomingDeadlines.isEmpty
                        ? 'No upcoming deadlines'
                        : '${upcomingDeadlines.first.title} due in ${_formatDaysRemaining(upcomingDeadlines.first.deadline)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.chevron_right, size: 16),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(right: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 4),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDaysRemaining(DateTime deadline) {
    final daysRemaining = deadline.difference(DateTime.now()).inDays;

    if (daysRemaining == 0) return 'today';
    if (daysRemaining == 1) return 'tomorrow';
    return '$daysRemaining days';
  }
}
