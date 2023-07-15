import 'dart:io';

import 'package:args/args.dart';
import 'package:logging/logging.dart' as log;
import 'package:znn_cli_dart/lib.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

String argsUsage = '';

ArgParser parseArgs(List<String> _args) {
  final ArgParser argParser = ArgParser();

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

  return argParser;
}

void handleFlags(ArgResults argResult, String _argsUsage) {
  argsUsage = _argsUsage;

  if (argResult['admin'] || (args.isNotEmpty && (args[0] == 'admin'))) {
    adminHelp();
    exit(0);
  }

  if (args.isEmpty || args[0] == 'help') {
    fullMenu();
    exit(0);
  }

  if (args.isNotEmpty && argResult['help']) {
    handleHelp();
  }

  if (argResult.wasParsed('verbose')) {
    log.hierarchicalLoggingEnabled = true;
    logger.level = Level.INFO;
    verbose = true;
  }

  if (!(commandsWithoutKeyStore.contains(args[0]) ||
      commandsWithKeyStore.contains(args[0]) ||
      adminCommands.contains(args[0]))) {
    invalidCommand();
    exit(-1);
  }
}

void handleHelp() {
  String command = args[0].split('.')[0];

  switch (command) {
    case 'general':
      generalMenu();
      exit(0);
    case 'stats':
      statsMenu();
      exit(0);
    case 'plasma':
      plasmaMenu();
      exit(0);
    case 'sentinel':
      sentinelMenu();
      exit(0);
    case 'staking':
      stakingMenu();
      exit(0);
    case 'pillar':
      pillarMenu();
      exit(0);
    case 'token':
      tokenMenu();
      exit(0);
    case 'wallet':
      walletMenu();
      exit(0);
    case 'az':
      acceleratorMenu();
      exit(0);
    case 'spork':
      sporkMenu();
      exit(0);
    case 'htlc':
      htlcMenu();
      exit(0);
    case 'bridge':
      bridgeMenu();
      exit(0);
    case 'liquidity':
      liquidityMenu();
      exit(0);
    case 'orchestrator':
      orchestratorMenu();
      exit(0);
    case 'admin':
      bridgeAdminMenu();
      liquidityAdminMenu();
      exit(0);
    default:
      break;
  }
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

void header() {
  print('USAGE:');
  print('  $znnCli [OPTIONS] [FLAGS]\n');
  print('FLAGS:');
  print(argsUsage + '\n');
  print('OPTIONS:');
}

void fullMenu() {
  header();
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
  header();
  bridgeAdminMenu();
  liquidityAdminMenu();
}
