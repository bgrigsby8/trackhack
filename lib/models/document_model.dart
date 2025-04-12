// lib/models/document_model.dart
class DocumentModel {
  final String id;
  final String projectId;
  final String title;
  final String content;
  final String? parentId;
  final List<String> childrenIds;
  final String createdBy;
  final String lastEditedBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isArchived;
  final int sortOrder;

  DocumentModel({
    required this.id,
    required this.projectId,
    required this.title,
    this.content = '',
    this.parentId,
    this.childrenIds = const [],
    required this.createdBy,
    required this.lastEditedBy,
    required this.createdAt,
    required this.updatedAt,
    this.isArchived = false,
    this.sortOrder = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'projectId': projectId,
      'title': title,
      'content': content,
      'parentId': parentId,
      'childrenIds': childrenIds,
      'createdBy': createdBy,
      'lastEditedBy': lastEditedBy,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'isArchived': isArchived,
      'sortOrder': sortOrder,
    };
  }

  factory DocumentModel.fromMap(Map<String, dynamic> map) {
    return DocumentModel(
      id: map['id'] as String,
      projectId: map['projectId'] as String,
      title: map['title'] as String,
      content: map['content'] as String? ?? '',
      parentId: map['parentId'] as String?,
      childrenIds: List<String>.from(map['childrenIds'] ?? []),
      createdBy: map['createdBy'] as String,
      lastEditedBy: map['lastEditedBy'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
      isArchived: map['isArchived'] as bool? ?? false,
      sortOrder: map['sortOrder'] as int? ?? 0,
    );
  }

  DocumentModel copyWith({
    String? id,
    String? projectId,
    String? title,
    String? content,
    String? parentId,
    List<String>? childrenIds,
    String? createdBy,
    String? lastEditedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isArchived,
    int? sortOrder,
  }) {
    return DocumentModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      content: content ?? this.content,
      parentId: parentId ?? this.parentId,
      childrenIds: childrenIds ?? this.childrenIds,
      createdBy: createdBy ?? this.createdBy,
      lastEditedBy: lastEditedBy ?? this.lastEditedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isArchived: isArchived ?? this.isArchived,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
