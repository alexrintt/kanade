import 'package:kanade/utils/apply_if_not_null.dart';

String? stringifyTreeUri(Uri? location) {
  return location?.apply(
    (uri) => Uri.decodeComponent(
      uri.pathSegments
          .skip(1)
          .join(), // Uris looks like: '/tree/primary:Downloads/Folder' so we skip the '/tree' path segment
    ),
  );
}

String? stringifyDocumentUri(Uri? location) {
  return location?.apply(
    (uri) => Uri.decodeComponent(
      uri.pathSegments.skipWhile((path) => path != 'document').skip(1).join(),
    ),
  );
}
