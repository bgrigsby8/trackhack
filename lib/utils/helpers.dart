// lib/utils/helpers.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/project_model.dart';
import '../models/task_model.dart';

class AppHelpers {
  // Date formatting helpers
  static String formatDate(DateTime date, {String format = 'MMM d, yyyy'}) {
    return DateFormat(format).format(date);
  }

  static String timeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} year(s) ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month(s) ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day(s) ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour(s) ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute(s) ago';
    } else {
      return 'Just now';
    }
  }

  // Project status color helper
  static Color getProjectStatusColor(ProjectMainStatus status) {
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

  // Task status color helper
  static Color getTaskStatusColor(TaskStatus status) {
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

  // Task priority color helper
  static Color getTaskPriorityColor(TaskPriority priority) {
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

  // String truncation helper
  static String truncateString(String text, int maxLength) {
    if (text.length <= maxLength) {
      return text;
    }
    return '${text.substring(0, maxLength)}...';
  }

  // Check if a string is a valid email
  static bool isValidEmail(String email) {
    final emailRegExp = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegExp.hasMatch(email);
  }

  // Calculate progress percentage
  static double calculateProgress(List<TaskModel> tasks) {
    if (tasks.isEmpty) return 0.0;

    final completedTasks =
        tasks.where((t) => t.status == TaskStatus.completed).length;
    return completedTasks / tasks.length;
  }

  // Show a snackbar with custom styling
  static void showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.secondary,
        duration: duration,
      ),
    );
  }
}
