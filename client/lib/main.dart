import 'package:flutter/material.dart';
import 'package:melodink_client/core/widgets/gradient_background.dart';
import 'package:melodink_client/features/tracks/presentation/pages/tracks_page.dart';
import 'package:window_manager/window_manager.dart';

import 'features/player/presentation/widgets/player_widget.dart';
import 'features/playlist/presentation/widgets/playlist_list_sidebar.dart';

import 'injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  di.setup();

  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );

  windowManager.waitUntilReadyToShow(windowOptions);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Melodink Client',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: false,
        brightness: Brightness.dark,
        appBarTheme: const AppBarTheme(backgroundColor: Colors.black),
        primaryColor: Colors.black,
        iconTheme: const IconThemeData().copyWith(color: Colors.white),
      ),
      home: const Scaffold(
        body: Column(children: [
          Expanded(
            child: Stack(
              children: [
                GradientBackground(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PlaylistListSidebar(),
                    Expanded(
                      child: TracksPage(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          AudioPlayerWidget()
        ]),
      ),
    );
  }
}
