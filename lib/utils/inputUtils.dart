import 'dart:io';

import 'package:dcli/dcli.dart';

String? enterPassphrase() {
  print('Insert passphrase:');
  stdin.echoMode = false;
  String? passphrase = stdin.readLineSync();
  stdin.echoMode = true;
  return passphrase;
}

bool retryOrAbort() {
  try {
    print("Press [${green('R')}]etry or [${red('A')}]bort to continue.");
    stdin.echoMode = false;
    stdin.lineMode = false;
    while (true) {
      var input = stdin.readByteSync();
      if (input == 82 || input == 114) return true; // Retry
      if (input == 65 || input == 97) return false; // Abort
    }
  } finally {
    stdin.lineMode = true;
    stdin.echoMode = true;
  }
}
