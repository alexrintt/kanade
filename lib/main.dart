import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_shared_tools/flutter_shared_tools.dart';

import 'pages/home_page.dart';
import 'setup.dart';
import 'stores/localization_store.dart';
import 'stores/theme_store.dart';
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
      animations: <Listenable>[
        getIt<ThemeStore>(),
        getIt<LocalizationStore>(),
      ],
      builder: (BuildContext context, Widget? child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: getIt<ThemeStore>().currentThemeData,
          locale: getIt<LocalizationStore>().locale,
          builder: (BuildContext context, Widget? child) {
            return AnimatedBuilder(
              animation: getIt<ThemeStore>(),
              builder: (BuildContext context, Widget? child) {
                final ScrollBehavior scrollBehavior =
                    getIt<ThemeStore>().scrollBehavior;

                Widget? childWithColoredScrollIndicator = child;

                if (scrollBehavior == const GlowScrollBehavior()) {
                  childWithColoredScrollIndicator = GlowingOverscrollIndicator(
                    color: context.theme.primaryColor,
                    axisDirection: AxisDirection.down,
                    child: childWithColoredScrollIndicator,
                  );
                }

                return ScrollConfiguration(
                  behavior: getIt<ThemeStore>().scrollBehavior,
                  child: childWithColoredScrollIndicator!,
                );
              },
              child: child,
            );
          },
          home: const HomePage(),
        );
      },
    );
  }
}
