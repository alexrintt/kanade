import 'package:flutter/cupertino.dart';
import 'package:kanade/constants/app_colors.dart';
import 'package:kanade/constants/app_spacing.dart';

import 'dotted_background.dart';

class Loading extends StatefulWidget {
  const Loading({Key? key}) : super(key: key);

  @override
  _LoadingState createState() => _LoadingState();
}

class _LoadingState extends State<Loading> {
  Widget _buildBackground() {
    return Positioned.fill(
      child: DottedBackground(
        color: kWhite10,
        size: k5dp,
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/pixel_animation.gif',
            filterQuality: FilterQuality.none,
          ),
          const Text(
            'Loading',
            style: TextStyle(
              fontFamily: 'Forward',
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildBackground(),
        _buildLoading(),
      ],
    );
  }
}
