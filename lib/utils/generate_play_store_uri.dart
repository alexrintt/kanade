Uri generatePlayStoreUriFromPackageId(String packageId) {
  final Uri base = Uri.parse('https://play.google.com/store/apps/details');

  return base.replace(
    queryParameters: <String, dynamic>{
      ...base.queryParametersAll,
      'id': packageId,
    },
  );
}

Uri generateFDroidUriFromPackageId(String packageId) {
  final Uri base = Uri.parse('https://f-droid.org/');

  return base.replace(
    pathSegments: <String>['packages', packageId],
  );
}

Uri generateDuckDuckGoUriFromQuery(String query) {
  final Uri searchUri = Uri.parse('https://duckduckgo.com/')
      .replace(query: 'q=${Uri.encodeComponent(query)}');

  return searchUri;
}
