// lib/widgets/app_drawer.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/dashboard/dashboard_screen.dart';
// import '../screens/settings/settings_screen.dart'; // TODO: Implement Settings Screen

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

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
          // User profile header
          UserAccountsDrawerHeader(
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

          // Navigation items
          ListTile(
            leading: const Icon(Icons.dashboard_outlined),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const DashboardScreen(),
                ),
                (route) => false,
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.book_outlined),
            title: const Text('My Projects'),
            onTap: () {
              // This is the same as the dashboard for now
              Navigator.pop(context);
            },
          ),

          ListTile(
            leading: const Icon(Icons.task_outlined),
            title: const Text('My Tasks'),
            onTap: () {
              // TODO: Implement My Tasks screen
              Navigator.pop(context);
            },
          ),

          ListTile(
            leading: const Icon(Icons.people_outline),
            title: const Text('Team'),
            onTap: () {
              // TODO: Implement Team screen
              Navigator.pop(context);
            },
          ),

          ListTile(
            leading: const Icon(Icons.calendar_today_outlined),
            title: const Text('Calendar'),
            onTap: () {
              // TODO: Implement Calendar screen
              Navigator.pop(context);
            },
          ),

          const Divider(),

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
                builder:
                    (context) => AlertDialog(
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
