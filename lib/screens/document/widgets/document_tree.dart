// lib/screens/document/widgets/document_tree.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/document_model.dart';
import '../../../providers/document_provider.dart';

class DocumentTree extends StatelessWidget {
  final String currentDocumentId;
  final String projectId;
  final Function(DocumentModel) onDocumentSelected;

  const DocumentTree({
    super.key,
    required this.currentDocumentId,
    required this.projectId,
    required this.onDocumentSelected,
  });

  @override
  Widget build(BuildContext context) {
    final documentProvider = Provider.of<DocumentProvider>(context);
    
    if (documentProvider.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.folder_outlined),
              const SizedBox(width: 8),
              Text(
                'Documents',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.search, size: 20),
                onPressed: () => _showSearchDialog(context),
                tooltip: 'Search documents',
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        TextField(
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            border: InputBorder.none,
            hintText: 'Filter documents...',
            prefixIcon: Icon(Icons.filter_list),
          ),
          onChanged: (query) {
            // Filter implementation would go here
          },
        ),
        const Divider(height: 1),
        Expanded(
          child: _buildDocumentList(
            context,
            documentProvider.rootDocuments,
            documentProvider.childrenDocuments,
            currentDocumentId,
          ),
        ),
      ],
    );
  }
  
  Widget _buildDocumentList(
    BuildContext context,
    List<DocumentModel> documents,
    Map<String, List<DocumentModel>> childrenMap,
    String currentDocumentId,
    {String? parentId, int level = 0}
  ) {
    final docsToShow = parentId == null 
      ? documents 
      : childrenMap[parentId] ?? [];
    
    if (docsToShow.isEmpty) {
      if (level == 0) {
        return const Center(
          child: Text('No documents yet'),
        );
      }
      return const SizedBox.shrink();
    }
    
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: docsToShow.length,
      itemBuilder: (context, index) {
        final document = docsToShow[index];
        final hasChildren = 
            childrenMap.containsKey(document.id) && 
            (childrenMap[document.id]?.isNotEmpty ?? false);
        
        return Column(
          children: [
            _buildDocumentListItem(
              context,
              document,
              hasChildren,
              document.id == currentDocumentId,
              level,
            ),
            if (hasChildren && document.id != currentDocumentId)
              Padding(
                padding: EdgeInsets.only(left: 16.0 * (level + 1)),
                child: _buildDocumentList(
                  context,
                  documents,
                  childrenMap,
                  currentDocumentId,
                  parentId: document.id,
                  level: level + 1,
                ),
              ),
          ],
        );
      },
    );
  }
  
  Widget _buildDocumentListItem(
    BuildContext context,
    DocumentModel document,
    bool hasChildren,
    bool isSelected,
    int level,
  ) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.only(
        left: 16.0 * (level + 1),
        right: 16.0,
      ),
      leading: Icon(
        hasChildren ? Icons.description_outlined : Icons.insert_drive_file,
        color: isSelected ? Theme.of(context).primaryColor : null,
        size: 20,
      ),
      title: Text(
        document.title,
        style: TextStyle(
          color: isSelected ? Theme.of(context).primaryColor : null,
          fontWeight: isSelected ? FontWeight.bold : null,
        ),
      ),
      selected: isSelected,
      onTap: () => onDocumentSelected(document),
    );
  }
  
  void _showSearchDialog(BuildContext context) {
    final documentProvider = Provider.of<DocumentProvider>(
      context,
      listen: false,
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Documents'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter search query',
            prefixIcon: Icon(Icons.search),
          ),
          onSubmitted: (query) async {
            Navigator.pop(context);
            
            if (query.isNotEmpty) {
              final results = await documentProvider.searchDocuments(query);
              
              if (results.isNotEmpty && context.mounted) {
                _showSearchResults(context, results);
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('No documents found matching your query'),
                  ),
                );
              }
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
  
  void _showSearchResults(
    BuildContext context,
    List<DocumentModel> results,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Results'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: results.length,
            itemBuilder: (context, index) {
              final document = results[index];
              return ListTile(
                title: Text(document.title),
                subtitle: Text(
                  document.content.length > 50
                      ? '${document.content.substring(0, 50)}...'
                      : document.content,
                ),
                onTap: () {
                  Navigator.pop(context);
                  onDocumentSelected(document);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}