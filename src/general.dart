import 'dart:convert';
import 'package:convert/convert.dart';
import 'package:dcli/dcli.dart' hide verbose;
import 'package:znn_sdk_dart/znn_sdk_dart.dart';
import 'src.dart';

void generalMenu() {
  print('  ${white('General')}');
  print(
      '    send toAddress amount [${green('ZNN')}/${blue('QSR')}/${magenta('ZTS')}]');
  print('    receive blockHash');
  print('    receiveAll');
  print('    unreceived');
  print('    unconfirmed');
  print('    balance address');
  print('    frontierMomentum');
  print('    createHash "string" [hashType preimageLength]');
  print('    version');
}

Future<void> generalFunctions() async {
  switch (args[0]) {
    case 'send':
      verbose ? print('Description: Send tokens to an address') : null;
      await _send();
      return;

    case 'receive':
      verbose
          ? print('Description: Manually receive a transaction by blockHash')
          : null;
      await _receive();
      return;

    case 'receiveAll':
      verbose ? print('Description: Receive all pending transactions') : null;
      await _receiveAll();
      return;

    case 'autoreceive':
      verbose ? print('Description: Automatically receive transactions') : null;
      await _autoreceive();
      return;

    case 'unreceived':
      verbose
          ? print('Description: List pending/unreceived transactions')
          : null;
      await _unreceived();
      return;

    case 'unconfirmed':
      verbose ? print('Description: List unconfirmed transactions') : null;
      await _unconfirmed();
      return;

    case 'balance':
      verbose ? print('Description: List account balance') : null;
      await _balance();
      return;

    case 'frontierMomentum':
      verbose ? print('Description: Display frontier momentum') : null;
      await _frontierMomentum();
      return;

    case 'createHash':
      verbose
          ? print(
              'Description: Create hash digests by using the stated algorithm')
          : null;
      await _createHash();
      return;

    case 'version':
      verbose ? print('Description: Display version information') : null;
      _version();
      return;

    default:
      invalidCommand();
  }
}

void _version() {
  print('$znnCli v$znnCliVersion using Zenon SDK v$znnSdkVersion');
  print(getZnndVersion(znnDaemon));
}

Future<void> _send() async {
  if (!(args.length == 4 || args.length == 5)) {
    print('Incorrect number of arguments. Expected:');
    print(
        'send toAddress amount [${green('ZNN')}/${blue('QSR')}/${magenta('ZTS')}]');
    return;
  }

  Address recipient = Address.parse(args[1]);
  TokenStandard tokenStandard = getTokenStandard(args[3]);
  Token token = (await znnClient.embedded.token.getByZts(tokenStandard))!;
  BigInt amount =
      AmountUtils.extractDecimals(num.parse(args[2]), token.decimals);

  if (!await hasBalance(znnClient, address, tokenStandard, amount)) {
    return;
  }

  var block = AccountBlockTemplate.send(recipient, tokenStandard, amount);

  if (args.length == 5) {
    block.data = AsciiEncoder().convert(args[4]);
    print(
        'Sending ${AmountUtils.addDecimals(amount, token.decimals)} ${token.symbol} to ${args[1]} with a message "${args[4]}"');
  } else {
    print(
        'Sending ${AmountUtils.addDecimals(amount, token.decimals)} ${token.symbol} to ${args[1]}');
  }

  await znnClient.send(block);
  print('Done');
}

Future<void> _receive() async {
  if (args.length != 2) {
    print('Incorrect number of arguments. Expected:');
    print('receive blockHash');
    return;
  }
  Hash sendBlockHash = Hash.parse(args[1]);
  print('Please wait ...');
  await znnClient.send(AccountBlockTemplate.receive(sendBlockHash));
  print('Done');
}

Future<void> _receiveAll() async {
  var unreceived = await znnClient.ledger
      .getUnreceivedBlocksByAddress(address, pageIndex: 0, pageSize: 5);
  if (unreceived.count == 0) {
    print('Nothing to receive');
    return;
  } else {
    if (unreceived.more!) {
      print(
          'You have ${red('more')} than ${green(unreceived.count.toString())} transaction(s) to receive');
    } else {
      print(
          'You have ${green(unreceived.count.toString())} transaction(s) to receive');
    }
  }

  print('Please wait ...');
  while (unreceived.count! > 0) {
    for (var block in unreceived.list!) {
      await znnClient.send(AccountBlockTemplate.receive(block.hash));
    }
    unreceived = await znnClient.ledger
        .getUnreceivedBlocksByAddress(address, pageIndex: 0, pageSize: 5);
  }
  print('Done');
}

