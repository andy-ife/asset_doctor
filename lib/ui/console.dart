import 'dart:async';
import 'dart:io';
import 'dart:isolate';

const String reset = '\x1B[0m';
const String red = '\x1B[31m';
const String green = '\x1B[32m';
const String yellow = '\x1B[33m';
const String blue = '\x1B[34m';
const String cyan = '\x1B[36m';

/// Simple wrapper around [Stdin] & [Stdout]
class Console {
  const Console();

  void _print(String value) {
    return print(value);
  }

  void write(String value) {
    return stdout.write(value);
  }

  String? read() {
    return stdin.readLineSync();
  }

  void printHeader(String title) {
    printHint('\n=============');
    printInfo(title);
    printHint('=============\n');
  }

  void printError(String message) {
    _print('$red$message$reset');
  }

  void printHint(String message) {
    _print('$cyan$message$reset');
  }

  void printInfo(String message) {
    _print(message);
  }

  void printWarning(String message) {
    _print('$yellow$message$reset');
  }

  void printSuccess(String message) {
    _print('$green$message$reset');
  }

  void printDefault(String message) {
    _print(message);
  }

  Future<T> printLoading<T>(
      {required String message, required T Function() work}) async {
    late final T result;
    bool loading = true;

    Isolate.run(work).then((data) {
      result = data;
    }).whenComplete(() {
      loading = false;
    });

    int i = 0;
    stdout.write('\x1B[?25l\n'); // hide cursor
    do {
      String dots = '.' * ((i % 3) + 1);
      write('\r$message${dots.padRight(4)}');
      i++;
      await Future.delayed(const Duration(milliseconds: 500));
    } while (loading);
    stdout.write('\x1B[?25h'); // show cursor
    print('');
    return result;
  }
}
