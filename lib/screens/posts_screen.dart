import 'package:flutter/material.dart';

import '../services/post_service.dart';
import '../widgets/create_post_dialog.dart';

/// Route '/' - the posts list fetched from the REST API.
class PostsScreen extends StatefulWidget {
  const PostsScreen({super.key});

  static const String routeName = '/';

  @override
  State<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen> {
  final PostService _service = PostService();
  late Future<List<Map<String, dynamic>>> _posts;

  @override
  void initState() {
    super.initState();
    _posts = _service.fetchPosts();
  }

  /// Re-runs the GET request (used by the retry button and pull-to-refresh).
  Future<void> _reload() async {
    final Future<List<Map<String, dynamic>>> request = _service.fetchPosts();
    setState(() => _posts = request);
    try {
      // Keep the refresh spinner up until the data actually arrives.
      await request;
    } catch (_) {
      // The error view below is already shown by the FutureBuilder.
    }
  }

  void _openDetails(Map<String, dynamic> post) {
    Navigator.pushNamed(
      context,
      '/details',
      arguments: post,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Posts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite),
            tooltip: 'Favorites',
            onPressed: () => Navigator.pushNamed(context, '/favorites'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showCreatePostDialog(context),
        tooltip: 'Create post',
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _posts,
        builder: (context, snapshot) {
          // Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error - shown on the screen, never just printed.
          if (snapshot.hasError) {
            return _ErrorView(
              message: snapshot.error.toString(),
              onRetry: _reload,
            );
          }

          final posts = snapshot.data ?? const <Map<String, dynamic>>[];
          if (posts.isEmpty) {
            return const Center(child: Text('No posts available.'));
          }

          // Success - ListView.builder with ListTile for every post.
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text(
                      post['title']?.toString() ?? 'Untitled',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      post['body']?.toString() ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _openDetails(post),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

/// Reusable on-screen error message with a retry button.
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 56, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 12),
            Text(
              'Something went wrong.',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
