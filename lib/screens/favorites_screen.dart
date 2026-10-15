import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../boxes.dart';

/// Route '/favorites' - reads, updates, and deletes locally saved posts.
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  static const String routeName = '/favorites';

  /// UPDATE - edit the personal note of a saved post.
  Future<void> _editNote(BuildContext context, dynamic key, Map post) async {
    final controller = TextEditingController(text: (post['note'] ?? '').toString());

    final String? saved = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit personal note'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 4,
          maxLength: 200,
          decoration: const InputDecoration(
            hintText: 'Write a short note about this post...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    controller.dispose();
    if (saved == null) return;

    await Boxes.saveNote(key, saved);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Note updated.')),
    );
  }

  /// DELETE - removes the post from the box.
  /// Reached from the delete icon and from the swipe gesture.
  Future<void> _delete(BuildContext context, dynamic key, String title) async {
    // Keep the messenger before awaiting: after a swipe the card (and its
    // context) is already gone by the time the box finishes updating.
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    await Boxes.deleteFavorite(key);

    messenger.showSnackBar(
      SnackBar(content: Text('"$title" removed from Favorites')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
        // Explicit Navigator.pop() to go back to the Posts screen.
        leading: BackButton(onPressed: () => Navigator.pop(context)),
      ),
      body: ValueListenableBuilder<Box<Map<dynamic, dynamic>>>(
        // Rebuilds automatically whenever the box changes.
        valueListenable: Boxes.favorites.listenable(),
        builder: (context, box, _) {
          if (box.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No favorites yet.\nOpen a post and tap "Save to Favorites".',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          // READ - every saved post, taken straight from the box
          // (newest first).
          final List<Map<dynamic, dynamic>> favorites =
              box.values.toList().reversed.toList();

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 16, top: 4),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final Map post = favorites[index];
              // The id is also the key the post was saved with.
              final dynamic key = post['id'];
              final String title = (post['title'] ?? 'Untitled').toString();
              final String body = (post['body'] ?? '').toString();
              final String note = (post['note'] ?? '').toString();

              return Dismissible(
                key: ValueKey(key),
                // DELETE - swipe the card from right to left to remove it.
                direction: DismissDirection.endToStart,
                dismissThresholds: const {DismissDirection.endToStart: 0.4},
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 24),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) => _delete(context, key, title),
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 4, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.black54),
                        ),
                        if (note.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0x1A1F3B63),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('Note: $note'),
                          ),
                        ],
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_note),
                              tooltip: 'Edit note',
                              onPressed: () => _editNote(context, key, post),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              tooltip: 'Delete',
                              onPressed: () => _delete(context, key, title),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
