import 'package:flutter/material.dart';
import 'package:kanade/pages/home_page.dart';
import 'package:kanade/setup.dart';
import 'package:kanade/stores/localization_store.dart';
import 'package:kanade/stores/theme.dart';
import 'package:kanade/widgets/multi_animated_builder.dart';
import 'package:kanade/widgets/no_glow_scroll_behavior.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

Future<void> main() async {
  await setup();
  await init();

  runApp(const App());
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiAnimatedBuilder(
      animations: [getIt<ThemeStore>(), getIt<LocalizationStore>()],
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: getIt<ThemeStore>().currentThemeData,
          locale: getIt<LocalizationStore>().locale,
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
