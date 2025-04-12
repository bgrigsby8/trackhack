// lib/services/document_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/document_model.dart';

class DocumentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // Create a new document
  Future<DocumentModel> createDocument({
    required String projectId,
    required String title,
    required String createdBy,
    String? parentId,
    String content = '',
    int sortOrder = 0,
  }) async {
    try {
      final String documentId = _uuid.v4();
      final now = DateTime.now();

      final newDocument = DocumentModel(
        id: documentId,
        projectId: projectId,
        title: title,
        content: content,
        parentId: parentId,
        createdBy: createdBy,
        lastEditedBy: createdBy,
        createdAt: now,
        updatedAt: now,
        sortOrder: sortOrder,
      );

      await _firestore
          .collection('documents')
          .doc(documentId)
          .set(newDocument.toMap());

      // If this is a child document, add it to parent's children
      if (parentId != null) {
        await _firestore.collection('documents').doc(parentId).update({
          'childrenIds': FieldValue.arrayUnion([documentId]),
        });
      }

      return newDocument;
    } catch (e) {
      rethrow;
    }
  }

  // Get a document by ID
  Future<DocumentModel?> getDocument(String documentId) async {
    try {
      final doc =
          await _firestore.collection('documents').doc(documentId).get();
      if (doc.exists) {
        return DocumentModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Get all root documents for a project (documents with no parent)
  Stream<List<DocumentModel>> getProjectRootDocuments(String projectId) {
    try {
      return _firestore
          .collection('documents')
          .where('projectId', isEqualTo: projectId)
          .where('parentId', isNull: true)
          .where('isArchived', isEqualTo: false)
          .orderBy('sortOrder')
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) => DocumentModel.fromMap(doc.data()))
                .toList();
          });
    } catch (e) {
      rethrow;
    }
  }

  // Get child documents for a parent document
  Stream<List<DocumentModel>> getChildDocuments(String parentId) {
    try {
      return _firestore
          .collection('documents')
          .where('parentId', isEqualTo: parentId)
          .where('isArchived', isEqualTo: false)
          .orderBy('sortOrder')
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) => DocumentModel.fromMap(doc.data()))
                .toList();
          });
    } catch (e) {
      rethrow;
    }
  }

  // Update a document
  Future<void> updateDocument({
    required String documentId,
    String? title,
    String? content,
    String? lastEditedBy,
    bool? isArchived,
    int? sortOrder,
  }) async {
    try {
      final docRef = _firestore.collection('documents').doc(documentId);
      final doc = await docRef.get();

      if (!doc.exists) {
        throw Exception('Document not found');
      }

      final Map<String, dynamic> updates = {};

      if (title != null) updates['title'] = title;
      if (content != null) updates['content'] = content;
      if (lastEditedBy != null) updates['lastEditedBy'] = lastEditedBy;
      if (isArchived != null) updates['isArchived'] = isArchived;
      if (sortOrder != null) updates['sortOrder'] = sortOrder;

      updates['updatedAt'] = DateTime.now().millisecondsSinceEpoch;

      await docRef.update(updates);
    } catch (e) {
      rethrow;
    }
  }

  // Delete a document and its children
  Future<void> deleteDocument(String documentId) async {
    try {
      // First get the document to check if it has a parent and children
      final doc =
          await _firestore.collection('documents').doc(documentId).get();
      if (!doc.exists) {
        return;
      }

      final document = DocumentModel.fromMap(
        doc.data() as Map<String, dynamic>,
      );

      // If the document has a parent, remove it from parent's children list
      if (document.parentId != null) {
        await _firestore.collection('documents').doc(document.parentId).update({
          'childrenIds': FieldValue.arrayRemove([documentId]),
        });
      }

      // Recursively delete all children
      for (final childId in document.childrenIds) {
        await deleteDocument(childId);
      }

      // Finally delete the document itself
      await _firestore.collection('documents').doc(documentId).delete();
    } catch (e) {
      rethrow;
    }
  }

  // Move a document to a new parent
  Future<void> moveDocument({
    required String documentId,
    required String? newParentId,
    required int newSortOrder,
  }) async {
    try {
      final docRef = _firestore.collection('documents').doc(documentId);
      final doc = await docRef.get();

      if (!doc.exists) {
        throw Exception('Document not found');
      }

      final document = DocumentModel.fromMap(
        doc.data() as Map<String, dynamic>,
      );
      final oldParentId = document.parentId;

      // Remove from old parent's children
      if (oldParentId != null) {
        await _firestore.collection('documents').doc(oldParentId).update({
          'childrenIds': FieldValue.arrayRemove([documentId]),
        });
      }

      // Add to new parent's children
      if (newParentId != null) {
        await _firestore.collection('documents').doc(newParentId).update({
          'childrenIds': FieldValue.arrayUnion([documentId]),
        });
      }

      // Update document's parent and sort order
      await docRef.update({
        'parentId': newParentId,
        'sortOrder': newSortOrder,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      rethrow;
    }
  }

  // Search documents
  Future<List<DocumentModel>> searchDocuments({
    required String projectId,
    required String query,
  }) async {
    try {
      // Firestore doesn't support full-text search natively
      // This is a simple implementation that searches in title
      final snapshot =
          await _firestore
              .collection('documents')
              .where('projectId', isEqualTo: projectId)
              .where('isArchived', isEqualTo: false)
              .get();

      final documents =
          snapshot.docs
              .map((doc) => DocumentModel.fromMap(doc.data()))
              .toList();

      // Filter documents that contain the query in title or content
      return documents.where((doc) {
        return doc.title.toLowerCase().contains(query.toLowerCase()) ||
            doc.content.toLowerCase().contains(query.toLowerCase());
      }).toList();
    } catch (e) {
      rethrow;
    }
  }
}
