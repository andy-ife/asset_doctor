import 'package:args/args.dart';
import 'package:app_size_doctor/fix/ui/console.dart';

enum CliMode { fullRun, cleanOnly, compressOnly, dryRun, none }

const PADDING = 32;

class Cli {
  Cli({Console? console}) : console = console ?? Console();

  late final Console console;

  CliMode start(List<String> arguments) {
    final parser = ArgParser()
      ..addFlag('help', abbr: 'h', defaultsTo: false)
      ..addFlag('full-run', abbr: 'f', defaultsTo: false)
      ..addFlag('clean-only', abbr: 'c', defaultsTo: false)
      ..addFlag('compress-only', abbr: 'x', defaultsTo: false)
      ..addFlag('dry-run', abbr: 'd', defaultsTo: false);

    ArgResults argResults = parser.parse(arguments);
    bool requestingHelp = argResults['help'] as bool;
    bool cleanOnly = argResults['clean-only'] as bool;
    bool compressOnly = argResults['compress-only'] as bool;
    bool fullRun = argResults['full-run'] as bool;
    bool dryRun = argResults['dry-run'] as bool;
    final noArgs =
        !cleanOnly && !compressOnly && !fullRun && !dryRun && !requestingHelp;

    console.printHeader('Asset Doctor');

    if (noArgs) {
      console.printInfo('Get started');
      showTutorial();
      do {
        final input = console.read();
        switch (input?.trim()) {
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
            dryRun = true;
            break;
          case '5':
            requestingHelp = true;
            break;
          default:
            console.printError('Invalid option. Please choose 1 - 4');
        }
      } while (!fullRun &&
          !cleanOnly &&
          !compressOnly &&
          !dryRun &&
          !requestingHelp);
    }

    if (requestingHelp) {
      showHelp();
      return CliMode.none;
    }

    if (fullRun) {
      return CliMode.fullRun;
    }

    if (cleanOnly) {
      return CliMode.cleanOnly;
    }

    if (compressOnly) {
      return CliMode.compressOnly;
    }

    if (dryRun) {
      return CliMode.dryRun;
    }

    return CliMode.none;
  }

  void showHelp() {
    console.printHeader("Help");
    console.printInfo(
        'Remove (clean) unused assets and compress the ones you use. You can choose clean, compress, or both');
    console.printInfo("\nMain command:");
    console.printHint('`dart run asset_doctor`\n');
    console.printInfo('Flags (optional):');
    console.printInfo(
        '${'-f, --full-run'.padRight(PADDING)}Full run (clean & compress)');
    console.printInfo('${'-c, --clean-only'.padRight(PADDING)}Clean only');
    console
        .printInfo('${'-x, --compress-only'.padRight(PADDING)}Compress only');
    console.printInfo(
        '${'-d, --dry-run'.padRight(PADDING)}Dry run (See potential size savings without touching anything)');
    console.printInfo('${'-h, --help'.padRight(PADDING)}Help');
  }

  void showTutorial() {
    console.printInfo('\nOptions:');
    console.printInfo('1. Full run (clean & compress)');
    console.printInfo('2. Clean only');
    console.printInfo('3. Compress only');
    console.printInfo('4. Dry run');
    console.printInfo('5. Help');
    console.printInputPrompt('Choose one (1-5): ');
  }
}
