import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:convert/convert.dart';
import 'package:dcli/dcli.dart' hide verbose;
import 'package:znn_sdk_dart/znn_sdk_dart.dart';
import 'src.dart';

void htlcMenu() {
  print('  ${white('HTLC')}');
  print(
      '    htlc.create hashLockedAddress tokenStandard amount expirationTime (in hours) [hashType hashLock]');
  print('    htlc.unlock id preimage');
  print('    htlc.reclaim id');
  print('    htlc.get id');
  print('    htlc.inspect blockHash');
  print('    htlc.getProxyStatus address');
  print('    htlc.denyProxy');
  print('    htlc.allowProxy');
  print('    htlc.monitor id');
}

Future<void> htlcFunctions() async {
  switch (args[0].split('.')[1]) {
    case 'create':
      verbose ? print('Description: Create an htlc') : null;
      await _create();
      return;

    case 'unlock':
      verbose ? print('Description: Unlock an active htlc') : null;
      await _unlock();
      return;

    case 'reclaim':
      verbose ? print('Description: Reclaim an expired htlc') : null;
      await _reclaim();
      return;

    case 'get':
      verbose ? print('Description: Display htlc details') : null;
      await _get();
      return;

    case 'inspect':
      verbose ? print('Description: Inspect htlc account-block') : null;
      await _inspect();
      return;

    case 'getProxyStatus':
      verbose
          ? print('Description: Display proxy unlock status for an address')
          : null;
      await _getProxyStatus();
      return;

    case 'denyProxy':
      verbose ? print('Description: Deny htlc proxy unlock') : null;
      await _denyProxy();
      return;

    case 'allowProxy':
      verbose ? print('Description: Allow htlc proxy unlock') : null;
      await _allowProxy();
      return;

    case 'monitor':
      verbose
          ? print(
              'Description: Monitor htlc by id -- automatically reclaim it or display its preimage')
          : null;
      await _monitor();
      return;

    default:
      invalidCommand();
  }
}

Future<void> _create() async {
  if (args.length < 5 || args.length > 7) {
    print('Incorrect number of arguments. Expected:');
    print(
        'htlc.create hashLockedAddress tokenStandard amount expirationTime (in hours) [hashType hashLock]');
    return;
  }

  Address hashLockedAddress;
  TokenStandard tokenStandard = getTokenStandard(args[2]);
  BigInt amount;
  int expirationTime;
  late Hash hashLock;
  int keyMaxSize = htlcPreimageMaxLength;
  int hashType = 0;
  List<int> preimage = generatePreimage(htlcPreimageDefaultLength);

  int htlcTimelockMinHours = 1;
  int htlcTimelockMaxHours = htlcTimelockMinHours * 24;

  try {
    hashLockedAddress = Address.parse(args[1]);
  } catch (e) {
    print('${red('Error!')} hashLockedAddress must be a valid address');
    return;
  }

  Token token = (await znnClient.embedded.token.getByZts(tokenStandard))!;
  amount = AmountUtils.extractDecimals(num.parse(args[3]), token.decimals);

  if (amount <= BigInt.zero) {
    print('${red('Error!')} amount must be greater than 0');
    return;
  }

  if (!await hasBalance(znnClient, address, tokenStandard, amount)) {
    return;
  }

  if (args.length >= 6) {
    try {
      hashType = int.parse(args[5]);
    } catch (e) {
      print('${red('Error!')} hash type must be an integer.');
      print('Supported hash types:');
      print('  0: SHA3-256');
      print('  1: SHA2-256');
      return;
    }
  }

  if (args.length == 7) {
    try {
      hashLock = Hash.parse(args[6]);
    } catch (e) {
      print('${red('Error!')} hashLock is not a valid hash');
      return;
    }
  } else {
    switch (hashType) {
      case 1:
        hashLock = Hash.fromBytes(await Crypto.sha256Bytes(preimage));
        return;
      default:
        hashLock = Hash.digest(preimage);
    }
  }

  try {
    expirationTime = int.parse(args[4]);
  } catch (e) {
    print('${red('Error!')} expirationTime must be an integer.');
    return;
  }

  if (expirationTime < htlcTimelockMinHours ||
      expirationTime > htlcTimelockMaxHours) {
    print(
        '${red('Error!')} expirationTime (hours) must be at least $htlcTimelockMinHours and at most $htlcTimelockMaxHours.');
    return;
  }

  expirationTime *= 60 * 60; // convert to seconds
  final duration = Duration(seconds: expirationTime);
  format(Duration d) => d.toString().split('.').first.padLeft(8, '0');
  Momentum currentFrontierMomentum =
      await znnClient.ledger.getFrontierMomentum();
  int currentTime = currentFrontierMomentum.timestamp;
  expirationTime += currentTime;

  if (args.length == 7) {
    print(
        'Creating htlc with amount ${AmountUtils.addDecimals(amount, token.decimals)} ${token.symbol}');
  } else {
    print(
        'Creating htlc with amount ${AmountUtils.addDecimals(amount, token.decimals)} ${token.symbol} using preimage ${green(hex.encode(preimage))}');
  }
  print('  Can be reclaimed in ${format(duration)} by $address');
  print(
      '  Can be unlocked by $hashLockedAddress with hashlock $hashLock hashtype $hashType');

  AccountBlockTemplate block = await znnClient.send(znnClient.embedded.htlc
      .create(token, amount, hashLockedAddress, expirationTime, hashType,
          keyMaxSize, hashLock.getBytes()));

  print('Submitted htlc with id ${green(block.hash.toString())}');
  print('Done');
}

