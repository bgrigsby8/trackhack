// lib/providers/task_provider.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';

class TaskProvider with ChangeNotifier {
  final TaskService _taskService = TaskService();

  List<TaskModel> _projectTasks = [];
  TaskModel? _currentTask;
  String? _error;
  bool _loading = false;
  String? _currentProjectId;

  StreamSubscription? _tasksSubscription;

  // Getters
  List<TaskModel> get projectTasks => _projectTasks;
  TaskModel? get currentTask => _currentTask;
  String? get error => _error;
  bool get loading => _loading;
  String? get currentProjectId => _currentProjectId;

  // Set current task
  void setCurrentTask(TaskModel task) {
    _currentTask = task;
    notifyListeners();
  }

  // Set current project and load its tasks
  void setCurrentProject(String projectId) {
    if (_currentProjectId != projectId) {
      _currentProjectId = projectId;
      _projectTasks = [];
      _currentTask = null;

      _tasksSubscription?.cancel();
      _loadProjectTasks(projectId);
    }
  }

  // Load tasks for a project
  void _loadProjectTasks(String projectId) {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      // Cancel previous subscription if it exists
      _tasksSubscription?.cancel();

      // Subscribe to project tasks stream
      _tasksSubscription = _taskService
          .getProjectTasks(projectId)
          .listen(
            (tasks) {
              _projectTasks = tasks;
              _loading = false;

              // If current task exists, update it with fresh data
              if (_currentTask != null) {
                final updatedTask = _projectTasks.firstWhere(
                  (t) => t.id == _currentTask!.id,
                  orElse: () => _currentTask!,
                );
                _currentTask = updatedTask;
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

  // Create a new task
  Future<TaskModel?> createTask({
    required String projectId,
    required String title,
    required String createdBy,
    String description = '',
    TaskStatus status = TaskStatus.todo,
    TaskPriority priority = TaskPriority.medium,
    String? assigneeId,
    DateTime? deadline,
  }) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final newTask = await _taskService.createTask(
        projectId: projectId,
        title: title,
        createdBy: createdBy,
        description: description,
        status: status,
        priority: priority,
        assigneeId: assigneeId,
        deadline: deadline,
      );

      return newTask;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Update a task
  Future<void> updateTask({
    required String taskId,
    String? title,
    String? description,
    TaskStatus? status,
    TaskPriority? priority,
    String? assigneeId,
    DateTime? deadline,
  }) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      await _taskService.updateTask(
        taskId: taskId,
        title: title,
        description: description,
        status: status,
        priority: priority,
        assigneeId: assigneeId,
        deadline: deadline,
      );

      if (_currentTask?.id == taskId) {
        _currentTask = _currentTask!.copyWith(
          title: title ?? _currentTask!.title,
          description: description ?? _currentTask!.description,
          status: status ?? _currentTask!.status,
          priority: priority ?? _currentTask!.priority,
          assigneeId: assigneeId ?? _currentTask!.assigneeId,
          deadline: deadline ?? _currentTask!.deadline,
          updatedAt: DateTime.now(),
        );
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Delete a task
  Future<void> deleteTask(String taskId) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      await _taskService.deleteTask(taskId);

      if (_currentTask?.id == taskId) {
        _currentTask = null;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Get task by ID (used when navigating directly to a task)
  Future<void> getTaskById(String taskId) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final task = await _taskService.getTask(taskId);
      if (task != null) {
        _currentTask = task;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Get tasks by status
  List<TaskModel> getTasksByStatus(TaskStatus status) {
    return _projectTasks.where((task) => task.status == status).toList();
  }

  // Get tasks by priority
  List<TaskModel> getTasksByPriority(TaskPriority priority) {
    return _projectTasks.where((task) => task.priority == priority).toList();
  }

  // Filter tasks by search query
  List<TaskModel> searchTasks(String query) {
    if (query.isEmpty) return _projectTasks;

    final lowercaseQuery = query.toLowerCase();
    return _projectTasks.where((task) {
      return task.title.toLowerCase().contains(lowercaseQuery) ||
          task.description.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  // Clear current task
  void clearCurrentTask() {
    _currentTask = null;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _tasksSubscription?.cancel();
    super.dispose();
  }
}
