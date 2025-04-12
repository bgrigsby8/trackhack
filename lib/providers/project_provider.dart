// lib/providers/project_provider.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/project_model.dart';
import '../services/project_service.dart';

class ProjectProvider with ChangeNotifier {
  final ProjectService _projectService = ProjectService();

  List<ProjectModel> _projects = [];
  ProjectModel? _currentProject;
  String? _error;
  bool _loading = false;
  StreamSubscription? _projectsSubscription;

  // Getters
  List<ProjectModel> get projects => _projects;
  ProjectModel? get currentProject => _currentProject;
  String? get error => _error;
  bool get loading => _loading;

  // Set current project
  void setCurrentProject(ProjectModel project) {
    _currentProject = project;
    notifyListeners();
  }

  // Load user projects
  void loadUserProjects(String userId) {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      // Cancel previous subscription if it exists
      _projectsSubscription?.cancel();

      // Subscribe to user projects stream
      _projectsSubscription = _projectService
          .getUserProjects(userId)
          .listen(
            (projectsList) {
              _projects = projectsList;
              _loading = false;

              // If current project exists, update it with fresh data
              if (_currentProject != null) {
                final updatedProject = _projects.firstWhere(
                  (p) => p.id == _currentProject!.id,
                  orElse: () => _currentProject!,
                );
                _currentProject = updatedProject;
              }

              notifyListeners();
            },
            onError: (e) {
              _error = e.toString();
              _loading = false;
              notifyListeners();
            },
          );
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
    }
  }

  // Create a new project
  Future<ProjectModel?> createProject(ProjectModel project) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final createdProject = await _projectService.createProject(project);
      return createdProject;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Update a project
  Future<void> updateProject(ProjectModel project) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      await _projectService.updateProject(project);

      if (_currentProject?.id == project.id) {
        _currentProject = project;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
  
  // Update a project's status
  Future<void> updateProjectStatus(String projectId, ProjectStatus newStatus) async {
    try {
      _error = null;
      
      // Find the project in the list
      final projectIndex = _projects.indexWhere((p) => p.id == projectId);
      if (projectIndex == -1) {
        _error = 'Project not found';
        notifyListeners();
        return;
      }
      
      // Create updated project
      final updatedProject = _projects[projectIndex].copyWith(
        status: newStatus,
        updatedAt: DateTime.now(),
      );
      
      // Update in Firestore
      await _projectService.updateProject(updatedProject);
      
      // Update locally
      _projects[projectIndex] = updatedProject;
      
      // If this is the current project, update it too
      if (_currentProject?.id == projectId) {
        _currentProject = updatedProject;
      }
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Delete a project
  Future<void> deleteProject(String projectId, String ownerId) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      await _projectService.deleteProject(projectId, ownerId);

      if (_currentProject?.id == projectId) {
        _currentProject = null;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }


  // Get project by ID (used when navigating directly to a project)
  Future<void> getProjectById(String projectId) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final project = await _projectService.getProject(projectId);
      if (project != null) {
        _currentProject = project;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Get projects by status
  List<ProjectModel> getProjectsByStatus(ProjectStatus status) {
    return _projects.where((project) => project.status == status).toList();
  }

  // Filter projects by search query
  List<ProjectModel> searchProjects(String query) {
    if (query.isEmpty) return _projects;

    final lowercaseQuery = query.toLowerCase();
    return _projects.where((project) {
      return project.title.toLowerCase().contains(lowercaseQuery) ||
          project.description.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _projectsSubscription?.cancel();
    super.dispose();
  }
}
