import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:melodink_client/core/routes/cubit.dart';
import 'package:melodink_client/core/routes/router.dart';
import 'package:window_manager/window_manager.dart';

import 'injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await di.setup();

  if (!kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
      minimumSize: Size(300, 534),
      fullScreen: false,
    );

    windowManager.waitUntilReadyToShow(windowOptions);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (BuildContext contex) => di.sl<RouterCubit>(),
      child: MaterialApp.router(
        title: 'Melodink Client',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: false,
          brightness: Brightness.dark,
          appBarTheme: const AppBarTheme(backgroundColor: Colors.black),
          primaryColor: Colors.black,
          iconTheme: const IconThemeData().copyWith(color: Colors.white),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromRGBO(196, 126, 208, 1),
            brightness: Brightness.dark,
          ),
          fontFamily: "Roboto",
        ),
        routerConfig: appRouter,
      ),
    );
  }
}
