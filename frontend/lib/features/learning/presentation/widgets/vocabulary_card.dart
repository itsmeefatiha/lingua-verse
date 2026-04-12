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
            const SizedBox(height: 8),
            Text(vocabulary.example),
          ],
        ),
      ),
    );
  }
}
