import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:shared_storage/saf.dart';

import '../utils/app_icons.dart';
import 'app_list_tile.dart';

class PackageImageBytes extends StatefulWidget {
  const PackageImageBytes({super.key, required this.icon});

  final Uint8List? icon;

  @override
  State<PackageImageBytes> createState() => _PackageImageBytesState();
}

class _PackageImageBytesState extends State<PackageImageBytes> {
  bool get _hasIcon => widget.icon != null;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: kLeadingSize.width,
      height: kLeadingSize.height,
      child: Center(
        child: _hasIcon
            ? Image.memory(
                widget.icon!,
                errorBuilder: (_, __, ___) =>
                    Icon(AppIcons.apk.data, size: AppIcons.apk.size),
              )
            : Icon(AppIcons.apk.data, size: AppIcons.apk.size),
      ),
    );
  }
}

class PackageImageUri extends StatefulWidget {
  const PackageImageUri({super.key, this.uri, this.fetchThumbnail = false});

  final Uri? uri;
  final bool fetchThumbnail;

  @override
  State<PackageImageUri> createState() => _PackageImageUriState();
}

class _PackageImageUriState extends State<PackageImageUri> {
  Widget _buildImageLoadingIconPlaceholder() {
    return AspectRatio(
      aspectRatio: 1,
      child: Icon(AppIcons.apk.data, size: AppIcons.apk.size),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.uri == null) {
      return Center(child: _buildImageLoadingIconPlaceholder());
    }

    return ImageUri(
      fetchThumbnail: widget.fetchThumbnail,
      uri: widget.uri!,
      error: Icon(AppIcons.apk.data, size: AppIcons.apk.size),
      loading: _buildImageLoadingIconPlaceholder(),
    );
  }
}

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
