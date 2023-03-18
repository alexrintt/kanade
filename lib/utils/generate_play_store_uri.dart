Uri generatePlayStoreUriFromPackageName(String packageName) {
  final Uri base = Uri.parse('https://play.google.com/store/apps/details');

  return base.replace(
    queryParameters: <String, dynamic>{
      ...base.queryParametersAll,
      'id': packageName,
    },
  );
}
