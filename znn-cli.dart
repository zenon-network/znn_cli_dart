import 'dart:async';
import 'dart:io';
import 'package:args/args.dart';
import 'package:dcli/dcli.dart' hide verbose;
import 'package:logging/logging.dart' as log;
import 'package:path/path.dart' as path;
import 'package:znn_sdk_dart/znn_sdk_dart.dart';
import 'src/src.dart';

String _argsUsage = '';

Future<int> main(List<String> _args) async {
  final ArgParser argParser = ArgParser();

  // Options
  argParser.addOption('url',
      abbr: 'u',
      defaultsTo: 'ws://127.0.0.1:$defaultWsPort',
      help: 'Provide a websocket $znnDaemon connection URL with a port');
  argParser.addOption('passphrase',
      abbr: 'p',
      help:
          'use this passphrase for the keyStore or enter it manually in a secure way');
  argParser.addOption('keyStore',
      abbr: 'k',
      defaultsTo: 'available keyStore if only one is present',
      help: 'Select the local keyStore');
  argParser.addOption('index',
      abbr: 'i', defaultsTo: '0', help: 'Address index');
  argParser.addOption('chain',
      abbr: 'c',
      defaultsTo: '1 (mainnet)',
      help: 'Chain Identifier for the connected node');

  // Flags
  argParser.addFlag('verbose',
      abbr: 'v',
      negatable: false,
      help: 'Prints detailed information about the action that it performs');
  argParser.addFlag('help',
      abbr: 'h', negatable: false, help: 'Displays help information');
  argParser.addFlag('admin',
      abbr: 'a', negatable: false, help: 'Displays admin functions');

  final argResult = argParser.parse(_args);
  args = argResult.rest;

  _argsUsage = argParser.usage;

  if (argResult['admin'] || (args.isNotEmpty && (args[0] == 'admin'))) {
    adminHelp();
    return 0;
  }

  if (argResult['help'] ||
      args.isEmpty ||
      (args.isNotEmpty && (args[0] == 'help'))) {
    help();
    return 0;
  }

  if (argResult.wasParsed('verbose')) {
    log.hierarchicalLoggingEnabled = true;
    logger.level = Level.INFO;
    verbose = true;
  }

  ensureDirectoriesExist();

  if (!(commandsWithoutKeyStore.contains(args[0]) ||
      commandsWithKeyStore.contains(args[0]) ||
      adminCommands.contains(args[0]))) {
    invalidCommand();
    exit(-1);
  }

  if (!commandsWithoutKeyStore.contains(args[0])) {
    // Get keyStoreFile
    File keyStoreFile;
    List<File> allKeyStores =
        await znnClient.keyStoreManager.listAllKeyStores();

    if (allKeyStores.isEmpty) {
      // Make sure at least one keyStore exists
      print('${red('Error!')} No keyStore in the default directory');
      return 0;
    } else if (argResult.wasParsed('keyStore')) {
      // Use user provided keyStore: make sure it exists
      keyStoreFile = File(
          path.join(znnDefaultWalletDirectory.path, argResult['keyStore']));
      if (!keyStoreFile.existsSync()) {
        print(
            '${red('Error!')} The keyStore ${argResult['keyStore']} does not exist in the default directory');
        return 0;
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
      return 0;
    }

    String? passphrase;
    if (argResult.wasParsed('passphrase')) {
      passphrase = argResult['passphrase'];
    } else {
      print('Insert passphrase:');
      stdin.echoMode = false;
      passphrase = stdin.readLineSync();
      stdin.echoMode = true;
    }

    int index = 0;
    if (argResult.wasParsed('index')) {
      index = int.parse(argResult['index']);
    }
    try {
      znnClient.defaultKeyStore = await znnClient.keyStoreManager
          .readKeyStore(passphrase!, keyStoreFile);
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

  String? _urlOption;
  bool urlOptionSupplied = false;

  if (argResult.wasParsed('url') && validateWsConnectionURL(argResult['url'])) {
    _urlOption = argResult['url'];
    urlOptionSupplied = true;
  } else if (!validateWsConnectionURL(argResult['url'])) {
    print('${red('Error!')} Malformed URL. Please try again');
    exit(-1);
  } else {
    _urlOption = 'ws://127.0.0.1:$defaultWsPort';
  }

  if (!commandsWithoutConnection.contains(args[0]) ||
      urlOptionSupplied == true) {
    if (!urlOptionSupplied && !isZnndRunning(znnDaemon)) {
      print('$znnDaemon is not running. Please try again');
      exit(-1);
    }

    await znnClient.wsClient.initialize(_urlOption!, retry: false);
    if (argResult.wasParsed('chain')) {
      String? _chainOption = argResult['chain'];
      if (_chainOption != 'auto') {
        chainId = int.parse(_chainOption!);
      } else {
        await znnClient.ledger.getFrontierMomentum().then((value) {
          chainId = value.chainIdentifier.toInt();
        });
      }
    }
  }

  await handleCli();
  znnClient.wsClient.stop();
  return 0;
}

void help() {
  print('USAGE:');
  print('  $znnCli [OPTIONS] [FLAGS]\n');
  print('FLAGS:');
  print(_argsUsage + '\n');
  print('OPTIONS:');
  generalMenu();
  statsMenu();
  plasmaMenu();
  sentinelMenu();
  stakingMenu();
  pillarMenu();
  tokenMenu();
  walletMenu();
  acceleratorMenu();
  sporkMenu();
  htlcMenu();
  bridgeMenu();
  liquidityMenu();
  orchestratorMenu();
}

void adminHelp() {
  print('USAGE:');
  print('  $znnCli [OPTIONS] [FLAGS]\n');
  print('FLAGS:');
  print(_argsUsage + '\n');
  print('OPTIONS:');
  bridgeAdminMenu();
  liquidityAdminMenu();
}

Future<void> handleCli() async {
  List<String> command = args[0].split('.');

  if (command.length == 1) {
    await generalFunctions();
  } else {
    if (command[0].contains('plasma')) {
      await plasmaFunctions();
    } else if (command[0].contains('stats')) {
      await statsFunctions();
    } else if (command[0].contains('sentinel')) {
      await sentinelFunctions();
    } else if (command[0].contains('staking')) {
      await stakingFunctions();
    } else if (command[0].contains('pillar')) {
      await pillarFunctions();
    } else if (command[0].contains('token')) {
      await tokenFunctions();
    } else if (command[0].contains('wallet')) {
      await walletFunctions();
    } else if (command[0].contains('az')) {
      await acceleratorFunctions();
    } else if (command[0].contains('spork')) {
      await sporkFunctions();
    } else if (command[0].contains('htlc')) {
      await htlcFunctions();
    } else if (command[0].contains('bridge')) {
      await bridgeFunctions();
    } else if (command[0].contains('liquidity')) {
      await liquidityFunctions();
    } else if (command[0].contains('orchestrator')) {
      await orchestatorFunctions();
    } else {
      invalidCommand();
    }
  }
}
