import 'package:flutter/material.dart';

const double kDefaultIconSize = 24;

enum AppIcons {
  browser(Icons.open_in_browser),
  playStore(Icons.play_arrow_outlined),
  search(Icons.search),
  checkboxSelected(Icons.check_box),
  checkboxUnselected(Icons.check_box_outline_blank),
  apk(Icons.file_download_outlined),
  android(Icons.android),
  name(Icons.abc),
  clipboard(Icons.content_copy_outlined),
  styling(Icons.color_lens_outlined),
  language(Icons.language),
  apps(Icons.dashboard_outlined),
  share(Icons.share_outlined),
  folder(Icons.folder_copy_outlined),
  settings(Icons.settings_outlined),
  reset(Icons.restore_outlined),
  delete(Icons.delete_outline_outlined),
  more(Icons.more_vert),
  arrowLeft(Icons.arrow_back_outlined),
  arrowRight(Icons.arrow_forward_outlined),
  chevronLeft(Icons.chevron_left_outlined),
  chevronRight(Icons.chevron_right_outlined),
  fontFamily(Icons.font_download_outlined),
  checkmark(Icons.check),
  download(Icons.download_outlined),
  x(Icons.close_outlined),
  arrowDown(Icons.arrow_downward_outlined),
  externalLink(Icons.open_in_new_outlined);

  // ignore: unused_element
  const AppIcons(this.data, [this.size = kDefaultSize]);

  final IconData data;
  final double size;

  static const double kDefaultSize = kDefaultIconSize;
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
