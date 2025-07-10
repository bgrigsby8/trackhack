// lib/models/project_model.dart
import 'package:flutter/material.dart';

// Book publishing workflow statuses - Main statuses
enum ProjectMainStatus {
  design, // Design phase
  paging, // Paging/layout phase
  proofing, // Proofing/editing phase
  epub, // E-book preparation phase
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

class ProjectModel {
  final String id;
  final String title;
  final String description;
  final String isbn; // ISBN number for the book
  final String productionEditor; // Production editor name
  final String format; // Book format
  final ProjectMainStatus mainStatus;
  final String subStatus; // Store as string to handle different enum types
  final Map<String, DateTime> statusDates; // Store dates for each sub-status (when completed)
  final Map<String, DateTime> scheduledDates; // Store scheduled/planned dates for each sub-status
  final DateTime deadline;
  final String coverImageUrl;
  final String ownerId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isCompleted; // Flag to indicate if the project is completed
  final DateTime? completedAt; // Date when the project was completed
  
  // Metadata fields
  final String imprint; // Publisher's imprint
  final DateTime? printerDate; // Printer date
  final DateTime? scDate; // S.C. date
  final DateTime? pubDate; // Publication date
  final String notes; // Additional notes
  final String ukCoPub; // UK co-publication information
  final bool pageCountSent; // Page count sent flag

  ProjectModel({
    required this.id,
    required this.title,
    required this.description,
    required this.isbn,
    required this.productionEditor,
    required this.format,
    required this.mainStatus,
    required this.subStatus,
    Map<String, DateTime>? statusDates,
    Map<String, DateTime>? scheduledDates,
    required this.deadline,
    this.coverImageUrl = '',
    required this.ownerId,
    required this.createdAt,
    required this.updatedAt,
    this.isCompleted = false,
    this.completedAt,
    this.imprint = '',
    this.printerDate,
    this.scDate,
    this.pubDate,
    this.notes = '',
    this.ukCoPub = '',
    this.pageCountSent = false,
  }) : statusDates = statusDates ?? {},
       scheduledDates = scheduledDates ?? {};

