// test/csv_import_test.dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackhack/models/project_model.dart';
import 'package:trackhack/utils/csv_import.dart';

void main() {
  group('CsvImportUtil', () {
    const testUserId = 'test-user-id';
    const testCsvContent = '''
ISBN,Title,Imprint,PE,Status,Next milestone,Printer Date,S.C. Date,Pub Date,Type,Notes,UK co-pub?,Page Count Sent?
9780306834530,Joy Prescriptions,Hachette Go,Sean Moreau,ready for press,ready to deliver to SC,2/19/2025,4/15/2025,5/6/2025,HC and EPUB,AQ design,,Y
9781541619951,Rome and Persia,Basic Books,Melissa Veronesi,in progress,next step,2/19/2025,4/15/2025,5/6/2025,TP AND E REFRESH,,,N/A
''';

    late File tempFile;

    setUp(() async {
      // Create a temporary file with test CSV content
      tempFile = File('test_temp.csv');
      await tempFile.writeAsString(testCsvContent);
    });

    tearDown(() async {
      // Clean up temporary file
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    });

    test(
        'parseProjectsFromCsv correctly parses completed and in-progress projects',
        () async {
      final projects =
          await CsvImportUtil.parseProjectsFromCsv(tempFile, testUserId);

      expect(projects.length, 2);

      // First project should be completed
      expect(projects[0].title, 'Joy Prescriptions');
      expect(projects[0].isbn, '9780306834530');
      expect(projects[0].imprint, 'Hachette Go');
      expect(projects[0].productionEditor, 'Sean Moreau');
      expect(projects[0].format, 'HC and EPUB');
      expect(projects[0].notes, 'AQ design');
      expect(projects[0].ukCoPub, '');
      expect(projects[0].pageCountSent, true);
      expect(projects[0].isCompleted, true);
      expect(projects[0].mainStatus, ProjectMainStatus.epub);

      // Second project should not be completed
      expect(projects[1].title, 'Rome and Persia');
      expect(projects[1].isbn, '9781541619951');
      expect(projects[1].imprint, 'Basic Books');
      expect(projects[1].productionEditor, 'Melissa Veronesi');
      expect(projects[1].format, 'TP AND E REFRESH');
      expect(projects[1].isCompleted, false);
      expect(projects[1].mainStatus, ProjectMainStatus.design);
    });

    test('parseProjectsFromCsv correctly parses dates', () async {
      final projects =
          await CsvImportUtil.parseProjectsFromCsv(tempFile, testUserId);

      // Check first project dates
      expect(projects[0].printerDate?.year, 2025);
      expect(projects[0].printerDate?.month, 2);
      expect(projects[0].printerDate?.day, 19);

      expect(projects[0].scDate?.year, 2025);
      expect(projects[0].scDate?.month, 4);
      expect(projects[0].scDate?.day, 15);

      expect(projects[0].pubDate?.year, 2025);
      expect(projects[0].pubDate?.month, 5);
      expect(projects[0].pubDate?.day, 6);
    });
  });
}
