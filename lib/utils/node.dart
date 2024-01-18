import 'dart:io';

import 'package:args/args.dart';
import 'package:dcli/dcli.dart';
import 'package:znn_cli_dart/lib.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';
import 'package:znn_ledger_dart/znn_ledger_dart.dart';

Future<void> connectToNode(ArgResults argResult) async {
  String? urlOption;
  bool urlOptionSupplied = false;

  if (argResult.wasParsed('url') && validateWsConnectionURL(argResult['url'])) {
    urlOption = argResult['url'];
    urlOptionSupplied = true;
  } else if (!validateWsConnectionURL(argResult['url'])) {
    print('${red('Error!')} Malformed URL. Please try again');
    exit(-1);
  } else {
    urlOption = 'ws://127.0.0.1:$defaultWsPort';
  }

  if (!commandsWithoutConnection.contains(args[0]) ||
      urlOptionSupplied == true) {
    await znnClient.wsClient.initialize(urlOption!, retry: false);
    await selectChainId(argResult);
  }
}

Future<void> selectChainId(ArgResults argResult) async {
  if (argResult.wasParsed('chain')) {
    String? chainOption = argResult['chain'];
    if (chainOption != 'auto') {
      chainId = int.parse(chainOption!);
    } else {
      await znnClient.ledger.getFrontierMomentum().then((value) {
        chainId = value.chainIdentifier.toInt();
      });
    }
  }
}

Future<AccountBlockTemplate> send(AccountBlockTemplate blockTemplate,
    [bool reconnect = false, int retries = 1]) async {
  try {
    if (reconnect) {
      if (znnClient.defaultKeyStore is LedgerWallet) {
        (znnClient.defaultKeyStore as LedgerWallet).disconnect();
      }
      // Reconnect the wallet.
      znnClient.defaultKeyStore = await znnClient.keyStoreManager
          .getWallet(walletDefinition, walletOptions);
      znnClient.defaultKeyPair =
          await znnClient.defaultKeyStore!.getAccount(accountIndex);
    }
    return await znnClient.send(blockTemplate);
  } catch (e) {
    if (e is ResponseError) {
      if (e.statusWord == StatusWord.unknownError) {
        print(
            '${red('Error!')} The Ledger ${walletDefinition.walletName} is not connected or unlocked.');
      } else if (e.statusWord == StatusWord.appIsNotOpen) {
        print(
            '${red('Error!')} The Zenon app is not open on the Ledger ${walletDefinition.walletName}.');
      } else if (e.statusWord == StatusWord.wrongResponseLength) {
        // This happens when the Ledger device was opened by another process.
        if (retries > 0) {
          return await send(blockTemplate, true, retries - 1);
        }
      }
    } else {
      print('${red('Error!')} Failed to send transaction $e.');
    }

    if (retries > 0) {
      if (confirm('Do you want to retry?', defaultValue: false)) {
        return await send(blockTemplate, true);
      } else {
        exit(-1);
      }
    }

    rethrow;
  }
}
