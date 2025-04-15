// lib/utils/csv_export.dart
import 'package:intl/intl.dart';
import 'package:universal_html/html.dart' as html;
import '../models/project_model.dart';

class CsvExportUtil {
  // Format date in MM/DD/YYYY format
  static String formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('M/d/yyyy').format(date);
  }

  // Get the status string for a project
  static String getStatusString(ProjectModel project) {
    if (project.isCompleted) {
      return 'ready for press';
    }

    // Find the previously completed substatus
    String previousSubstatus = '';
    DateTime? previousDate;

    final subStatuses = ProjectModel.getSubStatusesForMainStatus(project.mainStatus);
    for (final subStatus in subStatuses) {
      final value = subStatus['value']!;
      final label = subStatus['label']!;
      
      // If this substatus is completed
      if (project.statusDates.containsKey(value)) {
        previousSubstatus = label;
        previousDate = project.statusDates[value];
      } else {
        // Once we hit a non-completed status, break
        break;
      }
    }

    // If we have a previous substatus and date
    if (previousSubstatus.isNotEmpty && previousDate != null) {
      return '$previousSubstatus sent ${formatDate(previousDate)}';
    }

    // If no previous substatus found, return empty
    return '';
  }

  // Get the next milestone string for a project
  static String getNextMilestoneString(ProjectModel project) {
    if (project.isCompleted) {
      return 'ready to deliver to SC';
    }

    // If the last substatus in EPUB phase (Sent to DAD)
    if (project.mainStatus == ProjectMainStatus.epub && 
        project.subStatus == 'epub_dad') {
      return 'ready for press';
    }

    // Find the next uncompleted substatus
    String nextSubstatus = '';
    DateTime? nextDate;

    final subStatuses = ProjectModel.getSubStatusesForMainStatus(project.mainStatus);
    for (final subStatus in subStatuses) {
      final value = subStatus['value']!;
      final label = subStatus['label']!;
      
      // If this substatus is not completed
      if (!project.statusDates.containsKey(value)) {
        nextSubstatus = label;
        nextDate = project.getScheduledDateForSubStatus(value);
        break;
      }
    }

    // If we have a next substatus and date
    if (nextSubstatus.isNotEmpty) {
      return '$nextSubstatus due ${formatDate(nextDate)}';
    }

    // Special case for EPUB phase when moving to final stage
    if (project.mainStatus == ProjectMainStatus.epub) {
      return 'EPUB Routing';
    }

    // If no next substatus found, return empty
    return '';
  }

  // Generate CSV data from a list of projects
  static String generateCsv(List<ProjectModel> projects) {
    // Define CSV headers
    final List<String> headers = [
      'ISBN',
      'Title',
      'Imprint',
      'PE',
      'Status',
      'Next milestone',
      'Printer Date',
      'S.C. Date',
      'Pub Date',
      'Type',
      'Notes',
      'UK co-pub?',
      'Page Count Sent?',
    ];

    // Start with headers
    final StringBuffer csvContent = StringBuffer();
    csvContent.writeln(headers.join(','));

    // Add each project as a row
    for (final project in projects) {
      final List<String> row = [
        _escapeField(project.isbn),
        _escapeField(project.title),
        _escapeField(project.imprint),
        _escapeField(project.productionEditor),
        _escapeField(getStatusString(project)),
        _escapeField(getNextMilestoneString(project)),
        formatDate(project.printerDate),
        formatDate(project.scDate),
        formatDate(project.pubDate),
        _escapeField(project.format),
        _escapeField(project.notes),
        _escapeField(project.ukCoPub),
        _escapeField(project.pageCountSent ? 'Y' : ''),
      ];

      csvContent.writeln(row.join(','));
    }

    return csvContent.toString();
  }

  // Escape field for CSV format
  static String _escapeField(String field) {
    // If the field contains commas, quotes, or newlines, wrap it in quotes
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      // Double up any quotes within the field
      field = field.replaceAll('"', '""');
      // Wrap the field in quotes
      return '"$field"';
    }
    return field;
  }

  // Download CSV file with the given data
  static void downloadCsv(String csvData, String fileName) {
    // Create a Blob containing the CSV data
    final blob = html.Blob([csvData], 'text/csv');

    // Create a URL for the Blob
    final url = html.Url.createObjectUrlFromBlob(blob);

    // Create an anchor element
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..style.display = 'none';

    // Add the anchor to the document
    html.document.body?.append(anchor);

    // Trigger a click on the anchor
    anchor.click();

    // Clean up by removing the anchor and revoking the URL
    html.document.body?.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
  }

  // Export projects to CSV and download the file
  static void exportToCsv(List<ProjectModel> projects, {String fileName = 'projects.csv'}) {
    final csvData = generateCsv(projects);
    downloadCsv(csvData, fileName);
  }
}