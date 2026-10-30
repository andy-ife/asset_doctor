import 'dart:io';

import 'package:args/args.dart';
import 'package:asset_doctor/cleanup/asset_cleaner.dart';
import 'package:asset_doctor/compression/asset_compressor.dart';
import 'package:asset_doctor/utils/file_utils.dart';
import 'package:asset_doctor/utils/ui.dart';
import 'package:path/path.dart' as p;

class AssetDoctor {
  // Setup
  // TODO: Make all setup variables customizable via constructor
  final projectRoot = Directory.current.path;
  final ignoredDirs = ['test', 'build'];
  late final String pubspecPath;
  late final Directory libDir;

  late final List<Directory> assetsDir;
  late final List<Directory> androidAssetsDir;
  late final List<Directory> iosAssetsDir;
  late final List<Directory> macosAssetsDir;
  late final List<Directory> windowsAssetsDir;
  late final List<Directory> linuxAssetsDir;

  // Work
  late final AssetCleaner assetCleaner;
  late final AssetCompressor assetCompressor;

  final allAssetFiles = <String>{};
  final allNormalizedLiterals = <String>{};

  double spaceBefore = 0;
  double spaceCleaned = 0;
  double spaceCompressed = 0;

  AssetDoctor() {
    pubspecPath = p.join(projectRoot, 'pubspec.yaml');
    libDir = Directory(p.join(projectRoot, 'lib'));

    assetsDir.addAll(FileUtils.commonAssetLocations[Platform.assets]!
        .map((e) => Directory(p.join(projectRoot, e))));

    androidAssetsDir.addAll(FileUtils.commonAssetLocations[Platform.android]!
        .map((e) => Directory(p.join(projectRoot, e))));

    iosAssetsDir.addAll(FileUtils.commonAssetLocations[Platform.ios]!
        .map((e) => Directory(p.join(projectRoot, e))));

    macosAssetsDir.addAll(FileUtils.commonAssetLocations[Platform.macos]!
        .map((e) => Directory(p.join(projectRoot, e))));

    windowsAssetsDir.addAll(FileUtils.commonAssetLocations[Platform.windows]!
        .map((e) => Directory(p.join(projectRoot, e))));

    linuxAssetsDir.addAll(FileUtils.commonAssetLocations[Platform.linux]!
        .map((e) => Directory(p.join(projectRoot, e))));

    assetCleaner =
        AssetCleaner(projectRoot: projectRoot, ignoredDirs: ignoredDirs);

    assetCompressor =
        AssetCompressor(projectRoot: projectRoot, ignoredDirs: ignoredDirs);
  }

  void start(List<String> arguments) async {
    final ignoredDirs = [
      'test',
      'build'
    ]; // Folders to ignore during code search

    final parser = ArgParser()
      ..addFlag(
        'help',
        abbr: 'h',
        defaultsTo: false,
      )
      ..addFlag('full-run', abbr: 'f', defaultsTo: true)
      ..addFlag('clean-only', abbr: 'c', defaultsTo: false)
      ..addFlag('compress-only', abbr: 'x', defaultsTo: false);

    ArgResults argResults = parser.parse(arguments);
    final requestingHelp = argResults['help'] as bool;
    bool cleanOnly = argResults['clean-only'] as bool;
    bool compressOnly = argResults['compress-only'] as bool;
    bool fullRun = argResults['full-run'] as bool;
    final noArgs = !cleanOnly && !compressOnly && !fullRun && !requestingHelp;

    Ui.printInfo('--Asset Doctor--');

    if (noArgs) {
      Ui.printInfo('Get started');
      showTutorial();
      do {
        final input = stdin.readLineSync();
        switch (input) {
          case '1':
            fullRun = true;
            break;
          case '2':
            cleanOnly = true;
            break;
          case '3':
            compressOnly = true;
            break;
          case '4':
            showHelp();
            break;
          default:
            Ui.printError('Invalid option. Please choose 1 - 4');
        }
      } while (!fullRun && !cleanOnly && !compressOnly);
    }

    if (requestingHelp) {
      showHelp();
      return;
    }

    // --Work starts--
    Ui.printInfo('Checking asset usage in Dart/Flutter project...');

    allAssetFiles.addAll(FileUtils.findAllInDirectories(
      projectRoot,
      assetsDir,
    ));
    allAssetFiles.addAll(FileUtils.findAllInDirectories(
      projectRoot,
      androidAssetsDir,
    ));
    allAssetFiles.addAll(FileUtils.findAllInDirectories(
      projectRoot,
      iosAssetsDir,
    ));
    allAssetFiles.addAll(FileUtils.findAllInDirectories(
      projectRoot,
      macosAssetsDir,
    ));
    allAssetFiles.addAll(FileUtils.findAllInDirectories(
      projectRoot,
      windowsAssetsDir,
    ));
    allAssetFiles.addAll(FileUtils.findAllInDirectories(
      projectRoot,
      linuxAssetsDir,
    ));

    allNormalizedLiterals.addAll(FileUtils.findAllStringLiteralsInCode(
        libDir, projectRoot, ignoredDirs));

    Ui.printInfo(
        'Found ${allNormalizedLiterals.length} string literals in the code.');

    if (fullRun) {
      final filesLeft = clean();
      compress(filesLeft: filesLeft);
    } else if (cleanOnly) {
      clean(cleanOnly: true);
    } else if (compressOnly) {
      compress(compressOnly: true);
    }
  }

