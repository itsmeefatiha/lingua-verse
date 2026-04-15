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
                      backgroundImage: user.avatarUrl.trim().isNotEmpty ? NetworkImage(user.avatarUrl.trim()) : null,
                      child: user.avatarUrl.trim().isEmpty
                          ? Text(
                              user.fullName.isNotEmpty ? user.fullName.substring(0, 1).toUpperCase() : '?',
                              style: const TextStyle(color: Color(0xFF00A99A), fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                    title: Text(user.fullName),
                    subtitle: Text('${user.email}\n${user.role} • ${user.currentLeague} • ${user.totalXp} XP'),
                    isThreeLine: true,
                    trailing: Wrap(
                      spacing: 6,
                      children: [
                        IconButton(
                          onPressed: () => _showEditDialog(context, user),
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

  void _showEditDialog(BuildContext context, dynamic user) {
    final fullNameController = TextEditingController(text: user.fullName);
    final emailController = TextEditingController(text: user.email);
    final sourceLanguageController = TextEditingController(text: user.sourceLanguage);
    final targetLanguageController = TextEditingController(text: user.targetLanguage);
    String role = user.role;
    bool isActive = user.isActive;

    showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('Edit User Info'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: fullNameController, decoration: const InputDecoration(labelText: 'Full name')),
                const SizedBox(height: 12),
                TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
                const SizedBox(height: 12),
                TextField(controller: sourceLanguageController, decoration: const InputDecoration(labelText: 'Source language')),
                const SizedBox(height: 12),
                TextField(controller: targetLanguageController, decoration: const InputDecoration(labelText: 'Target language')),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: role.toLowerCase(),
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: const [
                    DropdownMenuItem(value: 'user', child: Text('user')),
                    DropdownMenuItem(value: 'admin', child: Text('admin')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => role = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active'),
                  value: isActive,
                  onChanged: (value) => setState(() => isActive = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await context.read<AdminUserProvider>().updateUser(
                      user.id,
                      fullName: fullNameController.text.trim(),
                      email: emailController.text.trim(),
                      sourceLanguage: sourceLanguageController.text.trim(),
                      targetLanguage: targetLanguageController.text.trim(),
                      role: role,
                      isActive: isActive,
                    );
              },
              child: const Text('Save'),
            ),
          ],
        ),
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
