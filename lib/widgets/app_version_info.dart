import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_shared_tools/constant/constant.dart';
import 'package:flutter_shared_tools/extensions/extensions.dart';
import 'package:kanade/constants/strings.dart';
import 'package:kanade/setup.dart';
import 'package:kanade/widgets/animated_app_name.dart';
import 'package:pixelarticons/pixel.dart';
import 'package:url_launcher/url_launcher_string.dart';

class AppVersionInfo extends StatefulWidget {
  const AppVersionInfo({Key? key}) : super(key: key);

  @override
  State<AppVersionInfo> createState() => _AppVersionInfoState();
}

class _AppVersionInfoState extends State<AppVersionInfo> {
  @override
  Widget build(BuildContext context) {
    final backgroundColor = context.theme.primaryColor.withOpacity(.02);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: k40dp),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Opacity(
              opacity: 0.5,
              child: Image.asset(
                'assets/images/bottom.png',
                height: kToolbarHeight,
              ),
            ),
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
                padding: const EdgeInsets.all(k4dp).copyWith(bottom: k6dp),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Center(child: AnimatedAppName()),
                    GestureDetector(
                      onTap: () => launchUrlString(
                        kRepositoryUrl,
                        mode: LaunchMode.externalApplication,
                      ),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text:
                                  'v${packageInfo.version}+${packageInfo.buildNumber}',
                            ),
                            TextSpan(
                              text: '\n${packageInfo.packageName}',
                              style: TextStyle(
                                color: context.theme.disabledColor,
                              ),
                            ),
                            WidgetSpan(
                              child: Padding(
                                padding: const EdgeInsets.only(left: k2dp),
                                child: Icon(
                                  Pixel.externallink,
                                  size: 14,
                                  color: context.theme.disabledColor,
                                ),
                              ),
                              alignment: PlaceholderAlignment.middle,
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
    );
  }
}
