// lib/utils/csv_import.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import '../models/project_model.dart';

class CsvImportUtil {
  // Method to parse CSV from bytes for web platform
  static Future<List<ProjectModel>> parseProjectsFromCsvBytes(
    Uint8List csvBytes,
    String userId,
  ) async {
    try {
      // Convert bytes to string
      final fileContent = utf8.decode(csvBytes);
      return _parseProjectsFromContent(fileContent, userId);
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing CSV from bytes: $e');
      }
      rethrow;
    }
  }
  // Parse CSV file and convert to ProjectModel objects
  static Future<List<ProjectModel>> parseProjectsFromCsv(
    File csvFile,
    String userId,
  ) async {
    try {
      // Read the file content
      final fileContent = await csvFile.readAsString();
      return _parseProjectsFromContent(fileContent, userId);
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing CSV file: $e');
      }
      rethrow;
    }
  }
  
  // Common parsing method used by both file and bytes approaches
  // Method to handle FilePickerResult directly (works for both web and native)
  static Future<List<ProjectModel>> parseProjectsFromPickerResult(
    FilePickerResult result,
    String userId,
  ) async {
    try {
      String fileContent;
      
      if (kIsWeb) {
        // Web platform - use bytes
        if (result.files.single.bytes != null) {
          try {
            // Try standard UTF-8 decoding first
            fileContent = utf8.decode(result.files.single.bytes!);
          } catch (e) {
            // If that fails, try with allowMalformed flag
            fileContent = utf8.decode(result.files.single.bytes!, allowMalformed: true);
          }
        } else {
          throw Exception('Could not read file content in web mode');
        }
      } else {
        // Native platforms - use file path
        if (result.files.single.path != null) {
          final file = File(result.files.single.path!);
          fileContent = await file.readAsString();
        } else {
          throw Exception('Could not access file path in native mode');
        }
      }
      
      return _parseProjectsFromContent(fileContent, userId);
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing CSV from picker result: $e');
      }
      rethrow;
    }
  }
  
  static Future<List<ProjectModel>> _parseProjectsFromContent(
    String fileContent,
    String userId,
  ) async {
    try {
      // Split by lines and skip header
      final lines = LineSplitter.split(fileContent).toList();
      
      if (lines.isEmpty) {
        throw Exception('CSV file is empty');
      }
      
      // Extract header to map column indices
      final header = _parseCSVLine(lines.first);
      final indices = _getColumnIndices(header);
      
      // Skip the header row
      final projectLines = lines.skip(1).toList();
      final projects = <ProjectModel>[];
      
      // Default deadline is 3 months from now
      final defaultDeadline = DateTime.now().add(const Duration(days: 90));
      
      // Process each line
      for (final line in projectLines) {
        if (line.trim().isEmpty) continue; // Skip empty lines
        
        final cols = _parseCSVLine(line);
        
        // Skip if we don't have enough columns
        if (cols.length < 5) continue;
        
        // Extract data from columns
        final isbn = indices['ISBN'] != null && indices['ISBN']! < cols.length 
            ? cols[indices['ISBN']!] 
            : '';
        final title = indices['Title'] != null && indices['Title']! < cols.length 
            ? cols[indices['Title']!] 
            : '';
        final imprint = indices['Imprint'] != null && indices['Imprint']! < cols.length 
            ? cols[indices['Imprint']!] 
            : '';
        final productionEditor = indices['PE'] != null && indices['PE']! < cols.length 
            ? cols[indices['PE']!] 
            : '';
        final status = indices['Status'] != null && indices['Status']! < cols.length 
            ? cols[indices['Status']!] 
            : '';
        final nextMilestone = indices['Next milestone'] != null && indices['Next milestone']! < cols.length 
            ? cols[indices['Next milestone']!] 
            : '';
        
        // Parse dates
        final printerDate = indices['Printer Date'] != null && indices['Printer Date']! < cols.length 
            ? _parseDate(cols[indices['Printer Date']!]) 
            : null;
        final scDate = indices['S.C. Date'] != null && indices['S.C. Date']! < cols.length 
            ? _parseDate(cols[indices['S.C. Date']!]) 
            : null;
        final pubDate = indices['Pub Date'] != null && indices['Pub Date']! < cols.length 
            ? _parseDate(cols[indices['Pub Date']!]) 
            : null;
            
        final format = indices['Type'] != null && indices['Type']! < cols.length 
            ? cols[indices['Type']!] 
            : '';
        final notes = indices['Notes'] != null && indices['Notes']! < cols.length 
            ? cols[indices['Notes']!] 
            : '';
        final ukCoPub = indices['UK co-pub?'] != null && indices['UK co-pub?']! < cols.length 
            ? cols[indices['UK co-pub?']!] 
            : '';
        final pageCountSentStr = indices['Page Count Sent?'] != null && indices['Page Count Sent?']! < cols.length 
            ? cols[indices['Page Count Sent?']!] 
            : '';
        final pageCountSent = pageCountSentStr.toLowerCase() == 'y' || 
                            pageCountSentStr.toLowerCase() == 'yes';
        
        // Determine if book is completed based on Status and Next milestone
        final isCompleted = status.toLowerCase() == 'ready for press' && 
                            nextMilestone.toLowerCase() == 'ready to deliver to sc';
        
        // Set deadline as the pub date if available, otherwise use default
        final deadline = pubDate ?? defaultDeadline;
        
        // Set appropriate project status based on data
        // For simplicity, new imported projects start in design phase unless completed
        final mainStatus = isCompleted ? ProjectMainStatus.epub : ProjectMainStatus.design;
        final subStatus = isCompleted ? 'epub_dad' : 'design_initial';
        
        // Create status dates map if the project is completed
        final Map<String, DateTime> statusDates = {};
        if (isCompleted) {
          // Add dates for all phases to mark them as completed
          final completionDate = DateTime.now();
          
          // Design phase statuses
          statusDates['design_initial'] = completionDate;
          statusDates['design_review'] = completionDate;
          statusDates['design_revisions'] = completionDate;
          statusDates['design_final'] = completionDate;
          
          // Paging phase statuses
          statusDates['paging_initial'] = completionDate;
          statusDates['paging_review'] = completionDate;
          statusDates['paging_revisions'] = completionDate;
          statusDates['paging_final'] = completionDate;
          
          // Proofing phase statuses
          statusDates['proofing_1p'] = completionDate;
          statusDates['proofing_1pcx'] = completionDate;
          statusDates['proofing_2p'] = completionDate;
          statusDates['proofing_2pcx'] = completionDate;
          statusDates['proofing_3p'] = completionDate;
          statusDates['proofing_3pcx'] = completionDate;
          statusDates['proofing_4p'] = completionDate;
          statusDates['proofing_approved'] = completionDate;
          
          // ePub phase statuses
          statusDates['epub_sent'] = completionDate;
          statusDates['epub_dad'] = completionDate;
        }
        
        // Create scheduled dates map
        final Map<String, DateTime> scheduledDates = {};
        if (printerDate != null) {
          scheduledDates['printer_date'] = printerDate;
        }
        if (scDate != null) {
          scheduledDates['sc_date'] = scDate;
        }
        if (pubDate != null) {
          scheduledDates['pub_date'] = pubDate;
        }
        
        // Create a new ProjectModel
        final project = ProjectModel(
          id: '', // Will be generated on save
          title: title,
          description: notes,
          isbn: isbn,
          productionEditor: productionEditor,
          format: format,
          mainStatus: mainStatus,
          subStatus: subStatus,
          statusDates: statusDates,
          scheduledDates: scheduledDates,
          deadline: deadline,
          ownerId: userId,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isCompleted: isCompleted,
          completedAt: isCompleted ? DateTime.now() : null,
          imprint: imprint,
          printerDate: printerDate,
          scDate: scDate,
          pubDate: pubDate,
          notes: notes,
          ukCoPub: ukCoPub,
          pageCountSent: pageCountSent,
        );
        
        projects.add(project);
      }
      
      return projects;
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing CSV content: $e');
      }
      rethrow;
    }
  }
  
  // Helper method to parse CSV line respecting quotes
  static List<String> _parseCSVLine(String line) {
    final result = <String>[];
    bool inQuotes = false;
    String currentField = '';
    
    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        result.add(currentField.trim());
        currentField = '';
      } else {
        currentField += char;
      }
    }
    
    // Add the last field
    result.add(currentField.trim());
    
    return result;
  }
  
  // Helper method to map column names to indices
  static Map<String, int> _getColumnIndices(List<String> header) {
    final indices = <String, int>{};
    
    for (int i = 0; i < header.length; i++) {
      // Clean up header names (remove BOM if present)
      String headerName = header[i].replaceAll('\uFEFF', '').trim();
      indices[headerName] = i;
    }
    
    return indices;
  }
  
  // Helper method to parse date strings
  static DateTime? _parseDate(String dateStr) {
    if (dateStr.isEmpty) return null;
    
    try {
      // Try parsing common date formats
      try {
        // MM/dd/yyyy format 
        return DateFormat('M/d/yyyy').parse(dateStr);
      } catch (e) {
        try {
          // MM-dd-yyyy format
          return DateFormat('M-d-yyyy').parse(dateStr);
        } catch (e) {
          try {
            // yyyy-MM-dd format
            return DateFormat('yyyy-MM-dd').parse(dateStr);
          } catch (e) {
            // If all parse attempts fail, return null
            return null;
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing date $dateStr: $e');
      }
      return null;
    }
  }
}