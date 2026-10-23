import 'dart:io';

import 'package:path/path.dart' as p;

class FileHelper {
  static Set<String> findAllFilesInAssets(String projectRoot, Directory dir) {
    final files = <String>{};
    if (!dir.existsSync()) return files;
    try {
      for (var entity in dir.listSync(recursive: true)) {
        if (entity is File) {
          if (!p.basename(entity.path).startsWith('.')) {
            files.add(p
                .relative(entity.path, from: projectRoot)
                .replaceAll('\\', '/'));
          }
        }
      }
    } catch (e) {
      print('⚠️ Error listing files in ${dir.path}: $e');
    }
    return files;
  }

  static List<String> extractAssetsFromPubspec(
      String pubspecPath, String projectRoot) {
    final pubspec = File(pubspecPath);
    if (!pubspec.existsSync()) {
      return [];
    }
    final content = pubspec.readAsStringSync();
    final assetRegex = RegExp(r'assets:\s*((?:\s+-\s+.+\n)+)', multiLine: true);
    final match = assetRegex.firstMatch(content);
    if (match == null) return [];
    final assetLines = match
        .group(1)!
        .split('\n')
        .where((line) => line.trim().startsWith('-'))
        .map(
          (line) => line
              .trim()
              .substring(1)
              .trim()
              .replaceAll("'", '')
              .replaceAll('"', ''),
        )
        .toList();
    final assets = <String>[];
    for (var declaration in assetLines) {
      final fullPath = p.join(projectRoot, declaration);
      final file = File(fullPath);
      final dir = Directory(fullPath);
      if (file.existsSync()) {
        assets.add(
          p.relative(file.path, from: projectRoot).replaceAll('\\', '/'),
        );
      } else if (dir.existsSync()) {
        final filesInDir = _getFilesRecursivelyRelative(dir, projectRoot);
        assets.addAll(filesInDir);
      } else {
        // Could not access declared asset
      }
    }
    return assets;
  }

  static List<String> _getFilesRecursivelyRelative(
      Directory dir, String projectRoot) {
    final files = <String>[];
    if (!dir.existsSync()) return files;
    try {
      for (var entity in dir.listSync(recursive: true)) {
        if (entity is File) {
          files.add(
              p.relative(entity.path, from: projectRoot).replaceAll('\\', '/'));
        }
      }
    } catch (e) {
      print('⚠️ Error listing files in ${dir.path}: $e');
    }
    return files;
  }
}
