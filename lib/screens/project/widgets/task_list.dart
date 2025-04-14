// lib/screens/project/widgets/task_list.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/task_model.dart';
import '../../../providers/task_provider.dart';
import '../../../providers/auth_provider.dart';

class TaskList extends StatelessWidget {
  final String projectId;

  const TaskList({super.key, required this.projectId});

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final tasks = taskProvider.projectTasks;
    
    if (taskProvider.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    // Just show an empty task tabs view even when there are no tasks
    // This allows more space for the project header section
    if (tasks.isEmpty) {
      return DefaultTabController(
        length: TaskStatus.values.length,
        child: Column(
          children: [
            TabBar(
              isScrollable: true,
              tabs: TaskStatus.values.map((status) {
                return Tab(
                  child: Row(
                    children: [
                      Text(_getStatusLabel(status)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status),
                          shape: BoxShape.circle,
                        ),
                        child: const Text(
                          "0",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const Expanded(
              child: TabBarView(
                children: [
                  // Empty views for each tab
                  SizedBox(), // Todo
                  SizedBox(), // In Progress
                  SizedBox(), // Completed
                  SizedBox(), // Blocked
                  SizedBox(), // Canceled
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Group tasks by status
    final tasksByStatus = <TaskStatus, List<TaskModel>>{};
    for (final status in TaskStatus.values) {
      tasksByStatus[status] = [];
    }
    
    for (final task in tasks) {
      tasksByStatus[task.status]!.add(task);
    }
    
    return DefaultTabController(
      length: TaskStatus.values.length,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            tabs: TaskStatus.values.map((status) {
              final count = tasksByStatus[status]!.length;
              return Tab(
                child: Row(
                  children: [
                    Text(_getStatusLabel(status)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        count.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          Expanded(
            child: TabBarView(
              children: TaskStatus.values.map((status) {
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: tasksByStatus[status]!.length,
                  itemBuilder: (context, index) {
                    final task = tasksByStatus[status]![index];
                    return _buildTaskCard(
                      context, 
                      task, 
                      taskProvider,
                      authProvider.user?.id ?? '',
                    );
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTaskCard(
    BuildContext context,
    TaskModel task,
    TaskProvider taskProvider,
    String userId,
  ) {
    final canEdit = task.assigneeId == userId || task.createdBy == userId;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Task priority indicator
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _getPriorityColor(task.priority),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                // Task title
                Expanded(
                  child: Text(
                    task.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                // Status change button for task owner
                if (canEdit)
                  PopupMenuButton<TaskStatus>(
                    onSelected: (newStatus) {
                      taskProvider.updateTask(taskId: task.id, status: newStatus);
                    },
                    itemBuilder: (context) => TaskStatus.values
                        .where((s) => s != task.status)
                        .map((status) {
                      return PopupMenuItem(
                        value: status,
                        child: Row(
                          children: [
                            Icon(
                              _getStatusIcon(status),
                              color: _getStatusColor(status),
                            ),
                            const SizedBox(width: 8),
                            Text(_getStatusLabel(status)),
                          ],
                        ),
                      );
                    }).toList(),
                    child: Chip(
                      backgroundColor: _getStatusColor(task.status),
                      label: Text(
                        _getStatusLabel(task.status),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                // Show status for non-owners
                if (!canEdit)
                  Chip(
                    backgroundColor: _getStatusColor(task.status),
                    label: Text(
                      _getStatusLabel(task.status),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(task.description),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  task.deadline != null ? 'Due: ${_formatDate(task.deadline!)}' : 'No deadline',
                  style: const TextStyle(color: Colors.grey),
                ),
                if (canEdit)
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          // Edit task implementation
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        color: Theme.of(context).colorScheme.error,
                        onPressed: () {
                          _showDeleteTaskDialog(context, task, taskProvider);
                        },
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  String _getStatusLabel(TaskStatus status) {
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
  
  IconData _getStatusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return Icons.check_box_outline_blank;
      case TaskStatus.inProgress:
        return Icons.pending;
      case TaskStatus.completed:
        return Icons.check_box;
      case TaskStatus.blocked:
        return Icons.block;
      case TaskStatus.canceled:
        return Icons.cancel;
    }
  }
  
  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return Colors.grey;
      case TaskStatus.inProgress:
        return Colors.blue;
      case TaskStatus.completed:
        return Colors.green;
      case TaskStatus.blocked:
        return Colors.red;
      case TaskStatus.canceled:
        return Colors.grey.shade700;
    }
  }
  
  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return Colors.green;
      case TaskPriority.medium:
        return Colors.amber;
      case TaskPriority.high:
        return Colors.orange;
      case TaskPriority.urgent:
        return Colors.red;
    }
  }
  
  String _formatDate(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
  }
  
  void _showDeleteTaskDialog(
    BuildContext context,
    TaskModel task,
    TaskProvider taskProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text(
          'Are you sure you want to delete "${task.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await taskProvider.deleteTask(task.id);
              
              if (taskProvider.error != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${taskProvider.error}'),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}