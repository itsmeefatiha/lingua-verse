import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'admin_add_content_page.dart';
import '../providers/admin_content_provider.dart';

class AdminContentManagementPage extends StatefulWidget {
  const AdminContentManagementPage({super.key});

  @override
  State<AdminContentManagementPage> createState() => _AdminContentManagementPageState();
}

class _AdminContentManagementPageState extends State<AdminContentManagementPage> {
  Future<void> _openAddFlow(AdminAddContentType type) async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AdminAddContentPage(type: type),
      ),
    );

    if (added == true && mounted) {
      await context.read<AdminContentProvider>().loadLanguages();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Content created successfully.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminContentProvider>();
    final languages = admin.languages;
    final levels = admin.levels;
    final lessons = admin.lessons;
    final words = admin.words;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Content Management'),
        actions: [
          IconButton(
            onPressed: () => _openAddFlow(AdminAddContentType.level),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF00D1C1),
        onPressed: () => _showAddPicker(context),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: RefreshIndicator(
        onRefresh: () => admin.loadLanguages(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (admin.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(admin.error!, style: const TextStyle(color: Colors.redAccent)),
              ),
            _SectionCard(
              title: 'Languages',
              trailing: languages.isEmpty ? null : Text('${languages.length} items'),
              child: Column(
                children: languages
                    .map(
                      (language) => ListTile(
                        title: Text('${language.name} (${language.code.toUpperCase()})'),
                        subtitle: Text('ID ${language.id}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(onPressed: () => _openAddFlow(AdminAddContentType.level), icon: const Icon(Icons.edit_outlined)),
                            IconButton(onPressed: () {}, icon: const Icon(Icons.delete_outline)),
                          ],
                        ),
                        onTap: () => context.read<AdminContentProvider>().loadLevels(language.code),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Levels',
              onAddTap: () => _openAddFlow(AdminAddContentType.level),
              trailing: levels.isEmpty ? null : Text('${levels.length} items'),
              child: Column(
                children: levels
                    .map(
                      (level) => ListTile(
                        title: Text(level.name),
                        subtitle: Text('Order ${level.orderIndex}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(onPressed: () => _openAddFlow(AdminAddContentType.level), icon: const Icon(Icons.edit_outlined)),
                            IconButton(onPressed: () {}, icon: const Icon(Icons.delete_outline)),
                          ],
                        ),
                        onTap: () => context.read<AdminContentProvider>().loadLessons(level.id),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Lessons',
              onAddTap: () => _openAddFlow(AdminAddContentType.lesson),
              trailing: lessons.isEmpty ? null : Text('${lessons.length} items'),
              child: Column(
                children: lessons
                    .map(
                      (lesson) => ListTile(
                        title: Text(lesson.name),
                        subtitle: Text('Level ${lesson.levelId}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(onPressed: () => _openAddFlow(AdminAddContentType.lesson), icon: const Icon(Icons.edit_outlined)),
                            IconButton(onPressed: () {}, icon: const Icon(Icons.delete_outline)),
                          ],
                        ),
                        onTap: () => context.read<AdminContentProvider>().loadWords(lesson.id),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Words',
              onAddTap: () => _openAddFlow(AdminAddContentType.word),
              trailing: words.isEmpty ? null : Text('${words.length} items'),
              child: Column(
                children: words
                    .map(
                      (word) => ListTile(
                        title: Text(word.targetText),
                        subtitle: Text(word.nativeText),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(onPressed: () => _openAddFlow(AdminAddContentType.word), icon: const Icon(Icons.edit_outlined)),
                            IconButton(onPressed: () {}, icon: const Icon(Icons.delete_outline)),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddPicker(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Content'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.stacked_bar_chart),
              title: const Text('Add Level'),
              onTap: () {
                Navigator.of(context).pop();
                _openAddFlow(AdminAddContentType.level);
              },
            ),
            ListTile(
              leading: const Icon(Icons.menu_book_outlined),
              title: const Text('Add Lesson'),
              onTap: () {
                Navigator.of(context).pop();
                _openAddFlow(AdminAddContentType.lesson);
              },
            ),
            ListTile(
              leading: const Icon(Icons.translate_outlined),
              title: const Text('Add Word'),
              onTap: () {
                Navigator.of(context).pop();
                _openAddFlow(AdminAddContentType.word);
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child, this.trailing, this.onAddTap});

  final String title;
  final Widget child;
  final Widget? trailing;
  final VoidCallback? onAddTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onAddTap,
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
                if (onAddTap != null)
                  TextButton.icon(
                    onPressed: onAddTap,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add'),
                  ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}
