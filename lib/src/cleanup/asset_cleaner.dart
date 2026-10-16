// Credits: https://github.com/ahmedelmwafy/flutter_assets_cleaner
// Code modified and adapted

import 'dart:io';
import 'package:path/path.dart' as p;
import 'dart:collection'; // Import for SplayTreeMap

class AssetCleaner {
  AssetCleaner({
    String? projectRoot,
    String? pubspecPath,
    Directory? libDir,
    Directory? assetsDir,
    List<String>? ignoredDirs,
  }) {
    this.projectRoot = projectRoot ?? Directory.current.path;
    this.pubspecPath = pubspecPath ?? p.join(this.projectRoot, 'pubspec.yaml');
    this.libDir = libDir ?? Directory(p.join(this.projectRoot, 'lib'));
    this.assetsDir = assetsDir ?? Directory(p.join(this.projectRoot, 'assets'));
    this.ignoredDirs = ignoredDirs ?? ['test', 'build'];
  }

  late final String projectRoot;
  late final String pubspecPath;
  late final Directory libDir;
  late final Directory assetsDir;
  late final List<String> ignoredDirs; // Folders to ignore during code search

  Map<String, dynamic> buildTree(List<String> paths) {
    Map<String, dynamic> root = SplayTreeMap<String, dynamic>();
    for (var path in paths) {
      final parts = p.split(path);
      Map<String, dynamic> currentNode = root;
      for (var i = 0; i < parts.length; i++) {
        final part = parts[i];
        if (i == parts.length - 1) {
          currentNode[part] = true;
        } else {
          currentNode.putIfAbsent(part, () => SplayTreeMap<String, dynamic>());
          currentNode = currentNode[part];
        }
      }
    }
    return root;
  }

  void printTree(Map<String, dynamic> node, String prefix, bool isLast) {
    final keys = node.keys.toList();
    for (var i = 0; i < keys.length; i++) {
      final key = keys[i];
      final isLastEntry = (i == keys.length - 1);
      final entityPrefix = isLastEntry ? '└── ' : '├── ';
      final childPrefix = prefix + (isLast ? '    ' : '│   ');
      print('$prefix$entityPrefix$key');
      if (node[key] is Map) {
        printTree(node[key], childPrefix, isLastEntry);
      }
    }
  }

  int countFilesInTree(Map<String, dynamic> node) {
    int count = 0;
    for (final key in node.keys) {
      if (node[key] is Map) {
        count += countFilesInTree(node[key]);
      } else {
        count++;
      }
    }
    return count;
  }

  Set<String> findAllStringLiteralsInCode(Directory dir, String projectRoot) {
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
          String? normalized = normalizeStringLiteral(literal);
          if (normalized != null && normalized.isNotEmpty) {
            allNormalizedLiterals.add(normalized);
          }
        }
      } catch (e) {
        print('⚠️ Error reading file ${file.path}: $e');
      }
    }

    if (dir.existsSync()) {
      try {
        for (var entity in dir.listSync(recursive: true)) {
          if (entity is File &&
              entity.path.endsWith('.dart') &&
              !shouldIgnore(entity)) {
            checkFile(entity);
          }
        }
      } catch (e) {
        print('⚠️ Error traversing directory ${dir.path}: $e');
      }
    } else {
      print('⚠️ Lib directory not found at ${dir.path}');
    }
    return allNormalizedLiterals;
  }

  String? normalizeStringLiteral(String literal) {
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

  bool shouldIgnore(File file) {
    final filePath = file.path.replaceAll('\\', '/');
    final rootPath = projectRoot.replaceAll('\\', '/');
    return ignoredDirs.any((dir) {
      final ignoredPath = p.join(rootPath, dir).replaceAll('\\', '/');
      return filePath.contains(ignoredPath);
    });
  }

  void displayResults(Set<String> allAssets, List<String> usedAssets,
      Map<String, dynamic> unusedTree, Map<String, dynamic> excludedTree) {
    print('\n--- Asset Usage Analysis ---');
    print(
        '\n✅ Potentially Used assets (Found in assets/ and path/name found as substring in code strings):');
    if (usedAssets.isNotEmpty) {
      for (var asset in usedAssets) {
        print('- $asset');
      }
    } else {
      print('  None found.');
    }
    print(
        '\n➡️ Excluded assets (Found in assets/ and appear unused, but are non-empty JSON files):');
    if (excludedTree.isNotEmpty) {
      printTree(excludedTree, '', true);
    } else {
      print('  None found.');
    }
    print('\n❌ Unused assets MARKED FOR DELETION:');
    int totalUnusedForDeletion = countFilesInTree(unusedTree);
    if (totalUnusedForDeletion > 0) {
      print('($totalUnusedForDeletion files listed below)');
      printTree(unusedTree, '', true);
    } else {
      print('  None found. 🎉');
    }
    final totalAssetsInDir = allAssets.length;
    final totalUsedAssets = usedAssets.length;
    int totalLocalizationExcluded = countFilesInTree(excludedTree);
    final totalUnused = totalUnusedForDeletion + totalLocalizationExcluded;
    print('\n📊 Summary:');
    print(
        '- Total files found in assets/ directory (excluding hidden): $totalAssetsInDir');
    print(
        '- Files in assets/ potentially referenced in code: $totalUsedAssets');
    print('- Files in assets/ appearing unused (Total): $totalUnused');
    print('  - Excluded (e.g., non-empty JSON): $totalLocalizationExcluded');
    print('  - Marked for deletion: $totalUnusedForDeletion');
    if (totalAssetsInDir > 0) {
      print(
          '- Percentage used: ${((totalUsedAssets / totalAssetsInDir) * 100).toStringAsFixed(2)}%');
      print(
          '- Percentage unused (for deletion): ${((totalUnusedForDeletion / totalAssetsInDir) * 100).toStringAsFixed(2)}%');
    }
    print('---------------------------');
  }

  Future<double> deleteUnusedAssets(List<String> unusedAssets) async {
    double totalSizeMB = 0;
    for (var assetRelativePath in unusedAssets) {
      final file = File(p.join(projectRoot, assetRelativePath));
      if (!file.existsSync()) {
        print('⚠️ File not found, skipping deletion: "$assetRelativePath"');
        continue;
      }
      try {
        final fileSize = await file.length();
        totalSizeMB += fileSize / (1024 * 1024);
        await file.delete();
        print('🗑️ Deleted: $assetRelativePath');
      } catch (e) {
        print('⚠️ Could not delete "$assetRelativePath": $e');
      }
    }
    return totalSizeMB;
  }
}
