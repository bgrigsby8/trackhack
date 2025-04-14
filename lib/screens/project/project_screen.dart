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

      // Load related documents
      documentProvider.setCurrentProject(widget.projectId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<ProjectProvider>(
          builder: (context, projectProvider, child) {
            final project = projectProvider.currentProject;
            return Text(project?.title ?? 'Project Details');
          },
        ),
        actions: [
          Consumer<ProjectProvider>(
            builder: (context, projectProvider, child) {
              final project = projectProvider.currentProject;
              if (project != null) {
                return PopupMenuButton(
                  icon: const Icon(Icons.more_vert),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('Edit Project'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete Project',
                              style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditProjectDialog(context, project);
                    } else if (value == 'delete') {
                      _showDeleteProjectDialog(context, project);
                    }
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<ProjectProvider>(
        builder: (context, projectProvider, child) {
          final project = projectProvider.currentProject;

          if (projectProvider.loading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (project == null) {
            return const Center(
              child: Text('Project not found'),
            );
          }

          // Calculate progress
          final completedTasks = project.statusDates.length;
          final totalTasks = ProjectModel.designSubStatuses.length +
              ProjectModel.pagingSubStatuses.length +
              ProjectModel.proofingSubStatuses.length +
              ProjectModel.epubSubStatuses.length;
          final progress = totalTasks > 0 ? completedTasks / totalTasks : 0.0;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: CustomScrollView(
              slivers: [
                // Project Overview
                SliverToBoxAdapter(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Progress bar
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Overall Progress',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '${(progress * 100).toInt()}%',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: progress,
                                backgroundColor: Colors.grey[200],
                                color: Colors.green,
                                minHeight: 10,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$completedTasks of $totalTasks steps completed',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Description',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(project.description),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'ISBN',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(project.isbn),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Current Phase',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      project.mainStatus
                                          .toString()
                                          .split('.')
                                          .last
                                          .toUpperCase(),
                                      style: TextStyle(
                                        color:
                                            _getStatusColor(project.mainStatus),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Current Step',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      // Get label for the current subStatus
                                      project.statusLabel,
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Deadline',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(_formatDate(project.deadline)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Status sections
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 8),
                    child: Text(
                      'Project Timeline',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                ),

                // Design Phase
                SliverToBoxAdapter(
                  child: _buildStatusSection(
                      context,
                      'Design Phase',
                      ProjectMainStatus.design,
                      ProjectModel.designSubStatuses,
                      Colors.purple,
                      project),
                ),

                // Paging Phase
                SliverToBoxAdapter(
                  child: _buildStatusSection(
                      context,
                      'Paging Phase',
                      ProjectMainStatus.paging,
                      ProjectModel.pagingSubStatuses,
                      Colors.blue,
                      project),
                ),

                // Proofing Phase
                SliverToBoxAdapter(
                  child: _buildStatusSection(
                      context,
                      'Proofing Phase',
                      ProjectMainStatus.proofing,
                      ProjectModel.proofingSubStatuses,
                      Colors.orange,
                      project),
                ),

                // E-Pub Phase
                SliverToBoxAdapter(
                  child: _buildStatusSection(
                      context,
                      'E-Pub Phase',
                      ProjectMainStatus.epub,
                      ProjectModel.epubSubStatuses,
                      Colors.green,
                      project),
                ),

                // Spacer at the bottom
                const SliverToBoxAdapter(
                  child: SizedBox(height: 40),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusSection(
    BuildContext context,
    String title,
    ProjectMainStatus status,
    List<Map<String, String>> subStatuses,
    Color color,
    ProjectModel project,
  ) {
    final bool isExpanded = _expandedStatuses[status] ?? false;
    final bool isCurrentPhase = project.mainStatus == status;
    final bool isCompletedPhase = _isPhaseCompleted(project, status);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isCurrentPhase ? color : Colors.transparent,
          width: isCurrentPhase ? 2 : 0,
        ),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () {
              setState(() {
                _expandedStatuses[status] = !isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isCompletedPhase
                            ? Icons.check_circle
                            : isCurrentPhase
                                ? Icons.play_circle_filled
                                : Icons.circle_outlined,
                        color: isCompletedPhase
                            ? color
                            : isCurrentPhase
                                ? color
                                : Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isCurrentPhase ? color : null,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: isCurrentPhase ? color : Colors.grey,
                  ),
                ],
              ),
            ),
          ),

          // Expanded content
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  const Divider(),
                  ...subStatuses.map((subStatus) => _buildSubStatusItem(
                      context, subStatus, project, status, color)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  bool _isPhaseCompleted(ProjectModel project, ProjectMainStatus phase) {
    // Get all substatuses for this phase
    final subStatuses = ProjectModel.getSubStatusesForMainStatus(phase);

    // Check if all substatuses have completion dates
    for (final subStatus in subStatuses) {
      final value = subStatus['value']!;
      if (!project.isSubStatusCompleted(value)) {
        return false;
      }
    }

    return true;
  }

  Widget _buildSubStatusItem(
    BuildContext context,
    Map<String, String> subStatus,
    ProjectModel project,
    ProjectMainStatus status,
    Color color,
  ) {
    final String subStatusValue = subStatus['value']!;
    final String subStatusLabel = subStatus['label']!;

    // Check if this substatus is completed
    final bool hasDate = project.isSubStatusCompleted(subStatusValue);
    final DateTime? statusDate = project.getDateForSubStatus(subStatusValue);

    // Is this the current substatus?
    final bool isCurrent =
        project.mainStatus == status && project.subStatus == subStatusValue;

    // Can this substatus be completed?
    final bool canComplete = project.canCompleteSubStatus(subStatusValue);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                hasDate
                    ? Icon(Icons.check_circle, color: color)
                    : Icon(Icons.circle_outlined,
                        color: canComplete
                            ? Colors.grey
                            : Colors.grey.withValues(alpha: 0.3)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    subStatusLabel,
                    style: TextStyle(
                      fontWeight: hasDate || isCurrent
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: hasDate
                          ? Colors.black
                          : isCurrent
                              ? color
                              : canComplete
                                  ? Colors.grey[700]
                                  : Colors.grey[400],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          canComplete && !hasDate
              ? OutlinedButton.icon(
                  icon: const Icon(Icons.task_alt, size: 16),
                  label: const Text('Complete'),
                  onPressed: () =>
                      _handleStatusUpdate(context, project, subStatusValue),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: color,
                    side: BorderSide(color: color),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    minimumSize: const Size(0, 32),
                  ),
                )
              : Text(
                  hasDate
                      ? _formatDate(statusDate!) // Show actual completion date
                      : _formatPlannedDate(subStatusValue,
                          project), // Show planned date if not completed
                  style: TextStyle(
                      color: hasDate
                          ? Colors.grey[600]
                          : Colors.grey[400], // Lighter color for planned dates
                      fontSize:
                          14, // Increased from 12 to 14 for better readability
                      fontStyle: hasDate
                          ? FontStyle.normal
                          : FontStyle.italic, // Italics for planned dates
                      fontWeight: hasDate
                          ? FontWeight.w500
                          : FontWeight
                              .normal // Slightly bolder for completed dates
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
    final productionEditorController = TextEditingController(text: project.productionEditor);
    final formatController = TextEditingController(text: project.format);

    // Map to store dates for each sub-status
    final Map<String, DateTime?> scheduledDates = {};
    final Map<String, TextEditingController> dateControllers = {};

    // Initialize date controllers with existing scheduled dates
    void setupDateControllers(List<Map<String, String>> subStatuses) {
      for (final subStatus in subStatuses) {
        final key = subStatus['value']!;
        final existingDate = project.scheduledDates[key];

        // Initialize with existing date or empty
        if (existingDate != null) {
          dateControllers[key] =
              TextEditingController(text: _formatDate(existingDate));
          scheduledDates[key] = existingDate;
        } else {
          dateControllers[key] = TextEditingController();
          scheduledDates[key] = null;
        }
      }
    }

    // Setup all status types with existing date fields
    setupDateControllers(ProjectModel.designSubStatuses);
    setupDateControllers(ProjectModel.pagingSubStatuses);
    setupDateControllers(ProjectModel.proofingSubStatuses);
    setupDateControllers(ProjectModel.epubSubStatuses);

    // Helper function to validate and parse date
    DateTime? parseDateMMDDYYYY(String input) {
      // Check format MM/DD/YYYY
      final RegExp dateRegex = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$');
      final match = dateRegex.firstMatch(input);

      if (match != null) {
        final month = int.parse(match.group(1)!);
        final day = int.parse(match.group(2)!);
        final year = int.parse(match.group(3)!);

        // Validate month and day
        if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
          try {
            return DateTime(year, month, day);
          } catch (e) {
            // Handle invalid date (e.g., February 30)
            return null;
          }
        }
      }
      return null;
    }

    // Helper to validate the date sequence for a phase
    String? validatePhaseSequence(
        List<Map<String, String>> phaseSubStatuses, String phaseName) {
      DateTime? previousDate;
      String? previousLabel;

      for (final subStatus in phaseSubStatuses) {
        final value = subStatus['value']!;
        final label = subStatus['label']!;
        final date = scheduledDates[value];

        // Check if date exists
        if (date == null) {
          return 'Please enter a date for $label in $phaseName phase';
        }

        // Check sequence with previous date
        if (previousDate != null && date.isBefore(previousDate)) {
          return '$label date must be on or after $previousLabel date';
        }

        previousDate = date;
        previousLabel = label;
      }

      return null; // No validation errors
    }

    // Helper to validate all phase sequences
    List<String> validateAllPhaseSequences() {
      final List<String> errors = [];

      // Validate each phase internally
      final String? designError =
          validatePhaseSequence(ProjectModel.designSubStatuses, 'Design');
      if (designError != null) errors.add(designError);

      final String? pagingError =
          validatePhaseSequence(ProjectModel.pagingSubStatuses, 'Paging');
      if (pagingError != null) errors.add(pagingError);

      final String? proofingError =
          validatePhaseSequence(ProjectModel.proofingSubStatuses, 'Proofing');
      if (proofingError != null) errors.add(proofingError);

      final String? epubError =
          validatePhaseSequence(ProjectModel.epubSubStatuses, 'E-Pub');
      if (epubError != null) errors.add(epubError);

      // If there are already errors, return them
      if (errors.isNotEmpty) return errors;

      // Validate phase transitions
      DateTime? lastDesignDate;
      // Get last date of each phase
      if (ProjectModel.designSubStatuses.isNotEmpty) {
        final lastDesignStatus = ProjectModel.designSubStatuses.last['value']!;
        lastDesignDate = scheduledDates[lastDesignStatus];
      }

      DateTime? firstPagingDate;
      if (ProjectModel.pagingSubStatuses.isNotEmpty) {
        final firstPagingStatus =
            ProjectModel.pagingSubStatuses.first['value']!;
        firstPagingDate = scheduledDates[firstPagingStatus];
      }

      if (lastDesignDate != null &&
          firstPagingDate != null &&
          firstPagingDate.isBefore(lastDesignDate)) {
        errors.add(
            'First Paging phase date must be on or after last Design phase date');
      }

      DateTime? lastPagingDate;
      if (ProjectModel.pagingSubStatuses.isNotEmpty) {
        final lastPagingStatus = ProjectModel.pagingSubStatuses.last['value']!;
        lastPagingDate = scheduledDates[lastPagingStatus];
      }

      DateTime? firstProofingDate;
      if (ProjectModel.proofingSubStatuses.isNotEmpty) {
        final firstProofingStatus =
            ProjectModel.proofingSubStatuses.first['value']!;
        firstProofingDate = scheduledDates[firstProofingStatus];
      }

      if (lastPagingDate != null &&
          firstProofingDate != null &&
          firstProofingDate.isBefore(lastPagingDate)) {
        errors.add(
            'First Proofing phase date must be on or after last Paging phase date');
      }

      DateTime? lastProofingDate;
      if (ProjectModel.proofingSubStatuses.isNotEmpty) {
        final lastProofingStatus =
            ProjectModel.proofingSubStatuses.last['value']!;
        lastProofingDate = scheduledDates[lastProofingStatus];
      }

      DateTime? firstEpubDate;
      if (ProjectModel.epubSubStatuses.isNotEmpty) {
        final firstEpubStatus = ProjectModel.epubSubStatuses.first['value']!;
        firstEpubDate = scheduledDates[firstEpubStatus];
      }

      if (lastProofingDate != null &&
          firstEpubDate != null &&
          firstEpubDate.isBefore(lastProofingDate)) {
        errors.add(
            'First E-Pub phase date must be on or after last Proofing phase date');
      }

      return errors;
    }

    // Controllers for metadata text and date fields
    final imprintController = TextEditingController(text: project.imprint);
    final notesController = TextEditingController(text: project.notes);
    
    // Controllers for metadata date fields
    final printerDateController = TextEditingController(
      text: project.printerDate != null ? _formatDate(project.printerDate!) : ''
    );
    final scDateController = TextEditingController(
      text: project.scDate != null ? _formatDate(project.scDate!) : ''
    );
    final pubDateController = TextEditingController(
      text: project.pubDate != null ? _formatDate(project.pubDate!) : ''
    );
    
    // Controller for UK co-pub
    final ukCoPubController = TextEditingController(text: project.ukCoPub);
    // Boolean values for checkboxes
    bool pageCountSent = project.pageCountSent;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          title: const Text('Edit Book Project'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.7,
            child: SingleChildScrollView(
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
                    'Production Editor',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: productionEditorController,
                    decoration: const InputDecoration(
                      hintText: 'Enter production editor name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Format',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: formatController,
                    decoration: const InputDecoration(
                      hintText: 'Enter book format',
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
                  
                  // Metadata Section Header
                  const Text(
                    'Metadata',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Metadata fields in a compact format
                  _buildMetadataSection(
                    project: project,
                    context: context, 
                    setState: setState,
                    imprintController: imprintController,
                    notesController: notesController,
                    printerDateController: printerDateController,
                    scDateController: scDateController,
                    pubDateController: pubDateController,
                    ukCoPubController: ukCoPubController,
                    pageCountSent: pageCountSent,
                    onPageCountSentChanged: (value) {
                      setState(() {
                        pageCountSent = value ?? false;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 16),

                  // Project Schedule Section Header
                  const Text(
                    'Project Schedule',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Edit target dates for each step below. Dates within each phase and '
                    'between phases must be in sequential order.',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 1. DESIGN PHASE
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.purple.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Phase 1: Design',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.purple,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text('Edit target dates for all design steps:'),
                        const SizedBox(height: 12),
                        ...ProjectModel.designSubStatuses.map((subStatus) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${subStatus['label']!} Date:',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                TextField(
                                  controller:
                                      dateControllers[subStatus['value']],
                                  decoration: const InputDecoration(
                                    hintText: 'MM/DD/YYYY',
                                    border: OutlineInputBorder(),
                                    helperText: 'Required',
                                  ),
                                  onChanged: (value) {
                                    final date = parseDateMMDDYYYY(value);
                                    setState(() {
                                      scheduledDates[subStatus['value']!] =
                                          date;
                                    });
                                  },
                                )
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                  // 2. PAGING PHASE
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Phase 2: Paging',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text('Edit target dates for all paging steps:'),
                        const SizedBox(height: 12),
                        ...ProjectModel.pagingSubStatuses.map((subStatus) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${subStatus['label']!} Date:',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                TextField(
                                  controller:
                                      dateControllers[subStatus['value']],
                                  decoration: const InputDecoration(
                                    hintText: 'MM/DD/YYYY',
                                    border: OutlineInputBorder(),
                                    helperText: 'Required',
                                  ),
                                  onChanged: (value) {
                                    final date = parseDateMMDDYYYY(value);
                                    setState(() {
                                      scheduledDates[subStatus['value']!] =
                                          date;
                                    });
                                  },
                                )
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                  // 3. PROOFING PHASE
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Phase 3: Proofing',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text('Edit target dates for all proofing steps:'),
                        const SizedBox(height: 12),
                        ...ProjectModel.proofingSubStatuses.map((subStatus) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${subStatus['label']!} Date:',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                TextField(
                                  controller:
                                      dateControllers[subStatus['value']],
                                  decoration: const InputDecoration(
                                    hintText: 'MM/DD/YYYY',
                                    border: OutlineInputBorder(),
                                    helperText: 'Required',
                                  ),
                                  onChanged: (value) {
                                    final date = parseDateMMDDYYYY(value);
                                    setState(() {
                                      scheduledDates[subStatus['value']!] =
                                          date;
                                    });
                                  },
                                )
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                  // 4. E-PUB PHASE
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.green.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Phase 4: E-Pub',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text('Edit target dates for all e-pub steps:'),
                        const SizedBox(height: 12),
                        ...ProjectModel.epubSubStatuses.map((subStatus) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${subStatus['label']!} Date:',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                TextField(
                                  controller:
                                      dateControllers[subStatus['value']],
                                  decoration: const InputDecoration(
                                    hintText: 'MM/DD/YYYY',
                                    border: OutlineInputBorder(),
                                    helperText: 'Required',
                                  ),
                                  onChanged: (value) {
                                    final date = parseDateMMDDYYYY(value);
                                    setState(() {
                                      scheduledDates[subStatus['value']!] =
                                          date;
                                    });
                                  },
                                )
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Basic validation
                if (titleController.text.isEmpty ||
                    descriptionController.text.isEmpty ||
                    isbnController.text.isEmpty ||
                    productionEditorController.text.isEmpty ||
                    formatController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill in all required fields'),
                    ),
                  );
                  return;
                }

                // Validate and check sequence of all dates
                final validationErrors = validateAllPhaseSequences();

                if (validationErrors.isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(validationErrors.first),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                  return;
                }

                // Set deadline to the last date in the final phase
                DateTime deadline;
                if (ProjectModel.epubSubStatuses.isNotEmpty) {
                  final lastEpubStatus =
                      ProjectModel.epubSubStatuses.last['value']!;
                  deadline = scheduledDates[lastEpubStatus]!;
                } else {
                  // Fallback if no epub substatus exists (shouldn't happen)
                  deadline = DateTime.now().add(const Duration(days: 30));
                }

                // Convert nullable scheduledDates to non-nullable for the project model
                final Map<String, DateTime> validScheduledDates = {};
                scheduledDates.forEach((key, date) {
                  if (date != null) {
                    validScheduledDates[key] = date;
                  }
                });

                // Get metadata values
                final imprint = imprintController.text.trim();
                final notes = notesController.text.trim();
                
                // Helper function to parse dates (ensuring it's available in this scope)
                DateTime? parseDateFromField(String input) {
                  if (input.isEmpty) return null;
                  
                  final RegExp dateRegex = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$');
                  final match = dateRegex.firstMatch(input);
    
                  if (match != null) {
                    final month = int.parse(match.group(1)!);
                    final day = int.parse(match.group(2)!);
                    final year = int.parse(match.group(3)!);
    
                    try {
                      return DateTime(year, month, day);
                    } catch (e) {
                      return null;
                    }
                  }
                  return null;
                }
                
                // Parse date fields
                DateTime? printerDate = parseDateFromField(printerDateController.text);
                DateTime? scDate = parseDateFromField(scDateController.text);
                DateTime? pubDate = parseDateFromField(pubDateController.text);

                // Update project with all fields including metadata
                final updatedProject = project.copyWith(
                  title: titleController.text,
                  description: descriptionController.text,
                  isbn: isbnController.text,
                  productionEditor: productionEditorController.text,
                  format: formatController.text,
                  scheduledDates: validScheduledDates,
                  deadline: deadline,
                  updatedAt: DateTime.now(),
                  // Metadata fields
                  imprint: imprint,
                  printerDate: printerDate,
                  scDate: scDate,
                  pubDate: pubDate,
                  notes: notes,
                  ukCoPub: ukCoPubController.text.trim(),
                  pageCountSent: pageCountSent,
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
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
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
                    duration: Duration(seconds: 10),
                  ),
                );
              }

              // Start the delete process
              try {
                // Need to execute this first before navigating
                await projectProvider.deleteProject(projectId, userId!);

                // Navigate back to dashboard after successful delete
                if (mounted) {
                  Navigator.pop(context);
                }

                // Reload the projects list
                if (mounted) {
                  projectProvider.loadUserProjects(userId);
                }
              } catch (e) {
                // Handle error
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleStatusUpdate(
    BuildContext context,
    ProjectModel project,
    String nextSubStatus,
  ) async {
    try {
      final projectProvider =
          Provider.of<ProjectProvider>(context, listen: false);

      // Determine if we need to update mainStatus as well
      final currentPhaseStatuses =
          ProjectModel.getSubStatusesForMainStatus(project.mainStatus);
      final currentIsLastInPhase =
          currentPhaseStatuses.last['value'] == nextSubStatus;

      // Prepare new mainStatus if needed
      ProjectMainStatus? newMainStatus;
      String? newSubStatus;

      if (currentIsLastInPhase) {
        // We're completing the last item in a phase, advance to next phase
        switch (project.mainStatus) {
          case ProjectMainStatus.design:
            newMainStatus = ProjectMainStatus.paging;
            if (ProjectModel.pagingSubStatuses.isNotEmpty) {
              newSubStatus = ProjectModel.pagingSubStatuses.first['value'];
            }
            break;
          case ProjectMainStatus.paging:
            newMainStatus = ProjectMainStatus.proofing;
            if (ProjectModel.proofingSubStatuses.isNotEmpty) {
              newSubStatus = ProjectModel.proofingSubStatuses.first['value'];
            }
            break;
          case ProjectMainStatus.proofing:
            newMainStatus = ProjectMainStatus.epub;
            if (ProjectModel.epubSubStatuses.isNotEmpty) {
              newSubStatus = ProjectModel.epubSubStatuses.first['value'];
            }
            break;
          case ProjectMainStatus.epub:
            // This is the final phase, just mark the step complete
            break;
        }
      }

      // Update the status date for the current substatus
      final now = DateTime.now();
      Map<String, DateTime> newStatusDates = Map.from(project.statusDates);
      newStatusDates[nextSubStatus] = now;

      // Create updated project
      ProjectModel updatedProject = project.copyWith(
        statusDates: newStatusDates,
        updatedAt: now,
      );

      // Apply phase change if needed
      if (newMainStatus != null && newSubStatus != null) {
        updatedProject = updatedProject.copyWith(
          mainStatus: newMainStatus,
          subStatus: newSubStatus,
        );
      }

      // Check if the project should be marked as complete
      if (updatedProject.shouldBeMarkedAsCompleted()) {
        updatedProject = updatedProject.copyWith(
          isCompleted: true,
          completedAt: now,
        );
      }

      // Save the changes
      await projectProvider.updateProject(updatedProject);

      // Update UI
      if (mounted) {
        setState(() {
          // If we advanced to a new phase, expand that phase
          if (newMainStatus != null) {
            for (var status in ProjectMainStatus.values) {
              _expandedStatuses[status] = status == newMainStatus;
            }
          }
        });
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
  
  // Method to build the metadata section
  Widget _buildMetadataSection({
    required ProjectModel project,
    required BuildContext context,
    required StateSetter setState,
    required TextEditingController imprintController,
    required TextEditingController notesController,
    required TextEditingController printerDateController,
    required TextEditingController scDateController,
    required TextEditingController pubDateController,
    required TextEditingController ukCoPubController,
    required bool pageCountSent,
    required Function(bool?) onPageCountSentChanged,
  }) {
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Imprint
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Imprint:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 40,
                      child: TextField(
                        controller: imprintController,
                        decoration: const InputDecoration(
                          hintText: 'Enter imprint',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        ),
                        onChanged: (value) {
                          // We'll handle this in the Save button
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Row 2: Dates
          Row(
            children: [
              // Printer Date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Printer Date:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 40,
                      child: TextField(
                        controller: printerDateController,
                        decoration: const InputDecoration(
                          hintText: 'MM/DD/YYYY',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 8),
              
              // S.C. Date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'S.C. Date:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 40,
                      child: TextField(
                        controller: scDateController,
                        decoration: const InputDecoration(
                          hintText: 'MM/DD/YYYY',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Pub Date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pub Date:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 40,
                      child: TextField(
                        controller: pubDateController,
                        decoration: const InputDecoration(
                          hintText: 'MM/DD/YYYY',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Row 3: Notes
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notes:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 60,
                      child: TextField(
                        controller: notesController,
                        decoration: const InputDecoration(
                          hintText: 'Additional notes',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        ),
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Row 4: Checkboxes
          Row(
            children: [
              // UK co-pub field
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'UK co-pub:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 40,
                      child: TextField(
                        controller: ukCoPubController,
                        decoration: const InputDecoration(
                          hintText: 'UK co-publication details',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Page Count Sent checkbox
              Expanded(
                child: Row(
                  children: [
                    Checkbox(
                      value: pageCountSent,
                      onChanged: onPageCountSentChanged,
                    ),
                    const Text('Page Count Sent?'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
