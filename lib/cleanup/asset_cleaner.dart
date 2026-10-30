// Credits: https://github.com/ahmedelmwafy/flutter_assets_cleaner
// Code modified and adapted

import 'dart:io';
import 'package:asset_doctor/utils/ui.dart';
import 'package:path/path.dart' as p;

class AssetCleaner {
  AssetCleaner({
    String? projectRoot,
    List<String>? ignoredDirs,
  }) {
    this.projectRoot = projectRoot ?? Directory.current.path;
    this.ignoredDirs = ignoredDirs ?? ['test', 'build'];
  }

  late final String projectRoot;
  late final List<String> ignoredDirs; // Folders to ignore during code search

  void displayResults(Set<String> allAssets, List<String> usedAssets,
      Map<String, dynamic> unusedTree, Map<String, dynamic> excludedTree) {
    Ui.printInfo('\n--Asset Usage Analysis--');
    Ui.printInfo(
        '\nPotentially Used assets (Found in assets/ and path/name found as a string somewhere in the code):');
    if (usedAssets.isNotEmpty) {
      for (var asset in usedAssets) {
        Ui.printDefault('• $asset');
      }
    } else {
      Ui.printDefault('None found.');
    }
    Ui.printInfo(
        '\nExcluded assets (Found in assets/ and appear unused, but are non-empty JSON files):');
    if (excludedTree.isNotEmpty) {
      Ui.printTree(excludedTree, '', true);
    } else {
      Ui.printDefault('None found.');
    }
    Ui.printWarning('\n❌ Unused assets MARKED FOR DELETION:');
    int totalUnusedForDeletion = countFilesInTree(unusedTree);
    if (totalUnusedForDeletion > 0) {
      Ui.printWarning('($totalUnusedForDeletion files)');
      Ui.printTree(unusedTree, '', true);
    } else {
      Ui.printDefault('  None found');
    }
    final totalAssetsInDir = allAssets.length;
    final totalUsedAssets = usedAssets.length;
    int totalLocalizationExcluded = countFilesInTree(excludedTree);
    final totalUnused = totalUnusedForDeletion + totalLocalizationExcluded;
    Ui.printInfo('\nSummary:');
    Ui.printInfo('• Total assets (excluding hidden): $totalAssetsInDir');
    Ui.printInfo('• Potentially Used assets: $totalUsedAssets');
    Ui.printInfo('• Unused assets (Total): $totalUnused');
    Ui.printInfo(
        '  • Excluded (e.g., non-empty JSON): $totalLocalizationExcluded');
    Ui.printInfo('  • Marked for deletion: $totalUnusedForDeletion');
    if (totalAssetsInDir > 0) {
      Ui.printInfo(
          '• Percentage used: ${((totalUsedAssets / totalAssetsInDir) * 100).toStringAsFixed(2)}%');
      Ui.printInfo(
          '• Percentage unused (for deletion): ${((totalUnusedForDeletion / totalAssetsInDir) * 100).toStringAsFixed(2)}%');
    }
    Ui.printInfo('---------------------------');
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

  Future<double> deleteUnusedAssets(List<String> unusedAssets) async {
    double totalSizeMB = 0;
    for (var assetRelativePath in unusedAssets) {
      final file = File(p.join(projectRoot, assetRelativePath));
      if (!file.existsSync()) {
        Ui.printWarning(
            'File not found, skipping deletion: "$assetRelativePath"');
        continue;
      }
      try {
        final fileSize = await file.length();
        totalSizeMB += fileSize / (1024 * 1024);
        await file.delete();
        Ui.printSuccess('Deleted: $assetRelativePath');
      } catch (e) {
        Ui.printError('Could not delete "$assetRelativePath": $e');
      }
    }
    return totalSizeMB;
  }
}
