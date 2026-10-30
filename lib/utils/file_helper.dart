import 'dart:io';

import 'package:asset_doctor/model/asset_file.dart';
import 'package:asset_doctor/utils/ui.dart';
import 'package:path/path.dart' as p;

enum Platform { assets, assetsVariant, android, ios, macos, windows, linux }

class FileHelper {
  static const Map<Platform, String> commonAssetLocations = {
    Platform.assets: 'assets',
    Platform.android: 'android/app/src/main/res',
    Platform.ios: 'ios/Runner/Assets.xcassets',
    Platform.macos: 'macos/Runner/Assets.xcassets',
    Platform.windows: 'windows/runner/resources',
    Platform.linux: 'linux/runner/resources'
  };

  static const Map<Platform, String> commonFontLocations = {
    Platform.assets: 'fonts',
    Platform.assetsVariant: 'font',
    Platform.ios: 'ios/Runner/Fonts',
    Platform.macos: 'macos/Runner/Fonts',
    Platform.windows: 'windows/runner/fonts',
    Platform.linux: 'linux/runner/fonts'
  };

  static Set<String> findAllFilesInDirectory(
      String projectRoot, Directory dir) {
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
      printError('Error listing files in ${dir.path}: $e');
    }
    return files;
  }

  static Set<String> findAllFilesInCommonAssetLocations(String projectRoot) {
    final files = <String>{};
    for (var dir in commonAssetLocations.values) {
      final safeDir = Directory(p.join(projectRoot, dir));
      try {
        if (!safeDir.existsSync()) continue;
        files.addAll(findAllFilesInDirectory(projectRoot, safeDir));
      } catch (e) {
        printError('Error listing files in ${safeDir.path}: $e');
      }
    }
    return files;
  }

  static Set<String> findAllStringLiteralsInCode(
      Directory dir, String projectRoot, List<String> ignoredDirs) {
    final allNormalizedLiterals = <String>{};
    final stringLiteralRegex = RegExp(
        '\'(?:[^\\\'\\\\]|\\\\.)*\\\'|\\"(?:[^\\"\\\\]|\\\\.)*\\"|r\'[^\\\']*\\\'|r"[^\\"]*\\""',
        multiLine: true);
    void checkFile(File file) {
      try {
        final content = file.readAsStringSync();
        final matches = stringLiteralRegex.allMatches(content);
        for (var match in matches) {
          String literal = match.group(0)!;
          String? normalized = _normalizeStringLiteral(literal);
          if (normalized != null && normalized.isNotEmpty) {
            allNormalizedLiterals.add(normalized);
          }
        }
      } catch (e) {
        printError('Error reading file ${file.path}: $e');
      }
    }

    if (dir.existsSync()) {
      try {
        for (var entity in dir.listSync(recursive: true)) {
          if (entity is File &&
              entity.path.endsWith('.dart') &&
              !_shouldIgnore(entity, projectRoot, ignoredDirs)) {
            checkFile(entity);
          }
        }
      } catch (e) {
        printError('Error traversing directory ${dir.path}: $e');
      }
    } else {
      printError('Lib directory not found at ${dir.path}');
    }
    return allNormalizedLiterals;
  }

  static String? _normalizeStringLiteral(String literal) {
    if (literal.isEmpty) return null;
    String? content;
    if (literal.startsWith('r')) {
      if (literal.length >= 3) {
        content = literal.substring(2, literal.length - 1);
      }
    } else if ((literal.startsWith("'") && literal.endsWith("'")) ||
        (literal.startsWith('"') && literal.endsWith('"'))) {
      if (literal.length >= 2) {
        content = literal.substring(1, literal.length - 1);
      }
    }
    return content?.trim();
  }

  static bool _shouldIgnore(
      File file, String projectRoot, List<String> ignoredDirs) {
    final filePath = file.path.replaceAll('\\', '/');
    final rootPath = projectRoot.replaceAll('\\', '/');
    return ignoredDirs.any((dir) {
      final ignoredPath = p.join(rootPath, dir).replaceAll('\\', '/');
      return filePath.contains(ignoredPath);
    });
  }

  static double calculateTotalFileSize(List<File> files) {
    return files.fold(0, (sum, curFile) {
      return curFile.existsSync() ? sum + curFile.lengthSync() : sum;
    });
  }

  static double calculateTotalAssetsSize(List<AssetFile?> files) {
    return files.fold(0, (sum, curFile) {
      return sum + (curFile?.newSize ?? 0);
    });
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
      printError('Error listing files in ${dir.path}: $e');
    }
    return files;
  }
}