Future<void> _unlock() async {
  if (args.length < 2 || args.length > 3) {
    print('Incorrect number of arguments. Expected:');
    print('htlc.unlock id preimage');
    return;
  }

  Hash id;
  String preimage = '';
  late Hash preimageCheck;
  int hashType = 0;
  int currentTime = ((DateTime.now().millisecondsSinceEpoch) / 1000).floor();

  try {
    id = Hash.parse(args[1]);
  } catch (e) {
    print('${red('Error!')} id is not a valid hash');
    return;
  }

  HtlcInfo htlc;
  try {
    htlc = await znnClient.embedded.htlc.getById(id);
    hashType = htlc.hashType;
  } catch (e) {
    print('${red('Error!')} The htlc id $id does not exist');
    return;
  }

  if (!await znnClient.embedded.htlc.getProxyUnlockStatus(htlc.hashLocked)) {
    print('${red('Error!')} Cannot unlock htlc. Permission denied');
    return;
  } else if (htlc.expirationTime <= currentTime) {
    print('${red('Error!')} Cannot unlock htlc. Time lock expired');
    return;
  }

  if (args.length == 2) {
    print('Insert preimage:');
    stdin.echoMode = false;
    preimage = stdin.readLineSync()!;
    stdin.echoMode = true;
  } else if (args.length == 3) {
    preimage = args[2];
  }

  if (preimage.isEmpty) {
    print('${red('Error!')} Cannot unlock htlc. Invalid pre-image');
    return;
  }

  switch (hashType) {
    case 1:
      print('HashType 1 detected. Encoding preimage to SHA-256...');
      preimageCheck =
          Hash.fromBytes(await Crypto.sha256Bytes(hex.decode(preimage)));
      return;
    default:
      preimageCheck = (Hash.digest(hex.decode(preimage)));
  }

  if (preimageCheck != Hash.fromBytes(htlc.hashLock)) {
    print('${red('Error!')} preimage does not match the hashlock');
    return;
  }

  await znnClient.embedded.token.getByZts(htlc.tokenStandard).then((token) => print(
      'Unlocking htlc id ${htlc.id} with amount ${AmountUtils.addDecimals(htlc.amount, token!.decimals)} ${token.symbol}'));

  await znnClient
      .send(znnClient.embedded.htlc.unlock(id, hex.decode(preimage)));
  print('Done');
  print(
      'Use ${green('receiveAll')} to collect your htlc amount after 2 momentums');
}

