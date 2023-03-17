import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:shared_storage/saf.dart';

class ImageUri extends StatefulWidget {
  const ImageUri({
    super.key,
    required this.uri,
    required this.loading,
    required this.error,
    this.fetchThumbnail = false,
  });

  final Uri uri;
  final Widget loading;
  final Widget error;
  final bool fetchThumbnail;

  @override
  State<ImageUri> createState() => _ImageUriState();
}

class _ImageUriState extends State<ImageUri> {
  late Future<Uint8List?> _bitmap;

  @override
  void initState() {
    super.initState();

    _initBitmapFuture();
  }

  @override
  void didUpdateWidget(covariant ImageUri oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.uri != widget.uri ||
        oldWidget.fetchThumbnail != widget.fetchThumbnail) {
      _initBitmapFuture();
    }
  }

  void _initBitmapFuture() {
    _bitmap = widget.fetchThumbnail
        ? _getDocumentThumbnail()
        : getDocumentContent(widget.uri);
  }

  Future<Uint8List?> _getDocumentThumbnail() async {
    return getDocumentContent(widget.uri);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _bitmap,
      builder: (BuildContext context, AsyncSnapshot<Uint8List?> snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
          case ConnectionState.waiting:
          case ConnectionState.active:
            return widget.loading;
          case ConnectionState.done:
            if (snapshot.hasData) {
              return Image.memory(
                snapshot.data!,
                errorBuilder: (_, __, ___) => widget.error,
              );
            } else {
              return widget.error;
            }
        }
      },
    );
  }
}
