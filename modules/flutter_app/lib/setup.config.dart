// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i1;
import 'package:injectable/injectable.dart' as _i2;
import 'package:kanade/stores/background_task_store.dart' as _i11;
import 'package:kanade/stores/bottom_navigation_store.dart' as _i3;
import 'package:kanade/stores/contextual_menu_store.dart' as _i4;
import 'package:kanade/stores/device_apps_store.dart' as _i5;
import 'package:kanade/stores/file_list_store.dart' as _i12;
import 'package:kanade/stores/global_file_change_store.dart' as _i6;
import 'package:kanade/stores/key_value_storage.dart' as _i7;
import 'package:kanade/stores/localization_store.dart' as _i8;
import 'package:kanade/stores/settings_store.dart' as _i9;
import 'package:kanade/stores/theme_store.dart' as _i10;

extension GetItInjectableX on _i1.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  Future<_i1.GetIt> init({
    String? environment,
    _i2.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i2.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    gh.singleton<_i3.BottomNavigationStore>(_i3.BottomNavigationStore());
    gh.factory<_i4.ContextualMenuStore>(() => _i4.ContextualMenuStore());
    gh.singleton<_i5.DeviceAppsStore>(_i5.DeviceAppsStore());
    await gh.singletonAsync<_i6.GlobalFileChangeStore>(
      () {
        final i = _i6.GlobalFileChangeStore();
        return i.load().then((_) => i);
      },
      preResolve: true,
    );
    await gh.singletonAsync<_i7.KeyValueStorage<String, String?>>(
      () {
        final i = _i7.SharedPreferencesStorage();
        return i.setup().then((_) => i);
      },
      preResolve: true,
      dispose: (i) => i.dispose(),
    );
    await gh.singletonAsync<_i8.LocalizationStore>(
      () {
        final i = _i8.LocalizationStore();
        return i.load().then((_) => i);
      },
      preResolve: true,
    );
    await gh.singletonAsync<_i9.SettingsStore>(
      () {
        final i = _i9.SettingsStore();
        return i.load().then((_) => i);
      },
      preResolve: true,
    );
    await gh.factoryAsync<_i10.ThemeStore>(
      () {
        final i = _i10.ThemeStore();
        return i.load().then((_) => i);
      },
      preResolve: true,
    );
    await gh.singletonAsync<_i11.BackgroundTaskStore>(
      () {
        final i = _i11.BackgroundTaskStore(
            bottomNavigationStore: gh<_i3.BottomNavigationStore>());
        return i.load().then((_) => i);
      },
      preResolve: true,
    );
    await gh.singletonAsync<_i12.FileListStore>(
      () {
        final i = _i12.FileListStore(settingsStore: gh<_i9.SettingsStore>());
        return i.load().then((_) => i);
      },
      preResolve: true,
    );
    return this;
  }
}