  Set<String> clean({bool cleanOnly = false}) {
    final usedAssetPaths = getUsedAssetPaths();
    final potentialUnusedPaths =
        allAssetFiles.difference(usedAssetPaths).toList()..sort();
    List<String> unusedAssetsForDeletion = <String>[]; // Use List for indexing
    final localizationAssetsExcluded = <String>[];

    for (final assetPath in potentialUnusedPaths) {
      final file = File(p.join(projectRoot, assetPath));
      bool isJson = assetPath.toLowerCase().endsWith('.json');
      bool isNonEmpty = false;
      try {
        if (file.existsSync()) {
          final size = file.lengthSync();
          isNonEmpty = size > 0;
          spaceBefore += size;
        }
      } catch (e) {
        Ui.printWarning('Could not check size of "$assetPath": $e');
        isJson = false;
      }

      if (isJson && isNonEmpty) {
        localizationAssetsExcluded.add(assetPath);
      } else {
        unusedAssetsForDeletion.add(assetPath);
      }
    }

    final unusedTree = Ui.buildTree(unusedAssetsForDeletion);
    final excludedTree = Ui.buildTree(localizationAssetsExcluded);

    assetCleaner.showAnalysis(
        allAssetFiles, usedAssetPaths.toList(), unusedTree, excludedTree);

    if (unusedAssetsForDeletion.isNotEmpty) {
      Ui.printInfo('Marking all unused assets for deletion...');
    }

    String? finalConfirm;
    Ui.printInfo(
        '\nFINAL CONFIRMATION: You are about to delete ${unusedAssetsForDeletion.length} asset(s).');
    stdout.write('Proceed with deletion? (Y/N): ');
    finalConfirm = stdin.readLineSync();
    if ((finalConfirm != null && finalConfirm.toLowerCase() == 'y')) {
      Ui.printLoading(
          message: '\nDeleting ${unusedAssetsForDeletion.length} assets',
          work: Future(() async {
            final freedSpace =
                await assetCleaner.deleteUnusedAssets(unusedAssetsForDeletion);
            spaceCleaned += freedSpace;
            Ui.printSuccess(
                '🎉 You have freed up ${freedSpace.toStringAsFixed(2)} MB of space.');
          }).asStream());
    } else {
      Ui.printError('Deletion cancelled by user.');
    }

    if (cleanOnly) {
      checkPubspecForSkippedAssets(pubspecPath, projectRoot, usedAssetPaths);
      Ui.printWorkSummary(spaceBefore, spaceCleaned, spaceCompressed);
    }

    return usedAssetPaths;
  }

  void compress({Set<String>? filesLeft, bool compressOnly = false}) {
    Set<String> files = {};

    if (compressOnly) {
      files = getUsedAssetPaths();
    } else {
      files = filesLeft ?? allAssetFiles;
    }

    final assetsForCompression = <String>[];

    for (final assetPath in files) {
      final file = File(p.join(projectRoot, assetPath));
      bool isNonEmpty = false;
      try {
        if (file.existsSync()) {
          isNonEmpty = file.lengthSync() > 0;
        }
      } catch (e) {
        Ui.printWarning('Could not check size of "$assetPath": $e');
      }

      if (isNonEmpty) {
        assetsForCompression.add(assetPath);
      }
    }

    final tree = Ui.buildTree(assetsForCompression);

    assetCompressor.showAnalysis(files, assetsForCompression, tree);

    if (assetsForCompression.isNotEmpty) {
      Ui.printInfo('Marking all media assets for compression');
    }

    String? finalConfirm;
    Ui.printInfo(
        '\nFINAL CONFIRMATION: You are about to compress ${assetsForCompression.length} asset(s).');
    stdout.write('Proceed with compression? It may take a while (Y/N): ');
    finalConfirm = stdin.readLineSync();
    if ((finalConfirm != null && finalConfirm.toLowerCase() == 'y')) {
      Ui.printLoading(
          message: '\nCompressing ${assetsForCompression.length} assets',
          work: Future(() async {
            final freedSpace =
                await assetCompressor.compressAssets(assetsForCompression);
            spaceCompressed += freedSpace;
            Ui.printSuccess(
                '🎉 You have freed up ${freedSpace.toStringAsFixed(2)} MB of space.');
          }).asStream());
    } else {
      Ui.printError('Deletion cancelled by user.');
    }

    checkPubspecForSkippedAssets(pubspecPath, projectRoot, files);
    Ui.printWorkSummary(spaceBefore, spaceCleaned, spaceCompressed);
  }

