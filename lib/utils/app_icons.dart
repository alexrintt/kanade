import 'package:flutter/material.dart';
import 'package:flutter_octicons/flutter_octicons.dart';

const double kDefaultIconSize = 18;

enum AppIcons {
  playStore(Icons.play_arrow_outlined, 26),
  search(OctIcons.search_16),
  checkboxSelected(OctIcons.check_circle_fill_16),
  checkboxUnselected(OctIcons.circle_16),
  apk(OctIcons.file_zip_16),
  styling(OctIcons.paintbrush_16),
  language(OctIcons.globe_16),
  apps(OctIcons.apps_16),
  share(OctIcons.share_android_16),
  folder(OctIcons.file_directory_16),
  settings(OctIcons.gear_16),
  reset(OctIcons.sync_16),
  delete(OctIcons.trash_16),
  more(Icons.more_vert, 26),
  arrowLeft(OctIcons.chevron_left_16),
  arrowRight(OctIcons.chevron_right_16),
  fontFamily(OctIcons.italic_16),
  checkmark(OctIcons.check_16),
  download(OctIcons.download_16),
  x(OctIcons.x_16),
  arrowDown(OctIcons.arrow_down_16),
  externalLink(OctIcons.link_external_16);

  const AppIcons(this.data, [this.size = kDefaultSize]);

  final IconData data;
  final double size;

  static const double kDefaultSize = 18.0;
}

// class AppIcons {
//   static IconData playStore = Icons.play_arrow_outlined;

//   static IconData search = OctIcons.search_16;
//   static IconData checkboxSelected = OctIcons.check_circle_fill_16;
//   static IconData checkboxUnselected = OctIcons.circle_16;
//   static IconData apk = OctIcons.file_zip_16;
//   static IconData styling = OctIcons.paintbrush_16;
//   static IconData language = OctIcons.globe_16;
//   static IconData apps = OctIcons.apps_16;
//   static IconData share = OctIcons.share_android_16;
//   static IconData folder = OctIcons.file_directory_16;
//   static IconData settings = OctIcons.gear_16;
//   static IconData reset = OctIcons.sync_16;
//   static IconData delete = OctIcons.trash_16;
//   static IconData more = Icons.more_vert;
//   static IconData arrowLeft = OctIcons.chevron_left_16;
//   static IconData arrowRight = OctIcons.chevron_right_16;
//   static IconData fontFamily = OctIcons.italic_16;
//   static IconData checkmark = OctIcons.check_16;
//   static IconData download = OctIcons.download_16;
//   static IconData x = OctIcons.x_16;
//   static IconData arrowDown = OctIcons.arrow_down_16;
//   static IconData externalLink = OctIcons.link_external_16;
// }
