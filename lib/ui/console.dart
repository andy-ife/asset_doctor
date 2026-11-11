import 'dart:async';
import 'dart:io';

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
      {required String message, required Future<T> work}) async {
    late final T result;
    bool loading = true;

    work.then((val) {
      result = val;
    }).whenComplete(() {
      loading = false;
    });

    int i = 0;

    do {
      String dots = '.' * ((i % 3) + 1);
      write('\r\n$message$dots');
      await Future.delayed(const Duration(milliseconds: 300));
    } while (loading);

    return result;
  }
}
