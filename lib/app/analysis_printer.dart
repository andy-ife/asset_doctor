import 'package:asset_doctor/app/models/clean_result.dart';
import 'package:asset_doctor/app/models/compress_result.dart';
import 'package:asset_doctor/data/file_system_client.dart';
import 'package:asset_doctor/ui/console.dart';
import 'package:asset_doctor/ui/extension.dart';
import 'package:asset_doctor/ui/tree.dart';

class AnalysisPrinter {
  AnalysisPrinter(
      {required this.usedAssets,
      required this.pubspecAssets,
      required this.fs,
      Console? console,
      TreePrinter? tree})
      : console = console ?? const Console(),
        tree = tree ?? TreePrinter();

  final Set<String> usedAssets;
  final List<String> pubspecAssets;
  final FileSystemClient fs;

  late final Console console;
  late final TreePrinter tree;

  void printCleanAnalysis(CleanResult result) {
    console.printInfo('\n--Asset Usage Analysis--');
    console.printInfo(
        '\nPotentially Used assets (Found in assets/ and path/name found as a string somewhere in the code):');
    if (result.usedAssets.isNotEmpty) {
      for (var asset in result.usedAssets) {
        console.printDefault('• $asset');
      }
    } else {
      console.printDefault('None found.');
    }
    console.printInfo(
        '\nExcluded assets (Found in assets/ and appear unused, but are non-empty JSON files):');
    if (result.excludedTree.isNotEmpty) {
      tree.print(paths: result.excludedTree, prefix: '');
    } else {
      console.printDefault('None found.');
    }
    console.printWarning('\n❌ Unused assets MARKED FOR DELETION:');
    int totalUnusedForDeletion = countFilesInTree(result.unusedTree);
    if (totalUnusedForDeletion > 0) {
      console.printWarning('($totalUnusedForDeletion files)');
      tree.print(
        paths: result.unusedTree,
        prefix: '',
      );
    } else {
      console.printDefault('  None found');
    }
    final totalAssetsInDir = result.allAssets.length;
    final totalUsedAssets = result.usedAssets.length;
    int totalLocalizationExcluded = countFilesInTree(result.excludedTree);
    final totalUnused = totalUnusedForDeletion + totalLocalizationExcluded;
    console.printInfo('\nSummary:');
    console.printInfo('• Total assets (excluding hidden): $totalAssetsInDir');
    console.printInfo('• Potentially Used assets: $totalUsedAssets');
    console.printInfo('• Unused assets (Total): $totalUnused');
    console.printInfo(
        '  • Excluded (e.g., non-empty JSON): $totalLocalizationExcluded');
    console.printInfo('  • Marked for deletion: $totalUnusedForDeletion');
    if (totalAssetsInDir > 0) {
      console.printInfo(
          '• Percentage used: ${((totalUsedAssets / totalAssetsInDir) * 100).toStringAsFixed(2)}%');
      console.printInfo(
          '• Percentage unused (for deletion): ${((totalUnusedForDeletion / totalAssetsInDir) * 100).toStringAsFixed(2)}%');
    }
    console.printInfo('---------------------------');
  }

  void printCompressAnalysis(CompressResult result) {
    console.printInfo('\n--Asset Compression Analysis--');
    console.printWarning('\nAssets MARKED FOR COMPRESSION:');
    if (result.assetsForCompression.isNotEmpty) {
      console.printWarning('(${result.assetsForCompression.length} files)');
      tree.print(paths: result.assetsForCompressionTree, prefix: '');
    } else {
      console.printDefault('  None found.');
    }

    final selectedAssets = result.assetsForCompression.toSet();
    final totalAssets = result.usedAssets.length;
    final totalForCompression = selectedAssets.length;
    final totalNotSelected =
        result.usedAssets.difference(selectedAssets).length;

    console.printInfo('\nSummary:');
    console.printInfo('• Total assets (excluding hidden): $totalAssets');
    console.printInfo('• Assets marked for compression: $totalForCompression');
    console
        .printInfo('• Assets not selected for compression: $totalNotSelected');
    if (totalAssets > 0) {
      console.printInfo(
          '• Percentage selected for compression: ${((totalForCompression / totalAssets) * 100).toStringAsFixed(2)}%');
    }
    console.printInfo('---------------------------');
  }

