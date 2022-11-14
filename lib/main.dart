import 'package:flutter/material.dart';
import 'package:kanade/pages/home_page.dart';
import 'package:kanade/setup.dart';
import 'package:kanade/stores/theme.dart';
import 'package:kanade/widgets/no_glow_scroll_behavior.dart';

Future<void> main() async {
  await setup();
  await init();

  runApp(const App());
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: getIt<ThemeStore>(),
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: getIt<ThemeStore>().currentThemeData,
          builder: (context, child) {
            return ScrollConfiguration(
              behavior: NoGlowScrollBehavior(),
              child: child!,
            );
          },
          home: const HomePage(),
        );
      },
    );
  }
}
