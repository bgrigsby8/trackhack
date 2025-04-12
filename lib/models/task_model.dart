// lib/models/task_model.dart
enum TaskStatus { todo, inProgress, completed, blocked, canceled }

enum TaskPriority { low, medium, high, urgent }

class TaskModel {
  final String id;
  final String projectId;
  final String title;
  final String description;
  final TaskStatus status;
  final TaskPriority priority;
  final String? assigneeId;
  final DateTime? deadline;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isArchived;

  TaskModel({
    required this.id,
    required this.projectId,
    required this.title,
    this.description = '',
    required this.status,
    required this.priority,
    this.assigneeId,
    this.deadline,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.isArchived = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'projectId': projectId,
      'title': title,
      'description': description,
      'status': status.index,
      'priority': priority.index,
      'assigneeId': assigneeId,
      'deadline': deadline?.millisecondsSinceEpoch,
      'createdBy': createdBy,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'isArchived': isArchived,
    };
  }

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'] as String,
      projectId: map['projectId'] as String,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      status: TaskStatus.values[map['status'] as int],
      priority: TaskPriority.values[map['priority'] as int],
      assigneeId: map['assigneeId'] as String?,
      deadline:
          map['deadline'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['deadline'])
              : null,
      createdBy: map['createdBy'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
      isArchived: map['isArchived'] as bool? ?? false,
    );
  }

  TaskModel copyWith({
    String? id,
    String? projectId,
    String? title,
    String? description,
    TaskStatus? status,
    TaskPriority? priority,
    String? assigneeId,
    DateTime? deadline,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isArchived,
  }) {
    return TaskModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      assigneeId: assigneeId ?? this.assigneeId,
      deadline: deadline ?? this.deadline,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  String get statusLabel {
    switch (status) {
      case TaskStatus.todo:
        return 'To Do';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.completed:
        return 'Completed';
      case TaskStatus.blocked:
        return 'Blocked';
      case TaskStatus.canceled:
        return 'Canceled';
    }
  }

  String get priorityLabel {
    switch (priority) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
      case TaskPriority.urgent:
        return 'Urgent';
    }
  }
}
