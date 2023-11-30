import 'dart:io';

import 'package:args/args.dart';
import 'package:dcli/dcli.dart';
import 'package:znn_cli_dart/lib.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

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
