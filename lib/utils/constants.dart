// lib/utils/constants.dart

class AppConstants {
  // App metadata
  static const String appName = 'TrackHack';
  static const String appVersion = '1.0.0';

  // Collection names
  static const String usersCollection = 'users';
  static const String projectsCollection = 'projects';
  static const String tasksCollection = 'tasks';
  static const String documentsCollection = 'documents';

  // User roles
  static const String roleEditor = 'Editor';
  static const String roleAuthor = 'Author';
  static const String rolePublisher = 'Publisher';
  static const String roleAdmin = 'Admin';

  // Date formats
  static const String dateFormatFull = 'MMMM d, yyyy';
  static const String dateFormatShort = 'MMM d, yyyy';
  static const String dateFormatCompact = 'yyyy-MM-dd';

  // UI constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double defaultBorderRadius = 8.0;
  static const double cardBorderRadius = 12.0;

  // Animation durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 350);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  // Document storage limits
  static const int maxDocumentTitleLength = 100;
  static const int maxDocumentContentLength = 50000;

  // Project status colors (matching ProjectStatus enum)
  static const Map<String, String> projectStatusColors = {
    'notTransmitted': '#78909C', // Grey
    'inDesign': '#AB47BC', // Purple
    'paging': '#42A5F5', // Blue
    'proofing': '#FF7043', // Orange
    'press': '#26A69A', // Teal
    'epub': '#FFA726', // Amber
    'published': '#66BB6A', // Green
  };

  // Status column mapping
  static const Map<String, List<String>> kanbanStatusMap = {
    'Design': ['inDesign'],
    'Paging': ['paging'],
    'Proofing': ['proofing'],
  };
}