Future<void> _reclaim() async {
  if (args.length != 2) {
    print('Incorrect number of arguments. Expected:');
    print('htlc.reclaim id');
    return;
  }

  Hash id;
  int currentTime = ((DateTime.now().millisecondsSinceEpoch) / 1000).floor();

  try {
    id = Hash.parse(args[1]);
  } catch (e) {
    print('${red('Error!')} id is not a valid hash');
    return;
  }

  HtlcInfo htlc;
  try {
    htlc = await znnClient.embedded.htlc.getById(id);
  } catch (e) {
    print('${red('Error!')} The htlc id $id does not exist');
    return;
  }

  if (htlc.expirationTime > currentTime) {
    format(Duration d) => d.toString().split('.').first.padLeft(8, '0');
    print(
        '${red('Error!')} Cannot reclaim htlc. Try again in ${format(Duration(seconds: htlc.expirationTime - currentTime))}.');
    return;
  }

  if (htlc.timeLocked != address) {
    print('${red('Error!')} Cannot reclaim htlc. Permission denied');
    return;
  }

  await znnClient.embedded.token.getByZts(htlc.tokenStandard).then((token) => print(
      'Reclaiming htlc id ${htlc.id} with amount ${AmountUtils.addDecimals(htlc.amount, token!.decimals)} ${token.symbol}'));

  await znnClient.send(znnClient.embedded.htlc.reclaim(id));
  print('Done');
  print(
      'Use ${green('receiveAll')} to collect your htlc amount after 2 momentums');
}

Future<void> _get() async {
  if (args.length != 2) {
    print('Incorrect number of arguments. Expected:');
    print('htlc.get id');
    return;
  }

  Hash id;
  int currentTime = ((DateTime.now().millisecondsSinceEpoch) / 1000).floor();
  format(Duration d) => d.toString().split('.').first.padLeft(8, '0');

  try {
    id = Hash.parse(args[1]);
  } catch (e) {
    print('${red('Error!')} id is not a valid hash');
    return;
  }

  HtlcInfo htlc;
  try {
    htlc = await znnClient.embedded.htlc.getById(id);
  } catch (e) {
    print('The htlc id $id does not exist');
    return;
  }

  await znnClient.embedded.token.getByZts(htlc.tokenStandard).then((token) => print(
      'Htlc id ${htlc.id} with amount ${AmountUtils.addDecimals(htlc.amount, token!.decimals)} ${token.symbol}'));
  if (htlc.expirationTime > currentTime) {
    print(
        '   Can be unlocked by ${htlc.hashLocked} with hashlock ${Hash.fromBytes(htlc.hashLock)} hashtype ${htlc.hashType}');
    print(
        '   Can be reclaimed in ${format(Duration(seconds: htlc.expirationTime - currentTime))} by ${htlc.timeLocked}');
  } else {
    print('   Can be reclaimed now by ${htlc.timeLocked}');
  }

  print('Done');
}

Future<void> _inspect() async {
  if (args.length != 2) {
    print('Incorrect number of arguments. Expected:');
    print('htlc.inspect blockHash');
    return;
  }

  Hash blockHash = Hash.parse(args[1]);
  var block = await znnClient.ledger.getAccountBlockByHash(blockHash);

  if (block == null) {
    print('The account block ${blockHash.toString()} does not exist');
    return;
  }

  if (block.pairedAccountBlock == null ||
      block.blockType != BlockTypeEnum.userSend.index) {
    print('The account block was not sent by a user');
    return;
  }

  Function eq = const ListEquality().equals;
  late AbiFunction f;
  for (var entry in Definitions.htlc.entries) {
    if (eq(AbiFunction.extractSignature(entry.encodeSignature()),
        AbiFunction.extractSignature(block.data))) {
      f = AbiFunction(entry.name!, entry.inputs!);
    }
  }

  if (f.name == null) {
    print('The account block contains invalid data');
    return;
  }

  var txArgs = f.decode(block.data);
  if (f.name.toString() == 'Unlock') {
    if (txArgs.length != 2) {
      print('The account block has an invalid unlock argument length');
      return;
    }
    String preimage = hex.encode(txArgs[1]);
    print(
        'Unlock htlc: id ${cyan(txArgs[0].toString())} unlocked by ${block.address} with pre-image: ${green(preimage)}');
  } else if (f.name.toString() == 'Reclaim') {
    if (txArgs.length != 1) {
      print('The account block has an invalid reclaim argument length');
      return;
    }
    print(
        'Reclaim htlc: id ${red(txArgs[0].toString())} reclaimed by ${block.address}');
  } else if (f.name.toString() == 'Create') {
    if (txArgs.length != 5) {
      print('The account block has an invalid create argument length');
      return;
    }

    var hashLocked = txArgs[0];
    var expirationTime = txArgs[1];
    var hashLock = Hash.fromBytes(txArgs[4]);
    var amount = block.amount;
    var token = block.token;
    var hashType = txArgs[2].toString();
    var keyMaxSize = txArgs[3].toString();
    print('Create htlc: ${hashLocked.toString()} '
        '${AmountUtils.addDecimals(amount, token!.decimals)} '
        '${token.symbol} $expirationTime '
        '$hashType '
        '$keyMaxSize '
        '${hashLock.toString()} '
        'created by ${block.address}');
  } else {
    print('The account block contains an unknown function call');
  }
}

