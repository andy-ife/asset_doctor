// Credits: https://github.com/ahmedelmwafy/flutter_assets_cleaner
// Code modified and adapted

import 'dart:io';
import 'package:asset_doctor/utils/file_helper.dart';
import 'package:asset_doctor/utils/ui.dart';
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
      final childPrefix = prefix + (isLastEntry ? '    ' : '│   ');
      printDefault('$prefix$entityPrefix$key');
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

  Set<String> findAllStringLiteralsInCode(Directory dir, String projectRoot) =>
      FileHelper.findAllStringLiteralsInCode(dir, projectRoot, ignoredDirs);

  void displayResults(Set<String> allAssets, List<String> usedAssets,
      Map<String, dynamic> unusedTree, Map<String, dynamic> excludedTree) {
    printInfo('\n--Asset Usage Analysis--');
    printInfo(
        '\nPotentially Used assets (Found in assets/ and path/name found as a string somewhere in the code):');
    if (usedAssets.isNotEmpty) {
      for (var asset in usedAssets) {
        printDefault('• $asset');
      }
    } else {
      printDefault('None found.');
    }
    printInfo(
        '\nExcluded assets (Found in assets/ and appear unused, but are non-empty JSON files):');
    if (excludedTree.isNotEmpty) {
      printTree(excludedTree, '', true);
    } else {
      printDefault('None found.');
    }
    printWarning('\n❌ Unused assets MARKED FOR DELETION:');
    int totalUnusedForDeletion = countFilesInTree(unusedTree);
    if (totalUnusedForDeletion > 0) {
      printWarning('($totalUnusedForDeletion files)');
      printTree(unusedTree, '', true);
    } else {
      printDefault('  None found');
    }
    final totalAssetsInDir = allAssets.length;
    final totalUsedAssets = usedAssets.length;
    int totalLocalizationExcluded = countFilesInTree(excludedTree);
    final totalUnused = totalUnusedForDeletion + totalLocalizationExcluded;
    printInfo('\nSummary:');
    print('• Total assets (excluding hidden): $totalAssetsInDir');
    print('• Potentially Used assets: $totalUsedAssets');
    print('• Unused assets (Total): $totalUnused');
    print('  • Excluded (e.g., non-empty JSON): $totalLocalizationExcluded');
    print('  • Marked for deletion: $totalUnusedForDeletion');
    if (totalAssetsInDir > 0) {
      print(
          '• Percentage used: ${((totalUsedAssets / totalAssetsInDir) * 100).toStringAsFixed(2)}%');
      print(
          '• Percentage unused (for deletion): ${((totalUnusedForDeletion / totalAssetsInDir) * 100).toStringAsFixed(2)}%');
    }
    print('---------------------------');
  }

  Future<double> deleteUnusedAssets(List<String> unusedAssets) async {
    double totalSizeMB = 0;
    for (var assetRelativePath in unusedAssets) {
      final file = File(p.join(projectRoot, assetRelativePath));
      if (!file.existsSync()) {
        printWarning('File not found, skipping deletion: "$assetRelativePath"');
        continue;
      }
      try {
        final fileSize = await file.length();
        totalSizeMB += fileSize / (1024 * 1024);
        await file.delete();
        printSuccess('Deleted: $assetRelativePath');
      } catch (e) {
        printError('Could not delete "$assetRelativePath": $e');
      }
    }
    return totalSizeMB;
  }
}
