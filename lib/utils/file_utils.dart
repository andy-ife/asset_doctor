import 'dart:io';

import 'package:asset_doctor/utils/ui.dart';
import 'package:path/path.dart' as p;

enum Platform { assets, android, ios, macos, windows, linux }

class FileUtils {
  static const Map<Platform, List<String>> commonAssetLocations = {
    Platform.assets: ['assets', 'fonts', 'font'],
    Platform.android: ['android/app/src/main/res'],
    Platform.ios: ['ios/Runner/Assets.xcassets', 'ios/Runner/Fonts'],
    Platform.macos: ['macos/Runner/Assets.xcassets', 'macos/Runner/Fonts'],
    Platform.windows: ['windows/runner/resources', 'windows/runner/fonts'],
    Platform.linux: ['linux/runner/resources', 'linux/runner/fonts']
  };

  /// Find all files in a directory
  static Set<String> findAllInDirectory(String projectRoot, Directory dir) {
    final files = <String>{};
    if (!dir.existsSync()) {
      Ui.printWarning('Assets directory not found at ${dir.path}');
      return files;
    }
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
      Ui.printError('Error listing files in ${dir.path}: $e');
    }
    if (files.isEmpty) {
      Ui.printWarning(
          'No files found in the assets directory ${dir.path} (Excluding hidden files)');
    } else {
      Ui.printInfo('\nFound ${files.length} files in the assets directory.');
    }
    return files;
  }

  /// Find all files from a set of directories
  static Set<String> findAllInDirectories(
      String projectRoot, List<Directory> directories) {
    final result = <String>{};
    for (var dir in directories) {
      result.addAll(findAllInDirectory(projectRoot, dir));
    }
    return result;
  }

  /// Find all string literals used in source code
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
        Ui.printError('Error reading file ${file.path}: $e');
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
        Ui.printError('Error traversing directory ${dir.path}: $e');
      }
    } else {
      Ui.printError('Lib directory not found at ${dir.path}');
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
      Ui.printError('Error listing files in ${dir.path}: $e');
    }
    return files;
  }
}
