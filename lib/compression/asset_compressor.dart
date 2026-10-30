import 'dart:io';
import 'dart:isolate';

import 'package:asset_doctor/compression/compressor.dart';
import 'package:asset_doctor/utils/ui.dart';

class AssetCompressor {
  AssetCompressor({
    Compressor? compressor,
    String? projectRoot,
    List<String>? ignoredDirs,
  }) {
    this.compressor = compressor ?? Compressor();
    this.projectRoot = projectRoot ?? Directory.current.path;
    this.ignoredDirs = ignoredDirs ?? ['test', 'build'];
  }

  late final Compressor compressor;
  late final String projectRoot;
  late final List<String> ignoredDirs; // Folders to ignore during code search

  List<Isolate> curIsolates = [];

  void showAnalysis(Set<String> allAssetFiles, List<String> filesForCompression,
      Map<String, dynamic> tree) {
    Ui.printInfo('\n--Asset Compression Analysis--');
    Ui.printWarning('\nAssets MARKED FOR COMPRESSION:');
    if (filesForCompression.isNotEmpty) {
      Ui.printWarning('(${filesForCompression.length} files)');
      Ui.printTree(tree, '', true);
    } else {
      Ui.printDefault('  None found.');
    }

    final selectedAssets = filesForCompression.toSet();
    final totalAssets = allAssetFiles.length;
    final totalForCompression = selectedAssets.length;
    final totalNotSelected = allAssetFiles.difference(selectedAssets).length;

    Ui.printInfo('\nSummary:');
    Ui.printInfo('• Total assets (excluding hidden): $totalAssets');
    Ui.printInfo('• Assets marked for compression: $totalForCompression');
    Ui.printInfo('• Assets not selected for compression: $totalNotSelected');
    if (totalAssets > 0) {
      Ui.printInfo(
          '• Percentage selected for compression: ${((totalForCompression / totalAssets) * 100).toStringAsFixed(2)}%');
    }
    Ui.printInfo('---------------------------');
  }

  Future<double> compressAssets(List<String> assets) async {
    double result = 0;
    for (var asset in assets) {
      final file = File(asset);
      if (!file.existsSync()) continue;
      print('Compressing ${file.path}...');
      curIsolates.add(await Isolate.spawn((_) async {
        try {
          final res = await compressor.compressMedia(file);
          result += res ?? 0;
        } catch (e) {
          rethrow;
        }
      }, null));
    }
    return result;
  }
}
