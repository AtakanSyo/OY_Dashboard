import 'dart:io';

import 'package:oy_site/models/session_scan_assets.dart';

class SessionScanAssetsParser {
  const SessionScanAssetsParser();

  SessionScanAssets parseFolder(String folderPath) {
    final dir = Directory(folderPath);

    if (!dir.existsSync()) {
      return SessionScanAssets(folderPath: folderPath);
    }

    final files = dir
        .listSync()
        .whereType<File>()
        .toList();

    String? archLeftPath;
    String? archRightPath;
    String? archSectionLeftPath;
    String? archSectionRightPath;
    String? foot2dLeftPath;
    String? foot2dRightPath;
    String? pronatorLeftPath;
    String? pronatorRightPath;
    String? stlLeftPath;
    String? stlRightPath;

    for (final file in files) {
      final name = file.uri.pathSegments.last.toLowerCase();
      final path = file.path;

      if (name == 'arch_l.bmp') {
        archLeftPath = path;
        continue;
      }

      if (name == 'arch_r.bmp') {
        archRightPath = path;
        continue;
      }

      if (name == 'archsectv_l.bmp') {
        archSectionLeftPath = path;
        continue;
      }

      if (name == 'archsectv_r.bmp') {
        archSectionRightPath = path;
        continue;
      }

      if (name == 'foot3d_l.bmp') {
        foot2dLeftPath = path;
        continue;
      }

      if (name == 'foot3d_r.bmp') {
        foot2dRightPath = path;
        continue;
      }

      if (name == 'pronatorl-line.bmp') {
        pronatorLeftPath = path;
        continue;
      }

      if (name == 'pronatorr-line.bmp') {
        pronatorRightPath = path;
        continue;
      }

      if (name.endsWith('_l.stl')) {
        stlLeftPath ??= path;
        continue;
      }

      if (name.endsWith('_r.stl')) {
        stlRightPath ??= path;
        continue;
      }
    }

    return SessionScanAssets(
      folderPath: folderPath,
      archLeftPath: archLeftPath,
      archRightPath: archRightPath,
      archSectionLeftPath: archSectionLeftPath,
      archSectionRightPath: archSectionRightPath,
      foot2dLeftPath: foot2dLeftPath,
      foot2dRightPath: foot2dRightPath,
      pronatorLeftPath: pronatorLeftPath,
      pronatorRightPath: pronatorRightPath,
      stlLeftPath: stlLeftPath,
      stlRightPath: stlRightPath,
    );
  }
}