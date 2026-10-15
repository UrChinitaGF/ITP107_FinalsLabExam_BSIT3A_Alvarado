import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'boxes.dart';
import 'screens/details_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/posts_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hive setup - local persistence for favorite posts.
  await Hive.initFlutter();
  await Hive.openBox<Map<dynamic, dynamic>>(Boxes.favoritesBoxName);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  /// Single seed color so every screen shares the same palette.
  static const Color brandColor = Color(0xFF1F3B63);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Post Reader & Favorites',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: brandColor,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          isDense: true,
        ),
        snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: brandColor,
          foregroundColor: Colors.white,
        ),
      ),

      // Part 1 - named routes.
      initialRoute: PostsScreen.routeName,
      routes: {
        PostsScreen.routeName: (_) => const PostsScreen(),
        DetailsScreen.routeName: (_) => const DetailsScreen(),
        FavoritesScreen.routeName: (_) => const FavoritesScreen(),
      },
    );
  }
}
