import 'dart:convert';

import 'package:http/http.dart' as http;

/// Thin wrapper around the JSONPlaceholder REST API.
class PostService {
  static const String _endpoint = 'https://jsonplaceholder.typicode.com/posts';

  /// GET - fetches every post and parses the JSON response.
  /// Throws [PostRequestException] for a non-200 status or a network failure.
  Future<List<Map<String, dynamic>>> fetchPosts() async {
    final http.Response response;
    try {
      response = await http.get(Uri.parse(_endpoint));
    } catch (error) {
      throw const PostRequestException(
          'Could not reach the server. Check your internet connection.');
    }

    if (response.statusCode != 200) {
      throw PostRequestException('Request failed with status ${response.statusCode}.');
    }

    final List<dynamic> decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded
        .map((dynamic item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  /// POST - sends a new post and reports whether the API answered 201.
  Future<bool> createPost({required String title, required String body}) async {
    final http.Response response;
    try {
      response = await http.post(
        Uri.parse(_endpoint),
        headers: const {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'title': title, 'body': body, 'userId': 1}),
      );
    } catch (error) {
      return false;
    }
    return response.statusCode == 201;
  }
}

/// Friendly message shown on the screen when a request fails.
class PostRequestException implements Exception {
  final String message;
  const PostRequestException(this.message);

  @override
  String toString() => message;
}
