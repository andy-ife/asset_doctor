import 'package:asset_doctor/app/models/compress_result.dart';
import 'package:asset_doctor/data/compression_client.dart';
import 'package:asset_doctor/data/file_system_client.dart';
import 'package:asset_doctor/ui/console.dart';
import 'package:asset_doctor/ui/tree.dart';
import 'package:path/path.dart' as p;

class AssetCompressor {
  AssetCompressor({
    required this.usedAssets,
    required this.fs,
    CompressionClient? compressor,
    String? projectRoot,
    List<String>? ignoredDirs,
    Console? console,
    TreePrinter? tree,
  }) {
    this.compressor = compressor ?? CompressionClient();
    this.projectRoot = projectRoot ?? this.fs.currentDir;
    this.ignoredDirs = ignoredDirs ?? ['test', 'build'];
    this.console = console ?? Console();
    this.tree = tree ?? TreePrinter();
  }

  final Set<String> usedAssets;
  final FileSystemClient fs;

  late final CompressionClient compressor;
  late final String projectRoot;
  late final List<String> ignoredDirs; // Folders to ignore during code search
  late final Console console;
  late final TreePrinter tree;

  CompressResult? _result;
  CompressResult? get result => _result;

  CompressResult analyze() {
    final List<String> assetsForCompression = [];
    double spaceofMediaAssetsBeforeCompress = 0;

    final mediaAssets = usedAssets.where((e) => compressor.isMedia(e));

    for (final assetPath in mediaAssets) {
      final path = p.join(projectRoot, assetPath);
      bool isNonEmpty = false;
      try {
        if (fs.fileExists(path)) {
          final size = fs.lengthSync(path);
          isNonEmpty = size > 0;
          spaceofMediaAssetsBeforeCompress += size;
        }
      } catch (e) {
        console.printWarning('Could not check size of "$assetPath": $e');
      }

      if (isNonEmpty) {
        assetsForCompression.add(assetPath);
      }
    }

    final compressTree = tree.build(assetsForCompression);

    _result = CompressResult(
        usedAssets: usedAssets,
        assetsForCompression: assetsForCompression,
        assetsForCompressionTree: compressTree,
        spaceOfMediaAssetsBeforeCompress: spaceofMediaAssetsBeforeCompress,
        spaceOfMediaAssetsAfterCompress: spaceofMediaAssetsBeforeCompress,
        hasAnalyzed: true,
        hasCompressed: false);
    return _result!;
  }

  CompressResult? compress() {
    if (_result == null || _result?.hasAnalyzed == false) {
      console.printError('Run analysis before compression');
      return null;
    }

    final curResult = _result!;

    if (curResult.assetsForCompression.isNotEmpty) {
      console.printInfo('Marking media assets for compression');
    }

    String? finalConfirm;
    double freeSpace = 0;
    console.printInfo(
        '\nFINAL CONFIRMATION: You are about to compress ${curResult.assetsForCompression.length} asset(s).');
    console.write('Proceed with compression? It may take a while (Y/N): ');
    finalConfirm = console.read();
    if ((finalConfirm != null &&
        (finalConfirm.toLowerCase() == 'y' ||
            finalConfirm.toLowerCase() == 'yes'))) {
      console.printLoading(
          message:
              '\nCompressing ${curResult.assetsForCompression.length} assets',
          work: () async {
            final freedSpace = await compressor
                .compressAllMedia(curResult.assetsForCompression);
            freeSpace += freedSpace ?? 0;
            if (freedSpace != null) {
              console.printSuccess(
                  '🎉 You have freed up ${freedSpace.toStringAsFixed(2)} MB of space.');
            }
          });
    } else {
      console.printError('Compression cancelled by user.');
      _result = curResult.copyWith(hasCompressed: false);
      return _result;
    }

    _result = curResult.copyWith(
      spaceofMediaAssetsAfterCompress:
          _result!.spaceOfMediaAssetsAfterCompress - freeSpace,
      hasCompressed: true,
    );

    return _result;
  }

  Future<double> compressAssets(List<String> assets) async {
    double result = 0;
    for (var asset in assets) {
      if (!fs.fileExists(asset)) continue;
      print('Compressing $asset...');
      try {
        final res = await compressor.compressMedia(asset);
        result += res ?? 0;
      } catch (e) {
        console.printError('Error compressing $asset: $e');
      }
    }
    return result;
  }
}
