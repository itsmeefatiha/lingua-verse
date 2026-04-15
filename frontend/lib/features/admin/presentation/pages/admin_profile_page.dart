import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/pages/login_page.dart';

class AdminProfilePage extends StatelessWidget {
  const AdminProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Admin Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: const Color(0xFF00D1C1).withOpacity(0.12),
                  child: Text(
                    user?.fullName.isNotEmpty == true ? user!.fullName.substring(0, 1).toUpperCase() : 'A',
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF00A99A)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(user?.fullName ?? 'Admin User', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(user?.email ?? '', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.admin_panel_settings_outlined),
                  title: const Text('Role'),
                  subtitle: Text(user?.role ?? 'admin'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.language_outlined),
                  title: const Text('Target language'),
                  subtitle: Text(user?.targetLanguage ?? '-'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showEditDialog(context),
                        child: const Text('Edit Profile'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: const Color(0xFF00D1C1)),
                    onPressed: () {
                      context.read<AuthProvider>().logout();
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    },
                    child: const Text('Logout'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Admin Profile'),
        content: const Text('You can wire the edit form to AuthProvider.updateProfile() next.'),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))],
      ),
    );
  }
}
