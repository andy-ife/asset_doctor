import 'package:args/args.dart';
import 'package:asset_doctor/ui/console.dart';

enum CliMode { fullRun, cleanOnly, compressOnly, none }

class Cli {
  Cli({Console? console}) : this.console = console ?? Console();
  late final Console console;

  CliMode start(List<String> arguments) {
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

    console.printInfo('--Asset Doctor--');

    if (noArgs) {
      console.printInfo('Get started');
      showTutorial();
      do {
        final input = console.read();
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
            console.printError('Invalid option. Please choose 1 - 4');
        }
      } while (!fullRun && !cleanOnly && !compressOnly);
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

    return CliMode.none;
  }

  void showHelp() {
    console.printInfo(
        'Clean unused Dart/Flutter assets and compress the ones you use. Choose full-run or one option only');
    console.printInfo('\n`dart run asset_doctor`\n');
    console.printInfo('Flags (optional):');
    console.printInfo('Full run (clean & compress): --full-run, -f');
    console.printInfo('Clean only: --clean-only, -c');
    console.printInfo('Compress only: --compress-only, -x');
    console.printInfo('Help, --help, -h');
  }

  void showTutorial() {
    console.printInfo('Choose an option:');
    console.printInfo('1. Full run (clean & compress)');
    console.printInfo('2. Clean only');
    console.printInfo('3. Compress only');
    console.printInfo('4. Help');
  }
}
