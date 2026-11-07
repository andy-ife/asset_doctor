import 'package:asset_doctor/app/analysis_printer.dart';
import 'package:asset_doctor/app/asset_cleaner.dart';
import 'package:asset_doctor/app/asset_compressor.dart';
import 'package:asset_doctor/app/models/clean_result.dart';
import 'package:asset_doctor/app/models/compress_result.dart';
import 'package:asset_doctor/ui/cli.dart';

class AssetDoctor {
  const AssetDoctor(
      {required this.cliMode,
      required this.assetCleaner,
      required this.assetCompressor,
      required this.analysisPrinter});

  final CliMode cliMode;
  final AssetCleaner assetCleaner;
  final AssetCompressor assetCompressor;
  final AnalysisPrinter analysisPrinter;

  void run() {
    switch (cliMode) {
      case CliMode.fullRun:
        {
          final cleanResult = clean();
          if (cleanResult == null) return;

          final compressResult = compress();
          if (compressResult == null) return;

          analysisPrinter.printPubspecAnalysis();
          analysisPrinter.printWorkSummary(cleanResult, compressResult);
          break;
        }

      case CliMode.cleanOnly:
        {
          final result = clean();
          if (result == null) return;

          analysisPrinter.printPubspecAnalysis();
          analysisPrinter.printWorkSummary(result, null);
          break;
        }
      case CliMode.compressOnly:
        {
          final result = compress();
          if (result == null) return;

          analysisPrinter.printPubspecAnalysis();
          analysisPrinter.printWorkSummary(null, result);
          break;
        }
      case CliMode.none:
        {
          break;
        }
    }
  }

  CleanResult? clean() {
    final result0 = assetCleaner.analyze();
    analysisPrinter.printCleanAnalysis(result0);

    final result1 = assetCleaner.clean();
    return result1;
  }

  CompressResult? compress() {
    final compress0 = assetCompressor.analyze();
    analysisPrinter.printCompressAnalysis(compress0);

    final compress1 = assetCompressor.compress();
    return compress1;
  }
}
