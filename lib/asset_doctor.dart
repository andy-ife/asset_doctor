import 'dart:io';

import 'package:args/args.dart';
import 'package:asset_doctor/cleanup/asset_cleaner.dart';
import 'package:asset_doctor/utils/file_helper.dart';
import 'package:path/path.dart' as p;

class AssetDoctor {
  static void start(List<String> arguments) async {
    final projectRoot = Directory.current.path;
    final pubspecPath = p.join(projectRoot, 'pubspec.yaml');
    final libDir = Directory(p.join(projectRoot, 'lib'));
    final assetsDir = Directory(p.join(projectRoot, 'assets'));
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

    final parser = ArgParser()
      ..addFlag(
        'help',
        abbr: 'h',
        defaultsTo: false,
      )
      ..addFlag('dry-run',
          abbr: 'd',
          defaultsTo: false,
          help: 'Perform a dry run without deleting files.')
      ..addFlag('include-json',
          abbr: 'j', defaultsTo: false, help: 'Include non-empty json files')
      ..addFlag('skip-interactive',
          abbr: 'y',
          defaultsTo: false,
          help:
              'Automatically delete unused assets, skipping the interactive flow');

    ArgResults argResults = parser.parse(arguments);
    final requestingHelp = argResults['help'] as bool;
    final isDryRun = argResults['dry-run'] as bool;
    final includeJson = argResults['include-json'] as bool;
    final skipInteractive = argResults['skip-interactive'] as bool;

    if (requestingHelp) {
      print(
          'Identify and clean assets in your Flutter project\nflags: --dry-run, --skip-interactive, --include-json');
      return;
    }

    print('🔍 Checking asset usage in Flutter project...');
    print('🚀 Dry Run Mode: ${isDryRun ? 'Enabled' : 'Disabled'}');

    if (!assetsDir.existsSync()) {
      print('❌ Assets directory not found at ${assetsDir.path}');
      return;
    }

    final allAssetFiles =
        FileHelper.findAllFilesInDirectory(projectRoot, assetsDir);
    if (allAssetFiles.isEmpty) {
      print('No files found in the assets directory (excluding hidden files).');
      return;
    }
    print('\nFound ${allAssetFiles.length} files in the assets directory.');

    final allNormalizedLiterals =
        assetCleaner.findAllStringLiteralsInCode(libDir, projectRoot);
    print('Found ${allNormalizedLiterals.length} string literals in the code.');

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
          isNonEmpty = file.lengthSync() > 0;
        }
      } catch (e) {
        print('⚠️ Could not check size of "$assetPath": $e');
        isJson = false;
      }

      if (!includeJson && isJson && isNonEmpty) {
        localizationAssetsExcluded.add(assetPath);
      } else {
        unusedAssetsForDeletion.add(assetPath);
      }
    }

    final unusedTree = assetCleaner.buildTree(unusedAssetsForDeletion);
    final excludedTree = assetCleaner.buildTree(localizationAssetsExcluded);

    assetCleaner.displayResults(
        allAssetFiles, usedAssetPaths.toList(), unusedTree, excludedTree);

    // --- Modified Interactive Unselection Logic (Removing from list) ---
    List<String> filesToRemoveFromDeletion =
        []; // List to hold files the user wants to keep

    if (unusedAssetsForDeletion.isNotEmpty && !isDryRun) {
      String? userInput;

      if (!skipInteractive) {
        print('\n--- Select Assets to Keep (Remove from Deletion List) ---');
        print('The following assets are currently marked for deletion:');

        for (var i = 0; i < unusedAssetsForDeletion.length; i++) {
          print('${i + 1}. ${unusedAssetsForDeletion[i]}');
        }

        print(
            '\nEnter a comma-separated list of numbers you wish to REMOVE from the deletion list (e.g., 1, 5, 8)');
        print(
            'Press Enter without typing numbers to delete ALL ${unusedAssetsForDeletion.length} listed assets.');
        stdout.write('Selection to REMOVE from deletion: ');
        userInput = stdin.readLineSync();
        print('');
      } else {
        print(
            'Skipping interactive asset selection. Automatically marking all unused assets for deletion.');
      }

      if (userInput != null && userInput.trim().isNotEmpty) {
        final numbersToRemove = <int>{};
        final parts = userInput.split(',');
        bool inputError = false;

        for (var part in parts) {
          final trimmedPart = part.trim();
          if (trimmedPart.isEmpty) continue;

          try {
            final number = int.parse(trimmedPart);
            if (number >= 1 && number <= unusedAssetsForDeletion.length) {
              numbersToRemove.add(number);
            } else {
              print(
                  '⚠️ Invalid number: $number is out of range (1-${unusedAssetsForDeletion.length}).');
              inputError = true;
            }
          } catch (e) {
            print('⚠️ Invalid input: "$trimmedPart" is not a valid number.');
            inputError = true;
          }
        }

        if (!inputError) {
          // Populate filesToRemoveFromDeletion based on the numbers provided
          for (var number in numbersToRemove) {
            filesToRemoveFromDeletion.add(unusedAssetsForDeletion[number - 1]);
          }
          print(
              '${filesToRemoveFromDeletion.length} asset(s) will be removed from the deletion list.');
        } else {
          print(
              '❌ Due to input errors, no changes will be made to the deletion list.');
          // If input errors, filesToRemoveFromDeletion remains empty, so original list is targeted
        }
      } else {
        print(
            '👍 No selection entered. Proceeding to delete ALL ${unusedAssetsForDeletion.length} listed assets.');
        filesToRemoveFromDeletion =
            []; // Empty list means nothing is removed from deletion
      }
      print('--- End Selection ---');
    }

    // Determine the final list to delete by removing selected items from the original list
    List<String> filesToActuallyDelete = unusedAssetsForDeletion
        .where((asset) => !filesToRemoveFromDeletion.contains(asset))
        .toList();

    if (filesToActuallyDelete.isNotEmpty) {
      if (isDryRun) {
        print('\n--- Dry Run ---');
        print(
            'The following ${filesToActuallyDelete.length} files would have been deleted after selection (see tree above for original list):');
        if (filesToActuallyDelete.length < 20) {
          for (var asset in filesToActuallyDelete) {
            print('- $asset');
          }
        } else {
          print('(List is long, referring to summary count)');
        }
        print('--- Dry Run Complete ---');
      } else {
        String? finalConfirm;
        if (!skipInteractive) {
          print(
              '\nFINAL CONFIRMATION: You are about to delete ${filesToActuallyDelete.length} asset(s).');
          stdout.write('Proceed with deletion? (Y/N): ');
          finalConfirm = stdin.readLineSync();
        } else {
          print('\n Skipping interactive mode and deleting unused assets');
        }

        if (skipInteractive ||
            (finalConfirm != null && finalConfirm.toLowerCase() == 'y')) {
          print('\n🧹 Deleting ${filesToActuallyDelete.length} assets...');
          final freedSpace =
              await assetCleaner.deleteUnusedAssets(filesToActuallyDelete);
          print(
              '🎉 You have freed up ${freedSpace.toStringAsFixed(2)} MB of space.');
        } else {
          print('\n❌ Deletion cancelled by user.');
        }
      }
    } else if (unusedAssetsForDeletion.isNotEmpty && !isDryRun) {
      // This case happens if the user selected all files to be removed from deletion
      print('\n✅ No assets remain for deletion after selection.');
    } else if (allAssetFiles.isNotEmpty && potentialUnusedPaths.isEmpty) {
      // Already printed the "All files used" message
    } else if (allAssetFiles.isNotEmpty &&
        potentialUnusedPaths.isNotEmpty &&
        unusedAssetsForDeletion.isEmpty) {
      // Already printed the "All potentially unused excluded" message
    }

    final declaredAssetsInPubspec =
        FileHelper.extractAssetsFromPubspec(pubspecPath, projectRoot);
    if (declaredAssetsInPubspec.isNotEmpty) {
      final unusedDeclaredAssets = declaredAssetsInPubspec
          .where((assetPath) => !usedAssetPaths.contains(assetPath))
          .toList()
        ..sort();
      print('\n--- Pubspec.yaml Info ---');
      print(
          'Found ${declaredAssetsInPubspec.length} assets declared in pubspec.yaml');
      if (unusedDeclaredAssets.isNotEmpty) {
        print(
            '${unusedDeclaredAssets.length} declared assets were found in assets/ but not referenced in code (these might be in the excluded/unused trees above):');
        for (var asset in unusedDeclaredAssets) {
          print('- $asset');
        }
      } else {
        print('All declared assets in pubspec.yaml appear to be referenced.');
      }
      final undeclaredUsedAssets = usedAssetPaths
          .where((assetPath) => !declaredAssetsInPubspec.contains(assetPath))
          .toList()
        ..sort();
      if (undeclaredUsedAssets.isNotEmpty) {
        print(
            '${undeclaredUsedAssets.length} files in assets/ were used but *not* declared in pubspec.yaml:');
        for (var asset in undeclaredUsedAssets) {
          print('- $asset');
        }
        print(
            '💡 Tip: Consider declaring used assets in pubspec.yaml under the `assets:` section.');
      }
      print('-------------------------');
    }
  }
}
