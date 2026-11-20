import 'package:app_size_doctor/fix/app/analysis_printer.dart';
import 'package:app_size_doctor/fix/app/asset_cleaner.dart';
import 'package:app_size_doctor/fix/app/asset_compressor.dart';
import 'package:app_size_doctor/fix/app/models/clean_result.dart';
import 'package:app_size_doctor/fix/app/models/compress_result.dart';
import 'package:app_size_doctor/fix/ui/cli.dart';
import 'package:app_size_doctor/fix/ui/console.dart';

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

  Future<void> run() async {
    switch (cliMode) {
      case CliMode.fullRun:
        {
          final cleanResult = await clean();
          if (cleanResult == null) return;

          Console().printInfo('Proceeding to compression...');
          await Future.delayed(Duration(seconds: 1));

          final compressResult = await compress();
          if (compressResult == null) return;

          if (cleanResult.hasCleaned || compressResult.hasCompressed) {
            analysisPrinter.printPubspecAnalysis();
            analysisPrinter.printWorkSummary(cleanResult, compressResult);
          }
          break;
        }

      case CliMode.cleanOnly:
        {
          final result = await clean();
          if (result == null) return;

          if (result.hasCleaned) {
            analysisPrinter.printPubspecAnalysis();
            analysisPrinter.printWorkSummary(result, null);
          }
          break;
        }
      case CliMode.compressOnly:
        {
          final result = await compress();
          if (result == null) return;

          if (result.hasCompressed) {
            analysisPrinter.printPubspecAnalysis();
            analysisPrinter.printWorkSummary(null, result);
          }
          break;
        }
      case CliMode.dryRun:
        {
          await dryRun();
          // analysisPrinter.printPubspecAnalysis();
          break;
        }
      case CliMode.none:
        {
          break;
        }
    }
  }

  Future<void> dryRun() async {
    final cleanResult = assetCleaner.analyze();
    final compressResult = assetCompressor.analyze();

    analysisPrinter.printDryRunAnalysis(cleanResult, compressResult);
  }

  Future<CleanResult?> clean() async {
    final result0 = assetCleaner.analyze();
    analysisPrinter.printCleanAnalysis(result0);

    final result1 = await assetCleaner.clean();
    return result1;
  }

  Future<CompressResult?> compress() async {
    final compress0 = assetCompressor.analyze();
    analysisPrinter.printCompressAnalysis(compress0);

    final compress1 = await assetCompressor.compress();
    return compress1;
  }
}
