// lib/providers/document_provider.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/document_model.dart';
import '../services/document_service.dart';

class DocumentProvider with ChangeNotifier {
  final DocumentService _documentService = DocumentService();

  List<DocumentModel> _rootDocuments = [];
  Map<String, List<DocumentModel>> _childrenDocuments = {};
  DocumentModel? _currentDocument;
  String? _error;
  bool _loading = false;
  String? _currentProjectId;

  StreamSubscription? _rootDocumentsSubscription;
  final Map<String, StreamSubscription> _childrenSubscriptions = {};

  // Getters
  List<DocumentModel> get rootDocuments => _rootDocuments;
  Map<String, List<DocumentModel>> get childrenDocuments => _childrenDocuments;
  DocumentModel? get currentDocument => _currentDocument;
  String? get error => _error;
  bool get loading => _loading;
  String? get currentProjectId => _currentProjectId;

  // Set current document
  void setCurrentDocument(DocumentModel document) {
    _currentDocument = document;
    _loadChildDocuments(document.id);
    notifyListeners();
  }

  // Set current project
  void setCurrentProject(String projectId) {
    if (_currentProjectId != projectId) {
      _currentProjectId = projectId;
      _rootDocuments = [];
      _childrenDocuments = {};
      _currentDocument = null;

      _disposeSubscriptions();
      _loadRootDocuments(projectId);
    }
  }

  // Load root documents for a project
  void _loadRootDocuments(String projectId) {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      // Cancel previous subscription if it exists
      _rootDocumentsSubscription?.cancel();

      // Subscribe to root documents stream
      _rootDocumentsSubscription =
          _documentService.getProjectRootDocuments(projectId).listen(
        (documents) {
          _rootDocuments = documents;
          _loading = false;
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

  // Load child documents for a parent document
  void _loadChildDocuments(String parentId) {
    try {
      // Cancel previous subscription if it exists
      _childrenSubscriptions[parentId]?.cancel();

      // Subscribe to child documents stream
      _childrenSubscriptions[parentId] =
          _documentService.getChildDocuments(parentId).listen(
        (documents) {
          _childrenDocuments[parentId] = documents;
          notifyListeners();
        },
        onError: (e) {
          _error = e.toString();
          notifyListeners();
        },
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Create a new document
  Future<DocumentModel?> createDocument({
    required String projectId,
    required String title,
    required String createdBy,
    String? parentId,
    String content = '',
  }) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final sortOrder = parentId == null
          ? _rootDocuments.length
          : _childrenDocuments[parentId]?.length ?? 0;

      final newDocument = await _documentService.createDocument(
        projectId: projectId,
        title: title,
        createdBy: createdBy,
        parentId: parentId,
        content: content,
        sortOrder: sortOrder,
      );

      return newDocument;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Update a document
  Future<void> updateDocument({
    required String documentId,
    String? title,
    String? content,
    required String lastEditedBy,
  }) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      await _documentService.updateDocument(
        documentId: documentId,
        title: title,
        content: content,
        lastEditedBy: lastEditedBy,
      );

      if (_currentDocument?.id == documentId) {
        _currentDocument = _currentDocument!.copyWith(
          title: title ?? _currentDocument!.title,
          content: content ?? _currentDocument!.content,
          lastEditedBy: lastEditedBy,
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

  // Delete a document
  Future<void> deleteDocument(String documentId) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      await _documentService.deleteDocument(documentId);

      if (_currentDocument?.id == documentId) {
        _currentDocument = null;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Move a document
  Future<void> moveDocument({
    required String documentId,
    required String? newParentId,
  }) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final newSortOrder = newParentId == null
          ? _rootDocuments.length
          : _childrenDocuments[newParentId]?.length ?? 0;

      await _documentService.moveDocument(
        documentId: documentId,
        newParentId: newParentId,
        newSortOrder: newSortOrder,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Search documents
  Future<List<DocumentModel>> searchDocuments(String query) async {
    if (_currentProjectId == null) return [];
    if (query.isEmpty) return _rootDocuments;

    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final results = await _documentService.searchDocuments(
        projectId: _currentProjectId!,
        query: query,
      );

      return results;
    } catch (e) {
      _error = e.toString();
      return [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Get document by ID (used when navigating directly to a document)
  Future<void> getDocumentById(String documentId) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final document = await _documentService.getDocument(documentId);
      if (document != null) {
        _currentDocument = document;
        _loadChildDocuments(documentId);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Clear current document
  void clearCurrentDocument() {
    _currentDocument = null;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Dispose subscriptions
  void _disposeSubscriptions() {
    _rootDocumentsSubscription?.cancel();
    _rootDocumentsSubscription = null;

    for (final subscription in _childrenSubscriptions.values) {
      subscription.cancel();
    }
    _childrenSubscriptions.clear();
  }

  @override
  void dispose() {
    _disposeSubscriptions();
    super.dispose();
  }
}