Future<void> _getProxyStatus() async {
  if (args.length != 2) {
    print('Incorrect number of arguments. Expected:');
    print('htlc.getProxyStatus address');
    return;
  }

  try {
    address = Address.parse(args[1]);
  } catch (e) {
    print('${red('Error!')} address is not valid');
    return;
  }

  await znnClient.embedded.htlc.getProxyUnlockStatus(address).then((value) => print(
      'Htlc proxy unlocking is ${(value) ? green('allowed') : red('denied')} for ${address.toString()}'));

  print('Done');
}

Future<void> _denyProxy() async {
  await znnClient.send(znnClient.embedded.htlc.denyProxyUnlock()).then(
      (_) => print('Htlc proxy unlocking is denied for ${address.toString()}'));

  print('Done');
}

Future<void> _allowProxy() async {
  await znnClient.send(znnClient.embedded.htlc.allowProxyUnlock()).then((_) =>
      print('Htlc proxy unlocking is allowed for ${address.toString()}'));

  print('Done');
}

Future<void> _monitor() async {
  if (args.length != 2) {
    print('Incorrect number of arguments. Expected:');
    print('htlc.monitor id');
    return;
  }

  Hash id;
  HtlcInfo htlc;

  try {
    id = Hash.parse(args[1]);
  } catch (e) {
    print('${red('Error!')} id is not a valid hash');
    return;
  }

  try {
    htlc = await znnClient.embedded.htlc.getById(id);
  } catch (e) {
    print('The htlc id $id does not exist');
    return;
  }
  List<HtlcInfo> htlcs = [];
  htlcs.add(htlc);

  while (await _monitorAsync(znnClient, address, htlcs) != true) {
    await Future.delayed(Duration(seconds: 1));
  }
}

