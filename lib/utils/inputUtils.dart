import 'dart:io';

String? enterPassphrase() {
  print('Insert passphrase:');
  stdin.echoMode = false;
  String? passphrase = stdin.readLineSync();
  stdin.echoMode = true;
  return passphrase;
}