  Map<String, dynamic> toMap() {
    // Convert statusDates Map to a format that can be stored in Firestore
    final Map<String, int> dateMap = {};
    statusDates.forEach((key, value) {
      dateMap[key] = value.millisecondsSinceEpoch;
    });
    
    // Convert scheduledDates Map to a format that can be stored in Firestore
    final Map<String, int> scheduledDateMap = {};
    scheduledDates.forEach((key, value) {
      scheduledDateMap[key] = value.millisecondsSinceEpoch;
    });

    return {
      'id': id,
      'title': title,
      'description': description,
      'isbn': isbn,
      'productionEditor': productionEditor,
      'format': format,
      'mainStatus': mainStatus.index,
      'subStatus': subStatus,
      'statusDates': dateMap,
      'scheduledDates': scheduledDateMap,
      'deadline': deadline.millisecondsSinceEpoch,
      'coverImageUrl': coverImageUrl,
      'ownerId': ownerId,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.millisecondsSinceEpoch,
      // Metadata fields
      'imprint': imprint,
      'printerDate': printerDate?.millisecondsSinceEpoch,
      'scDate': scDate?.millisecondsSinceEpoch,
      'pubDate': pubDate?.millisecondsSinceEpoch,
      'notes': notes,
      'ukCoPub': ukCoPub,
      'pageCountSent': pageCountSent,
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
    
    // Convert scheduledDates Map from Firestore format back to Map<String, DateTime>
    final Map<String, DateTime> scheduledDateMap = {};
    if (map['scheduledDates'] != null) {
      (map['scheduledDates'] as Map<String, dynamic>).forEach((key, value) {
        scheduledDateMap[key] = DateTime.fromMillisecondsSinceEpoch(value as int);
      });
    }

    // Parse optional DateTime fields
    DateTime? completedAt;
    if (map['completedAt'] != null) {
      completedAt = DateTime.fromMillisecondsSinceEpoch(map['completedAt'] as int);
    }
    
    DateTime? printerDate;
    if (map['printerDate'] != null) {
      printerDate = DateTime.fromMillisecondsSinceEpoch(map['printerDate'] as int);
    }
    
    DateTime? scDate;
    if (map['scDate'] != null) {
      scDate = DateTime.fromMillisecondsSinceEpoch(map['scDate'] as int);
    }
    
    DateTime? pubDate;
    if (map['pubDate'] != null) {
      pubDate = DateTime.fromMillisecondsSinceEpoch(map['pubDate'] as int);
    }

    var test = ProjectModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      isbn: map['isbn'] as String? ?? '',
      productionEditor: map['productionEditor'] as String? ?? '',
      format: map['format'] as String? ?? '',
      mainStatus: ProjectMainStatus.values[map['mainStatus'] as int],
      subStatus: map['subStatus'] as String? ?? '',
      statusDates: dateMap,
      scheduledDates: scheduledDateMap,
      deadline: DateTime.fromMillisecondsSinceEpoch(map['deadline'] as int),
      coverImageUrl: map['coverImageUrl'] as String? ?? '',
      ownerId: map['ownerId'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
      isCompleted: map['isCompleted'] as bool? ?? false,
      completedAt: completedAt,
      // Metadata fields
      imprint: map['imprint'] as String? ?? '',
      printerDate: printerDate,
      scDate: scDate,
      pubDate: pubDate,
      notes: map['notes'] as String? ?? '',
      ukCoPub: map['ukCoPub'] as String? ?? '',
      pageCountSent: map['pageCountSent'] as bool? ?? false,
    );

    return test;
  }

  // For backward compatibility or migration
  static ProjectMainStatus convertOldStatusToMainStatus(int oldStatusIndex) {
    switch (oldStatusIndex) {
      case 0: // notTransmitted
        return ProjectMainStatus.design;
      case 1: // inDesign
        return ProjectMainStatus.design;
      case 2: // paging
        return ProjectMainStatus.paging;
      case 3: // proofing
        return ProjectMainStatus.proofing;
      case 4: // epub
        return ProjectMainStatus.epub;
      default:
        return ProjectMainStatus.design;
    }
  }

  ProjectModel copyWith({
    String? id,
    String? title,
    String? description,
    String? isbn,
    String? productionEditor,
    String? format, 
    ProjectMainStatus? mainStatus,
    String? subStatus,
    Map<String, DateTime>? statusDates,
    Map<String, DateTime>? scheduledDates,
    DateTime? deadline,
    String? coverImageUrl,
    String? ownerId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isCompleted,
    DateTime? completedAt,
    String? imprint,
    DateTime? printerDate,
    DateTime? scDate,
    DateTime? pubDate,
    String? notes,
    String? ukCoPub,
    bool? pageCountSent,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isbn: isbn ?? this.isbn,
      productionEditor: productionEditor ?? this.productionEditor,
      format: format ?? this.format,
      mainStatus: mainStatus ?? this.mainStatus,
      subStatus: subStatus ?? this.subStatus,
      statusDates: statusDates ?? Map.from(this.statusDates),
      scheduledDates: scheduledDates ?? Map.from(this.scheduledDates),
      deadline: deadline ?? this.deadline,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      ownerId: ownerId ?? this.ownerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      imprint: imprint ?? this.imprint,
      printerDate: printerDate ?? this.printerDate,
      scDate: scDate ?? this.scDate,
      pubDate: pubDate ?? this.pubDate,
      notes: notes ?? this.notes,
      ukCoPub: ukCoPub ?? this.ukCoPub,
      pageCountSent: pageCountSent ?? this.pageCountSent,
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
    }
  }

  String _getDesignStatusLabel() {
    switch (subStatus) {
      case 'design_initial':
        return 'Initial Design';
      case 'design_final':
        return 'Final Design';
      // Legacy support for removed statuses
      case 'design_review':
        return 'Design Review (Legacy)';
      case 'design_revisions':
        return 'Design Revisions (Legacy)';
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
      case 'paging_initial':
        return 'Initial Paging';
      case 'paging_final':
        return 'Final Paging';
      // Legacy support for removed statuses
      case 'paging_review':
        return 'Paging Review (Legacy)';
      case 'paging_revisions':
        return 'Paging Revisions (Legacy)';
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
      case 'proofing_1p':
        return '1P';
      case 'proofing_1pcx':
        return '1P CX';
      case 'proofing_2p':
        return '2P';
      case 'proofing_2pcx':
        return '2P CX';
      case 'proofing_3p':
        return '3P';
      case 'proofing_3pcx':
        return '3P CX';
      case 'proofing_4p':
        return '4P';
      case 'proofing_approved':
        return 'Approved For Press';
      // Legacy support
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
      case 'epub_sent':
        return 'WO Sent';
      case 'epub_dad':
        return 'Sent to DAD';
      // Legacy support
      case 'sentEPub':
        return 'WO Sent';
      case 'sentDAD':
        return 'Sent to DAD';
      default:
        return 'E-Pub';
    }
  }
  
  // Check if this project should be marked as completed
  // A project is completed when all steps in the final phase (epub) are completed
  bool shouldBeMarkedAsCompleted() {
    // If already marked completed, don't need to check again
    if (isCompleted) return true;
    
    // Only consider projects in the last phase (E-Pub)
    if (mainStatus != ProjectMainStatus.epub) return false;
    
    // Get all steps for the E-Pub phase
    final steps = epubSubStatuses;
    
    // Check if all steps are completed
    for (final step in steps) {
      final stepKey = step['value']!;
      if (!statusDates.containsKey(stepKey)) {
        return false; // Found an incomplete step
      }
    }
    
    // All steps in the final phase are completed
    return true;
  }

  // Get the completion date for a specific sub-status
  DateTime? getDateForSubStatus(String subStatus) {
    return statusDates[subStatus];
  }
  
  // Get the scheduled/planned date for a specific sub-status
  DateTime? getScheduledDateForSubStatus(String subStatus) {
    return scheduledDates[subStatus];
  }

  // Check if a substatus is completed (has a date)
  bool isSubStatusCompleted(String subStatus) {
    return statusDates.containsKey(subStatus);
  }

  // Check if a substatus can be marked as complete
  // (either it's the first one or previous ones are completed)
  bool canCompleteSubStatus(String subStatus) {
    // Get list of all substatus values for the current main status
    final List<Map<String, String>> subStatuses =
        getSubStatusesForMainStatus(mainStatus);

    // If it's the first substatus, it can always be completed
    if (subStatuses.isNotEmpty && subStatuses[0]['value'] == subStatus) {
      return true;
    }

    // Find the index of the current substatus
    final currentIndex = subStatuses.indexWhere((s) => s['value'] == subStatus);
    if (currentIndex > 0) {
      // Check if the previous substatus is completed
      final previousSubStatus = subStatuses[currentIndex - 1]['value'];
      return isSubStatusCompleted(previousSubStatus!);
    }

    return false;
  }

  // Get the next incomplete substatus for the current main status
  String? getNextIncompleteSubStatus() {
    final List<Map<String, String>> subStatuses =
        getSubStatusesForMainStatus(mainStatus);

    for (final subStatus in subStatuses) {
      final value = subStatus['value']!;
      if (!isSubStatusCompleted(value)) {
        return value;
      }
    }

    return null;
  }
  
  // Get the current active step label
  String getCurrentStepLabel() {
    if (isCompleted) {
      return 'Completed';
    }

    // Get the list of all sub-statuses for the current main status
    final subStatuses = getSubStatusesForMainStatus(mainStatus);

    // Look for the next incomplete step that needs attention
    String? nextIncompleteStep;
    for (final status in subStatuses) {
      final value = status['value']!;
      if (!statusDates.containsKey(value)) {
        // Found the first incomplete step
        nextIncompleteStep = status['label'];
        break;
      }
    }

    // If we found a next step, use that; otherwise fall back to the current subStatus
    if (nextIncompleteStep != null) {
      return nextIncompleteStep;
    }

    // If all steps in this phase are complete, find the current step (probably the last one completed)
    final currentSubStatus = subStatuses.firstWhere(
        (status) => status['value'] == subStatus,
        orElse: () => {'label': statusLabel, 'value': subStatus});

    return currentSubStatus['label'] ?? statusLabel;
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
    }
  }

