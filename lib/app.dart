import 'dart:io';
import 'package:asset_doctor/app/analysis_printer.dart';
import 'package:asset_doctor/app/asset_cleaner.dart';
import 'package:asset_doctor/app/asset_compressor.dart';
import 'package:asset_doctor/asset_doctor.dart';
import 'package:asset_doctor/app/app_initialization.dart';
import 'package:asset_doctor/ui/cli.dart';
import 'package:path/path.dart' as p;

class App {
  static void start(List<String> args) async {
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

    final initialData = await app.init();

    // Start
    final assetDoctor = AssetDoctor(
        cliMode: cliMode,
        assetCleaner: AssetCleaner(
            allAssets: initialData.allAssets,
            usedAssets: initialData.usedAssets,
            fs: app.fs),
        assetCompressor:
            AssetCompressor(usedAssets: initialData.usedAssets, fs: app.fs),
        analysisPrinter: AnalysisPrinter(
            usedAssets: initialData.usedAssets,
            pubspecAssets: initialData.pubspecAssets,
            fs: app.fs));

    assetDoctor.run();
  }
}
