import 'dart:async';

/// Do not declare it directly like this:
/// ```dart
/// final kThrottle5000ms = throttleIt(const Duration(milliseconds: 5000));
/// ```
/// because any global call will reset the throttle function.
void Function(void Function()) throttleIt1s() {
  return throttleIt(const Duration(seconds: 1));
}

void Function(void Function()) throttleIt500ms() {
  return throttleIt(const Duration(milliseconds: 500));
}

void Function(void Function()) throttleIt(Duration duration) {
  Timer? throttle;

  var allowExec = true;

  void resetThrottle(void Function() fn) {
    allowExec = false;

    void callback() => {allowExec = true, throttle?.cancel()};

    throttle = Timer(duration, callback);

    fn();
  }

  return (fn) {
    if (!allowExec) return;

    resetThrottle(fn);
  };
}
