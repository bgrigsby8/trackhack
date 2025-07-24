// lib/screens/dashboard/widgets/import_csv_dialog.dart
import 'package:file_picker/_internal/file_picker_web.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:trackhack/providers/auth_provider.dart';
import 'package:trackhack/providers/project_provider.dart';
import 'package:trackhack/utils/csv_import.dart';
import 'package:trackhack/widgets/custom_button.dart';

class ImportCsvDialog extends StatefulWidget {
  const ImportCsvDialog({super.key});

  @override
  State<ImportCsvDialog> createState() => _ImportCsvDialogState();
}

class _ImportCsvDialogState extends State<ImportCsvDialog> {
  FilePickerResult? _pickerResult;
  String? _fileName;
  bool _isLoading = false;
  String? _errorMessage;
  int _importedCount = 0;
  int _skippedCount = 0;
  bool _importComplete = false;
  int _totalProjects = 0;
  int _processedProjects = 0;

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePickerWeb.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true, // Important for web support
      );

      if (result != null) {
        setState(() {
          _pickerResult = result;
          _fileName = result.files.single.name;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error selecting file: $e';
      });
    }
  }

  Future<void> _importCsv() async {
    if (_pickerResult == null) {
      setState(() {
        _errorMessage = 'Please select a CSV file first';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final projectProvider =
          Provider.of<ProjectProvider>(context, listen: false);

      // Get current user ID
      final userId = authProvider.user?.id;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Process the file using our new unified method
      final projects = await CsvImportUtil.parseProjectsFromPickerResult(
          _pickerResult!, userId);

      if (projects.isEmpty) {
        throw Exception('No valid projects found in the CSV file');
      }

      // Create projects in database, skipping duplicates
      int successCount = 0;
      int skippedCount = 0;
      
      for (final project in projects) {
        // Check if ISBN already exists for this user
        final isDuplicate = await projectProvider.isbnExists(project.isbn, userId);
        
        if (isDuplicate) {
          skippedCount++;
        } else {
          final createdProject = await projectProvider.createProject(project);
          if (createdProject != null) {
            successCount++;
          }
        }
      }

      setState(() {
        _importedCount = successCount;
        _skippedCount = skippedCount;
        _importComplete = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error importing CSV: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Import Projects from CSV',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Select a CSV file containing project data. The CSV should have headers matching the following fields: ISBN, Title, Imprint, PE, Status, Next milestone, Printer Date, S.C. Date, Pub Date, Type, Notes, UK co-pub?, Page Count Sent?',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _fileName != null
                          ? 'Selected: $_fileName'
                          : 'No file selected',
                      style: const TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 16),
                  CustomButton(
                    text: 'Select File',
                    onPressed: _isLoading ? null : _pickFile,
                    outline: true,
                  ),
                ],
              ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ),
              if (_importComplete)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Import completed!',
                        style: TextStyle(color: Colors.green, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '• $_importedCount new projects imported',
                        style: const TextStyle(color: Colors.green, fontSize: 14),
                      ),
                      if (_skippedCount > 0)
                        Text(
                          '• $_skippedCount projects skipped (ISBN already exists)',
                          style: const TextStyle(color: Colors.orange, fontSize: 14),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CustomButton(
                    text: 'Cancel',
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    outline: true,
                  ),
                  const SizedBox(width: 16),
                  CustomButton(
                    text: _importComplete ? 'Done' : 'Import',
                    loading: _isLoading,
                    onPressed: _isLoading
                        ? null
                        : _importComplete
                            ? () => Navigator.pop(context)
                            : _importCsv,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
