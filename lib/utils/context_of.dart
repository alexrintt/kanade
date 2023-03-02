import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

extension ContextOf on BuildContext {
  T of<T>({bool listen = false}) {
    return Provider.of<T>(this, listen: listen);
  }
}
