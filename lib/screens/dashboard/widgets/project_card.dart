// lib/screens/dashboard/widgets/project_card.dart
import 'package:flutter/material.dart';
import '../../../models/project_model.dart';
import '../../../utils/helpers.dart';

class ProjectCard extends StatelessWidget {
  final ProjectModel project;
  final VoidCallback onTap;

  const ProjectCard({
    super.key,
    required this.project,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card header with status
            _buildCardHeader(context),

            // Card content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.title,
                      style: Theme.of(context).textTheme.titleLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      project.description,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    _buildCardFooter(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardHeader(BuildContext context) {
    return Container(
      height: 8,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            project.getMainStatusColor(),
            project.getMainStatusColor().withValues(alpha: 0.7),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
    );
  }

  Widget _buildCardFooter(BuildContext context) {
    final daysLeft = project.deadline.difference(DateTime.now()).inDays;
    final isOverdue = daysLeft < 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Status chip
        Chip(
          backgroundColor: project.getMainStatusColor()
              .withValues(alpha: 0.2),
          label: Text(
            project.statusLabel,
            style: TextStyle(
              color: project.getMainStatusColor(),
              fontWeight: FontWeight.bold,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide.none,
          ),
        ),

        // Deadline text
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Deadline',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              AppHelpers.formatDate(project.deadline),
              style: TextStyle(
                color: isOverdue ? Theme.of(context).colorScheme.error : null,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
