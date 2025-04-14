// lib/models/project_model.dart
import 'package:flutter/material.dart';

// Book publishing workflow statuses - Main statuses
enum ProjectMainStatus {
  design, // Design phase
  paging, // Paging/layout phase
  proofing, // Proofing/editing phase
  epub, // E-book preparation phase
  other, // Other phases (not in one of the main kanban columns)
}

// For future implementation: Sub-statuses for Design
enum DesignSubStatus {
  prForm, // Initial Design
  designSample, // Design Review
}

// For future implementation: Sub-statuses for Paging
enum PagingSubStatus {
  settingCopy, // Initial Paging
  firstPass, // Paging Review
  finalPageCount, // Paging Revisions
}

// Sub-statuses for Proofing
enum ProofingSubStatus {
  firstPass, // 1P
  firstPassCX, // 1P CX (correction)
  secondPass, // 2P
  secondPassCX, // 2P CX (correction)
  thirdPass, // 3P
  thirdPassCX, // 3P CX (correction)
  fourthPass, // 4P
  approvedForPress // Approved For Press
}

enum EPubSubStatus {
  sentEPub, // WO Sent
  sentDAD, // Sent to DAD
}

// Others for the "Other" main status category
enum OtherStatus {
  notTransmitted, // Not yet started
  press, // At the press
  epub, // E-book preparation
  published, // Published
}

class ProjectModel {
  final String id;
  final String title;
  final String description;
  final ProjectMainStatus mainStatus;
  final String subStatus; // Store as string to handle different enum types
  final Map<String, DateTime> statusDates; // Store dates for each sub-status
  final DateTime deadline;
  final String coverImageUrl;
  final String ownerId;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProjectModel({
    required this.id,
    required this.title,
    required this.description,
    required this.mainStatus,
    required this.subStatus,
    Map<String, DateTime>? statusDates,
    required this.deadline,
    this.coverImageUrl = '',
    required this.ownerId,
    required this.createdAt,
    required this.updatedAt,
  }) : statusDates = statusDates ?? {};

