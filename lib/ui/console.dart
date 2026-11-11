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

  void printLoading({required String message, required Stream work}) async {
    int i = 0;
    bool loading = true;
    work.listen((data) {}, onError: (e) {
      loading = false;
    }, onDone: () {
      loading = false;
      // Clear the line and print completion message
      // stdout.write('\rDone!              \n');
    });

    while (loading) {
      String dots = '.' * ((i % 3) + 1);
      write('\r$message$dots');
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }
}
