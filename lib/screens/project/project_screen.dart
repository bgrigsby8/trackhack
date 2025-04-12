// lib/screens/project/project_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/project_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/document_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/project_model.dart';
import 'widgets/task_list.dart';
import '../document/document_screen.dart';

class ProjectScreen extends StatefulWidget {
  final String projectId;

  const ProjectScreen({
    super.key,
    required this.projectId,
  });

  @override
  State<ProjectScreen> createState() => _ProjectScreenState();
}

class _ProjectScreenState extends State<ProjectScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final projectProvider =
          Provider.of<ProjectProvider>(context, listen: false);
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      final documentProvider =
          Provider.of<DocumentProvider>(context, listen: false);

      projectProvider.getProjectById(widget.projectId);
      taskProvider.setCurrentProject(widget.projectId);
      documentProvider.setCurrentProject(widget.projectId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Tasks'),
            Tab(text: 'Documents'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildProjectHeader(context, project),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                TaskList(projectId: project.id),
                _buildDocumentsTab(context, project),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            _showAddTaskDialog(context, project);
          } else {
            _showAddDocumentDialog(context, project);
          }
        },
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
                  color: _getStatusColor(project.status),
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
        ],
      ),
    );
  }

  Widget _buildDocumentsTab(BuildContext context, ProjectModel project) {
    final documentProvider = Provider.of<DocumentProvider>(context);
    final rootDocuments = documentProvider.rootDocuments;

    if (documentProvider.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (rootDocuments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.description_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No documents yet',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first document to get started',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rootDocuments.length,
      itemBuilder: (context, index) {
        final document = rootDocuments[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.description),
            title: Text(document.title),
            subtitle: Text(
              'Last updated: ${_formatDate(document.updatedAt)}',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              documentProvider.setCurrentDocument(document);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DocumentScreen(documentId: document.id),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Color _getStatusColor(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.paging:
        return Colors.blue;
      case ProjectStatus.inDesign:
        return Colors.amber;
      case ProjectStatus.proofing:
        return Colors.purple;
      case ProjectStatus.notTransmitted:
        return Colors.grey;
      case ProjectStatus.press:
        return Colors.grey;
      case ProjectStatus.epub:
        return Colors.grey;
      case ProjectStatus.published:
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

  void _showAddTaskDialog(BuildContext context, ProjectModel project) {
    // Add task dialog implementation
    // Not implementing in this cleanup
  }

  void _showAddDocumentDialog(BuildContext context, ProjectModel project) {
    // Add document dialog implementation
    // Not implementing in this cleanup
  }
}