  void showHelp() {
    Ui.printInfo(
        'Clean unused Dart/Flutter assets and compress the ones you use. Choose full-run or one option only');
    Ui.printInfo('\n`dart run asset_doctor`\n');
    Ui.printInfo('Flags (optional):');
    Ui.printInfo('Full run (clean & compress): --full-run, -f');
    Ui.printInfo('Clean only: --clean-only, -c');
    Ui.printInfo('Compress only: --compress-only, -x');
    Ui.printInfo('Help, --help, -h');
  }

  void showTutorial() {
    Ui.printInfo('Choose an option:');
    Ui.printInfo('1. Full run (clean & compress)');
    Ui.printInfo('2. Clean only');
    Ui.printInfo('3. Compress only');
    Ui.printInfo('4. Help');
  }

  void checkPubspecForSkippedAssets(
      String pubspecPath, String projectRoot, Set<String> usedAssetPaths) {
    Ui.printInfo('Checking pubspec.yaml for any skipped assets...');

    final declaredAssetsInPubspec =
        FileUtils.extractAssetsFromPubspec(pubspecPath, projectRoot);
    if (declaredAssetsInPubspec.isNotEmpty) {
      final unusedDeclaredAssets = declaredAssetsInPubspec
          .where((assetPath) => !usedAssetPaths.contains(assetPath))
          .toList()
        ..sort();
      Ui.printInfo('\n--- Pubspec.yaml Info ---');
      Ui.printInfo(
          'Found ${declaredAssetsInPubspec.length} assets declared in pubspec.yaml');
      if (unusedDeclaredAssets.isNotEmpty) {
        Ui.printInfo(
            '${unusedDeclaredAssets.length} declared assets were found in assets/ but not referenced in code');
        for (var asset in unusedDeclaredAssets) {
          Ui.printInfo('- $asset');
        }
      } else {
        Ui.printInfo(
            'All declared assets in pubspec.yaml appear to be referenced.');
      }
      final undeclaredUsedAssets = usedAssetPaths
          .where((assetPath) => !declaredAssetsInPubspec.contains(assetPath))
          .toList()
        ..sort();
      if (undeclaredUsedAssets.isNotEmpty) {
        Ui.printInfo(
            '${undeclaredUsedAssets.length} files in assets/ were used but *not* declared in pubspec.yaml:');
        for (var asset in undeclaredUsedAssets) {
          Ui.printInfo('- $asset');
        }
        Ui.printInfo(
            '💡 Tip: Consider declaring used assets in pubspec.yaml under the `assets:` section.');
      }
      Ui.printInfo('-------------------------');
    }
  }

  /// Compare all asset files with all string literals.
  ///
  /// If an asset's filename `foo.png`, path `project/lib/assets/foo.png` or basename without extension `foo`
  /// is found in the string literals set,
  /// we make an educated guess that the asset is used.
  Set<String> getUsedAssetPaths() {
    Set<String> usedAssetPaths = {};
    for (final assetPath in allAssetFiles) {
      final filename = p.basename(assetPath);
      final basenameWithoutExtension = p.basenameWithoutExtension(assetPath);

      final potentialReferences = [
        assetPath,
        filename,
        basenameWithoutExtension,
      ];

      final isUsed = allNormalizedLiterals.any((literal) {
        return potentialReferences.any((ref) => literal.contains(ref));
      });

      if (isUsed) {
        try {
          usedAssetPaths.add(assetPath);
          spaceBefore += File(assetPath).lengthSync();
        } catch (e) {
          // Do nothing. We should almost never throw errors here
          // And if we do, user already likely uses the asset in his app
        }
      }
    }
    return usedAssetPaths;
  }
}
