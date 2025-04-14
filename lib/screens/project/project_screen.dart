// lib/screens/project/project_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/project_provider.dart';
import '../../providers/document_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/project_model.dart';

class ProjectScreen extends StatefulWidget {
  final String projectId;

  const ProjectScreen({
    super.key,
    required this.projectId,
  });

  @override
  State<ProjectScreen> createState() => _ProjectScreenState();
}

class _ProjectScreenState extends State<ProjectScreen> {
  // Track expanded status for each main status category
  final Map<ProjectMainStatus, bool> _expandedStatuses = {
    ProjectMainStatus.design: false,
    ProjectMainStatus.paging: false,
    ProjectMainStatus.proofing: false,
    ProjectMainStatus.epub: false,
    ProjectMainStatus.other: false,
  };

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final projectProvider =
          Provider.of<ProjectProvider>(context, listen: false);
      final documentProvider =
          Provider.of<DocumentProvider>(context, listen: false);

      projectProvider.getProjectById(widget.projectId).then((_) {
        // Once project is loaded, expand the current status section
        if (mounted && projectProvider.currentProject != null) {
          setState(() {
            // Set all to false first
            for (var status in ProjectMainStatus.values) {
              _expandedStatuses[status] = false;
            }
            // Then expand only the current status
            _expandedStatuses[projectProvider.currentProject!.mainStatus] =
                true;
          });
        }
      });

