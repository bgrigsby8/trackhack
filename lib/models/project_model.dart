// lib/models/project_model.dart
// Book publishing workflow statuses
enum ProjectStatus {
  notTransmitted,  // Not yet started
  inDesign,        // Design phase
  paging,          // Paging/layout phase
  proofing,        // Proofing/editing phase
  press,           // At the press
  epub,            // E-book preparation
  published,       // Published
}

class ProjectModel {
  final String id;
  final String title;
  final String description;
  final ProjectStatus status;
  final DateTime deadline;
  final String coverImageUrl;
  final String ownerId;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProjectModel({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.deadline,
    this.coverImageUrl = '',
    required this.ownerId,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status.index,
      'deadline': deadline.millisecondsSinceEpoch,
      'coverImageUrl': coverImageUrl,
      'ownerId': ownerId,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory ProjectModel.fromMap(Map<String, dynamic> map) {
    return ProjectModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      status: ProjectStatus.values[map['status'] as int],
      deadline: DateTime.fromMillisecondsSinceEpoch(map['deadline']),
      coverImageUrl: map['coverImageUrl'] as String? ?? '',
      ownerId: map['ownerId'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
    );
  }

  ProjectModel copyWith({
    String? id,
    String? title,
    String? description,
    ProjectStatus? status,
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
      status: status ?? this.status,
      deadline: deadline ?? this.deadline,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      ownerId: ownerId ?? this.ownerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get statusLabel {
    switch (status) {
      case ProjectStatus.notTransmitted:
        return 'Not Yet Transmitted';
      case ProjectStatus.inDesign:
        return 'In Design';
      case ProjectStatus.paging:
        return 'Paging';
      case ProjectStatus.proofing:
        return 'Proofing';
      case ProjectStatus.press:
        return 'At Press';
      case ProjectStatus.epub:
        return 'Epub Status';
      case ProjectStatus.published:
        return 'Published';
    }
  }
}
