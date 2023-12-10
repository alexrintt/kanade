import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:auto_translate_dart/sort_i18n_keys.dart';
import 'package:deeptc/deeptc.dart';
import 'package:path/path.dart';
import 'package:yaml/yaml.dart';

final String thisScriptPath = File.fromUri(Platform.script).absolute.path;
final String thisScriptParentDir = Directory(thisScriptPath).parent.path;
final String flutterI18nConfig = normalize(
  join(
    dirname(thisScriptParentDir),
    '..',
    '..',
    'flutter_app',
    'l10n.yaml',
  ),
);

final String configFilePath = flutterI18nConfig;

Future<void> main() async {
  print('Loading config from $configFilePath');

  final File configFile = File(configFilePath);
  final String configContents = await configFile.readAsString();
  final Map<String, dynamic> config =
      json.decode(json.encode(loadYaml(configContents)));

  final String templateArbFileName = config['template-arb-file'];
  final String arbDirPath =
      normalize(join(dirname(flutterI18nConfig), config['arb-dir']));

  final String arbTemplateFilePath =
      normalize(File(join(arbDirPath, templateArbFileName)).absolute.path);

  final Map<String, dynamic> baseI18nData =
      readJsonFileAsMap(arbTemplateFilePath);

  void setNestedValue(
    Map<dynamic, dynamic> nestedDict,
    dynamic value,
    List<String> keys,
  ) {
    final String key = keys[0];

    if (keys.length == 1) {
      nestedDict[key] = value;
    } else {
      if (!nestedDict.containsKey(key)) {
        nestedDict[key] = {};
      }
      setNestedValue(
        nestedDict[key],
        value,
        keys.sublist(1),
      );
    }
  }

  void writeJsonToFile(String filePath, Map<String, dynamic> data) {
    final File file = File(filePath);
    final JsonEncoder encoder = JsonEncoder.withIndent('  ');
    file.writeAsStringSync(encoder.convert(data), mode: FileMode.write);
  }

  int cached = 0;
  int nonCached = 0;
  int removed = 0;

  await for (var entity in Directory(arbDirPath).list(recursive: true)) {
    if (entity is! File) {
      return;
    }

    final String fileName = entity.uri.pathSegments.last;

    if (fileName == templateArbFileName) {
      continue;
    }

    String getFileNameWithoutExt(String fileName) {
      final splittedByDots = fileName.split('.');
      return splittedByDots.sublist(0, splittedByDots.length - 1).join('.');
    }

    final String targetLangFilePath = entity.path;
    final String targetLangFileBaseName =
        File(targetLangFilePath).uri.pathSegments.last;
    final String targetLangFileNameWithoutExt = getFileNameWithoutExt(
        File(targetLangFileBaseName).uri.pathSegments.last);

    Map<String, dynamic> targetLangFileData =
        readJsonFileAsMapOrNull(targetLangFilePath) ?? <String, dynamic>{};

    final String? jsonDefinedLocale = targetLangFileData['@@locale'];
    final String targetLangFileLocale = targetLangFileNameWithoutExt;

    final String targetLocale = jsonDefinedLocale ?? targetLangFileLocale;

    if (jsonDefinedLocale == null) {
      targetLangFileData['@@locale'] = targetLocale;
      writeJsonToFile(targetLangFilePath, targetLangFileData);
    }

    List<String> unusedKeys = targetLangFileData.keys
        .where((key) => !baseI18nData.containsKey(key))
        .toList();

    for (String unusedKey in unusedKeys) {
      if (isReservedKey(unusedKey)) {
        continue;
      }
      removed += 1;
      print('Removing key $unusedKey');
      targetLangFileData.remove(unusedKey);
    }

    writeJsonToFile(targetLangFilePath, targetLangFileData);

    for (final MapEntry(key: baseLangKey, value: baseLangSourceValue)
        in baseI18nData.entries) {
      if (isReservedKey(baseLangKey)) {
        continue;
      }

      print('Key: $baseLangKey');
      print('Lang: $targetLocale');
      print('Original: $baseLangSourceValue');

      String? getCurrentAssetDefinedTranslation() {
        final bool hasTranslation =
            targetLangFileData.containsKey(baseLangKey) &&
                targetLangFileData[baseLangKey] != null;

        final String? baseLangCachedSourceValue =
            targetLangFileData['@$baseLangKey']?['info']?['source'];

        final bool sameSourceValue =
            hasTranslation && baseLangSourceValue == baseLangCachedSourceValue;

        if (sameSourceValue) {
          return targetLangFileData[baseLangKey];
        } else {
          return null;
        }
      }

      String normalizeCase(String translated, String source) {
        if (startLower(source) != startLower(translated)) {
          if (startLower(source)) {
            return firstLower(translated);
          } else {
            return firstUpper(translated);
          }
        }

        return translated;
      }

      List<Function> transformFunctions = [normalizeCase];

      String? translated;
      bool fromCache = false;

      final String? cachedTranslated = getCurrentAssetDefinedTranslation();
      if (cachedTranslated != null) {
        cached += 1;
        translated = cachedTranslated;
        fromCache = true;
      } else {
        try {
          nonCached += 1;
          translated = await translate(
            baseLangSourceValue,
            to: targetLocale,
            from: 'en',
          );
        } catch (e) {
          print('Failed to load translation for $baseLangKey ($targetLocale)');
          print('Translated: null');
        }
      }

      if (translated != null) {
        for (Function transform in transformFunctions) {
          translated = transform(translated!, baseLangSourceValue);
        }
      }

      if (translated == null) {
        print('Translated: [Translation not available, skipping...]');
      } else {
        if (fromCache) {
          print('Translated (cached): $translated');
        } else {
          print('Translated: $translated');
        }
      }

      targetLangFileData[baseLangKey] = translated;
      setNestedValue(
        targetLangFileData,
        baseLangSourceValue,
        ['@$baseLangKey', 'info', 'source'],
      );

      bool cacheChanged = fromCache && cachedTranslated != translated;
      bool fromNetwork = !fromCache;

      if (cacheChanged || fromNetwork) {
        writeJsonToFile(targetLangFilePath, targetLangFileData);
      }

      print('-' * 30);
    }

    writeJsonToFile(targetLangFilePath, targetLangFileData);

    print('*' * 30);
    print('Finished translating to $targetLocale');
    print('*' * 30);
  }

  sortI18nKeys(Directory(arbDirPath));

  print('=' * 30);
  print('Loaded $nonCached non-cached results');
  print('Loaded $cached cached results');
  print('Removed $removed unused translation keys');
  print('=' * 30);
}

Map<String, dynamic> loadYaml(String yamlString) {
  final dynamic yamlMap = loadYamlDocument(yamlString).contents;
  return Map<String, dynamic>.from(yamlMap);
}

Map<String, dynamic> readJsonFileAsMap(String filePath) {
  final File file = File(filePath);
  final String fileContents = file.readAsStringSync();
  return json.decode(json.encode(json.decode(fileContents)));
}

Map<String, dynamic>? readJsonFileAsMapOrNull(String filePath) {
  try {
    return readJsonFileAsMap(filePath);
  } catch (e) {
    return null;
  }
}

bool isReservedKey(String key) {
  List<String> reservedPrefixes = ['_', '@'];
  for (String prefix in reservedPrefixes) {
    if (key.startsWith(prefix)) {
      return true;
    }
  }
  return false;
}

bool startLower(String s) {
  if (s.isEmpty) {
    return false;
  }
  return s[0] == s[0].toLowerCase();
}

String firstUpper(String s) {
  if (s.isEmpty) {
    return s;
  }
  return s[0].toUpperCase() + s.substring(1);
}

String firstLower(String s) {
  if (s.isEmpty) {
    return s;
  }
  return s[0].toLowerCase() + s.substring(1);
}
