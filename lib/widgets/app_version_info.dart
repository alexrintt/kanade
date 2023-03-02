import 'package:flutter/material.dart';
import 'package:flutter_shared_tools/constant/constant.dart';
import 'package:flutter_shared_tools/extensions/extensions.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../constants/strings.dart';
import '../setup.dart';
import 'animated_app_name.dart';
import 'bolt_animation.dart';

class AppVersionInfo extends StatefulWidget {
  const AppVersionInfo({
    super.key,
    this.enableAnimation = true,
  });

  final bool enableAnimation;

  @override
  State<AppVersionInfo> createState() => _AppVersionInfoState();
}

class _AppVersionInfoState extends State<AppVersionInfo>
    with TickerProviderStateMixin {
  bool _animate = false;

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = context.theme.primaryColor.withOpacity(.02);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: k40dp),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: <Widget>[
                BoltAnimation(animate: _animate),
              ],
            ),
            GestureDetector(
              onTapDown: (_) => setState(() => _animate = true),
              onTapUp: (_) => setState(() => _animate = false),
              onTapCancel: () => setState(() => _animate = false),
              child: Stack(
                children: <Widget>[
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      border: Border.symmetric(
                        horizontal: BorderSide(
                          width: k1dp,
                          color: context.theme.dividerColor,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding:
                          const EdgeInsets.all(k4dp).copyWith(bottom: k6dp),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Center(child: AnimatedAppName()),
                          GestureDetector(
                            onTap: () => launchUrlString(
                              kRepositoryUrl,
                              mode: LaunchMode.externalApplication,
                            ),
                            child: Text.rich(
                              TextSpan(
                                children: <InlineSpan>[
                                  TextSpan(
                                    text:
                                        'Apk Extractor v${packageInfo.version}+${packageInfo.buildNumber}\n',
                                  ),
                                  TextSpan(
                                    text: packageInfo.packageName,
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: context.theme.disabledColor,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