Future<void> _autoreceive() async {
  znnClient.wsClient.addOnConnectionEstablishedCallback((broadcaster) async {
    print('Subscribing for account-block events ...');
    await znnClient.subscribe.toAllAccountBlocks();
    print('Subscribed successfully!');

    broadcaster.listen((json) async {
      if (json!['method'] == 'ledger.subscription') {
        for (var i = 0; i < json['params']['result'].length; i += 1) {
          var tx = json['params']['result'][i];
          if (tx['toAddress'] != address.toString()) {
            continue;
          }
          var hash = tx['hash'];
          print('receiving transaction with hash $hash');
          var template = await znnClient
              .send(AccountBlockTemplate.receive(Hash.parse(hash)));
          print(
              'successfully received $hash. Receive-block-hash ${template.hash}');
          await Future.delayed(Duration(seconds: 1));
        }
      }
    });
  });

  for (;;) {
    await Future.delayed(Duration(seconds: 1));
  }
}

Future<void> _unreceived() async {
  var unreceived = await znnClient.ledger
      .getUnreceivedBlocksByAddress(address, pageIndex: 0, pageSize: 5);

  if (unreceived.count == 0) {
    print('Nothing to receive');
  } else {
    if (unreceived.more!) {
      print(
          'You have ${red('more')} than ${green(unreceived.count.toString())} transaction(s) to receive');
    } else {
      print(
          'You have ${green(unreceived.count.toString())} transaction(s) to receive');
    }
    print('Showing the first ${unreceived.list!.length}');
  }

  for (var block in unreceived.list!) {
    print(
        'Unreceived ${block.amount} ${block.token!.symbol} from ${block.address.toString()}. Use the hash ${block.hash} to receive');
  }
}

Future<void> _unconfirmed() async {
  var unconfirmed = await znnClient.ledger
      .getUnconfirmedBlocksByAddress(address, pageIndex: 0, pageSize: 5);

  if (unconfirmed.count == 0) {
    print('No unconfirmed transactions');
  } else {
    print(
        'You have ${green(unconfirmed.count.toString())} unconfirmed transaction(s)');
    print('Showing the first ${unconfirmed.list!.length}');
  }

  var encoder = JsonEncoder.withIndent('     ');
  for (var block in unconfirmed.list!) {
    print(encoder.convert(block.toJson()));
  }
}

Future<void> _balance() async {
  if (args.length != 2) {
    print('Incorrect number of arguments. Expected:');
    print('balance address');
    return;
  }

  Address address = Address.parse(args[1]);

  AccountInfo info = await znnClient.ledger.getAccountInfoByAddress(address);
  print(
      'Balance for account-chain ${info.address!.toString()} having height ${info.blockCount}');
  if (info.balanceInfoList!.isEmpty) {
    print('  No coins or tokens at address ${address.toString()}');
  }
  for (BalanceInfoListItem entry in info.balanceInfoList!) {
    print(
        '  ${AmountUtils.addDecimals(entry.balance!, entry.token!.decimals)} ${entry.token!.symbol} '
        '${entry.token!.domain} ${entry.token!.tokenStandard.toString()}');
  }
}

Future<void> _frontierMomentum() async {
  Momentum currentFrontierMomentum =
      await znnClient.ledger.getFrontierMomentum();
  print('Momentum height: ${currentFrontierMomentum.height.toString()}');
  print('Momentum hash: ${currentFrontierMomentum.hash.toString()}');
  print(
      'Momentum previousHash: ${currentFrontierMomentum.previousHash.toString()}');
  print('Momentum timestamp: ${currentFrontierMomentum.timestamp.toString()}');
}

Future<void> _createHash() async {
  if (args.length > 3) {
    print('Incorrect number of arguments. Expected:');
    print('createHash [hashType preimageLength]');
    return;
  }

  Hash hash;
  int hashType = 0;
  final List<int> preimage;
  int preimageLength = htlcPreimageDefaultLength;

  if (args.length >= 2) {
    try {
      hashType = int.parse(args[1]);
      if (hashType > 1) {
        print(
            '${red('Error!')} Invalid hash type. Value $hashType not supported.');
        return;
      }
    } catch (e) {
      print('${red('Error!')} hash type must be an integer.');
      print('Supported hash types:');
      print('  0: SHA3-256');
      print('  1: SHA2-256');
      return;
    }
  }

  if (args.length == 3) {
    try {
      preimageLength = int.parse(args[2]);
    } catch (e) {
      print('${red('Error!')} preimageLength must be an integer.');
      return;
    }
  }

  if (preimageLength > htlcPreimageMaxLength ||
      preimageLength < htlcPreimageMinLength) {
    print(
        '${red('Error!')} Invalid preimageLength. Preimage must be $htlcPreimageMaxLength bytes or less.');
    return;
  }
  if (preimageLength < htlcPreimageDefaultLength) {
    print(
        '${yellow('Warning!')} preimageLength is less than $htlcPreimageDefaultLength and may be insecure');
  }
  preimage = generatePreimage(preimageLength);
  print('Preimage: ${hex.encode(preimage)}');

  switch (hashType) {
    case 1:
      hash = Hash.fromBytes(await Crypto.sha256Bytes(preimage));
      print('SHA-256 Hash: $hash');
      return;
    default:
      hash = Hash.digest(preimage);
      print('SHA-3 Hash: $hash');
      return;
  }
}
