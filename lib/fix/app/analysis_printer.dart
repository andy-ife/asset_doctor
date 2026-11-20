import 'package:app_size_doctor/fix/app/models/clean_result.dart';
import 'package:app_size_doctor/fix/app/models/compress_result.dart';
import 'package:app_size_doctor/fix/data/file_system_client.dart';
import 'package:app_size_doctor/fix/ui/console.dart';
import 'package:app_size_doctor/fix/ui/extension.dart';
import 'package:app_size_doctor/fix/ui/tree.dart';
import 'package:path/path.dart' as p;

class AnalysisPrinter {
  AnalysisPrinter(
      {required this.usedAssets,
      required this.pubspecAssets,
      required this.fs,
      String? projectRoot,
      Console? console,
      TreePrinter? tree})
      : projectRoot = projectRoot ?? fs.currentDir,
        console = console ?? Console(),
        tree = tree ?? TreePrinter();

  final Set<String> usedAssets;
  final List<String> pubspecAssets;
  final FileSystemClient fs;

  late final String projectRoot;
  late final Console console;
  late final TreePrinter tree;

  void printCleanAnalysis(CleanResult result) {
    console.printHeader('Asset Usage Analysis');

    console.printSubHeader(
        'Potentially Used assets (Their path/name was found as a string literal somewhere in the code):',
        nl: false);
    if (result.usedAssets.isNotEmpty) {
      console.printInfo('(${result.usedAssets.length} files)');
      console.printMatrix(result.usedAssets);
    } else {
      console.printInfo('None found.');
    }

    console.printSubHeader(
      'Excluded assets (e.g unused JSON files):',
    );
    if (result.excludedTree.isNotEmpty) {
      tree.print(paths: result.excludedTree, prefix: '');
    } else {
      console.printInfo('None found.');
    }

    console.printWarning('\n🗑️  Unused assets MARKED FOR DELETION:');
    int totalUnusedForDeletion = countFilesInTree(result.unusedTree);
    if (totalUnusedForDeletion > 0) {
      console.printWarning('($totalUnusedForDeletion files)');
      tree.print(
        paths: result.unusedTree,
        prefix: '',
      );
    } else {
      console.printInfo('  None found');
    }

    final totalAssetsInDir = result.allAssets.length;
    final totalUsedAssets = result.usedAssets.length;
    int totalLocalizationExcluded = countFilesInTree(result.excludedTree);
    final totalUnused = totalUnusedForDeletion + totalLocalizationExcluded;
    console.printSubHeader('Pre-deletion Summary:');

    console.printInfo(
      '• Total assets (excluding hidden): ${totalAssetsInDir.toString()}',
    );

    console.printInfo(
      '• Potentially Used assets: ${totalUsedAssets.toString()}',
    );

    console.printInfo(
      '• Unused assets (Total): ${totalUnused.toString()}',
    );

    console.printInfo(
      '  - Excluded (e.g., unused JSON): ${totalLocalizationExcluded.toString()}',
    );

    console.printInfo(
      '  - Marked for deletion: ${totalUnusedForDeletion.toString()}',
    );

    if (totalAssetsInDir > 0) {
      console.printInfo(
        '• Percentage used: ${((totalUsedAssets / totalAssetsInDir) * 100).toStringAsFixed(1)}%',
      );

      console.printInfo(
        '• Percentage unused (for deletion): ${((totalUnusedForDeletion / totalAssetsInDir) * 100).toStringAsFixed(1)}%',
      );
    }

    console.printWarning(
        '\n• Potential space saved: ${result.potentiallySavedSpace.toStorageString()}');
  }

