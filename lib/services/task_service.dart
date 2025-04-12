// lib/services/task_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/task_model.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // Create a new task
  Future<TaskModel> createTask({
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
      final String taskId = _uuid.v4();
      final now = DateTime.now();

      final newTask = TaskModel(
        id: taskId,
        projectId: projectId,
        title: title,
        description: description,
        status: status,
        priority: priority,
        assigneeId: assigneeId,
        deadline: deadline,
        createdBy: createdBy,
        createdAt: now,
        updatedAt: now,
      );

      await _firestore.collection('tasks').doc(taskId).set(newTask.toMap());

      return newTask;
    } catch (e) {
      rethrow;
    }
  }

  // Get a task by ID
  Future<TaskModel?> getTask(String taskId) async {
    try {
      final doc = await _firestore.collection('tasks').doc(taskId).get();
      if (doc.exists) {
        return TaskModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Get all tasks for a project
  Stream<List<TaskModel>> getProjectTasks(String projectId) {
    try {
      return _firestore
          .collection('tasks')
          .where('projectId', isEqualTo: projectId)
          .where('isArchived', isEqualTo: false)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => TaskModel.fromMap(doc.data()))
            .toList();
      });
    } catch (e) {
      rethrow;
    }
  }

  // Get tasks assigned to a user
  Stream<List<TaskModel>> getUserTasks(String userId) {
    try {
      return _firestore
          .collection('tasks')
          .where('assigneeId', isEqualTo: userId)
          .where('isArchived', isEqualTo: false)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => TaskModel.fromMap(doc.data()))
            .toList();
      });
    } catch (e) {
      rethrow;
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
    bool? isArchived,
  }) async {
    try {
      final taskRef = _firestore.collection('tasks').doc(taskId);
      final task = await taskRef.get();

      if (!task.exists) {
        throw Exception('Task not found');
      }

      final Map<String, dynamic> updates = {};

      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (status != null) updates['status'] = status.index;
      if (priority != null) updates['priority'] = priority.index;
      if (assigneeId != null) updates['assigneeId'] = assigneeId;
      if (deadline != null) {
        updates['deadline'] = deadline.millisecondsSinceEpoch;
      }
      if (isArchived != null) updates['isArchived'] = isArchived;

      updates['updatedAt'] = DateTime.now().millisecondsSinceEpoch;

      await taskRef.update(updates);
    } catch (e) {
      rethrow;
    }
  }

  // Delete a task
  Future<void> deleteTask(String taskId) async {
    try {
      await _firestore.collection('tasks').doc(taskId).delete();
    } catch (e) {
      rethrow;
    }
  }

  // Get tasks by status for a project
  Future<List<TaskModel>> getTasksByStatus({
    required String projectId,
    required TaskStatus status,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('tasks')
          .where('projectId', isEqualTo: projectId)
          .where('status', isEqualTo: status.index)
          .where('isArchived', isEqualTo: false)
          .get();

      return snapshot.docs.map((doc) => TaskModel.fromMap(doc.data())).toList();
    } catch (e) {
      rethrow;
    }
  }

  // Get tasks by priority for a project
  Future<List<TaskModel>> getTasksByPriority({
    required String projectId,
    required TaskPriority priority,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('tasks')
          .where('projectId', isEqualTo: projectId)
          .where('priority', isEqualTo: priority.index)
          .where('isArchived', isEqualTo: false)
          .get();

      return snapshot.docs.map((doc) => TaskModel.fromMap(doc.data())).toList();
    } catch (e) {
      rethrow;
    }
  }
}
