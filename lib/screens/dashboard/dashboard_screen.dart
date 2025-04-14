// lib/screens/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/project_provider.dart';
import '../../models/project_model.dart';
import '../../utils/helpers.dart';
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
  Map<String, bool> _columnSortDirections = {
    'Design': true,
    'Paging': true,
    'Proofing': true,
    'EPUB': true, // Added EPUB column
    'Other': true,
  };

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

    // Ensure projects are loaded if user exists but projects are empty
    if (user != null &&
        !projectProvider.loading &&
        projectProvider.projects.isEmpty) {
      // Use a post-frame callback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          projectProvider.loadUserProjects(user.id);
        }
      });
    }

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'TrackHack',
          style: TextStyle(fontSize: 25),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () => _showUserProfileDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showSignOutDialog(context),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSearchAndFilter(context),
          if (projectProvider.loading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (projectProvider.projects.isEmpty)
            _buildEmptyProjectsView(context)
          else
            Expanded(
              child: _buildProjectsGrid(context, projectProvider),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddProjectDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchAndFilter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
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
    );
  }

  Widget _buildEmptyProjectsView(BuildContext context) {
    return Expanded(
      child: Center(
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
    final Map<String, List<ProjectModel>> kanbanColumns = {
      'Design': _getSortedProjects(
          filteredProjects
              .where((p) => p.mainStatus == ProjectMainStatus.design)
              .toList(),
          'Design'),
      'Paging': _getSortedProjects(
          filteredProjects
              .where((p) => p.mainStatus == ProjectMainStatus.paging)
              .toList(),
          'Paging'),
      'Proofing': _getSortedProjects(
          filteredProjects
              .where((p) => p.mainStatus == ProjectMainStatus.proofing)
              .toList(),
          'Proofing'),
      'EPUB': _getSortedProjects(
          filteredProjects
              .where((p) => p.mainStatus == ProjectMainStatus.epub)
              .toList(),
          'EPUB'),
      'Other': _getSortedProjects(
          filteredProjects
              .where((p) => p.mainStatus == ProjectMainStatus.other)
              .toList(),
          'Other'),
    };

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
              color: _getColumnHeaderColor(title).withValues(alpha: 0.2),
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
                        color: _getColumnHeaderColor(title),
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
                          color: _getColumnHeaderColor(title),
                        ),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getColumnHeaderColor(title),
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
            DragTarget<ProjectModel>(
              onAcceptWithDetails: (data) =>
                  _handleProjectDrop(data as ProjectModel, title),
              builder: (context, candidateData, rejectedData) {
                return Container(
                  height: 150,
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: candidateData.isNotEmpty
                        ? _getColumnHeaderColor(title).withValues(alpha: 0.1)
                        : null,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Center(
                    child: Text(
                      candidateData.isNotEmpty
                          ? 'Drop here to move to $title'
                          : 'No projects in $title',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: candidateData.isNotEmpty
                            ? _getColumnHeaderColor(title)
                            : Colors.grey,
                      ),
                    ),
                  ),
                );
              },
            )
          else
            Expanded(
              child: DragTarget<ProjectModel>(
                onAcceptWithDetails: (data) =>
                    _handleProjectDrop(data as ProjectModel, title),
                builder: (context, candidateData, rejectedData) {
                  return Container(
                    decoration: BoxDecoration(
                      color: candidateData.isNotEmpty
                          ? _getColumnHeaderColor(title).withValues(alpha: 0.1)
                          : null,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(8.0),
                        bottomRight: Radius.circular(8.0),
                      ),
                    ),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8.0),
                      itemCount: projects.length,
                      itemBuilder: (context, index) {
                        final project = projects[index];
                        return LongPressDraggable<ProjectModel>(
                          data: project,
                          delay: const Duration(milliseconds: 500),
                          feedback: Material(
                            elevation: 4.0,
                            child: Container(
                              width: MediaQuery.of(context).size.width * 0.2,
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                color: theme.cardColor,
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Text(
                                project.title,
                                style: theme.textTheme.titleMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          childWhenDragging: Opacity(
                            opacity: 0.3,
                            child: _buildProjectCard(context, project),
                          ),
                          child: _buildProjectCard(context, project),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProjectCard(BuildContext context, ProjectModel project) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: InkWell(
        onTap: () => _navigateToProject(context, project),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                project.title,
                style: theme.textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                project.description,
                style: theme.textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Chip(
                    backgroundColor:
                        AppHelpers.getProjectStatusColor(project.mainStatus)
                            .withValues(alpha: 0.2),
                    label: Text(
                      project.statusLabel,
                      style: TextStyle(
                        color: AppHelpers.getProjectStatusColor(
                            project.mainStatus),
                        fontSize: 12,
                      ),
                    ),
                    padding: EdgeInsets.zero,
                    labelPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  Text(
                    'Due: ${_formatDate(project.deadline)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleProjectDrop(ProjectModel project, String columnTitle) async {
    final projectProvider =
        Provider.of<ProjectProvider>(context, listen: false);

    // Based on the column, determine the new main status and default sub-status
    ProjectMainStatus? newMainStatus;
    String defaultSubStatus = '';

    switch (columnTitle) {
      case 'Design':
        newMainStatus = ProjectMainStatus.design;
        defaultSubStatus = 'initial'; // Using the first sub-status for design
        break;
      case 'Paging':
        newMainStatus = ProjectMainStatus.paging;
        defaultSubStatus = 'initial'; // Using the first sub-status for paging
        break;
      case 'Proofing':
        newMainStatus = ProjectMainStatus.proofing;
        defaultSubStatus =
            'firstPass'; // Using the first proofing sub-status (1P)
        break;
      case 'EPUB':
        newMainStatus = ProjectMainStatus.epub;
        defaultSubStatus = 'initial'; // Default sub-status for EPUB
        break;
      case 'Other':
        // Keep the same status if moving within "Other"
        if (project.mainStatus == ProjectMainStatus.other) {
          return;
        }
        // If moving from another column to "Other", set to "Not Transmitted"
        newMainStatus = ProjectMainStatus.other;
        defaultSubStatus = 'notTransmitted';
        break;
    }

    if (newMainStatus != null && newMainStatus != project.mainStatus) {
      try {
        await projectProvider.updateProjectMainStatus(
            project.id, newMainStatus, defaultSubStatus);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Moved "${project.title}" to $columnTitle'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating project: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
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
      case 'Other':
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }

  List<ProjectModel> _filterProjects(List<ProjectModel> projects) {
    return projects.where((project) {
      // Apply search filter only (removed main status filter)
      return _searchQuery.isEmpty ||
          project.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          project.description
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());
    }).toList();
  }

  String _getMainStatusLabel(ProjectMainStatus status) {
    switch (status) {
      case ProjectMainStatus.design:
        return 'Design';
      case ProjectMainStatus.paging:
        return 'Paging';
      case ProjectMainStatus.proofing:
        return 'Proofing';
      case ProjectMainStatus.epub:
        return 'EPUB';
      case ProjectMainStatus.other:
        return 'Other';
    }
  }

  Color _getMainStatusColor(ProjectMainStatus status) {
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

  String _formatDateMMDDYYYY(DateTime date) {
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

    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final deadlineController = TextEditingController(
      text: _formatDateMMDDYYYY(
        DateTime.now().add(const Duration(days: 30)),
      ),
    );

    // Default selection values
    ProjectMainStatus selectedMainStatus = ProjectMainStatus.other;
    String selectedSubStatus = 'notTransmitted';
    // ignore: unused_local_variable
    DateTime selectedDeadline = DateTime.now().add(const Duration(days: 30));

    // Map to store dates for each sub-status
    final Map<String, DateTime> statusDates = {};
    final Map<String, TextEditingController> dateControllers = {};

    // Set the current date as the default for all Proofing sub-statuses
    final now = DateTime.now();
    for (final subStatus in ProjectModel.proofingSubStatuses) {
      statusDates[subStatus['value']!] = now;
      dateControllers[subStatus['value']!] = TextEditingController(
        text: _formatDateMMDDYYYY(now),
      );
    }

    // Helper function to validate and parse data
    DateTime? _parseDateMMDDYYYY(String input) {
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

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create New Book Project'),
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

                  // Main Status dropdown
                  const Text(
                    'Main Status',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<ProjectMainStatus>(
                    value: selectedMainStatus,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: ProjectMainStatus.values.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: _getMainStatusColor(status),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(_getMainStatusLabel(status)),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedMainStatus = value;

                          // Set appropriate default sub-status based on main status
                          switch (value) {
                            case ProjectMainStatus.design:
                              selectedSubStatus = 'initial';
                              break;
                            case ProjectMainStatus.paging:
                              selectedSubStatus = 'initial';
                              break;
                            case ProjectMainStatus.proofing:
                              selectedSubStatus = 'firstPass';
                              break;
                            case ProjectMainStatus.epub:
                              selectedSubStatus = 'sentEPub';
                              break;
                            case ProjectMainStatus.other:
                              selectedSubStatus = 'notTransmitted';
                              break;
                          }
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Sub-Status section that changes based on main status
                  if (selectedMainStatus == ProjectMainStatus.proofing) ...[
                    const Text('Proofing Status:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: selectedSubStatus,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: ProjectModel.proofingSubStatuses.map((subStatus) {
                        return DropdownMenuItem(
                          value: subStatus['value'],
                          child: Text(subStatus['label']!),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedSubStatus = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Status dates for proofing
                    const Text('Status Dates:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
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
                              controller: dateControllers[subStatus['value']],
                              decoration: const InputDecoration(
                                hintText: 'MM/DD/YYYY',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (value) {
                                final date = _parseDateMMDDYYYY(value);
                                if (date != null) {
                                  setState(() {
                                    statusDates[subStatus['value']!] = date;
                                  });
                                }
                              },
                            )
                          ],
                        ),
                      );
                    }),
                  ] else if (selectedMainStatus ==
                      ProjectMainStatus.design) ...[
                    const Text('Design Status:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    // Placeholder for design sub-statuses
                    DropdownButtonFormField<String>(
                      value: selectedSubStatus,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'initial',
                          child: Text('Initial Design'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedSubStatus = value;
                          });
                        }
                      },
                    ),
                  ] else if (selectedMainStatus ==
                      ProjectMainStatus.paging) ...[
                    const Text('Paging Status:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    // Placeholder for paging sub-statuses
                    DropdownButtonFormField<String>(
                      value: selectedSubStatus,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'initial',
                          child: Text('Initial Paging'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedSubStatus = value;
                          });
                        }
                      },
                    ),
                  ] else ...[
                    const Text('Other Status:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: selectedSubStatus,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'notTransmitted',
                          child: Text('Not Transmitted'),
                        ),
                        DropdownMenuItem(
                          value: 'press',
                          child: Text('At Press'),
                        ),
                        DropdownMenuItem(
                          value: 'epub',
                          child: Text('E-book'),
                        ),
                        DropdownMenuItem(
                          value: 'published',
                          child: Text('Published'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedSubStatus = value;
                          });
                        }
                      },
                    ),
                  ],

                  const SizedBox(height: 16),
                  const Text(
                    'Project Deadline',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: deadlineController,
                    decoration: const InputDecoration(
                      hintText: 'MM/DD/YYYY',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      final date = _parseDateMMDDYYYY(value);
                      if (date != null) {
                        setState(() {
                          selectedDeadline = date;
                        });
                      }
                    },
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
                if (titleController.text.isEmpty ||
                    descriptionController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill in all fields'),
                    ),
                  );
                  return;
                }

                // Validate deadline
                final deadline = _parseDateMMDDYYYY(deadlineController.text);
                if (deadline == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Invalid date format. Use MM/DD/YYYY'),
                    ),
                  );
                  return;
                }

                // Validate status dates if needed
                if (selectedMainStatus == ProjectMainStatus.proofing) {
                  bool allDatesValid = true;
                  final Map<String, DateTime> validatedStatusDates = {};

                  for (final entry in dateControllers.entries) {
                    final date = _parseDateMMDDYYYY(entry.value.text);
                    if (date == null) {
                      allDatesValid = false;
                      break;
                    }
                    validatedStatusDates[entry.key] = date;
                  }

                  if (!allDatesValid) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Invalid date format. Use MM/DD/YYYY'),
                      ),
                    );
                    return;
                  }

                  // Update with validated dates
                  statusDates.clear();
                  statusDates.addAll(validatedStatusDates);
                }

                final userId = authProvider.user?.id;
                if (userId == null) return;

                final newProject = ProjectModel(
                  id: '', // Will be set by the service
                  title: titleController.text,
                  description: descriptionController.text,
                  mainStatus: selectedMainStatus,
                  subStatus: selectedSubStatus,
                  statusDates: selectedMainStatus == ProjectMainStatus.proofing
                      ? statusDates
                      : {},
                  deadline: deadline,
                  ownerId: userId,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                Navigator.pop(context);

                final createdProject =
                    await projectProvider.createProject(newProject);

                // Handle UI updates if context is still mounted
                if (context.mounted) {
                  if (createdProject != null) {
                    // Explicitly reload projects after creating a new one
                    final authProvider =
                        Provider.of<AuthProvider>(context, listen: false);
                    if (authProvider.user != null) {
                      projectProvider.loadUserProjects(authProvider.user!.id);
                    }

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

  void _showUserProfileDialog(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user == null) return;

    final nameController = TextEditingController(text: user.name);
    final roleController = TextEditingController(text: user.role);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('User Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar
              CircleAvatar(
                radius: 40,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontSize: 32,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Email (read-only)
              Text(
                user.email,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // Name
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                ),
              ),
              const SizedBox(height: 16),
              // Role
              TextField(
                controller: roleController,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  hintText: 'e.g. Editor, Author, Publisher',
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
              if (nameController.text.isEmpty || roleController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill in all fields'),
                  ),
                );
                return;
              }

              Navigator.pop(context);

              await authProvider.updateUserProfile(
                name: nameController.text,
                role: roleController.text,
              );

              if (authProvider.error != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${authProvider.error}'),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profile updated successfully'),
                  ),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              authProvider.signOut();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