  void printCompressAnalysis(CompressResult result) {
    console.printHeader('Asset Compression Analysis');

    console.printSubHeader(
        'Potentially Used assets (Found in assets/ and path/name found as a string somewhere in the code):',
        nl: false);
    if (result.usedAssets.isNotEmpty) {
      console.printInfo('(${result.usedAssets.length} files)');
      console.printMatrix(result.usedAssets);
    } else {
      console.printInfo('None found.');
    }

    console.printWarning(
        '\n🔨 Assets MARKED FOR COMPRESSION (Potentiallyy Used assets only):');
    if (result.assetsForCompression.isNotEmpty) {
      console.printWarning('(${result.assetsForCompression.length} files)');
      tree.print(paths: result.assetsForCompressionTree, prefix: '');
    } else {
      console.printInfo('  None found.');
    }

    final selectedAssets = result.assetsForCompression.toSet();
    final totalAssets = result.usedAssets.length;
    final totalForCompression = selectedAssets.length;
    final totalNotSelected =
        result.usedAssets.difference(selectedAssets).length;

    console.printSubHeader('Pre-compression Summary:');
    console.printInfo(
      '• Total assets (excluding hidden): ${totalAssets.toString()}',
    );

    console.printInfo(
      '• Assets marked for compression: ${totalForCompression.toString()}',
    );

    console.printInfo(
      '• Assets not selected for compression: ${totalNotSelected.toString()}',
    );

    if (totalAssets > 0) {
      console.printInfo(
        '• Percentage selected for compression: ${((totalForCompression / totalAssets) * 100).toStringAsFixed(1)}%',
      );
    }

    console.printSuccess(
        '\n• Estimated space to be saved: ${result.potentiallySavedSpace.toStorageString()}');
  }

  /// Summarize what cleaning and compression would free up without
  /// changing any files. Meant to be more concise than the full
  /// [printCleanAnalysis] and [printCompressAnalysis] breakdowns.
  void printDryRunAnalysis(
      CleanResult cleanResult, CompressResult compressResult) {
    console.printHeader('Dry Run Analysis');
    console.printInfo(
        'No files were changed. Here is what Asset Doctor could free up:');

    final totalForDeletion = cleanResult.unusedAssetsForDeletion.length;
    final totalExcluded = countFilesInTree(cleanResult.excludedTree);
    final totalForCompression = compressResult.assetsForCompression.length;

    if (totalForDeletion == 0 && totalForCompression == 0) {
      if (totalExcluded > 0) {
        console.printSuccess('\n✨ Nothing to delete or compress.');
        console.printInfo(
          '• Unused but excluded from deletion (e.g., non-empty JSON): ${totalExcluded.toString()} ',
        );
      } else {
        console.printSuccess(
            '\n✨ Nothing to delete or compress. Your project is already lean.');
      }
      return;
    }

    console.printSubHeader('🗑️  Cleaning');
    if (totalForDeletion == 0) {
      console.printInfo('  Nothing to delete.');
    } else {
      console.printInfo(
        '• Assets marked for deletion: ${totalForDeletion.toString()}',
      );
      console.printInfo(
        '• Potential savings: ${cleanResult.potentiallySavedSpace.toStorageString()}',
      );
    }
    if (totalExcluded > 0) {
      console.printInfo(
        '• Excluded (e.g., non-empty JSON): ${totalExcluded.toString()}',
      );
    }

    console.printSubHeader('🔨 Compression');
    if (totalForCompression == 0) {
      console.printInfo('  Nothing to compress.');
    } else {
      console.printInfo(
        '• Assets marked for compression: ${totalForCompression.toString()}',
      );
      console.printInfo(
        '• Total media assets size: ${compressResult.spaceOfMediaAssetsBeforeCompress.toStorageString()}',
      );
      console.printInfo(
        '• Estimated savings: ${compressResult.potentiallySavedSpace.toStorageString()}',
      );
    }

    final totalPotentialSavings = cleanResult.potentiallySavedSpace +
        compressResult.potentiallySavedSpace;
    console.printSubHeader('Total Potential Savings:');
    console.printInfo(
        '• Estimated total savings: ${totalPotentialSavings.toStorageString()}');
    console.printInfo(
        '\nRun again without --dry-run to view detailed file trees and apply these changes.');
  }

