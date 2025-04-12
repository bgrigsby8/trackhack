// lib/screens/document/widgets/document_editor.dart
import 'package:flutter/material.dart';
import 'dart:async';
import '../../../models/document_model.dart';

class DocumentEditor extends StatefulWidget {
  final DocumentModel document;
  final Function(String) onTitleChanged;
  final Function(String) onContentChanged;

  const DocumentEditor({
    super.key,
    required this.document,
    required this.onTitleChanged,
    required this.onContentChanged,
  });

  @override
  State<DocumentEditor> createState() => _DocumentEditorState();
}

class _DocumentEditorState extends State<DocumentEditor> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool _isDirty = false;
  Timer? _autoSaveTimer;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.document.title);
    _contentController = TextEditingController(text: widget.document.content);

    // Set up auto-save timer
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_isDirty) {
        _saveChanges();
      }
    });
  }

  @override
  void didUpdateWidget(DocumentEditor oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update controllers if the document changes
    if (oldWidget.document.id != widget.document.id) {
      _titleController.text = widget.document.title;
      _contentController.text = widget.document.content;
      _isDirty = false;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _autoSaveTimer?.cancel();
    super.dispose();
  }

  void _saveChanges() {
    if (_isDirty) {
      widget.onTitleChanged(_titleController.text);
      widget.onContentChanged(_contentController.text);
      _isDirty = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _titleController,
            style: Theme.of(context).textTheme.headlineSmall,
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'Document Title',
            ),
            onChanged: (value) {
              _isDirty = true;
            },
            onEditingComplete: _saveChanges,
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _contentController,
              maxLines: null,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Start writing...',
              ),
              style: Theme.of(context).textTheme.bodyLarge,
              onChanged: (value) {
                _isDirty = true;
              },
            ),
          ),
        ),
        if (_isDirty)
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.grey.withValues(alpha: 0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Unsaved changes',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _saveChanges,
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
