import 'package:app_size_doctor/fix/app/models/clean_result.dart';
import 'package:app_size_doctor/fix/data/file_system_client.dart';
import 'package:app_size_doctor/fix/ui/console.dart';
import 'package:app_size_doctor/fix/ui/extension.dart';
import 'package:app_size_doctor/fix/ui/tree.dart';
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
    double spaceOfUnusedAssetsBeforeClean = 0;
    double potentiallySavedSpace = 0;

    for (final assetPath in potentialUnusedPaths) {
      final path = p.join(projectRoot, assetPath);
      bool isJson = assetPath.toLowerCase().endsWith('.json');
      bool isNonEmpty = false;
      double fileSize = 0;
      try {
        if (fs.fileExists(path)) {
          fileSize = fs.lengthSync(path).toDouble();
          isNonEmpty = fileSize > 0;
          spaceOfUnusedAssetsBeforeClean += fileSize;
        }
      } catch (e) {
        console.printWarning('Could not check size of "$assetPath": $e');
        isJson = false;
      }

      if (isJson && isNonEmpty) {
        localizationAssetsExcluded.add(assetPath);
      } else {
        unusedAssetsForDeletion.add(assetPath);
        potentiallySavedSpace += fileSize;
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
        spaceOfUnusedAssetsBeforeClean: spaceOfUnusedAssetsBeforeClean,
        potentiallySavedSpace: potentiallySavedSpace,
        spaceOfUnusedAssetsAfterClean: null,
        hasAnalyzed: true,
        hasCleaned: false);

    return _result!;
  }

  Future<CleanResult?> clean() async {
    if (_result == null || _result?.hasAnalyzed == false) {
      console.printError('Run analysis before cleaning');
      return null;
    }

    var curResult = _result!;

    if (curResult.unusedAssetsForDeletion.isNotEmpty) {
      String? shouldKeepSome;
      int? totalUnused;
      console.printInfo(
          '\n${curResult.unusedAssetsForDeletion.length} assets are marked for deletion. ');
      console.printInputPrompt(
          'Select some assets to keep (remove from deletion list)? (Y/N): ');
      do {
        shouldKeepSome = console.read();
        if (shouldKeepSome.isYes) {
          final toDelete = curResult.unusedAssetsForDeletion;

          final indexes = console.printMultiSelect(
              message: '(Press <space> to select, <enter> to confirm)',
              options: toDelete);

          final toKeep = toDelete.indexed
              .where((e) => indexes.contains(e.$1))
              .map((e) => e.$2);

          totalUnused = toDelete.length;
          curResult = curResult.copyWith(
              unusedAssetsForDeletion:
                  toDelete.where((e) => !toKeep.contains(e)).toList());
        } else if (shouldKeepSome.isNo) {
          // do nothing. Continue code
        } else {
          console.printError('Invalid option. Please enter "y" or "n"');
        }
      } while (!shouldKeepSome.isYesOrNo);

      if (curResult.unusedAssetsForDeletion.isNotEmpty) {
        console.printWarning(
            '\nMarking ${shouldKeepSome.isYes ? '${curResult.unusedAssetsForDeletion.length}/$totalUnused' : 'all'} unused assets for deletion...');
      } else {
        console.printSuccess("\n✨ Nothing to clean. Keeping all assets");
        return curResult;
      }
    } else {
      console.printSuccess("\n✨ Nothing to clean. No unused assets found");
      return curResult;
    }

    String? finalConfirm;
    double freedSpace = 0;
    console.printInfo(
        '\nFINAL CONFIRMATION: You are about to delete ${curResult.unusedAssetsForDeletion.length} asset(s).');
    do {
      console.printInputPrompt('Proceed with deletion? (Y/N): ');
      finalConfirm = console.read();
      if (finalConfirm.isYes) {
        freedSpace += await console.printLoading<double>(
            message:
                'Deleting ${curResult.unusedAssetsForDeletion.length} asset(s)',
            work: () {
              final justFreed =
                  deleteUnusedAssets(curResult.unusedAssetsForDeletion);
              console.printSuccess(
                  '\n✨ You have freed up ${justFreed.toStorageString()} of space.');
              return justFreed;
            });
      } else if (finalConfirm.isNo) {
        console.printError('Deletion cancelled by user.');
        _result = curResult.copyWith(
            hasCleaned: false, spaceOfUnusedAssetsAfterClean: () => null);
        return _result;
      } else {
        console.printError('Invalid option. Please enter "y" or "n"');
      }
    } while (!finalConfirm.isYesOrNo);

    _result = curResult.copyWith(
        spaceOfUnusedAssetsAfterClean: () =>
            curResult.spaceOfUnusedAssetsBeforeClean -
            freedSpace, // should be 0
        hasCleaned: true);

    return _result;
  }

  double deleteUnusedAssets(List<String> unusedAssets) {
    double totalSize = 0;
    for (var assetRelativePath in unusedAssets) {
      final isFirst = unusedAssets.first == assetRelativePath;
      final path = p.join(projectRoot, assetRelativePath);
      if (!fs.fileExists(path)) {
        console.printWarning(
            'File not found, skipping deletion: "$assetRelativePath"');
        continue;
      }
      try {
        final fileSize = fs.lengthSync(path);
        totalSize += fileSize;
        fs.deleteSync(path);
        console
            .printSuccess('${isFirst ? '\n' : ''}Deleted: $assetRelativePath');
      } catch (e) {
        console.printError('Could not delete "$assetRelativePath": $e');
      }
    }
    return totalSize;
  }
}
