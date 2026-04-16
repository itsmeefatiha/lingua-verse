import 'package:flutter/material.dart';

import '../../data/models/catalog_models.dart';

class VocabularyCard extends StatelessWidget {
  const VocabularyCard({
    super.key,
    required this.vocabulary,
    required this.onAudioTap,
  });

  final VocabularyModel vocabulary;
  final VoidCallback onAudioTap;

  @override
  Widget build(BuildContext context) {
    final imageUrl = vocabulary.imageUrl?.trim() ?? '';
    final hasImage = imageUrl.isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    vocabulary.term,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'Native audio',
                  onPressed: onAudioTap,
                  icon: const Icon(Icons.volume_up_rounded),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              vocabulary.translation,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                height: 150,
                color: Theme.of(context).colorScheme.surface,
                child: hasImage
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const _VocabularyImagePlaceholder(),
                      )
                    : const _VocabularyImagePlaceholder(),
              ),
            ),
            const SizedBox(height: 8),
            Text(vocabulary.example),
          ],
        ),
      ),
    );
  }
}

class _VocabularyImagePlaceholder extends StatelessWidget {
  const _VocabularyImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Icon(
        Icons.image_not_supported_outlined,
        size: 36,
        color: scheme.onSurface.withOpacity(0.6),
      ),
    );
  }
}
