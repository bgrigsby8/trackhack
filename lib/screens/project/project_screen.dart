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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            project.title,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                        // Show completion badge if project is completed
                        if (project.isCompleted)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.green),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 16,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'COMPLETED',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
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
          // Project details - deadline and ISBN
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  project.isCompleted
                      ? Text(
                          'Completed: ${_formatDate(project.completedAt!)}',
                          style: const TextStyle(color: Colors.green),
                        )
                      : Text(
                          'Deadline: ${_formatDate(project.deadline)}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                ],
              ),
              Row(
                children: [
                  const Icon(
                    Icons.book,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'ISBN: ${project.isbn}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
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

    // Determine if this step is next in the sequence
    final canComplete = project.canCompleteSubStatus(subStatusValue);

    // Completion and UI states
    final isCompleted = hasDate && project.mainStatus == mainStatus;
    final isUpcoming =
        !hasDate && !canComplete; // Neither completed nor next in sequence
    final isNext = !hasDate &&
        canComplete &&
        project.mainStatus == mainStatus; // The next step to complete

    // Visual styling based on step status
    final TextStyle textStyle;
    if (isCompleted) {
      // Completed steps: greyed out with strikethrough
      textStyle = const TextStyle(
        fontWeight: FontWeight.normal,
        color: Colors.grey,
        decoration: TextDecoration.lineThrough,
      );
    } else if (isNext) {
      // Next step: highlighted with color and bold
      textStyle = TextStyle(
        fontWeight: FontWeight.bold,
        color: color,
      );
    } else if (isUpcoming) {
      // Upcoming steps: regular style, slightly dimmed
      textStyle = TextStyle(
        fontWeight: FontWeight.normal,
        color: Colors.grey[700],
      );
    } else {
      // Current step that's not completed
      textStyle = TextStyle(
        fontWeight: isCurrentSubStatus ? FontWeight.bold : FontWeight.normal,
        color: isCurrentSubStatus ? color : null,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          // Checkbox - only enabled for the current step in sequence
          Checkbox(
            value: hasDate,
            activeColor: isCompleted ? Colors.grey : color,
            checkColor: Colors.white,
            onChanged: isNext || isCompleted
                ? (bool? newValue) {
                    _updateSubStatusDate(
                      context,
                      project,
                      subStatusValue,
                      newValue ?? false,
                    );
                  }
                : null, // Disabled for upcoming steps
          ),
          const SizedBox(width: 8),

          // Status label with styling based on state
          Expanded(
            child: Text(
              subStatusLabel,
              style: textStyle,
            ),
          ),

          // Display status date for all steps (completed or planned)
          Text(
            hasDate
                ? _formatDate(statusDate) // Show actual completion date
                : _formatPlannedDate(subStatusValue,
                    project), // Show planned date if not completed
            style: TextStyle(
                color: hasDate
                    ? Colors.grey[600]
                    : Colors.grey[400], // Lighter color for planned dates
                fontSize: 14, // Increased from 12 to 14 for better readability
                fontStyle: hasDate
                    ? FontStyle.normal
                    : FontStyle.italic, // Italics for planned dates
                fontWeight: hasDate
                    ? FontWeight.w500
                    : FontWeight.normal // Slightly bolder for completed dates
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
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
  }

  // Format the planned date for a step that hasn't been completed yet
  String _formatPlannedDate(String subStatusValue, ProjectModel project) {
    // Check if we have a scheduled date for this substatus
    final scheduledDate = project.getScheduledDateForSubStatus(subStatusValue);
    if (scheduledDate != null) {
      return _formatDate(scheduledDate);
    }
    
    // Fallback to project creation date if no scheduled date exists
    // This should only happen for projects created before we added scheduled dates
    final subStatuses =
        ProjectModel.getSubStatusesForMainStatus(project.mainStatus);
    final index = subStatuses.indexWhere((s) => s['value'] == subStatusValue);

    if (index >= 0) {
      return _formatDate(project.createdAt);
    }

    // Fallback if we can't find a date
    return '--/--/----';
  }

  void _showEditProjectDialog(BuildContext context, ProjectModel project) {
    final projectProvider =
        Provider.of<ProjectProvider>(context, listen: false);
    final titleController = TextEditingController(text: project.title);
    final descriptionController =
        TextEditingController(text: project.description);
    final isbnController = TextEditingController(text: project.isbn);
    final deadlineController = TextEditingController(
      text: _formatDate(project.deadline),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Project'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Title',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  hintText: 'Enter book title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'ISBN',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: isbnController,
                decoration: const InputDecoration(
                  hintText: 'Enter ISBN number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Description',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  hintText: 'Enter book description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              const Text(
                'Deadline',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: deadlineController,
                decoration: const InputDecoration(
                  hintText: 'MM/DD/YYYY',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isEmpty ||
                  descriptionController.text.isEmpty ||
                  isbnController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill in all required fields'),
                  ),
                );
                return;
              }

              // Parse deadline
              final dateParts = deadlineController.text.split('/');
              if (dateParts.length != 3) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Invalid date format. Use MM/DD/YYYY'),
                  ),
                );
                return;
              }

              try {
                final month = int.parse(dateParts[0]);
                final day = int.parse(dateParts[1]);
                final year = int.parse(dateParts[2]);
                final deadline = DateTime(year, month, day);

                // Update project
                final updatedProject = project.copyWith(
                  title: titleController.text,
                  description: descriptionController.text,
                  isbn: isbnController.text,
                  deadline: deadline,
                  updatedAt: DateTime.now(),
                );

                Navigator.pop(context);

                await projectProvider.updateProject(updatedProject);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Project updated successfully'),
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteProjectDialog(BuildContext context, ProjectModel project) {
    final projectProvider =
        Provider.of<ProjectProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false, // User must choose an option
      builder: (context) => AlertDialog(
        title: const Text('Delete Project'),
        content: Text(
          'Are you sure you want to delete "${project.title}"?\n\n'
          'This action cannot be undone and all project data will be permanently lost.',
          style: const TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Close the dialog first
              Navigator.pop(context);

              // Store values we need before navigating
              final String projectId = project.id;
              final String? userId = authProvider.user?.id;

              // First show the deleting indicator
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 16),
                        Text('Deleting project...'),
                      ],
                    ),
                    duration: Duration(seconds: 1),
                  ),
                );
              }

              // IMPORTANT: Navigate back BEFORE deleting to avoid deactivated widget errors
              if (mounted) {
                // Pop the ProjectScreen to return to previous screen
                Navigator.of(context).pop();
              }

              // Now delete the project after navigation
              try {
                await projectProvider.deleteProject(
                  projectId,
                  userId ?? '',
                );

                // We can't show additional feedback here as we've already navigated away
              } catch (e) {
                // We can't show error UI since we've already navigated away
                print('Error deleting project: $e');
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Update the project's status (main and sub-status)
  Future<void> _updateProjectStatus(BuildContext context, ProjectModel project,
      ProjectMainStatus newMainStatus, String newSubStatus,
      {bool skipValidation = false}) async {
    final projectProvider =
        Provider.of<ProjectProvider>(context, listen: false);

    try {
      // When changing main status, check if the current main status has all steps completed
      if (project.mainStatus != newMainStatus) {
        // Verify all substeps in the current main status are completed before moving on
        final currentSubStatuses =
            ProjectModel.getSubStatusesForMainStatus(project.mainStatus);
        bool allCurrentCompleted = true;

        for (final subStatus in currentSubStatuses) {
          if (!project.isSubStatusCompleted(subStatus['value']!)) {
            allCurrentCompleted = false;
            break;
          }
        }

        // Don't allow moving to a new main status if current one has incomplete steps
        // Skip this validation if skipValidation is true (for automatic advancement)
        if (!skipValidation &&
            !allCurrentCompleted &&
            ProjectMainStatus.values.indexOf(newMainStatus) >
                ProjectMainStatus.values.indexOf(project.mainStatus)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Cannot move to next main status until all current steps are completed.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        await projectProvider.updateProjectMainStatus(
            project.id, newMainStatus, newSubStatus);
      } else {
        // If main status is the same, make sure we're following the sequence
        final subStatuses =
            ProjectModel.getSubStatusesForMainStatus(project.mainStatus);
        final currentIndex =
            subStatuses.indexWhere((s) => s['value'] == project.subStatus);
        final newIndex =
            subStatuses.indexWhere((s) => s['value'] == newSubStatus);

        // Skip sequence validation if skipValidation is true
        if (!skipValidation) {
          // Only allow sequential or backward movement if all previous steps are completed
          bool canMove = true;

          if (newIndex > currentIndex) {
            // Moving forward - check if all previous substatus items are completed
            for (int i = 0; i <= currentIndex; i++) {
              if (!project.isSubStatusCompleted(subStatuses[i]['value']!)) {
                canMove = false;
                break;
              }
            }
          }

          if (!canMove) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Cannot move to this step until previous steps are completed.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }
        }

        // Update the sub-status
        await projectProvider.updateProjectSubStatus(
          project.id,
          newSubStatus,
          DateTime.now(), // Set current date as status date
        );
      }

      // Only show the generic update notification if not auto-advancing
      if (mounted && !skipValidation) {
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
      // Can only mark as complete if the previous steps are completed
      if (isComplete && !project.canCompleteSubStatus(subStatus)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Cannot mark this step as complete until previous steps are completed.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      DateTime? statusDate;
      if (isComplete) {
        // If marking as complete, set current date
        statusDate = DateTime.now();
      } else {
        // If marking as incomplete, verify if this would create a gap in the sequence
        final subStatuses =
            ProjectModel.getSubStatusesForMainStatus(project.mainStatus);
        final currentIndex =
            subStatuses.indexWhere((s) => s['value'] == subStatus);

        // Check if there are any later steps that are already completed
        bool hasCompletedLaterSteps = false;
        for (int i = currentIndex + 1; i < subStatuses.length; i++) {
          if (project.isSubStatusCompleted(subStatuses[i]['value']!)) {
            hasCompletedLaterSteps = true;
            break;
          }
        }

        if (hasCompletedLaterSteps) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Cannot mark this step as incomplete because later steps are already completed.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

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

      // If completed, automatically set the current status to this completed one
      if (isComplete && project.subStatus != subStatus) {
        await projectProvider.updateProjectSubStatus(
            project.id,
            subStatus, // Set as current substatus
            DateTime.now());
      }

      // If this was the last step in the phase and it's now complete, automatically move to next phase
      if (isComplete) {
        final subStatuses =
            ProjectModel.getSubStatusesForMainStatus(project.mainStatus);

        // Check if we just completed the very last step in the phase
        bool isLastStepInPhase = subStatus == subStatuses.last['value'];

        // Check if all other steps are completed too
        bool allOtherStepsCompleted = true;
        for (final ss in subStatuses) {
          final String value = ss['value']!;
          if (value != subStatus && !project.isSubStatusCompleted(value)) {
            allOtherStepsCompleted = false;
            break;
          }
        }

        // If we just completed the last step and all others are done, automatically advance to next phase
        if (isLastStepInPhase && allOtherStepsCompleted && mounted) {
          final int currentIndex =
              ProjectMainStatus.values.indexOf(project.mainStatus);

          // Check if there's a next phase to move to
          if (currentIndex < ProjectMainStatus.values.length - 1) {
            final nextMainStatus = ProjectMainStatus.values[currentIndex + 1];

            // Get the first step of the next phase
            final nextPhaseSubStatuses =
                ProjectModel.getSubStatusesForMainStatus(nextMainStatus);

            if (nextPhaseSubStatuses.isNotEmpty) {
              final String nextPhaseFirstStep =
                  nextPhaseSubStatuses[0]['value']!;

              // Short delay to allow the current update to complete
              Future.delayed(const Duration(milliseconds: 500), () async {
                try {
                  // Automatically advance to the next phase and its first step
                  _updateProjectStatus(
                    context,
                    project,
                    nextMainStatus,
                    nextPhaseFirstStep,
                    skipValidation:
                        true, // Skip sequence validation since we're auto-advancing
                  );
                } catch (e) {
                  // Handle errors from phase advancement
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error advancing to next phase: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              });
            }
          } else {
            // This was the final phase
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All project phases completed! 🎉'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 3),
                ),
              );
            }
          }
        }
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
