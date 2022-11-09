## 0.2.1

- Update app version ID to `versionCode: 2`.
- Remove legacy app id and use the new one, so the app will be installed as duplicated, you can just uninstall the old one.

## 0.2.0-alpha

Privacy and performance were improved:

- Migration to Storage Access Framework (`MANAGE_EXTERNAL_STORAGE` permission is no longer required, see [#9](https://github.com/alexrintt/kanade/issues/9)).
- Re-implemented [`device_apps`](https://github.com/alexrintt/flutter_plugin_device_apps) plugin to support apps lazy loading (There's no more 5/10 seconds of loading screen).

## 0.1.0-alpha

Initial release, supported features:

- Extract single or multiple apks.
- Search packages.
