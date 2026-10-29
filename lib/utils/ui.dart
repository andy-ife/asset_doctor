import 'dart:io';

const String reset = '\x1B[0m';
const String red = '\x1B[31m';
const String green = '\x1B[32m';
const String yellow = '\x1B[33m';
const String blue = '\x1B[34m';
const String cyan = '\x1B[36m';

void printError(String message) {
  print('$red$message$reset');
}

void printInfo(String message) {
  print('$cyan$message$reset');
}

void printWarning(String message) {
  print('$yellow$message$reset');
}

void printSuccess(String message) {
  print('$green$message$reset');
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
    stdout.write('\r$message$dots');
    await Future.delayed(const Duration(milliseconds: 300));
  }
}
