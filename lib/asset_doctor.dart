import 'dart:io';

import 'package:args/args.dart';
import 'package:asset_doctor/cleanup/asset_cleaner.dart';
import 'package:asset_doctor/compression/asset_compressor.dart';
import 'package:asset_doctor/utils/file_helper.dart';
import 'package:asset_doctor/utils/ui.dart';
import 'package:path/path.dart' as p;

class AssetDoctor {
  static void start(List<String> arguments) async {
    final projectRoot = Directory.current.path;
    final pubspecPath = p.join(projectRoot, 'pubspec.yaml');
    final libDir = Directory(p.join(projectRoot, 'lib'));

    final assetsDir = Directory(
        p.join(projectRoot, FileHelper.commonAssetLocations[Platform.assets]));
    final androidAssetsDir = Directory(
        p.join(projectRoot, FileHelper.commonAssetLocations[Platform.android]));
    final iosAssetsDir = Directory(
        p.join(projectRoot, FileHelper.commonAssetLocations[Platform.ios]));
    final macosAssetsDir = Directory(
        p.join(projectRoot, FileHelper.commonAssetLocations[Platform.macos]));
    final windowsAssetsDir = Directory(
        p.join(projectRoot, FileHelper.commonAssetLocations[Platform.windows]));
    final linuxAssetsDir = Directory(
        p.join(projectRoot, FileHelper.commonAssetLocations[Platform.linux]));

    final ignoredDirs = [
      'test',
      'build'
    ]; // Folders to ignore during code search

    final assetCleaner = AssetCleaner(
        projectRoot: projectRoot,
        pubspecPath: pubspecPath,
        libDir: libDir,
        assetsDir: assetsDir,
        ignoredDirs: ignoredDirs);

    final assetComppressor = AssetCompressor(
        projectRoot: projectRoot,
        assetsDir: assetsDir,
        ignoredDirs: ignoredDirs);

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

    printInfo('--Asset Doctor--');

    if (noArgs) {
      printInfo('Get started');
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
            printError('Invalid option. Please choose 1 - 4');
        }
      } while (!fullRun && !cleanOnly && !compressOnly);
    }

    if (requestingHelp) {
      printInfo(
          'Clean unused Dart/Flutter assets and compress the ones you use. Choose full-run or one option only');
      showHelp();
      return;
    }

    // Work starts
    Set<String> allAssetFiles = {};

    printInfo('Checking asset usage in Dart/Flutter project...');

    getFiles(projectRoot, assetsDir, allAssetFiles);
    getFiles(projectRoot, androidAssetsDir, allAssetFiles);
    getFiles(projectRoot, iosAssetsDir, allAssetFiles);
    getFiles(projectRoot, macosAssetsDir, allAssetFiles);
    getFiles(projectRoot, windowsAssetsDir, allAssetFiles);
    getFiles(projectRoot, linuxAssetsDir, allAssetFiles);

    final allNormalizedLiterals =
        assetCleaner.findAllStringLiteralsInCode(libDir, projectRoot);
    printInfo(
        'Found ${allNormalizedLiterals.length} string literals in the code.');

    if (fullRun) {
      clean(allAssetFiles, allNormalizedLiterals, projectRoot, assetCleaner,
          pubspecPath);
      compress();
    } else if (cleanOnly) {
      clean(allAssetFiles, allNormalizedLiterals, projectRoot, assetCleaner,
          pubspecPath);
    } else if (compressOnly) {
      compress();
    }
  }
}

