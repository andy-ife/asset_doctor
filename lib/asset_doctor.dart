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

  final ignoredDirs = [
      'test',
      'build'
    ]; // Folders to ignore during code search

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


  

