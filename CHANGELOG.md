## 0.3.2

Behavior changes on home and search page.

### Behavior changes

- On start the app there is a throttling being applied to the render process which makes the app fps smoothier.
- Search page has now a debounce applied (of 50ms) to improve performance.
- The search algorithm is now using a [string_similarity](https://pub.dev/packages/string_similarity) algorithm to rank and display best results.

## 0.3.1

This released was focused in adding internationalization features to the app, following languages were added:

- German (de).
- Portuguese (pt-BR).
- Japanese (ja).
- Spanish (es).
- (Previously supported) English (en).

### New

- Settings:
  - Added location settings tile.
  - Added Zen Kaku Gothic Antique (Yoshimichi Ohira) font.
  - Minimal UI changes (Section title and horizontal rule).

## 0.3.0

Most release changes are related to UI and design stuff, minimal changes to core behavior of the apk extraction process.

UI/UX improvements:

### New

- Settings:

  - It now supports multiple themes (see `README.md` for screenshots):

    - Dark dimmed (default when system in dark mode): theme was available in the previous versions.
    - Light (default when system in light mode): ~~lazy~~ basic light theme.
    - Dark lights out: ~~best~~ high-contrast dark theme.
    - Dark hacker: high-contrast dark mode with green as primary color.
    - Dark blood: high-contrast dark mode with red as primary color.
    - Follow system: follows native system color scheme, dark dimmed if in dark mode, light otherwise.

  - Support for multiple font families:

    - [Inconsolata](https://fonts.google.com/specimen/Inconsolata) (default).
    - [Roboto Mono](https://fonts.google.com/specimen/Roboto+Mono).

  - It now display app version code and name

- Homepage:

  - Apk/package tiles are now transparent and have no more touch boundaries (implicitly added before through padding).
  - The repository link button was removed from app bar.
  - Theme button was added to the app bar.

- Homepage and loading:

  - Replaced gif and app bar with a minimal logo animation written using `FFF Forward` font.

### Behavior changes

- When in selection or search mode, on tap back (through arrow back or native device buttons) it now redirects to the previous state instead popping to the homepage directly.

### Bug fixes

- Fix crash when trying to export to a folder that no longer exists (probably was deleted through the system file manager or a third-party app). It now prompt the user to select a new location.

## 0.2.1

- Update app version ID and set `versionCode` to `2`.
- Remove legacy app id and use the new one, so the app will be installed as duplicated, you can just uninstall the old one.

## 0.2.0-alpha

Privacy and performance were improved:

- Migration to Storage Access Framework (`MANAGE_EXTERNAL_STORAGE` permission is no longer required, see [#9](https://github.com/alexrintt/kanade/issues/9)).
- Re-implemented [`device_apps`](https://github.com/alexrintt/flutter_plugin_device_apps) plugin to support apps lazy loading (There's no more 5/10 seconds of loading screen).

## 0.1.0-alpha

Initial release, supported features:

- Extract single or multiple apks.
- Search packages.