  void printPubspecAnalysis() {
    console.printInfo('Checking pubspec.yaml for any skipped assets...');

    final declaredAssetsInPubspec =
        pubspecAssets.where((e) => fs.isFile(e) || fs.isDirectory(e));

    if (declaredAssetsInPubspec.isNotEmpty) {
      final unusedDeclaredAssets = declaredAssetsInPubspec
          .where((assetPath) => !usedAssets.contains(assetPath))
          .toList()
        ..sort();
      console.printInfo('\n--- Pubspec.yaml Info ---');
      console.printInfo(
          'Found ${declaredAssetsInPubspec.length} assets declared in pubspec.yaml');
      if (unusedDeclaredAssets.isNotEmpty) {
        console.printInfo(
            '${unusedDeclaredAssets.length} declared assets were found in assets/ but not referenced in code');
        for (var asset in unusedDeclaredAssets) {
          console.printInfo('- $asset');
        }
      } else {
        console.printInfo(
            'All declared assets in pubspec.yaml appear to be referenced.');
      }
      final undeclaredUsedAssets = usedAssets
          .where((assetPath) => !declaredAssetsInPubspec.contains(assetPath))
          .toList()
        ..sort();
      if (undeclaredUsedAssets.isNotEmpty) {
        console.printInfo(
            '${undeclaredUsedAssets.length} files in assets/ were used but *not* declared in pubspec.yaml:');
        for (var asset in undeclaredUsedAssets) {
          console.printInfo('- $asset');
        }
        console.printInfo(
            '💡 Tip: Consider declaring used assets in pubspec.yaml under the `assets:` section.');
      }
      console.printInfo('-------------------------');
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

  void printWorkSummary(
      CleanResult? cleanResult, CompressResult? compressResult) {
    // Round to 2 d.p
    final beforeCleaning = cleanResult == null
        ? null
        : (cleanResult.spaceOfUnusedAssetsBeforeClean * 100).round() / 100;

    final afterCleaning = cleanResult == null
        ? null
        : (cleanResult.spaceOfUnusedAssetsAfterClean * 100).round() / 100;

    final beforeCompression = compressResult == null
        ? null
        : (compressResult.spaceOfMediaAssetsBeforeCompress * 100).round() / 100;

    final afterCompression = compressResult == null
        ? null
        : (compressResult.spaceOfMediaAssetsAfterCompress * 100).round() / 100;

    console.printSuccess("Woohoo! You've saved some major space!");

    if (cleanResult != null) {
      console.printSuccess(
          "\nSpace taken by unused assets before: ${beforeCleaning!.toStorageString()}");

      console
          .printSuccess("After cleaning: ${afterCleaning!.toStorageString()}");
      console.printSuccess(
          "Saved: ${(beforeCleaning - afterCleaning).toStorageString()}");
    }

    if (compressResult != null) {
      console.printSuccess(
          "\nSpace taken by media assets before: ${beforeCompression!.toStorageString()}");
      console.printSuccess(
          'After compression: ${afterCompression!.toStorageString()}');
      console.printSuccess(
          'Saved: ${(beforeCompression - afterCompression).toStorageString()}');
    }

    if (cleanResult != null && compressResult != null) {
      final totalFreed = (beforeCleaning! - afterCleaning!) +
          (beforeCompression! - afterCompression!);

      final totalBefore = beforeCleaning + beforeCompression;

      console
          .printSuccess('Total space freed: ${totalFreed.toStorageString()}');

      console.printSuccess(
          'Percentage freed: ${((totalFreed) / totalBefore) * 100}');
    }
  }
}
