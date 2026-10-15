import 'package:hive_flutter/hive_flutter.dart';

/// Central place for Hive box names, accessors, and favorite-post operations.
///
/// The box is opened in main() before runApp(), so it is safe to use
/// synchronously anywhere in the widget tree.
class Boxes {
  static const String favoritesBoxName = 'favoritesBox';

  static Box<Map<dynamic, dynamic>> get favorites =>
      Hive.box<Map<dynamic, dynamic>>(favoritesBoxName);

  /// CREATE - the post id is used as the key, so saving the same post twice
  /// simply overwrites it and never creates a duplicate.
  static Future<void> saveFavorite(Map<String, dynamic> post) {
    final favorite = Map<String, dynamic>.from(post)..putIfAbsent('note', () => '');
    return favorites.put(post['id'], favorite);
  }

  /// UPDATE - writes the edited personal note back to the box.
  static Future<void> saveNote(dynamic key, String note) async {
    final current = favorites.get(key);
    if (current == null) return;
    final updated = Map<String, dynamic>.from(current)..['note'] = note;
    await favorites.put(key, updated);
  }

  /// DELETE - removes a saved favorite.
  static Future<void> deleteFavorite(dynamic key) => favorites.delete(key);

  static bool isFavorite(dynamic key) => favorites.containsKey(key);
}
