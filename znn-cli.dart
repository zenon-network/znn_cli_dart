import 'dart:async';
import 'package:args/args.dart';
import 'package:znn_cli_dart/lib.dart';

import 'package:znn_sdk_dart/znn_sdk_dart.dart';

Future<int> main(List<String> _args) async {
  final ArgParser argParser = parseArgs(_args);
  final argResult = argParser.parse(_args);
  args = argResult.rest;

  handleFlags(argResult, argParser.usage);

  ensureDirectoriesExist();
  if (!commandsWithoutKeyStore.contains(args[0])) {
    await unlockKeystore(argResult);
  }

  await connectToNode(argResult);
  await handleCli();
  znnClient.wsClient.stop();
  return 0;
}
