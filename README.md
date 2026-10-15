# Post Reader & Favorites

ITP107 – Mobile Application Development · Finals Laboratory Examination

A Flutter app that fetches posts from the internet, lets the user open a post, and
saves favorite posts locally. Data comes from the
[JSONPlaceholder](https://jsonplaceholder.typicode.com/posts) REST API; favorites
are persisted on-device with **Hive**.

## Features

**Routes & Navigation**

- Three named routes registered with `initialRoute` + `routes`:
  `/` (Posts), `/details` (Post Details), `/favorites` (Favorites)
- `Navigator.pushNamed()` to move between screens, `Navigator.pop()` to go back
- AppBar button on the Posts screen opens Favorites
- The tapped post's `id`, `title`, and `body` are passed as route arguments and
  read back with `ModalRoute.of(context)!.settings.arguments`

**Fetch Data from the Internet**

- `http.get(Uri.parse(...))` inside an async method called from `initState()`
- On HTTP 200 the response is parsed with `jsonDecode()` and rendered with
  `ListView.builder` + `ListTile`
- Non-200 responses and network failures show an on-screen error view with a
  retry button
- Floating action button opens a dialog that validates a non-empty title and
  body, then sends them with `http.post()` + `jsonEncode()`; success is reported
  on HTTP 201, failure otherwise

**Local Persistence with Hive**

- `WidgetsFlutterBinding.ensureInitialized()` → `await Hive.initFlutter()` →
  `openBox('favoritesBox')` before `runApp()`
- **Create** – "Save to Favorites" stores the post as a `Map` with `put()`,
  keyed by the post id so a post is never saved twice
- **Read** – the Favorites screen lists `box.values` and refreshes on its own via
  `ValueListenableBuilder`
- **Update** – a short personal note can be edited and written back
- **Delete** – remove with the delete icon **or** by swiping the card
- Favorites survive closing and reopening the app

## Getting started

```bash
flutter pub get
flutter run          # pick a device or emulator with internet access
```

Run the tests:

```bash
flutter test
flutter analyze
```

## Project structure

```
lib/
├── main.dart                        Hive bootstrap, named routes, ThemeData
├── boxes.dart                       favoritesBox helpers (create/update/delete)
├── services/post_service.dart       GET + POST requests and JSON parsing
├── screens/
│   ├── posts_screen.dart            '/'          posts list
│   ├── details_screen.dart          '/details'   post details + save
│   └── favorites_screen.dart        '/favorites' read / edit / delete
└── widgets/create_post_dialog.dart  POST dialog with validation
test/
└── widget_test.dart                 routes, Hive CRUD, swipe-to-delete
```

## Design

A single `ThemeData` (Material 3, one seeded brand color) is shared by every
screen, with clear AppBar titles, consistent card spacing, and empty/loading/error
states on each screen.
