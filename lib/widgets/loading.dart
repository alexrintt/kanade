import 'package:flutter/material.dart';
import 'package:kanade/widgets/animated_app_name.dart';

class Loading extends StatefulWidget {
  const Loading({Key? key}) : super(key: key);

  @override
  _LoadingState createState() => _LoadingState();
}

class _LoadingState extends State<Loading> {
  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          AnimatedAppName(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildLoading();
  }
}
