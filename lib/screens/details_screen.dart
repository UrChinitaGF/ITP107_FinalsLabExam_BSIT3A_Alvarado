import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../boxes.dart';

/// Route '/details' - shows one post and can save it to Hive.
class DetailsScreen extends StatefulWidget {
  const DetailsScreen({super.key});

  static const String routeName = '/details';

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  Map<String, dynamic>? _post;
  String? _argumentError;

  /// Arguments are read from the route - ModalRoute needs a valid context,
  /// so they are collected once in didChangeDependencies.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_post != null || _argumentError != null) return;

    final Object? arguments = ModalRoute.of(context)!.settings.arguments;
    if (arguments is Map) {
      _post = Map<String, dynamic>.from(arguments);
    } else {
      _argumentError = 'No post was passed to this screen.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? post = _post;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Details'),
        // Explicit Navigator.pop() to go back to the Posts screen.
        leading: BackButton(onPressed: () => Navigator.pop(context)),
      ),
      body: post == null
          ? Center(child: Text(_argumentError ?? 'Post not found.'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  post['title']?.toString() ?? 'Untitled',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Post #${post['id']}  •  User ${post['userId']}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Divider(height: 32),
                Text(
                  post['body']?.toString() ?? '',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
                ),
                const SizedBox(height: 32),
                _SaveToFavoritesButton(post: post),
              ],
            ),
    );
  }
}

/// CREATE - writes the post (as a Map) into the favorites box using the
/// post id as the key, so the same post is never saved twice.
class _SaveToFavoritesButton extends StatelessWidget {
  final Map<String, dynamic> post;

  const _SaveToFavoritesButton({required this.post});

  @override
  Widget build(BuildContext context) {
    final dynamic key = post['id'];

    return ValueListenableBuilder<Box<Map<dynamic, dynamic>>>(
      valueListenable: Boxes.favorites.listenable(),
      builder: (context, box, _) {
        final bool saved = box.containsKey(key);

        return SizedBox(
          width: double.infinity,
          child: saved
              ? OutlinedButton.icon(
                  icon: const Icon(Icons.favorite),
                  label: const Text('Saved to Favorites  •  Tap to remove'),
                  onPressed: () async {
                    await Boxes.deleteFavorite(key);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Removed from Favorites.')),
                    );
                  },
                )
              : FilledButton.icon(
                  icon: const Icon(Icons.favorite_border),
                  label: const Text('Save to Favorites'),
                  onPressed: () async {
                    await Boxes.saveFavorite(post);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Saved to Favorites.')),
                    );
                  },
                ),
        );
      },
    );
  }
}
