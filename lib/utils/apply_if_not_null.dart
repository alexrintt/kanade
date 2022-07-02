extension ApplyIfNotNull<T> on T? {
  R? apply<R>(R Function(T) f) {
    // Local variable to allow automatic type promotion.  Also see:
    // <https://github.com/dart-lang/language/issues/1397>
    var self = this;
    return (self == null) ? null : f(self);
  }
}
