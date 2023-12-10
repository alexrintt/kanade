import 'dart:collection';
import 'dart:convert';
import 'dart:io';

void sortI18nKeys(Directory directory) {
  directory.listSync().whereType<File>().forEach((File file) {
    final String content = file.readAsStringSync();
    late final Map<String, dynamic> res;

    try {
      res = Map<String, dynamic>.from(
        jsonDecode(content) as Map<dynamic, dynamic>,
      );
    } on FormatException catch (e) {
      throw Exception(
        'Tried to decode ${file.absolute.path} but got a FormatException: $e',
      );
    }

    final actualKeys = res.keys
        .where((key) => key.startsWithAlphaNumeric)
        .toList()
      ..sort((String a, String z) => a.compareTo(z));

    final sortedKeysWithItsMetadata = [
      for (final actualKey in actualKeys) ...[actualKey, '@$actualKey'],
    ];

    final otherMetaKeys = res.keys
        .where((key) => !sortedKeysWithItsMetadata.contains(key))
        .toList();

    final finalSortedKeys = [
      ...otherMetaKeys,
      ...sortedKeysWithItsMetadata,
    ];

    final SplayTreeMap<String, dynamic> orderedRes =
        SplayTreeMap<String, dynamic>.from(
      res,
      (String a, String b) =>
          finalSortedKeys.indexOf(a).compareTo(finalSortedKeys.indexOf(b)),
    );

    file.writeAsStringSync(getPrettyJSONString(orderedRes));
  });
}

String getPrettyJSONString(Object? jsonObject) {
  const JsonEncoder encoder = JsonEncoder.withIndent('  ');
  return encoder.convert(jsonObject);
}

extension StartsWithAlphaNumeric on String {
  bool get startsWithAlphaNumeric {
    final RegExp alphaNumeric = RegExp(r'^[a-zA-Z0-9]');
    return alphaNumeric.hasMatch(this);
  }
}