void clean(Set<String> allAssetFiles, Set<String> allNormalizedLiterals,
    String projectRoot, AssetCleaner assetCleaner, String pubspecPath) {
  final usedAssetPaths = <String>{};
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
      usedAssetPaths.add(assetPath);
    }
  }

  final potentialUnusedPaths = allAssetFiles.difference(usedAssetPaths).toList()
    ..sort();
  List<String> unusedAssetsForDeletion = <String>[]; // Use List for indexing
  final localizationAssetsExcluded = <String>[];

  for (final assetPath in potentialUnusedPaths) {
    final file = File(p.join(projectRoot, assetPath));
    bool isJson = assetPath.toLowerCase().endsWith('.json');
    bool isNonEmpty = false;
    try {
      if (file.existsSync()) {
        isNonEmpty = file.lengthSync() > 0;
      }
    } catch (e) {
      printWarning('Could not check size of "$assetPath": $e');
      isJson = false;
    }

    if (isJson && isNonEmpty) {
      localizationAssetsExcluded.add(assetPath);
    } else {
      unusedAssetsForDeletion.add(assetPath);
    }
  }

  final unusedTree = assetCleaner.buildTree(unusedAssetsForDeletion);
  final excludedTree = assetCleaner.buildTree(localizationAssetsExcluded);

  assetCleaner.displayResults(
      allAssetFiles, usedAssetPaths.toList(), unusedTree, excludedTree);

  if (unusedAssetsForDeletion.isNotEmpty) {
    printInfo('Marking all unused assets for deletion...');
  }

  String? finalConfirm;
  printInfo(
      '\nFINAL CONFIRMATION: You are about to delete ${unusedAssetsForDeletion.length} asset(s).');
  stdout.write('Proceed with deletion? (Y/N): ');
  finalConfirm = stdin.readLineSync();
  if ((finalConfirm != null && finalConfirm.toLowerCase() == 'y')) {
    printLoading(
        message: '\nDeleting ${unusedAssetsForDeletion.length} assets',
        work: Future(() async {
          final freedSpace =
              await assetCleaner.deleteUnusedAssets(unusedAssetsForDeletion);
          printSuccess(
              '🎉 You have freed up ${freedSpace.toStringAsFixed(2)} MB of space.');
        }).asStream());
  } else {
    printError('Deletion cancelled by user.');
  }

  printInfo('Checking pubspec.yaml for any skipped assets...');

  final declaredAssetsInPubspec =
      FileHelper.extractAssetsFromPubspec(pubspecPath, projectRoot);
  if (declaredAssetsInPubspec.isNotEmpty) {
    final unusedDeclaredAssets = declaredAssetsInPubspec
        .where((assetPath) => !usedAssetPaths.contains(assetPath))
        .toList()
      ..sort();
    printInfo('\n--- Pubspec.yaml Info ---');
    printInfo(
        'Found ${declaredAssetsInPubspec.length} assets declared in pubspec.yaml');
    if (unusedDeclaredAssets.isNotEmpty) {
      printInfo(
          '${unusedDeclaredAssets.length} declared assets were found in assets/ but not referenced in code');
      for (var asset in unusedDeclaredAssets) {
        printInfo('- $asset');
      }
    } else {
      printInfo('All declared assets in pubspec.yaml appear to be referenced.');
    }
    final undeclaredUsedAssets = usedAssetPaths
        .where((assetPath) => !declaredAssetsInPubspec.contains(assetPath))
        .toList()
      ..sort();
    if (undeclaredUsedAssets.isNotEmpty) {
      printInfo(
          '${undeclaredUsedAssets.length} files in assets/ were used but *not* declared in pubspec.yaml:');
      for (var asset in undeclaredUsedAssets) {
        printInfo('- $asset');
      }
      printInfo(
          '💡 Tip: Consider declaring used assets in pubspec.yaml under the `assets:` section.');
    }
    printInfo('-------------------------');
  }
}

void compress() {}

void getFiles(String projectRoot, Directory dir, Set<String> result) {
  if (dir.existsSync()) {
    final allAssetFiles = FileHelper.findAllFilesInDirectory(projectRoot, dir);
    if (allAssetFiles.isEmpty) {
      printWarning(
          'No files found in the assets directory (excluding hidden files).');
    }
    result.addAll(allAssetFiles);
    printInfo('\nFound ${allAssetFiles.length} files in the assets directory.');
  } else {
    printWarning('Assets directory not found at ${dir.path}');
  }
}

void showHelp() {
  printInfo('\n`dart run asset_doctor`\n');
  printInfo('Flags (optional):');
  printInfo('Full run (clean & compress): --full-run, -f');
  printInfo('Clean only: --clean-only, -c');
  printInfo('Compress only: --compress-only, -x');
  printInfo('Help, --help, -h');
}

void showTutorial() {
  printInfo('Choose an option:');
  printInfo('1. Full run (clean & compress)');
  printInfo('2. Clean only');
  printInfo('3. Compress only');
  printInfo('4. Help');
}
