// lib/screens/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/project_provider.dart';
import '../../models/project_model.dart';
import '../../utils/helpers.dart';
import '../project/project_screen.dart';
import 'widgets/stats_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _searchQuery = '';
  ProjectStatus? _filterStatus;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
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

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('TrackHack'),
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
          _buildWelcomeHeader(context, user.name),
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

  Widget _buildWelcomeHeader(BuildContext context, String userName) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      color: primary.withValues(alpha: 0.7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome, $userName',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          const StatsWidget(),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
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
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text('Filter: '),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context,
                  label: 'All',
                  selected: _filterStatus == null,
                  onSelected: (_) {
                    setState(() {
                      _filterStatus = null;
                    });
                  },
                ),
                for (final status in ProjectStatus.values)
                  _buildFilterChip(
                    context,
                    label: _getStatusLabel(status),
                    selected: _filterStatus == status,
                    color: AppHelpers.getProjectStatusColor(status),
                    onSelected: (_) {
                      setState(() {
                        _filterStatus = status;
                      });
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required bool selected,
    required Function(bool) onSelected,
    Color? color,
  }) {
    final theme = Theme.of(context);
    final backgroundColor =
        color?.withValues(alpha: 0.2) ?? theme.chipTheme.backgroundColor;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: onSelected,
        backgroundColor: backgroundColor,
        selectedColor: color ?? theme.colorScheme.primary,
        labelStyle: TextStyle(
          color: selected ? Colors.white : null,
        ),
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
                  _filterStatus = null;
                });
              },
              child: const Text('Clear filters'),
            ),
          ],
        ),
      );
    }

    // Group projects by the main Kanban categories
    final Map<String, List<ProjectModel>> kanbanColumns = {
      'Design': filteredProjects
          .where((p) => p.status == ProjectStatus.inDesign)
          .toList(),
      'Paging': filteredProjects
          .where((p) => p.status == ProjectStatus.paging)
          .toList(),
      'Proofing': filteredProjects
          .where((p) => p.status == ProjectStatus.proofing)
          .toList(),
      'Other': filteredProjects
          .where((p) =>
              p.status != ProjectStatus.inDesign &&
              p.status != ProjectStatus.paging &&
              p.status != ProjectStatus.proofing)
          .toList(),
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
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _getColumnHeaderColor(title),
                  ),
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
                        AppHelpers.getProjectStatusColor(project.status)
                            .withValues(alpha: 0.2),
                    label: Text(
                      project.statusLabel,
                      style: TextStyle(
                        color: AppHelpers.getProjectStatusColor(project.status),
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

    // Based on the column, determine the new status
    ProjectStatus? newStatus;

    switch (columnTitle) {
      case 'Design':
        newStatus = ProjectStatus.inDesign;
        break;
      case 'Paging':
        newStatus = ProjectStatus.paging;
        break;
      case 'Proofing':
        newStatus = ProjectStatus.proofing;
        break;
      case 'Other':
        // Keep the same status if moving within "Other"
        if (project.status != ProjectStatus.inDesign &&
            project.status != ProjectStatus.paging &&
            project.status != ProjectStatus.proofing) {
          return;
        }
        // If moving from another column to "Other", set to "Not Transmitted"
        newStatus = ProjectStatus.notTransmitted;
        break;
    }

    if (newStatus != null && newStatus != project.status) {
      try {
        await projectProvider.updateProjectStatus(project.id, newStatus);

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
      case 'Other':
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }

  List<ProjectModel> _filterProjects(List<ProjectModel> projects) {
    return projects.where((project) {
      // Apply search filter
      final matchesSearch = _searchQuery.isEmpty ||
          project.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          project.description
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());

      // Apply status filter
      final matchesStatus =
          _filterStatus == null || project.status == _filterStatus;

      return matchesSearch && matchesStatus;
    }).toList();
  }

  String _getStatusLabel(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.notTransmitted:
        return 'Not Transmitted';
      case ProjectStatus.inDesign:
        return 'In Design';
      case ProjectStatus.paging:
        return 'Paging';
      case ProjectStatus.proofing:
        return 'Proofing';
      case ProjectStatus.press:
        return 'At Press';
      case ProjectStatus.epub:
        return 'Epub';
      case ProjectStatus.published:
        return 'Published';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
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

    ProjectStatus selectedStatus = ProjectStatus.notTransmitted;
    DateTime selectedDeadline = DateTime.now().add(const Duration(days: 30));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create New Book Project'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'Enter book title',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Enter book description',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<ProjectStatus>(
                  value: selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                  ),
                  items: ProjectStatus.values.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: AppHelpers.getProjectStatusColor(status),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(_getStatusLabel(status)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedStatus = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Deadline: '),
                    TextButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDeadline,
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365 * 2)),
                        );
                        if (date != null && context.mounted) {
                          setState(() {
                            selectedDeadline = date;
                          });
                        }
                      },
                      child: Text(
                        _formatDate(selectedDeadline),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
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
                    descriptionController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill in all fields'),
                    ),
                  );
                  return;
                }

                final userId = authProvider.user?.id;
                if (userId == null) return;

                final newProject = ProjectModel(
                  id: '', // Will be set by the service
                  title: titleController.text,
                  description: descriptionController.text,
                  status: selectedStatus,
                  deadline: selectedDeadline,
                  ownerId: userId,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                Navigator.pop(context);

                final createdProject =
                    await projectProvider.createProject(newProject);

                if (createdProject != null && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Project created successfully'),
                    ),
                  );
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${projectProvider.error}'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
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
