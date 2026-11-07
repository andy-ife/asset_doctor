import 'dart:io';
import 'package:asset_doctor/app/analysis_printer.dart';
import 'package:asset_doctor/app/asset_cleaner.dart';
import 'package:asset_doctor/app/asset_compressor.dart';
import 'package:asset_doctor/asset_doctor.dart';
import 'package:asset_doctor/app_initialization.dart';
import 'package:asset_doctor/ui/cli.dart';
import 'package:path/path.dart' as p;

class App {
  static void start(List<String> args) {
    final projectRoot = Directory.current.path;
    final ignoredDirs = ['test', 'build', 'integration_test'];
    final pubspecPath = p.join(projectRoot, 'pubspec.yaml');

    final app = AppInitialization(
        projectRoot: projectRoot,
        ignoredDirs: ignoredDirs,
        pubspecPath: pubspecPath);

    final cliMode = Cli().start(args);

    if (cliMode == CliMode.none) {
      return;
    }

    // Pubspec
    final pubspecAssets = app.getPubspecAssets();

    // String literals
    final Set<String> allNormalizedLiterals = app.getAllNormalizedLiterals();

    // All Assets
    final allAssets = app.getAllAssets();

    // Used Assets
    final usedAssets = app.getUsedAssets(allAssets, allNormalizedLiterals);

    // Start
    final assetDoctor = AssetDoctor(
        cliMode: cliMode,
        assetCleaner: AssetCleaner(
            allAssets: allAssets, usedAssets: usedAssets, fs: app.fs),
        assetCompressor: AssetCompressor(usedAssets: usedAssets, fs: app.fs),
        analysisPrinter: AnalysisPrinter(
            usedAssets: usedAssets, pubspecAssets: pubspecAssets, fs: app.fs));

    assetDoctor.run();
  }
}
