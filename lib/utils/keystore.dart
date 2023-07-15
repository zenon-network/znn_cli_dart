import 'dart:io';

import 'package:args/args.dart';
import 'package:dcli/dcli.dart';
import 'package:path/path.dart' as path;
import 'package:znn_cli_dart/lib.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

Future<void> unlockKeystore(ArgResults argResult) async {
  // Get keyStoreFile
  File keyStoreFile;
  List<File> allKeyStores = await znnClient.keyStoreManager.listAllKeyStores();

  if (allKeyStores.isEmpty) {
    // Make sure at least one keyStore exists
    print('${red('Error!')} No keyStore in the default directory');
    return;
  } else if (argResult.wasParsed('keyStore')) {
    // Use user provided keyStore: make sure it exists
    keyStoreFile =
        File(path.join(znnDefaultWalletDirectory.path, argResult['keyStore']));
    if (!keyStoreFile.existsSync()) {
      print(
          '${red('Error!')} The keyStore ${argResult['keyStore']} does not exist in the default directory');
      return;
    }
  } else if (allKeyStores.length == 1) {
    // In case there is just one keyStore, use it by default
    print(
        'Using the default keyStore ${green(path.basename(allKeyStores[0].path))}');
    keyStoreFile = allKeyStores[0];
  } else {
    // Multiple keyStores present, but none is selected: action required
    print(
        '${red('Error!')} Please provide a keyStore or an address. Use ${green('wallet.list')} to list all available keyStores');
    return;
  }

  String? passphrase;
  if (argResult.wasParsed('passphrase')) {
    passphrase = argResult['passphrase'];
  } else {
    passphrase = enterPassphrase();
  }

  int index = 0;
  if (argResult.wasParsed('index')) {
    index = int.parse(argResult['index']);
  }
  try {
    znnClient.defaultKeyStore =
        await znnClient.keyStoreManager.readKeyStore(passphrase!, keyStoreFile);
    znnClient.defaultKeyStorePath = keyStoreFile;
  } on Exception catch (e) {
    if (e == IncorrectPasswordException) {
      print('${red('Error!')} Invalid passphrase for keyStore $keyStoreFile');
    } else {
      rethrow;
    }
  }

  znnClient.defaultKeyPair = znnClient.defaultKeyStore!.getKeyPair(index);
  address = (await znnClient.defaultKeyPair!.address)!;
  logger.info('Using address ${green(address.toString())}');
}