      documentProvider.setCurrentProject(widget.projectId);
    });
  }

  // No TabController to dispose

  @override
  Widget build(BuildContext context) {
    final projectProvider = Provider.of<ProjectProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final project = projectProvider.currentProject;

    if (project == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Project')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(project.title),
        actions: [
          if (project.ownerId == authProvider.user?.id)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditProjectDialog(context, project),
            ),
          if (project.ownerId == authProvider.user?.id)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _showDeleteProjectDialog(context, project),
            ),
        ],
      ),
      body: Column(
        children: [
          // Project header and status workflow
          Expanded(
            child: SingleChildScrollView(
              child: _buildProjectHeader(context, project),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDocumentDialog(context, project),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildProjectHeader(BuildContext context, ProjectModel project) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Project title and current status
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      project.description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(project.mainStatus),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  project.statusLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Project deadline
          Row(
            children: [
              const Icon(
                Icons.calendar_today,
                size: 16,
                color: Colors.grey,
              ),
              const SizedBox(width: 4),
              Text(
                'Deadline: ${_formatDate(project.deadline)}',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Status sections
          const Text(
            'Project Status Workflow',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Build a section for each main status
          _buildStatusSection(context, ProjectMainStatus.design, 'Design Phase',
              Colors.purple, project),
          _buildStatusSection(context, ProjectMainStatus.paging, 'Paging Phase',
              Colors.blue, project),
          _buildStatusSection(context, ProjectMainStatus.proofing,
              'Proofing Phase', Colors.orange, project),
          _buildStatusSection(context, ProjectMainStatus.epub, 'E-book Phase',
              Colors.green, project),
          _buildStatusSection(context, ProjectMainStatus.other,
              'Other Statuses', Colors.grey, project),
        ],
      ),
    );
  }

  Widget _buildStatusSection(
    BuildContext context,
    ProjectMainStatus mainStatus,
    String title,
    Color color,
    ProjectModel project,
  ) {
    final isCurrentMainStatus = project.mainStatus == mainStatus;
    final isExpanded = _expandedStatuses[mainStatus] ?? false;
    final subStatuses = ProjectModel.getSubStatusesForMainStatus(mainStatus);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isCurrentMainStatus ? color : Colors.transparent,
          width: isCurrentMainStatus ? 2 : 0,
        ),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () {
              setState(() {
                _expandedStatuses[mainStatus] = !isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_right,
                    color: color,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isCurrentMainStatus
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isCurrentMainStatus ? color : null,
                      ),
                    ),
                  ),
                  // Current status indicator
                  if (isCurrentMainStatus)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Current',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Expanded content
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // List all sub-statuses
                  for (final subStatus in subStatuses)
                    _buildSubStatusItem(
                      context,
                      mainStatus,
                      subStatus['value']!,
                      subStatus['label']!,
                      color,
                      project,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSubStatusItem(
    BuildContext context,
    ProjectMainStatus mainStatus,
    String subStatusValue,
    String subStatusLabel,
    Color color,
    ProjectModel project,
  ) {
    final isCurrentSubStatus =
        project.subStatus == subStatusValue && project.mainStatus == mainStatus;
    final statusDate = project.getDateForSubStatus(subStatusValue);
    final hasDate = statusDate != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          // Checkbox
          Checkbox(
            value: hasDate,
            activeColor: color,
            onChanged: (bool? newValue) {
              _updateSubStatusDate(
                context,
                project,
                subStatusValue,
                newValue ?? false,
              );
            },
          ),
          const SizedBox(width: 8),

          // Status label
          Expanded(
            child: Text(
              subStatusLabel,
              style: TextStyle(
                fontWeight:
                    isCurrentSubStatus ? FontWeight.bold : FontWeight.normal,
                color: isCurrentSubStatus ? color : null,
              ),
            ),
          ),

          // Completion date
          if (hasDate)
            Text(
              _formatDate(statusDate),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),

          // Set as current button (if not current)
          if (!isCurrentSubStatus)
            IconButton(
              icon: const Icon(Icons.play_arrow, size: 18),
              tooltip: 'Set as current status',
              onPressed: () => _updateProjectStatus(
                context,
                project,
                mainStatus,
                subStatusValue,
              ),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(ProjectMainStatus status) {
    switch (status) {
      case ProjectMainStatus.design:
        return Colors.purple;
      case ProjectMainStatus.paging:
        return Colors.blue;
      case ProjectMainStatus.proofing:
        return Colors.orange;
      case ProjectMainStatus.epub:
        return Colors.green;
      case ProjectMainStatus.other:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _showEditProjectDialog(BuildContext context, ProjectModel project) {
    // Edit project dialog implementation
    // Not implementing in this cleanup
  }

  void _showDeleteProjectDialog(BuildContext context, ProjectModel project) {
    // Delete project dialog implementation
    // Not implementing in this cleanup
  }

  void _showAddDocumentDialog(BuildContext context, ProjectModel project) {
    // Add document dialog implementation
    // Not implementing in this cleanup
  }

  // Update the project's status (main and sub-status)
  void _updateProjectStatus(
    BuildContext context,
    ProjectModel project,
    ProjectMainStatus newMainStatus,
    String newSubStatus,
  ) async {
    final projectProvider =
        Provider.of<ProjectProvider>(context, listen: false);

    try {
      // First, update the main status if different
      if (project.mainStatus != newMainStatus) {
        await projectProvider.updateProjectMainStatus(
            project.id, newMainStatus, newSubStatus);
      } else {
        // If main status is the same, just update the sub-status
        await projectProvider.updateProjectSubStatus(
          project.id,
          newSubStatus,
          DateTime.now(), // Set current date as status date
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Project status updated'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Update a sub-status date (mark as complete/incomplete)
  void _updateSubStatusDate(
    BuildContext context,
    ProjectModel project,
    String subStatus,
    bool isComplete,
  ) async {
    final projectProvider =
        Provider.of<ProjectProvider>(context, listen: false);

    try {
      DateTime? statusDate;
      if (isComplete) {
        // If marking as complete, set current date
        statusDate = DateTime.now();
      } else {
        // If marking as incomplete, set to null (will remove the date)
        statusDate = null;
      }

      // Update status date and keep current sub-status the same
      await projectProvider.updateProjectSubStatus(
        project.id,
        project.subStatus, // Keep current sub-status
        statusDate, // Update the date
        subStatus: subStatus, // Specify which sub-status to update
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isComplete
                ? 'Status marked as complete'
                : 'Status marked as incomplete'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
