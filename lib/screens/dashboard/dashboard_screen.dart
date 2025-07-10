// lib/screens/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/project_provider.dart';
import '../../models/project_model.dart';
import '../../utils/helpers.dart';
import '../../widgets/app_drawer.dart';
import '../project/project_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _searchQuery = '';
  // Map to track sorting direction for each column
  // true = newest first (default), false = oldest first
  final Map<String, bool> _columnSortDirections = {
    'Design': true,
    'Paging': true,
    'Proofing': true,
    'EPUB': true, // Added EPUB column
  };

  // State for completed books section
  bool _showCompletedBooks = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final projectProvider =
          Provider.of<ProjectProvider>(context, listen: false);

      if (authProvider.user != null) {
        projectProvider.loadUserProjects(authProvider.user!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final projectProvider = Provider.of<ProjectProvider>(context);
    final user = authProvider.user;

    // Load projects only in initState, don't trigger it again here
    // This prevents the flashing effect when loading state changes

    if (user == null) {
      print("User is null, showing progress screen");
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Text(
              'TrackHack',
              style: TextStyle(fontSize: 25),
            ),
            SizedBox(width: 8),
            Text(
              'v1.1.0',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      endDrawer: const AppDrawer(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSearchAndFilter(context),
          // Use AnimatedSwitcher to smooth transitions between states
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildMainContent(projectProvider),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddProjectDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMainContent(ProjectProvider projectProvider) {
    if (projectProvider.loading) {
      return const Center(
        key: ValueKey('loading'),
        child: CircularProgressIndicator(),
      );
    } else if (projectProvider.projects.isEmpty) {
      return _buildEmptyProjectsView(context);
    } else {
      return Column(
        key: ValueKey('projects'),
        children: [
          // Completed books expandable section
          _buildCompletedBooksSection(context, projectProvider),
          // Main kanban board
          Expanded(
            child: _buildProjectsGrid(context, projectProvider),
          ),
        ],
      );
    }
  }

  Widget _buildSearchAndFilter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Search field
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search projects...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedBooksSection(
      BuildContext context, ProjectProvider projectProvider) {
    final completedProjects = projectProvider.getCompletedProjects();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          // Header with expand/collapse button
          InkWell(
            onTap: () =>
                setState(() => _showCompletedBooks = !_showCompletedBooks),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    _showCompletedBooks
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_right,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Completed Books',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${completedProjects.length}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expanded content when showCompletedBooks is true
          if (_showCompletedBooks)
            completedProjects.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(16),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        const Icon(
                          Icons.local_library,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No completed books yet',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Books will appear here when all steps in the EPUB phase are completed',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : Container(
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const ClampingScrollPhysics(),
                      itemCount: completedProjects.length,
                      itemBuilder: (context, index) {
                        final project = completedProjects[index];
                        return ListTile(
                          title: Text(project.title),
                          subtitle: Row(
                            children: [
                              const Icon(Icons.book,
                                  size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text('ISBN: ${project.isbn}'),
                              const SizedBox(width: 16),
                              const Icon(Icons.calendar_today,
                                  size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                  'Completed: ${_formatDate(project.completedAt!)}'),
                            ],
                          ),
                          trailing: const Icon(Icons.check_circle,
                              color: Colors.green),
                          onTap: () => _navigateToProject(context, project),
                        );
                      },
                    ),
                  ),
        ],
      ),
    );
  }

  Widget _buildEmptyProjectsView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.book_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'No projects yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first book project to get started',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddProjectDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Project'),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectsGrid(
      BuildContext context, ProjectProvider projectProvider) {
    final filteredProjects = _filterProjects(projectProvider.projects);

    if (filteredProjects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off,
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text('No projects match your filters'),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                });
              },
              child: const Text('Clear filters'),
            ),
          ],
        ),
      );
    }

    // Group projects by the main Kanban categories and sort according to column's setting
    // Exclude completed projects from the main columns
    final incompleteProjects =
        filteredProjects.where((p) => !p.isCompleted).toList();

    final Map<String, List<ProjectModel>> kanbanColumns = {
      'Design': _getSortedProjects(
          incompleteProjects
              .where((p) => p.mainStatus == ProjectMainStatus.design)
              .toList(),
          'Design'),
      'Paging': _getSortedProjects(
          incompleteProjects
              .where((p) => p.mainStatus == ProjectMainStatus.paging)
              .toList(),
          'Paging'),
      'Proofing': _getSortedProjects(
          incompleteProjects
              .where((p) => p.mainStatus == ProjectMainStatus.proofing)
              .toList(),
          'Proofing'),
      'EPUB': _getSortedProjects(
          incompleteProjects
              .where((p) => p.mainStatus == ProjectMainStatus.epub)
              .toList(),
          'EPUB'),
    };

    // Return a scrollable row that contains the kanban columns
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: kanbanColumns.entries.map((entry) {
        return Expanded(
          child: _buildKanbanColumn(
            context,
            entry.key,
            entry.value,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildKanbanColumn(
      BuildContext context, String title, List<ProjectModel> projects) {
    final theme = Theme.of(context);
    final columnColor = _getColumnHeaderColor(title);

    // Separate projects into Overdue and Upcoming
    final now = DateTime.now();
    final List<ProjectModel> overdueProjects = [];
    final List<ProjectModel> upcomingProjects = [];

    for (final project in projects) {
      // Get the due date for the current step
      final currentStepDueDate = _getStepDueDate(project);

      // Mark as overdue if the step due date is before today
      // Exception: don't mark as overdue if project is in EPUB phase or is completed
      if (currentStepDueDate != null &&
          currentStepDueDate.isBefore(now) &&
          !project.isCompleted &&
          project.mainStatus != ProjectMainStatus.epub) {
        overdueProjects.add(project);
      } else {
        upcomingProjects.add(project);
      }
    }

    return Container(
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Column header
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: columnColor.withValues(alpha: 0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8.0),
                topRight: Radius.circular(8.0),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: columnColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Sort toggle button
                    InkWell(
                      onTap: () {
                        setState(() {
                          // Toggle sort direction for this column
                          _columnSortDirections[title] =
                              !_columnSortDirections[title]!;
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          _columnSortDirections[title]!
                              ? Icons.arrow_downward
                              : Icons.arrow_upward,
                          size: 16,
                          color: columnColor,
                        ),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: columnColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${projects.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Project cards
          if (projects.isEmpty)
            Container(
              height: 150,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Center(
                child: Text(
                  'No projects in $title',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                  child: Column(
                    children: [
                      // OVERDUE SECTION
                      if (overdueProjects.isNotEmpty) ...[
                        // Overdue header
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 8, top: 4),
                          padding: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 8),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.warning_amber,
                                  color: Colors.red, size: 12),
                              SizedBox(width: 4),
                              Text(
                                'Overdue',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Overdue projects list
                        ...overdueProjects.map((project) => _buildProjectCard(
                            context, project,
                            isOverdue: true)),
                        // Add a divider if both sections are present
                        if (upcomingProjects.isNotEmpty)
                          const Divider(height: 24, thickness: 1),
                      ],

                      // UPCOMING SECTION
                      if (upcomingProjects.isNotEmpty) ...[
                        // Upcoming header
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 8, top: 4),
                          padding: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 8),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.schedule,
                                  color: Colors.grey, size: 12),
                              SizedBox(width: 4),
                              Text(
                                'Upcoming',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Upcoming projects list
                        ...upcomingProjects.map(
                            (project) => _buildProjectCard(context, project)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProjectCard(BuildContext context, ProjectModel project,
      {bool isOverdue = false}) {
    final theme = Theme.of(context);

    // We no longer need to calculate this here since we use project.getCurrentStepLabel() directly

    // Calculate the due date for the current step (not the overall project deadline)
    final currentStepDueDate = _getStepDueDate(project);

    final now = DateTime.now();

    // Check if the current step is overdue
    final isStepOverdue = currentStepDueDate != null &&
        currentStepDueDate.isBefore(now) &&
        !project.isCompleted;

    // Calculate days overdue for current step
    final daysOverdue =
        isStepOverdue ? now.difference(currentStepDueDate).inDays : 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      elevation: (isOverdue || isStepOverdue) ? 2 : 1,
      shape: (isOverdue || isStepOverdue)
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                  color: Colors.red.withValues(alpha: 0.5), width: 1),
            )
          : null,
      child: InkWell(
        onTap: () => _navigateToProject(context, project),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overdue icon
                  if (isOverdue || isStepOverdue)
                    const Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: Icon(
                        Icons.warning_amber,
                        color: Colors.red,
                        size: 18,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      project.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: (isOverdue || isStepOverdue) ? Colors.red : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Show completion indicator if the project is completed
                  if (project.isCompleted)
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 18,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                project.description,
                style: theme.textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Display ISBN
              Row(
                children: [
                  const Icon(
                    Icons.book,
                    size: 12,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'ISBN: ${project.isbn}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Show current step chip (not general status)
                  project.isCompleted
                      ? Chip(
                          backgroundColor: Colors.green.withValues(alpha: 0.2),
                          label: const Text(
                            'Completed',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                            ),
                          ),
                          padding: EdgeInsets.zero,
                          labelPadding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 0),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          side: BorderSide.none,
                        )
                      : Chip(
                          backgroundColor: AppHelpers.getProjectStatusColor(
                                  project.mainStatus)
                              .withValues(alpha: 0.2),
                          label: Text(
                            project
                                .getCurrentStepLabel(), // Use current step label from model
                            style: TextStyle(
                              color: AppHelpers.getProjectStatusColor(
                                  project.mainStatus),
                              fontSize: 12,
                            ),
                          ),
                          padding: EdgeInsets.zero,
                          labelPadding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 0),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          side: BorderSide.none,
                        ),
                  // Show step due date or completion date with overdue indicator
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        project.isCompleted
                            ? 'Completed: ${_formatDate(project.completedAt!)}'
                            : currentStepDueDate != null
                                ? 'Due: ${_formatDate(currentStepDueDate)}'
                                : 'Project due: ${_formatDate(project.deadline)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: (isOverdue || isStepOverdue)
                              ? Colors.red
                              : Colors.grey[600],
                          fontWeight: (isOverdue || isStepOverdue)
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      if (isStepOverdue || isOverdue)
                        if (daysOverdue > 0)
                          Text(
                            'Overdue by $daysOverdue days',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.red,
                              fontWeight: FontWeight.normal,
                            ),
                          )
                        else
                          const Text(
                            'This is due today!',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.red,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // The getCurrentStepLabel method has been moved to the ProjectModel class

  // Helper method to calculate the due date for the current step
  DateTime? _getStepDueDate(ProjectModel project) {
    if (project.isCompleted) return null;

    // Get the list of sub-statuses for the current main status
    final subStatuses =
        ProjectModel.getSubStatusesForMainStatus(project.mainStatus);

    // Find the first incomplete step
    String? nextIncompleteStep;
    for (final status in subStatuses) {
      final value = status['value'];
      if (value != null && !project.statusDates.containsKey(value)) {
        // Found the first incomplete step
        nextIncompleteStep = value;
        break;
      }
    }

    // If there's a next incomplete step, try to get its scheduled date
    if (nextIncompleteStep != null) {
      // Check if there's a scheduled date for this step
      final scheduledDate =
          project.getScheduledDateForSubStatus(nextIncompleteStep);
      if (scheduledDate != null) {
        return scheduledDate;
      }
    }

    // If all steps in this phase are complete, use the last completed step date
    if (subStatuses.isNotEmpty) {
      final lastSubStatus = subStatuses.last['value'];
      if (lastSubStatus != null &&
          project.statusDates.containsKey(lastSubStatus)) {
        return project.statusDates[lastSubStatus];
      }
    }

    // Fallback to project deadline if no other date is available
    return project.deadline;
  }

  Color _getColumnHeaderColor(String columnTitle) {
    switch (columnTitle) {
      case 'Design':
        return Colors.purple;
      case 'Paging':
        return Colors.blue;
      case 'Proofing':
        return Colors.orange;
      case 'EPUB':
        return Colors.green;
      default:
        return Colors.blueGrey;
    }
  }

  List<ProjectModel> _filterProjects(List<ProjectModel> projects) {
    // If there's a search query, return all projects matching the search including completed ones
    if (_searchQuery.isNotEmpty) {
      return projects.where((project) {
        return project.title
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            project.description
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            project.isbn.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // If no search query, return all projects (including completed ones)
    // Completed ones will be shown in the Completed section but filtered from main columns
    return projects;
  }

  String _formatDate(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
  }

  // Helper method to sort projects based on column's sort direction
  List<ProjectModel> _getSortedProjects(
      List<ProjectModel> projects, String columnTitle) {
    final sortNewestFirst = _columnSortDirections[columnTitle] ?? true;

    // Sort by updated date
    projects.sort((a, b) {
      if (sortNewestFirst) {
        // Default - newest first (descending)
        return b.updatedAt.compareTo(a.updatedAt);
      } else {
        // Oldest first (ascending)
        return a.updatedAt.compareTo(b.updatedAt);
      }
    });

    return projects;
  }

  void _navigateToProject(BuildContext context, ProjectModel project) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProjectScreen(projectId: project.id),
      ),
    );
  }

  void _showAddProjectDialog(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final projectProvider =
        Provider.of<ProjectProvider>(context, listen: false);

    // Scroll controller to scroll to top when an error occurs
    final ScrollController scrollController = ScrollController();
    // Error message state for in-dialog errors
    String? errorMessage;

    final titleController = TextEditingController();
    final isbnController = TextEditingController();
    final descriptionController = TextEditingController();
    final productionEditorController = TextEditingController();
    final formatController = TextEditingController();

    // Controllers for metadata fields
    final imprintController = TextEditingController();
    final notesController = TextEditingController();
    final printerDateController = TextEditingController();
    final scDateController = TextEditingController();
    final pubDateController = TextEditingController();

    // Controllers for additional metadata
    final ukCoPubController = TextEditingController();
    // Boolean values for metadata checkboxes
    bool pageCountSent = false;

    // Map to store dates for each sub-status - explicitly for scheduling, not for completion status
    final Map<String, DateTime?> scheduledDates = {};
    final Map<String, TextEditingController> dateControllers = {};

    // Initialize date controllers but don't set default values
    void setupDateControllers(List<Map<String, String>> subStatuses) {
      for (final subStatus in subStatuses) {
        // Initialize with empty text field
        dateControllers[subStatus['value']!] = TextEditingController();
        // Initialize scheduled dates as null
        scheduledDates[subStatus['value']!] = null;
      }
    }

    // Setup all status types with empty date fields
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

      // Validate phase transitions
      DateTime? lastDesignDate;
      if (errors.isNotEmpty)
        return errors; // Return if there are already errors

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

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          title: const Text('Create New Book Project'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.7,
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Required fields note
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      'Fields marked with * are required',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  // Error message display (will only be visible when there's an error)
                  if (errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              errorMessage!,
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () =>
                                setState(() => errorMessage = null),
                            color: Colors.red.shade700,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: const [
                      Text(
                        'Title',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        ' *',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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
                  Row(
                    children: const [
                      Text(
                        'ISBN',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        ' *',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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
                    'New projects always start in the Design phase and progress through each stage. '
                    'Please enter target dates for each step below. Dates within each phase and '
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
                        const Text('Enter target dates for all design steps:'),
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
                        const Text('Enter target dates for all paging steps:'),
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
                        const Text(
                            'Enter target dates for all proofing steps:'),
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
                        const Text('Enter target dates for all e-pub steps:'),
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
                // Basic validation for required fields only
                if (titleController.text.isEmpty ||
                    isbnController.text.isEmpty) {
                  setState(() {
                    errorMessage =
                        'Please fill in all required fields (Title and ISBN)';
                  });
                  // Scroll to the top of the dialog to show the error message
                  scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                  return;
                }

                // Validate and check sequence of all dates
                final validationErrors = validateAllPhaseSequences();

                if (validationErrors.isNotEmpty) {
                  setState(() {
                    errorMessage = validationErrors.first;
                  });
                  // Scroll to the top of the dialog to show the error message
                  scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
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

                // All validation passed, we can create the project
                final userId = authProvider.user?.id;
                if (userId == null) return;

                // Convert nullable scheduledDates to non-nullable for the project model
                final Map<String, DateTime> validScheduledDates = {};
                scheduledDates.forEach((key, date) {
                  if (date != null) {
                    validScheduledDates[key] = date;
                  }
                });

                // Always start with Design phase and first step
                // Parse metadata date fields
                DateTime? printerDate =
                    parseDateMMDDYYYY(printerDateController.text);
                DateTime? scDate = parseDateMMDDYYYY(scDateController.text);
                DateTime? pubDate = parseDateMMDDYYYY(pubDateController.text);

                final newProject = ProjectModel(
                  id: '', // Will be set by the service
                  title: titleController.text,
                  description: descriptionController.text,
                  isbn: isbnController.text,
                  productionEditor: productionEditorController.text,
                  format: formatController.text,
                  mainStatus:
                      ProjectMainStatus.design, // Always start at design phase
                  subStatus: ProjectModel.designSubStatuses.isNotEmpty
                      ? ProjectModel.designSubStatuses[0]['value']!
                      : 'design_initial', // First design step
                  statusDates: {}, // Empty statusDates - nothing marked as completed yet
                  scheduledDates:
                      validScheduledDates, // Store all user-entered due dates
                  deadline: deadline,
                  ownerId: userId,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                  // Metadata fields
                  imprint: imprintController.text.trim(),
                  printerDate: printerDate,
                  scDate: scDate,
                  pubDate: pubDate,
                  notes: notesController.text.trim(),
                  ukCoPub: ukCoPubController.text.trim(),
                  pageCountSent: pageCountSent,
                );

                // Dispose of the scroll controller
                scrollController.dispose();
                Navigator.pop(context);

                // Show a loading indicator in the dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Creating project...'),
                    duration: Duration(seconds: 1),
                  ),
                );

                final createdProject =
                    await projectProvider.createProject(newProject);

                // Handle UI updates if context is still mounted
                if (context.mounted) {
                  if (createdProject != null) {
                    // We don't explicitly reload projects as the stream should handle it
                    // Just add the new project to the local list for immediate display
                    projectProvider.addLocalProject(createdProject);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Project created successfully'),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${projectProvider.error}'),
                        backgroundColor: Theme.of(context).colorScheme.error,
                      ),
                    );
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  // Method to build the metadata section
  Widget _buildMetadataSection({
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
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        ),
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
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 10, vertical: 10),
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
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