Future<bool> _monitorAsync(
    Zenon znnClient, Address address, List<HtlcInfo> htlcs) async {
  for (var htlc in htlcs) {
    print('Monitoring htlc id ${cyan(htlc.id.toString())}');
  }

  // Thread 1: append new htlc contract interactions to queue
  List<Hash> queue = [];
  znnClient.wsClient.addOnConnectionEstablishedCallback((broadcaster) async {
    print('Subscribing for htlc-contract events...');

    try {
      await znnClient.subscribe.toAllAccountBlocks();
    } catch (e) {
      print(e);
    }

    // Extract hashes for all new tx that interact with the htlc contract
    broadcaster.listen((json) async {
      if (json!['method'] == 'ledger.subscription') {
        for (var i = 0; i < json['params']['result'].length; i += 1) {
          var tx = json['params']['result'][i];
          if (tx['toAddress'] != htlcAddress.toString()) {
            continue;
          } else {
            var hash = tx['hash'];
            queue.add(Hash.parse(hash));
            print('Receiving transaction with hash ${orange(hash)}');
          }
        }
      }
    });
  });

  List<HtlcInfo> waitingToBeReclaimed = [];

  // Thread 2: if any tx in queue matches monitored htlc, remove it from queue
  for (;;) {
    if (htlcs.isEmpty && waitingToBeReclaimed.isEmpty) {
      break;
    }
    var currentTime = (DateTime.now().millisecondsSinceEpoch / 1000).round();
    List<HtlcInfo> _htlcs = htlcs.toList();

    for (var htlc in _htlcs) {
      // Reclaim any expired timeLocked htlc that is being monitored
      if (htlc.expirationTime <= currentTime) {
        print('Htlc id ${red(htlc.id.toString())} expired');

        if (htlc.timeLocked == address) {
          try {
            await znnClient.send(znnClient.embedded.htlc.reclaim(htlc.id));
            print('  Reclaiming htlc id ${red(htlc.id.toString())} now... ');
            htlcs.remove(htlc);
          } catch (e) {
            print('  Error occurred when reclaiming ${htlc.id}');
          }
        } else {
          print('  Waiting for ${htlc.timeLocked} to reclaim...');
          waitingToBeReclaimed.add(htlc);
          htlcs.remove(htlc);
        }
      }

      List<HtlcInfo> _waitingToBeReclaimed = waitingToBeReclaimed.toList();
      List<Hash> _queue = queue.toList();

      if (queue.isNotEmpty) {
        for (var hash in _queue) {
          // Identify if htlc tx are either 'Unlock' or 'Reclaim'
          var block = await znnClient.ledger.getAccountBlockByHash(hash);

          if (block?.blockType != BlockTypeEnum.userSend.index) {
            continue;
          }

          if (block?.pairedAccountBlock == null ||
              block?.pairedAccountBlock?.blockType !=
                  BlockTypeEnum.contractReceive.index) {
            continue;
          }

          if ((block?.pairedAccountBlock?.descendantBlocks)!.isEmpty) {
            continue;
          }

          Function eq = const ListEquality().equals;
          late AbiFunction f;
          for (var entry in Definitions.htlc.entries) {
            if (eq(AbiFunction.extractSignature(entry.encodeSignature()),
                AbiFunction.extractSignature((block?.data)!))) {
              f = AbiFunction(entry.name!, entry.inputs!);
            }
          }

          if (f.name == null) {
            continue;
          }

          // If 'Unlock', display its preimage
          for (var htlc in _htlcs) {
            if (f.name.toString() == 'Unlock') {
              var args = f.decode((block?.data)!);

              if (args.length != 2) {
                continue;
              }

              if (args[0].toString() != htlc.id.toString()) {
                continue;
              }

              if ((block?.pairedAccountBlock?.descendantBlocks)!.any((x) =>
                  x.blockType == BlockTypeEnum.contractSend.index &&
                  x.tokenStandard == htlc.tokenStandard &&
                  x.amount == htlc.amount)) {
                final preimage = hex.encode(args[1]);
                print(
                    'htlc id ${cyan(htlc.id.toString())} unlocked with pre-image: ${green(preimage)}');

                htlcs.remove(htlc);
              }
            }
          }

          // If 'Reclaim', inform user that a monitored, expired htlc
          // and has been reclaimed by the timeLocked address
          for (var htlc in _waitingToBeReclaimed) {
            if (f.name.toString() == 'Reclaim') {
              if (block?.address != htlc.timeLocked) {
                continue;
              }

              var args = f.decode((block?.data)!);

              if (args.length != 1) {
                continue;
              }

              if (args[0].toString() != htlc.id.toString()) {
                continue;
              }

              if ((block?.pairedAccountBlock?.descendantBlocks)!.any((x) =>
                  x.blockType == BlockTypeEnum.contractSend.index &&
                  x.toAddress == htlc.timeLocked &&
                  x.tokenStandard == htlc.tokenStandard &&
                  x.amount == htlc.amount)) {
                print(
                    'htlc id ${red(htlc.id.toString())} reclaimed by ${htlc.timeLocked}');
                waitingToBeReclaimed.remove(htlc);
              } else {
                print((block?.pairedAccountBlock?.descendantBlocks)!);
              }
            }
          }
          queue.remove(hash);
        }
      }
      await Future.delayed(Duration(seconds: 1));
    }
  }
  print('No longer monitoring the htlc');
  return true;
}
