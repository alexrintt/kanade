import 'dart:async';

void Function(void Function()) debounceIt200ms() {
  return debounceIt(const Duration(milliseconds: 200));
}

void Function(void Function()) debounceIt(Duration duration) {
  Timer? debounce;

  return (fn) {
    debounce?.cancel();

    void callback() => ({fn(), debounce?.cancel()});

    debounce = Timer(duration, callback);
  };
}