  // Get design sub-statuses
  static List<Map<String, String>> get designSubStatuses {
    return [
      {'value': 'design_initial', 'label': 'Initial Design'},
      {'value': 'design_final', 'label': 'Final Design'},
    ];
  }

  // Get paging sub-statuses
  static List<Map<String, String>> get pagingSubStatuses {
    return [
      {'value': 'paging_initial', 'label': 'Initial Paging'},
      {'value': 'paging_final', 'label': 'Final Paging'},
    ];
  }

  // Get all proofing sub-statuses for display
  static List<Map<String, String>> get proofingSubStatuses {
    return [
      {'value': 'proofing_1p', 'label': '1P'},
      {'value': 'proofing_1pcx', 'label': '1P CX'},
      {'value': 'proofing_2p', 'label': '2P'},
      {'value': 'proofing_2pcx', 'label': '2P CX'},
      {'value': 'proofing_3p', 'label': '3P'},
      {'value': 'proofing_3pcx', 'label': '3P CX'},
      {'value': 'proofing_4p', 'label': '4P'},
      {'value': 'proofing_approved', 'label': 'Approved For Press'},
    ];
  }

  // Get all ePub sub-statuses for display
  static List<Map<String, String>> get epubSubStatuses {
    return [
      {'value': 'epub_sent', 'label': 'WO Sent'},
      {'value': 'epub_dad', 'label': 'Sent to DAD'},
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
    }
  }
}
