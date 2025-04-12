// lib/screens/document/document_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/document_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/document_model.dart';
import 'widgets/document_editor.dart';
import 'widgets/document_tree.dart';

class DocumentScreen extends StatefulWidget {
  final String documentId;

  const DocumentScreen({
    super.key,
    required this.documentId,
  });

  @override
  State<DocumentScreen> createState() => _DocumentScreenState();
}

class _DocumentScreenState extends State<DocumentScreen> {
  bool _showSidebar = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final documentProvider = Provider.of<DocumentProvider>(
        context, 
        listen: false,
      );
      
      documentProvider.getDocumentById(widget.documentId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final documentProvider = Provider.of<DocumentProvider>(context);
    final document = documentProvider.currentDocument;
    
    if (document == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Document')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(document.title),
        actions: [
          IconButton(
            icon: Icon(_showSidebar ? Icons.menu_open : Icons.menu),
            onPressed: () {
              setState(() {
                _showSidebar = !_showSidebar;
              });
            },
          ),
          _buildDocumentActions(context, document),
        ],
      ),
      body: Row(
        children: [
          if (_showSidebar)
            SizedBox(
              width: 250,
              child: DocumentTree(
                currentDocumentId: document.id,
                projectId: document.projectId,
                onDocumentSelected: (DocumentModel doc) {
                  documentProvider.setCurrentDocument(doc);
                },
              ),
            ),
          const VerticalDivider(width: 1),
          Expanded(
            child: DocumentEditor(
              document: document,
              onTitleChanged: (title) {
                if (title != document.title) {
                  _updateDocument(
                    context: context,
                    documentId: document.id,
                    title: title,
                  );
                }
              },
              onContentChanged: (content) {
                if (content != document.content) {
                  _updateDocument(
                    context: context,
                    documentId: document.id,
                    content: content,
                  );
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _showSidebar
          ? FloatingActionButton(
              onPressed: () => _showAddChildDocumentDialog(context, document),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
  
  Widget _buildDocumentActions(BuildContext context, DocumentModel document) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isOwner = document.createdBy == authProvider.user?.id;
    
    if (!isOwner) return const SizedBox.shrink();
    
    return PopupMenuButton<String>(
      onSelected: (value) {
        switch (value) {
          case 'move':
            _showMoveDocumentDialog(context, document);
            break;
          case 'delete':
            _showDeleteDocumentDialog(context, document);
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'move',
          child: Row(
            children: [
              Icon(Icons.drive_file_move_outline),
              SizedBox(width: 8),
              Text('Move'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }
  
  Future<void> _updateDocument({
    required BuildContext context,
    required String documentId,
    String? title,
    String? content,
  }) async {
    final documentProvider = Provider.of<DocumentProvider>(
      context,
      listen: false,
    );
    final authProvider = Provider.of<AuthProvider>(
      context,
      listen: false,
    );
    
    if (authProvider.user == null) return;
    
    await documentProvider.updateDocument(
      documentId: documentId,
      title: title,
      content: content,
      lastEditedBy: authProvider.user!.id,
    );
    
    if (documentProvider.error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${documentProvider.error}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
  
  void _showAddChildDocumentDialog(
    BuildContext context,
    DocumentModel parentDocument,
  ) {
    // Add child document dialog implementation
    // Not implementing in this cleanup
  }
  
  void _showMoveDocumentDialog(
    BuildContext context,
    DocumentModel document,
  ) {
    // Move document dialog implementation
    // Not implementing in this cleanup
  }
  
  void _showDeleteDocumentDialog(
    BuildContext context,
    DocumentModel document,
  ) {
    // Delete document dialog implementation
    // Not implementing in this cleanup
  }
}