import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'pages/home_page.dart';
import 'setup.dart';
import 'stores/localization_store.dart';
import 'stores/theme.dart';
import 'widgets/multi_animated_builder.dart';
import 'widgets/no_glow_scroll_behavior.dart';

Future<void> main() async {
  await setup();
  await init();

  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiAnimatedBuilder(
      animations: <Listenable>[getIt<ThemeStore>(), getIt<LocalizationStore>()],
      builder: (BuildContext context, Widget? child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: getIt<ThemeStore>().currentThemeData,
          locale: getIt<LocalizationStore>().locale,
          builder: (BuildContext context, Widget? child) {
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
