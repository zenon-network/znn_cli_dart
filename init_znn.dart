import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dcli/dcli.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

const znnDaemon = 'znnd';
const znnCli = 'znn-cli';
const znnCliVersion = '0.0.1';

String _argsUsage = '';

final znndConfigPath = File(path.join(znnDefaultDirectory.path, 'config.json'));

void help() {
  print('USAGE:');
  print('  $znnCli [OPTIONS] [FLAGS]\n');
  print('FLAGS:');
  print(_argsUsage + '\n');
  print('OPTIONS:');
  print('  General');
  print(
      '    send toAddress amount [${green('ZNN')}/${blue('QSR')}/${magenta('ZTS')}]');
  print('    receive blockHash');
  print('    receiveAll');
  print('    unreceived');
  print('    unconfirmed');
  print('    balance');
  print('    frontierMomentum');
  print('    version');
  print('  Plasma');
  print('    plasma.list [pageIndex pageCount]');
  print('    plasma.get');
  print('    plasma.fuse toAddress amount (in ${blue('QSR')})');
  print('    plasma.cancel id');
  print('  Sentinel');
  print('    sentinel.list');
  print('    sentinel.register');
  print('    sentinel.revoke');
  print('    sentinel.collect');
  print('    sentinel.withdrawQsr');
  print('  Staking');
  print('    stake.list [pageIndex pageCount]');
  print('    stake.register amount duration (in months)');
  print('    stake.revoke id');
  print('    stake.collect');
  print('  Pillar');
  print('    pillar.list');
  print(
      '    pillar.register name producerAddress rewardAddress giveBlockRewardPercentage giveDelegateRewardPercentage');
  print('    pillar.revoke name');
  print('    pillar.delegate name');
  print('    pillar.undelegate');
  print('    pillar.collect');
  print('    pillar.withdrawQsr');
  print('  ZTS Tokens');
  print('    token.list [pageIndex pageCount]');
  print('    token.getByStandard tokenStandard');
  print('    token.getByOwner ownerAddress');
  print(
      '    token.issue name symbol domain totalSupply maxSupply decimals isMintable isBurnable isUtility');
  print('    token.mint tokenStandard amount receiveAddress');
  print('    token.burn tokenStandard amount');
  print('    token.transferOwnership tokenStandard newOwnerAddress');
  print('    token.disableMint tokenStandard');
  print('  Wallet');
  print('    wallet.list');
  print('    wallet.createNew passphrase [keyStoreName]');
  print(
      '    wallet.createFromMnemonic "${green('mnemonic')}" passphrase [keyStoreName]');
  print('    wallet.dumpMnemonic');
  print('    wallet.deriveAddresses start end');
  print('    wallet.export filePath');
}

Future<int> initZnn(List<String> args, Function handler) async {
  final ArgParser argParser = ArgParser();
  final Zenon znnClient = Zenon();

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

  // Flags
  argParser.addFlag('verbose',
      abbr: 'v',
      negatable: false,
      help: 'Prints detailed information about the action that it performs');
  argParser.addFlag('help',
      abbr: 'h', negatable: false, help: 'Displays help information');

  final argResult = argParser.parse(args);
  args = argResult.rest;

  _argsUsage = argParser.usage;

  if (argResult['help'] ||
      args.isEmpty ||
      (args.isNotEmpty && (args[0] == 'help'))) {
    help();
    return 0;
  }

  if (argResult.wasParsed('verbose')) {
    logger.level = Level.INFO;
  }

  ensureDirectoriesExist();

  List<String> commandsWithKeyStore = [
    'send',
    'receive',
    'receiveAll',
    'autoreceive',
    'unreceived',
    'unconfirmed',
    'balance',
    'plasma.list',
    'plasma.fuse',
    'plasma.get',
    'plasma.cancel',
    'sentinel.list',
    'sentinel.register',
    'sentinel.revoke',
    'sentinel.collect',
    'sentinel.withdrawQsr',
    'stake.list',
    'stake.register',
    'stake.revoke',
    'stake.collect',
    'pillar.register',
    'pillar.revoke',
    'pillar.delegate',
    'pillar.undelegate',
    'pillar.collect',
    'pillar.withdrawQsr',
    'token.issue',
    'token.mint',
    'token.burn',
    'token.transferOwnership',
    'token.disableMint',
    'wallet.dumpMnemonic',
    'wallet.deriveAddresses',
    'wallet.export',
  ];

  List<String> commandsWithoutKeyStore = [
    'frontierMomentum',
    'version',
    'pillar.list',
    'token.list',
    'token.getByStandard',
    'token.getByOwner',
    'wallet.createNew',
    'wallet.createFromMnemonic',
    'wallet.list',
  ];

  List<String> commandsWithoutConnection = [
    'version',
    'wallet.createNew',
    'wallet.createFromMnemonic',
    'wallet.list',
    'wallet.dumpMnemonic',
    'wallet.deriveAddresses',
  ];

  if (!(commandsWithoutKeyStore.contains(args[0]) ||
      commandsWithKeyStore.contains(args[0]))) {
    print('${red('Error!')} Unrecognized command ${red(args[0])}');
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
      print("Insert passphrase:");
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
    var address = await znnClient.defaultKeyPair!.address;
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
  }

  await handler(args);

  znnClient.wsClient.stop();

  return 0;
}

String formatJSON(Map<dynamic, dynamic> j) {
  var spaces = ' ' * 4;
  var encoder = JsonEncoder.withIndent(spaces);
  return encoder.convert(j);
}

String formatAmount(int amount, int decimals) {
  return (amount / pow(10, decimals)).toStringAsFixed(decimals);
}

String formatDuration(int seconds) {
  format(Duration d) => d.toString().split('.').first.padLeft(8, '0');
  final duration = Duration(seconds: seconds);
  return format(duration);
}

Map<dynamic, dynamic> parseJSON(String fileName) {
  File file = File(fileName);
  if (file.existsSync()) {
    return json.decode(file.readAsStringSync());
  } else {
    return <dynamic, dynamic>{};
  }
}

Map<dynamic, dynamic> parseConfig() {
  if (znndConfigPath.existsSync()) {
    return json.decode(znndConfigPath.readAsStringSync());
  } else {
    return <dynamic, dynamic>{};
  }
}

bool writeConfig(Map<dynamic, dynamic> config) {
  try {
    znndConfigPath.writeAsStringSync(formatJSON(config));
  } on FileSystemException {
    return false;
  }
  return true;
}

bool isZnndRunning(String executableName) {
  switch (Platform.operatingSystem) {
    case 'linux':
      return Process.runSync('pgrep', [executableName], runInShell: true)
          .stdout
          .toString()
          .isNotEmpty;
    case 'windows':
      return Process.runSync('tasklist', [], runInShell: true)
          .stdout
          .toString()
          .contains(znnDaemon);
    case 'macos':
      return Process.runSync('pgrep', [executableName], runInShell: true)
          .stdout
          .toString()
          .isNotEmpty;
    default:
      return false;
  }
}

String getZnndVersion() {
  switch (Platform.operatingSystem) {
    case 'linux':
      return Process.runSync('./' + znnDaemon, ['-v'], runInShell: true)
          .stdout
          .toString();
    case 'windows':
      return Process.runSync('$znnDaemon.exe', ['-v'], runInShell: true)
          .stdout
          .toString();
    case 'macos':
      return Process.runSync('./' + znnDaemon, ['-v'], runInShell: true)
          .stdout
          .toString();
    default:
      return 'Unknown znnd version';
  }
}
