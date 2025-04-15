// lib/widgets/app_drawer.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trackhack/models/project_model.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/project_provider.dart';
import '../screens/dashboard/widgets/import_csv_dialog.dart';
import '../utils/csv_export.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  // Export projects to CSV
  void _exportProjectsToCSV(BuildContext context) {
    final projectProvider =
        Provider.of<ProjectProvider>(context, listen: false);
    // Get projects and create a new list to avoid modifying the original
    final projects = List<ProjectModel>.from(projectProvider.projects);

    if (projects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No projects available to export'),
        ),
      );
      return;
    }

    // Reverse the list so older projects appear first (chronological order)
    projects.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    // Export the CSV
    CsvExportUtil.exportToCsv(projects, fileName: 'trackhack_export.csv');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Projects exported to CSV successfully'),
      ),
    );
  }

  // Show user profile dialog
  void _showUserProfileDialog(
      BuildContext context, UserModel user, AuthProvider authProvider) {
    final nameController = TextEditingController(text: user.name);
    final roleController = TextEditingController(text: user.role);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('User Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar
              CircleAvatar(
                radius: 40,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontSize: 32,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Email (read-only)
              Text(
                user.email,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // Name
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                ),
              ),
              const SizedBox(height: 16),
              // Role
              TextField(
                controller: roleController,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  hintText: 'e.g. Editor, Author, Publisher',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty || roleController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill in all fields'),
                  ),
                );
                return;
              }

              Navigator.pop(context);

              await authProvider.updateUserProfile(
                name: nameController.text,
                role: roleController.text,
              );

              if (authProvider.error != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${authProvider.error}'),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profile updated successfully'),
                  ),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    if (user == null) {
      return const SizedBox.shrink();
    }

    return Drawer(
      child: Column(
        children: [
          // User profile header with tap functionality
          GestureDetector(
            onTap: () => _showUserProfileDialog(context, user, authProvider),
            child: UserAccountsDrawerHeader(
              accountName: Text(user.name),
              accountEmail: Text(user.email),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '',
                  style: const TextStyle(fontSize: 24.0, color: Colors.white),
                ),
              ),
              decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            ),
          ),

          // Import CSV option
          ListTile(
            leading: const Icon(Icons.file_upload),
            title: const Text('Import CSV'),
            onTap: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (context) => const ImportCsvDialog(),
              );
            },
          ),

          // Export CSV option
          ListTile(
            leading: const Icon(Icons.file_download),
            title: const Text('Export CSV'),
            onTap: () {
              Navigator.pop(context);
              _exportProjectsToCSV(context);
            },
          ),

          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            onTap: () {
              // TODO: Implement Settings screen
              Navigator.pop(context);
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(builder: (context) => const SettingsScreen()),
              // );
            },
          ),

          const Spacer(),

          const Divider(),

          // Sign out
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign Out'),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text('Are you sure you want to sign out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                if (context.mounted) {
                  await authProvider.signOut();
                }
              }
            },
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
