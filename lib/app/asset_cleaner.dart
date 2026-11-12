import 'package:asset_doctor/app/models/clean_result.dart';
import 'package:asset_doctor/data/file_system_client.dart';
import 'package:asset_doctor/ui/console.dart';
import 'package:asset_doctor/ui/tree.dart';
import 'package:path/path.dart' as p;

class AssetCleaner {
  AssetCleaner({
    required this.allAssets,
    required this.usedAssets,
    required this.fs,
    String? projectRoot,
    List<String>? ignoredDirs,
    Console? console,
    TreePrinter? tree,
  }) {
    this.projectRoot = projectRoot ?? fs.currentDir;
    this.ignoredDirs = ignoredDirs ?? ['test', 'build'];
    this.console = console ?? Console();
    this.tree = tree ?? TreePrinter();
  }

  final Set<String> allAssets;
  final Set<String> usedAssets;
  final FileSystemClient fs;

  late final String projectRoot;
  late final Console console;
  late final TreePrinter tree;
  late final List<String> ignoredDirs; // Folders to ignore during code search

  CleanResult? _result;
  CleanResult? get result => _result;

  CleanResult analyze() {
    final usedAssetPaths = usedAssets;
    final potentialUnusedPaths = allAssets.difference(usedAssetPaths).toList()
      ..sort();
    List<String> unusedAssetsForDeletion = <String>[]; // Use List for indexing
    final localizationAssetsExcluded = <String>[];
    double spaceBeforeClean = 0;

    for (final assetPath in potentialUnusedPaths) {
      final path = p.join(projectRoot, assetPath);
      bool isJson = assetPath.toLowerCase().endsWith('.json');
      bool isNonEmpty = false;
      try {
        if (fs.fileExists(path)) {
          final size = fs.lengthSync(path);
          isNonEmpty = size > 0;
          spaceBeforeClean += size;
        }
      } catch (e) {
        console.printWarning('Could not check size of "$assetPath": $e');
        isJson = false;
      }

      if (isJson && isNonEmpty) {
        localizationAssetsExcluded.add(assetPath);
      } else {
        unusedAssetsForDeletion.add(assetPath);
      }
    }

    final unusedTree = tree.build(unusedAssetsForDeletion);
    final excludedTree = tree.build(localizationAssetsExcluded);

    _result = CleanResult(
        allAssets: allAssets,
        usedAssets: usedAssetPaths,
        unusedAssetsForDeletion: unusedAssetsForDeletion,
        unusedTree: unusedTree,
        excludedTree: excludedTree,
        spaceOfUnusedAssetsBeforeClean: spaceBeforeClean,
        spaceOfUnusedAssetsAfterClean: spaceBeforeClean,
        hasAnalyzed: true,
        hasCleaned: false);

    return _result!;
  }

  Future<CleanResult?> clean() async {
    if (_result == null || _result?.hasAnalyzed == false) {
      console.printError('Run analysis before cleaning');
      return null;
    }

    final curResult = _result!;

    if (curResult.unusedAssetsForDeletion.isNotEmpty) {
      console.printInfo('Marking all unused assets for deletion...');
    }

    String? finalConfirm;
    double freeSpace = 0;
    console.printInfo(
        '\nFINAL CONFIRMATION: You are about to delete ${curResult.unusedAssetsForDeletion.length} asset(s).');
    console.write('Proceed with deletion? (Y/N): ');
    finalConfirm = console.read();
    if ((finalConfirm != null &&
        (finalConfirm.toLowerCase() == 'y' ||
            finalConfirm.toLowerCase() == 'yes'))) {
      await console.printLoading<void>(
          message:
              '\nDeleting ${curResult.unusedAssetsForDeletion.length} assets',
          work: () async {
            final freedSpace =
                deleteUnusedAssets(curResult.unusedAssetsForDeletion);
            freeSpace += freedSpace;
            console.printSuccess(
                '🎉 You have freed up ${freedSpace.toStringAsFixed(2)} MB of space.');
          });
    } else {
      console.printError('Deletion cancelled by user.');
      _result = curResult.copyWith(hasCleaned: false);
      return _result;
    }

    // space after should be zero
    _result = curResult.copyWith(
        spaceAfterClean: _result!.spaceOfUnusedAssetsAfterClean - freeSpace,
        hasCleaned: true);

    return _result;
  }

  double deleteUnusedAssets(List<String> unusedAssets) {
    double totalSizeMB = 0;
    for (var assetRelativePath in unusedAssets) {
      final path = p.join(projectRoot, assetRelativePath);
      if (!fs.fileExists(path)) {
        console.printWarning(
            'File not found, skipping deletion: "$assetRelativePath"');
        continue;
      }
      try {
        final fileSize = fs.lengthSync(path);
        totalSizeMB += fileSize / (1024 * 1024);
        fs.deleteSync(path);
        console.printSuccess('Deleted: $assetRelativePath');
      } catch (e) {
        console.printError('Could not delete "$assetRelativePath": $e');
      }
    }
    return totalSizeMB;
  }
}
