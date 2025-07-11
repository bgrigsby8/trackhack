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
    
    // Update the project in the projects list too if it exists
    final index = _projects.indexWhere((p) => p.id == project.id);
    if (index != -1) {
      _projects[index] = project;
    }
    
    notifyListeners();
  }

  // Load user projects
  void loadUserProjects(String userId) {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      // Cancel previous subscription if it exists
      if (_projectsSubscription != null) {
        _projectsSubscription?.cancel();
      }

      // Subscribe to user projects stream
      _projectsSubscription = _projectService.getUserProjects(userId).listen(
        (projectsList) {
          // Sort by last updated to show newest first
          projectsList.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

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
  
  // Add a project to the local list without reloading from Firestore
  // This helps avoid flickering while waiting for the Firestore stream to update
  void addLocalProject(ProjectModel project) {
    // Check if the project is already in the list
    final index = _projects.indexWhere((p) => p.id == project.id);
    if (index >= 0) {
      // Update existing project
      _projects[index] = project;
    } else {
      // Add new project
      _projects.add(project);
      // Sort by updated date (newest first)
      _projects.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }
    notifyListeners();
  }

  // Update a project
  Future<void> updateProject(ProjectModel project) async {
    try {
      // We don't set loading = true here anymore since we're using optimistic updates
      _error = null;
      
      // The UI may already be updated if we're using optimistic updates
      // Still make sure our local state is updated
      final projectIndex = _projects.indexWhere((p) => p.id == project.id);
      if (projectIndex >= 0) {
        _projects[projectIndex] = project;
      }
      
      if (_currentProject?.id == project.id) {
        _currentProject = project;
      }
      
      // Notify listeners before the async operation to ensure UI is updated
      notifyListeners();

      // Now update Firestore without blocking the UI
      await _projectService.updateProject(project);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      // Rethrow to allow the caller to handle the error
      rethrow;
    }
  }

  // Update a project's main status
  Future<void> updateProjectMainStatus(String projectId,
      ProjectMainStatus newMainStatus, String defaultSubStatus) async {
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
        mainStatus: newMainStatus,
        subStatus: defaultSubStatus,
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

  // Update a project's sub-status
  Future<void> updateProjectSubStatus(
      String projectId, String newSubStatus, DateTime? statusDate, {String? subStatus}) async {
    try {
      _error = null;

      // Find the project in the list
      final projectIndex = _projects.indexWhere((p) => p.id == projectId);
      if (projectIndex == -1) {
        _error = 'Project not found';
        notifyListeners();
        return;
      }

      // Update status dates
      Map<String, DateTime> statusDates =
          Map.from(_projects[projectIndex].statusDates);
          
      // If a specific subStatus is provided, update only that status's date
      // without changing the current project sub-status
      final String statusToUpdate = subStatus ?? newSubStatus;
      
      if (statusDate != null) {
        // Add or update the date
        statusDates[statusToUpdate] = statusDate;
      } else if (subStatus != null) {
        // If statusDate is null and a specific subStatus was provided,
        // remove that status date (mark as incomplete)
        statusDates.remove(statusToUpdate);
      }

      // Create updated project - only change the current subStatus if none was specified
      var updatedProject = _projects[projectIndex].copyWith(
        // Only update subStatus if no specific subStatus was provided
        subStatus: subStatus == null ? newSubStatus : _projects[projectIndex].subStatus,
        statusDates: statusDates,
        updatedAt: DateTime.now(),
      );
      
      // Check if the project's completion status should change
      if (!updatedProject.isCompleted && updatedProject.shouldBeMarkedAsCompleted()) {
        // Mark as completed if all tasks in the last phase are completed
        final now = DateTime.now();
        updatedProject = updatedProject.copyWith(
          isCompleted: true,
          completedAt: now,
        );
      } else if (updatedProject.isCompleted && !updatedProject.shouldBeMarkedAsCompleted()) {
        // If project was marked as completed before but now has incomplete tasks,
        // move it back to normal status
        updatedProject = updatedProject.copyWith(
          isCompleted: false,
          completedAt: null,
        );
      }

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
  
  // Get completed projects
  List<ProjectModel> getCompletedProjects() {
    return _projects.where((project) => project.isCompleted).toList()
      ..sort((a, b) => b.completedAt!.compareTo(a.completedAt!)); // Most recently completed first
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
  Future<ProjectModel?> getProjectById(String projectId) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final project = await _projectService.getProject(projectId);
      if (project != null) {
        _currentProject = project;
      }
      
      _loading = false;
      notifyListeners();
      return _currentProject;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      return null;
    }
  }

  // Get projects by main status
  List<ProjectModel> getProjectsByMainStatus(ProjectMainStatus mainStatus) {
    return _projects
        .where((project) => project.mainStatus == mainStatus)
        .toList();
  }

  // Get projects by sub-status
  List<ProjectModel> getProjectsBySubStatus(String subStatus) {
    return _projects
        .where((project) => project.subStatus == subStatus)
        .toList();
  }

  // Filter projects by search query
  List<ProjectModel> searchProjects(String query) {
    if (query.isEmpty) return _projects;

    final lowercaseQuery = query.toLowerCase();
    return _projects.where((project) {
      return project.title.toLowerCase().contains(lowercaseQuery) ||
          project.description.toLowerCase().contains(lowercaseQuery) ||
          project.isbn.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  // Mark a project as complete by completing all remaining sub-statuses
  Future<void> markProjectAsComplete(String projectId) async {
    try {
      _error = null;

      // Find the project in the list
      final projectIndex = _projects.indexWhere((p) => p.id == projectId);
      if (projectIndex == -1) {
        _error = 'Project not found';
        notifyListeners();
        return;
      }

      final project = _projects[projectIndex];
      
      // If project is already completed, nothing to do
      if (project.isCompleted) {
        return;
      }

      // Create updated status dates map
      Map<String, DateTime> statusDates = Map.from(project.statusDates);
      final now = DateTime.now();

      // Complete all sub-statuses in all phases
      final allSubStatuses = [
        ...ProjectModel.designSubStatuses,
        ...ProjectModel.pagingSubStatuses,
        ...ProjectModel.proofingSubStatuses,
        ...ProjectModel.epubSubStatuses,
      ];

      for (final subStatus in allSubStatuses) {
        final statusKey = subStatus['value']!;
        if (!statusDates.containsKey(statusKey)) {
          statusDates[statusKey] = now;
        }
      }

      // Create updated project with all statuses completed
      var updatedProject = project.copyWith(
        mainStatus: ProjectMainStatus.epub,
        subStatus: ProjectModel.epubSubStatuses.last['value']!,
        statusDates: statusDates,
        isCompleted: true,
        completedAt: now,
        updatedAt: now,
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
      rethrow;
    }
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
