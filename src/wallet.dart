import 'dart:io';

import 'package:bip39/bip39.dart' as bip39;
import 'package:dcli/dcli.dart' hide verbose;
import 'package:path/path.dart' as path;
import 'package:znn_sdk_dart/znn_sdk_dart.dart';
import 'src.dart';

void walletMenu() {
  print('  ${white('Wallet')}');
  print('    wallet.list');
  print('    wallet.createNew passphrase [keyStoreName]');
  print(
      '    wallet.createFromMnemonic "${green('mnemonic')}" passphrase [keyStoreName]');
  print('    wallet.dumpMnemonic');
  print('    wallet.deriveAddresses start end');
  print('    wallet.export filePath');
}

Future<void> walletFunctions() async {
  switch (args[0].split('.')[1]) {
    case 'list':
      verbose ? print('Description: List all wallets') : null;
      await _list();
      return;

    case 'createNew':
      verbose ? print('Description: Create a new wallet') : null;
      await _createNew();
      return;

    case 'createFromMnemonic':
      verbose
          ? print('Description: Create a new wallet from a mnemonic')
          : null;
      await _createFromMnemonic();
      return;

    case 'dumpMnemonic':
      verbose ? print('Description: Dump the mnemonic of a wallet') : null;
      await _dumpMnemonic();
      return;

    case 'deriveAddresses':
      verbose
          ? print('Description: Derive one or more addresses of a wallet')
          : null;
      await _deriveAddresses();
      return;

    case 'export':
      verbose ? print('Description: Export wallet') : null;
      await _export();
      return;

    default:
      invalidCommand();
  }
}

Future<void> _list() async {
  List<File> stores = await znnClient.keyStoreManager.listAllKeyStores();
  if (stores.isNotEmpty) {
    print('Available keyStores:');
    for (File store in stores) {
      print(path.basename(store.path));
    }
  } else {
    print('No keyStores found');
  }
}

Future<void> _createNew() async {
  if (!(args.length == 2 || args.length == 3)) {
    print('Incorrect number of arguments. Expected:');
    print('wallet.createNew passphrase [keyStoreName]');
    return;
  }

  String? name;
  if (args.length == 3) name = args[2];

  File keyStore = await znnClient.keyStoreManager.createNew(args[1], name);
  print(
      'keyStore ${green('successfully')} created: ${path.basename(keyStore.path)}');
}

Future<void> _createFromMnemonic() async {
  if (!(args.length == 3 || args.length == 4)) {
    print('Incorrect number of arguments. Expected:');
    print(
        'wallet.createFromMnemonic "${green('mnemonic')}" passphrase [keyStoreName]');
    return;
  }
  if (!bip39.validateMnemonic(args[1])) {
    throw AskValidatorException(red('Invalid mnemonic'));
  }

  String? name;
  if (args.length == 4) name = args[3];
  File keyStore = await znnClient.keyStoreManager
      .createFromMnemonic(args[1], args[2], name);
  print(
      'keyStore ${green('successfully')} created from mnemonic: ${path.basename(keyStore.path)}');
}

Future<void> _dumpMnemonic() async {
  print('Mnemonic for keyStore ${znnClient.defaultKeyStorePath!}');
  print(znnClient.defaultKeyStore!.mnemonic);
}

Future<void> _deriveAddresses() async {
  if (args.length != 3) {
    print('Incorrect number of arguments. Expected:');
    print('wallet.deriveAddresses');
    return;
  }

  print('Addresses for keyStore ${znnClient.defaultKeyStorePath!}');
  int left = int.parse(args[1]);
  int right = int.parse(args[2]);
  List<Address?> addresses =
      await znnClient.defaultKeyStore!.deriveAddressesByRange(left, right);
  for (int i = 0; i < right - left; i += 1) {
    print('  ${i + left}\t${addresses[i].toString()}');
  }
}

Future<void> _export() async {
  if (args.length != 2) {
    print('Incorrect number of arguments. Expected:');
    print('wallet.export filePath');
    return;
  }

  await znnClient.defaultKeyStorePath!.copy(args[1]);
  print('Done! Check the current directory');
}
