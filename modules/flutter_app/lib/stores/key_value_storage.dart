import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../setup.dart';

/// Helper mixin to avoid code repetition through stores.
///
/// Do not use this directly on UI classes (e.g that extends from [State<T>]).
///
/// Instead create a store that uses this mixin and then depend on it in the UI.
mixin KeyValueStorageConsumer<K, V> {
  KeyValueStorage<K, V?> get keyValueStorage =>
      _keyValueStorage ??= getIt<KeyValueStorage<K, V>>();
  KeyValueStorage<K, V>? _keyValueStorage;
}

/// The changes made in [this] will be available even after the device/app restart.
abstract class KeyValueStorage<K, V> {
  /// Retrive all values associated with this instance [keys].
  Future<List<V>> get values async {
    return <V>[
      for (final K key in await keys) await this[key],
    ];
  }

  /// Retrive all map entries associated with this instance [keys] and [values].
  Future<List<MapEntry<K, V>>> get entries async {
    return <MapEntry<K, V>>[
      for (final K key in await keys) MapEntry<K, V>(key, await this[key]),
    ];
  }

  /// Retrieve all instance keys.
  Future<Set<K>> get keys;

  /// Alias for [get] method.
  Future<V> operator [](K key) => get(key);

  /// Alias for [set] method.
  void operator []=(K key, V value) => set(key, value);

  /// Store a given [value] under the given [key] of [this] hash map.
  Future<MapEntry<K, V>?> set(K key, V value);

  /// Retrives the value persisted under the given [key].
  Future<V> get(K key);

  /// Override this method to setup any background tasks required.
  ///
  /// If you are using a third-party package, you can retrieve the package
  /// async instance here.
  ///
  /// If you are using your own [MethodChannel] you can instantiate it here.
  Future<void> setup();

  /// Release any resource (if any) created by the [setup] method.
  Future<void> dispose();
}

@Singleton(as: KeyValueStorage<String, String?>)
class SharedPreferencesStorage extends KeyValueStorage<String, String?> {
  late SharedPreferences _sharedPreferences;

  @postConstruct
  @override
  Future<void> setup() async {
    _sharedPreferences = await SharedPreferences.getInstance();
  }

  @disposeMethod
  @override
  Future<void> dispose() async {}

  @override
  Future<String?> get(String key) async {
    return _sharedPreferences.getString(key);
  }

  @override
  Future<Set<String>> get keys async => _sharedPreferences.getKeys();

  @override
  Future<MapEntry<String, String>?> set(String key, String? value) async {
    if (value == null) return null;

    await _sharedPreferences.setString(key, value);

    return MapEntry<String, String>(key, value);
  }
}
