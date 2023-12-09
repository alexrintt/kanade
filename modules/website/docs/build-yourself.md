
Flutter has a [great documentation](https://docs.flutter.dev/get-started/install) in case you don't have a configured Flutter environment yet.

### 1. Get deps and generate l10n local library

To get app dependencies:

```shell
flutter pub get
```

To run the code generation (that generates the `flutter_gen` library used for i18n features):

```shell
flutter gen-l10n

# Use nodemon if you are developing (watch for changes).
# https://www.npmjs.com/package/nodemon
nodemon --watch i18n --ext arb --exec "flutter gen-l10n"
```

### 2. Generate binaries

If you're looking for the apk:

```shell
flutter build apk
# or specific-abis
flutter build apk --split-per-abi
```

You can also generate the app bundle:

```shell
flutter build appbundle
```