  void printPubspecAnalysis() {
    console.printInfo('\nChecking pubspec.yaml for any skipped assets...');

    final declaredAssetsInPubspec =
        pubspecAssets.where((e) => fs.isFile(e) || fs.isDirectory(e));

    if (declaredAssetsInPubspec.isNotEmpty) {
      final unusedDeclaredAssets =
          getUsedInAButNotB(declaredAssetsInPubspec, usedAssets)..sort();
      console.printHeader('pubspec.yaml Analysis');
      console.printInfo(
          'Found ${declaredAssetsInPubspec.length} assets declared in pubspec.yaml');
      if (unusedDeclaredAssets.isNotEmpty) {
        console.printSubHeader(
          '${unusedDeclaredAssets.length} declared assets were found in the assets section but not referenced in code:',
        );
        for (var asset in unusedDeclaredAssets) {
          console.printInfo('• $asset');
        }
      } else {
        console.printInfo(
            'All declared assets in pubspec.yaml seem to be referenced.');
      }
      final undeclaredUsedAssets =
          getUsedInAButNotB(usedAssets, declaredAssetsInPubspec)..sort();
      if (undeclaredUsedAssets.isNotEmpty) {
        console.printSubHeader(
            '${undeclaredUsedAssets.length} files in assets/ were used but *not* declared in pubspec.yaml:');
        for (var asset in undeclaredUsedAssets) {
          console.printInfo('• $asset');
        }
        console.printInfo(
            '\nTip: Consider declaring used assets in pubspec.yaml under the `assets:` section.');
      }
      console.printDivider();
    } else {
      console.printInfo('None found');
    }
  }

  /// Get folders referenced in a but not in b
  /// Handles sub folders, partial path
  List<String> getUsedInAButNotB(Iterable<String> a, Iterable<String> b) {
    return a.where((assetPath) {
      final relativePath =
          p.relative(assetPath, from: projectRoot).replaceAll('\\', '/');
      final dirs = p.split(relativePath);

      // generate all possible subdirs
      final subdirs = <String>{};
      for (var i = 0; i < dirs.length; i++) {
        for (var j = i; j < dirs.length; j++) {
          if (j == i) {
            subdirs.add(dirs[j]);
          } else {
            subdirs.add('/${dirs.sublist(i, j).join('/')}');
          }
        }
      }
      // check if any of the subdirs are contained in pubspec
      return subdirs
          .every((subdir) => !b.any((bPath) => bPath.contains(subdir)));
    }).toList();
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
    final hasCleaned = cleanResult != null &&
        cleanResult.hasCleaned &&
        cleanResult.spaceOfUnusedAssetsAfterClean != null;
    final hasCompressed = compressResult != null &&
        compressResult.hasCompressed &&
        compressResult.spaceOfMediaAssetsAfterCompress != null;

    if (hasCleaned) {
      console.printSuccess(
          "\nSpace taken by unused assets before: ${cleanResult.spaceOfUnusedAssetsBeforeClean.to1dp.toStorageString()}");
      console.printSuccess(
          "After cleaning: ${cleanResult.spaceOfUnusedAssetsAfterClean!.to1dp.toStorageString()}");
      console.printSuccess(
          "Saved: ${(cleanResult.spaceOfUnusedAssetsBeforeClean - cleanResult.spaceOfUnusedAssetsAfterClean!).to1dp.toStorageString()}");
    }

    if (hasCompressed) {
      console.printSuccess(
          "\nSpace taken by media assets before: ${compressResult.spaceOfMediaAssetsBeforeCompress.to1dp.toStorageString()}");
      console.printSuccess(
          'After compression: ${compressResult.spaceOfMediaAssetsAfterCompress!.to1dp.toStorageString()}');
      console.printSuccess(
          'Saved: ${(compressResult.spaceOfMediaAssetsBeforeCompress - compressResult.spaceOfMediaAssetsAfterCompress!).to1dp.toStorageString()}');
    }

    if (hasCleaned && hasCompressed) {
      final totalFreed = (cleanResult.spaceOfUnusedAssetsBeforeClean -
              cleanResult.spaceOfUnusedAssetsAfterClean!) +
          (compressResult.spaceOfMediaAssetsBeforeCompress -
              compressResult.spaceOfMediaAssetsAfterCompress!);

      console
          .printSuccess('\nTotal space freed: ${totalFreed.toStorageString()}');
    }
  }
}
