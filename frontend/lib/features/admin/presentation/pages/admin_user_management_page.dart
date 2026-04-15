import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/admin_user_provider.dart';

class AdminUserManagementPage extends StatefulWidget {
  const AdminUserManagementPage({super.key});

  @override
  State<AdminUserManagementPage> createState() => _AdminUserManagementPageState();
}

class _AdminUserManagementPageState extends State<AdminUserManagementPage> {
  final _searchController = TextEditingController();
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) {
      return;
    }
    _loaded = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminUserProvider>().loadUsers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminUserProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('User Management'),
      ),
      body: RefreshIndicator(
        onRefresh: () => admin.loadUsers(search: _searchController.text),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _searchController,
              onChanged: (value) => admin.loadUsers(search: value),
              decoration: InputDecoration(
                hintText: 'Search by username or email',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 16),
            if (admin.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(admin.error!, style: const TextStyle(color: Colors.redAccent)),
              ),
            if (admin.isLoading && admin.users.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 120),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (admin.users.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: Text('No users found.')),
              )
            else
              ...admin.users.map(
                (user) => Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF00D1C1).withOpacity(0.12),
                      child: Text(
                        user.fullName.isNotEmpty ? user.fullName.substring(0, 1).toUpperCase() : '?',
                        style: const TextStyle(color: Color(0xFF00A99A), fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(user.fullName),
                    subtitle: Text('${user.email}\n${user.role} • ${user.currentLeague} • ${user.totalXp} XP'),
                    isThreeLine: true,
                    trailing: Wrap(
                      spacing: 6,
                      children: [
                        IconButton(
                          onPressed: () => _showEditDialog(context, user.fullName),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                        IconButton(
                          onPressed: user.role == 'admin'
                              ? null
                              : () => _confirmDelete(context, user.id, user.fullName),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, String currentName) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit User Info'),
        content: Text('Editing flow for $currentName can be wired next.'),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))],
      ),
    );
  }

  void _confirmDelete(BuildContext context, int userId, String name) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete $name?'),
        content: const Text('This will remove the user account from the system.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await context.read<AdminUserProvider>().deleteUser(userId);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
