import 'dart:collection';
import 'dart:convert';
import 'dart:io';

final Directory i18nDir = Directory('i18n');

void main() {
  i18nDir.listSync().whereType<File>().forEach((File file) {
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

    final SplayTreeMap<String, dynamic> orderedRes =
        SplayTreeMap<String, dynamic>.from(
      res,
      (String a, String z) => a.compareTo(z),
    );

    file.writeAsStringSync(getPrettyJSONString(orderedRes));
  });
}

String getPrettyJSONString(Object? jsonObject) {
  const JsonEncoder encoder = JsonEncoder.withIndent('  ');
  return encoder.convert(jsonObject);
}