  Map<String, dynamic> toMap() {
    // Convert statusDates Map to a format that can be stored in Firestore
    final Map<String, int> dateMap = {};
    statusDates.forEach((key, value) {
      dateMap[key] = value.millisecondsSinceEpoch;
    });

    return {
      'id': id,
      'title': title,
      'description': description,
      'mainStatus': mainStatus.index,
      'subStatus': subStatus,
      'statusDates': dateMap,
      'deadline': deadline.millisecondsSinceEpoch,
      'coverImageUrl': coverImageUrl,
      'ownerId': ownerId,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory ProjectModel.fromMap(Map<String, dynamic> map) {
    // Convert statusDates Map from Firestore format back to Map<String, DateTime>
    final Map<String, DateTime> dateMap = {};
    if (map['statusDates'] != null) {
      (map['statusDates'] as Map<String, dynamic>).forEach((key, value) {
        dateMap[key] = DateTime.fromMillisecondsSinceEpoch(value as int);
      });
    }

    var test = ProjectModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      mainStatus: ProjectMainStatus.values[map['mainStatus'] as int],
      subStatus: map['subStatus'] as String? ?? '',
      statusDates: dateMap,
      deadline: DateTime.fromMillisecondsSinceEpoch(map['deadline'] as int),
      coverImageUrl: map['coverImageUrl'] as String? ?? '',
      ownerId: map['ownerId'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
    );

    return test;
  }

  // For backward compatibility or migration
  static ProjectMainStatus convertOldStatusToMainStatus(int oldStatusIndex) {
    switch (oldStatusIndex) {
      case 0: // notTransmitted
        return ProjectMainStatus.other;
      case 1: // inDesign
        return ProjectMainStatus.design;
      case 2: // paging
        return ProjectMainStatus.paging;
      case 3: // proofing
        return ProjectMainStatus.proofing;
      case 4: // epub
        return ProjectMainStatus.epub;
      default:
        return ProjectMainStatus.other;
    }
  }

  ProjectModel copyWith({
    String? id,
    String? title,
    String? description,
    ProjectMainStatus? mainStatus,
    String? subStatus,
    Map<String, DateTime>? statusDates,
    DateTime? deadline,
    String? coverImageUrl,
    String? ownerId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      mainStatus: mainStatus ?? this.mainStatus,
      subStatus: subStatus ?? this.subStatus,
      statusDates: statusDates ?? Map.from(this.statusDates),
      deadline: deadline ?? this.deadline,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      ownerId: ownerId ?? this.ownerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Get the display label for the current sub-status
  String get statusLabel {
    switch (mainStatus) {
      case ProjectMainStatus.proofing:
        return _getProofingStatusLabel();
      case ProjectMainStatus.design:
        return _getDesignStatusLabel();
      case ProjectMainStatus.paging:
        return _getPagingStatusLabel();
      case ProjectMainStatus.epub:
        return _getEPubStatusLabel();
      case ProjectMainStatus.other:
        return subStatus;
    }
  }

  String _getDesignStatusLabel() {
    switch (subStatus) {
      case 'prForm':
        return 'PR Form';
      case 'designSample':
        return 'Design Sample';
      default:
        return 'Design';
    }
  }

  String _getPagingStatusLabel() {
    switch (subStatus) {
      case 'settingCopy':
        return 'Setting Copy';
      case 'firstPass':
        return '1P';
      case 'finalPageCount':
        return 'Final Page Count';
      default:
        return 'Paging';
    }
  }

  // Get more detailed label for Proofing sub-status
  String _getProofingStatusLabel() {
    switch (subStatus) {
      case 'firstPass':
        return '1P';
      case 'firstPassCX':
        return '1P CX';
      case 'secondPass':
        return '2P';
      case 'secondPassCX':
        return '2P CX';
      case 'thirdPass':
        return '3P';
      case 'thirdPassCX':
        return '3P CX';
      case 'fourthPass':
        return '4P';
      case 'approvedForPress':
        return 'Approved For Press';
      default:
        return 'Proofing';
    }
  }

  String _getEPubStatusLabel() {
    switch (subStatus) {
      case 'sentEPub':
        return 'WO Sent';
      case 'sentDAD':
        return 'Sent to DAD';
      default:
        return 'Other';
    }
  }

  // Get the date for a specific sub-status
  DateTime? getDateForSubStatus(String subStatus) {
    return statusDates[subStatus];
  }

  // Get the main category color
  Color getMainStatusColor() {
    switch (mainStatus) {
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

  // Get design sub-statuses
  static List<Map<String, String>> get designSubStatuses {
    return [
      {'value': 'initial', 'label': 'Initial Design'},
      {'value': 'review', 'label': 'Design Review'},
      {'value': 'revisions', 'label': 'Design Revisions'},
      {'value': 'finalDesign', 'label': 'Final Design'},
    ];
  }

  // Get paging sub-statuses
  static List<Map<String, String>> get pagingSubStatuses {
    return [
      {'value': 'initial', 'label': 'Initial Paging'},
      {'value': 'review', 'label': 'Paging Review'},
      {'value': 'revisions', 'label': 'Paging Revisions'},
      {'value': 'finalDesign', 'label': 'Final Paging'},
    ];
  }

  // Get all proofing sub-statuses for display
  static List<Map<String, String>> get proofingSubStatuses {
    return [
      {'value': 'firstPass', 'label': '1P'},
      {'value': 'firstPassCX', 'label': '1P CX'},
      {'value': 'secondPass', 'label': '2P'},
      {'value': 'secondPassCX', 'label': '2P CX'},
      {'value': 'thirdPass', 'label': '3P'},
      {'value': 'thirdPassCX', 'label': '3P CX'},
      {'value': 'fourthPass', 'label': '4P'},
      {'value': 'approvedForPress', 'label': 'Approved For Press'},
    ];
  }

  // Get all ePub sub-statuses for display
  static List<Map<String, String>> get epubSubStatuses {
    return [
      {'value': 'sentEPub', 'label': 'WO Sent'},
      {'value': 'sentDAD', 'label': 'Sent to DAD'},
    ];
  }

  // Get other sub-statuses
  static List<Map<String, String>> get otherSubStatuses {
    return [
      {'value': 'notTransmitted', 'label': 'Not Transmitted'},
    ];
  }

  // Get sub-statuses for a specific main status
  static List<Map<String, String>> getSubStatusesForMainStatus(
      ProjectMainStatus mainStatus) {
    switch (mainStatus) {
      case ProjectMainStatus.design:
        return designSubStatuses;
      case ProjectMainStatus.paging:
        return pagingSubStatuses;
      case ProjectMainStatus.proofing:
        return proofingSubStatuses;
      case ProjectMainStatus.epub:
        return epubSubStatuses;
      case ProjectMainStatus.other:
        return otherSubStatuses;
    }
  }
}
