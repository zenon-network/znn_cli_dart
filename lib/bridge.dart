import 'dart:convert';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:dcli/dcli.dart' hide verbose;
import 'package:znn_cli_dart/lib.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

void bridgeMenu() {
  print('  ${white('Bridge')}');
  print('    bridge.info');
  print('    bridge.security');
  print('    bridge.timeChallenges');
  print('    bridge.orchestratorInfo');
  print('    bridge.fees [tokenStandard]');
  print('    bridge.network.list');
  print('    bridge.network.get networkClass chainId');
  print(
      '    bridge.wrap.token networkClass chainId toAddress amount tokenStandard');
  print('    bridge.wrap.list');
  print('    bridge.wrap.listByAddress address [networkClass chainId]');
  print('    bridge.wrap.listUnsigned');
  print('    bridge.wrap.get id');
  print('    bridge.unwrap.redeem transactionHash logIndex');
  print('    bridge.unwrap.redeemAll [bool]');
  print('    bridge.unwrap.list');
  print('    bridge.unwrap.listByAddress toAddress');
  print('    bridge.unwrap.listUnredeemed [toAddress]');
  print('    bridge.unwrap.get transactionHash logIndex');
  print('    bridge.guardian.proposeAdmin address');
}

void bridgeAdminMenu() {
  print('  ${white('Bridge Admin')}');
  print('    bridge.admin.emergency');
  print('    bridge.admin.halt');
  print('    bridge.admin.unhalt');
  print('    bridge.admin.enableKeyGen');
  print('    bridge.admin.disableKeyGen');
  print(
      '    bridge.admin.setTokenPair networkClass chainId tokenStandard tokenAddress bridgeable redeemable owned minAmount feePercentage redeemDelay metadata');
  print(
      '    bridge.admin.removeTokenPair networkClass chainId tokenStandard tokenAddress');
  print('    bridge.admin.revokeUnwrapRequest transactionHash logIndex');
  print('    bridge.admin.nominateGuardians address1 address2 ... addressN');
  print('    bridge.admin.changeAdmin address');
  print('    bridge.admin.setMetadata metadata');
  print(
      '    bridge.admin.setOrchestratorInfo windowSize keyGenThreshold confirmationsToFinality estimatedMomentumTime');
  print(
      '    bridge.admin.setNetwork networkClass chainId name contractAddress metadata');
  print('    bridge.admin.removeNetwork networkClass chainId');
  print('    bridge.admin.setNetworkMetadata networkClass chainId metadata');
}

Future<void> bridgeFunctions() async {
  switch (args[0].split('.')[1]) {
    case 'info':
      verbose ? print('Description: Get the bridge information') : null;
      await _info();
      return;

    case 'security':
      verbose
          ? print('Description: Get the bridge security information')
          : null;
      await _security();
      return;

    case 'timeChallenges':
      verbose ? print('Description: List all bridge time challenges') : null;
      await _timeChallenges();
      return;

    case 'orchestratorInfo':
      verbose ? print('Description: Get the orchestrator information') : null;
      await _orchestratorInfo();
      return;

    case 'fees':
      verbose
          ? print(
              'Description: Display the accumulated wrapping fees for a ZTS')
          : null;
      await _fees();
      return;

    case 'network':
      await _networkFunctions();
      return;

    case 'wrap':
      await _wrapFunctions();
      return;

    case 'unwrap':
      await _unwrapFunctions();
      return;

    case 'guardian':
      await _guardianFunctions();
      return;

    case 'admin':
      await _adminFunctions();
      return;

    default:
      invalidCommand();
  }
}

Future<void> _info() async {
  BridgeInfo info = await znnClient.embedded.bridge.getBridgeInfo();
  var metadata = jsonDecode(info.metadata);
  print('Bridge info:');
  print('   Administrator: ${info.administrator}');
  print('   Compressed TSS ECDSA public key: ${info.compressedTssECDSAPubKey}');
  print(
      '   Decompressed TSS ECDSA public key: ${info.decompressedTssECDSAPubKey}');
  print('   Allow key generation: ${info.allowKeyGen}');
  print('   Is halted: ${info.halted}');
  print('   Unhalted at: ${info.unhaltedAt}');
  print('   Unhalt duration in momentums: ${info.unhaltDurationInMomentums}');
  print('   TSS nonce: ${info.tssNonce}');
  print('   Metadata:');
  print('      Party Timeout: ${metadata['partyTimeout']}');
  print('      KeyGen Timeout: ${metadata['keyGenTimeout']}');
  print('      KeySign Timeout: ${metadata['keySignTimeout']}');
  print('      PreParam Timeout: ${metadata['preParamTimeout']}');
  print('      KeyGen Version: ${metadata['keyGenVersion']}');
  print('      Leader Block Height: ${metadata['leaderBlockHeight']}');
  print('      Affiliate Program: ${metadata['affiliateProgram']}');
}

Future<void> _security() async {
  SecurityInfo info = await znnClient.embedded.bridge.getSecurityInfo();
  print('Security info:');

  if (info.guardians.isEmpty) {
    print('   Guardians: none');
  } else {
    print('   Guardians: ');
    for (Address guardian in info.guardians) {
      print('      $guardian');
    }
  }

  if (info.guardiansVotes.isEmpty) {
    print('   Guardian votes: none');
  } else {
    print('   Guardian votes: ');
    for (Address guardianVotes in info.guardiansVotes) {
      print('      $guardianVotes');
    }
  }

  print('   Administrator delay: ${info.administratorDelay}');
  print('   Soft delay: ${info.softDelay}');
}

Future<void> _timeChallenges() async {
  TimeChallengesList list =
      await znnClient.embedded.bridge.getTimeChallengesInfo();

  if (list.count == 0) {
    print('No time challenges found.');
    return;
  }

  print('Time challenges:');
  for (var info in list.list) {
    print('   Method: ${info.methodName}');
    print('   Start height: ${info.challengeStartHeight}');
    print('   Params hash: ${info.paramsHash}');
    print('');
  }
}

Future<void> _orchestratorInfo() async {
  OrchestratorInfo info = await znnClient.embedded.bridge.getOrchestratorInfo();
  print('Orchestrator info:');
  print('   Window size: ${info.windowSize}');
  print('   Key generation threshold: ${info.keyGenThreshold}');
  print('   Confirmations to finality: ${info.confirmationsToFinality}');
  print('   Estimated momentum time: ${info.estimatedMomentumTime}');
  print('   Allow key generation height: ${info.allowKeyGenHeight}');
}

Future<void> _fees() async {
  if (args.length > 2) {
    print('Incorrect number of arguments. Expected:');
    print('bridge.getFees [tokenStandard]');
    return;
  }
  if (args.length == 2) {
    TokenStandard tokenStandard = getTokenStandard(args[1]);
    Token token = await getToken(tokenStandard);
    ZtsFeesInfo info =
        await znnClient.embedded.bridge.getFeeTokenPair(tokenStandard);
    Function color = getColor(tokenStandard);

    print(
        'Fees accumulated for ${color(token.symbol)}: ${AmountUtils.addDecimals(info.accumulatedFee, token.decimals)}');
  } else {
    ZtsFeesInfo znnInfo =
        await znnClient.embedded.bridge.getFeeTokenPair(znnZts);
    ZtsFeesInfo qsrInfo =
        await znnClient.embedded.bridge.getFeeTokenPair(qsrZts);
    print(
        'Fees accumulated for ${green('ZNN')}: ${AmountUtils.addDecimals(znnInfo.accumulatedFee, coinDecimals)}');
    print(
        'Fees accumulated for ${blue('QSR')}: ${AmountUtils.addDecimals(qsrInfo.accumulatedFee, coinDecimals)}');
  }
}

Future<void> _networkFunctions() async {
  switch (args[0].split('.')[2]) {
    case 'list':
      verbose ? print('Description: List all available bridge networks') : null;
      await _networkList();
      return;

    case 'get':
      verbose
          ? print(
              'Description: Get the information for a network class and chain id')
          : null;
      await _networkGet();
      return;

    default:
      invalidCommand();
  }
}

Future<void> _networkList() async {
  BridgeNetworkInfoList networkList =
      await znnClient.embedded.bridge.getAllNetworks();
  if (networkList.count == 0) {
    print('No bridge networks found');
    return;
  }

  for (var network in networkList.list) {
    print('   Name: ${network.name}');
    print('   Network Class: ${network.networkClass}');
    print('   Chain Id: ${network.chainId}');
    print('   Contract Address: ${network.contractAddress}');
    print('   Metadata: ${network.metadata}');
    if (network.tokenPairs.isNotEmpty) {
      print('   Token Pairs:');
      for (var tokenPair in network.tokenPairs) {
        print('      ${tokenPair.toJson()}');
      }
    }
    print('');
  }
}

Future<void> _networkGet() async {
  if (args.length != 3) {
    print('Incorrect number of arguments. Expected:');
    print('bridge.network.get networkClass chainId');
    return;
  }

  int networkClass = int.parse(args[1]);
  int chainId = int.parse(args[2]);

  if (networkClass == 0 || chainId == 0) {
    print('The bridge network does not exist');
    return;
  }

  BridgeNetworkInfo info =
      await znnClient.embedded.bridge.getNetworkInfo(networkClass, chainId);

  if (info.networkClass == 0 || info.chainId == 0) {
    print('The bridge network does not exist');
    return;
  }

  print('   Name: ${info.name}');
  print('   Network Class: ${info.networkClass}');
  print('   Chain Id: ${info.chainId}');
  print('   Contract Address: ${info.contractAddress}');
  print('   Metadata: ${info.metadata}');
  if (info.tokenPairs.isNotEmpty) {
    print('   Token Pairs:');
    for (var tokenPair in info.tokenPairs) {
      print('      ${tokenPair.toJson()}');
    }
  }
}

Future<void> _wrapFunctions() async {
  switch (args[0].split('.')[2]) {
    case 'token':
      verbose
          ? print('Description: Wrap assets for an EVM-compatible network')
          : null;
      await _wrapToken();
      return;

    case 'list':
      verbose ? print('Description: List all wrap token requests') : null;
      await _wrapList();
      return;

    case 'listByAddress':
      verbose
          ? print(
              'Description: List all wrap token requests for a NoM or EVM address')
          : null;
      await _wrapListByAddress();
      return;

    case 'listUnsigned':
      verbose
          ? print('Description: List all unsigned wrap token requests')
          : null;
      await _wrapListUnsigned();
      return;

    case 'get':
      verbose ? print('Description: Get wrap token request by id') : null;
      await _wrapGet();
      return;

    default:
      invalidCommand();
  }
}

Future<void> _wrapToken() async {
  if (args.length != 6) {
    print('Incorrect number of arguments. Expected:');
    print(
        'bridge.wrap.token networkClass chainId toAddress amount tokenStandard');
    return;
  }

  int networkClass = int.parse(args[1]);
  int chainId = int.parse(args[2]);
  String toAddress = args[3]; // must be EVM-compatible
  TokenStandard tokenStandard = getTokenStandard(args[5]);
  Token token = await getToken(tokenStandard);
  BigInt amount = AmountUtils.extractDecimals(args[4], token.decimals);

  if (amount <= BigInt.zero) {
    print('${red('Error!')} You cannot send that amount.');
    return;
  }

  if (!await hasBalance(address, tokenStandard, amount)) {
    return;
  }

  BridgeNetworkInfo info =
      await znnClient.embedded.bridge.getNetworkInfo(networkClass, chainId);

  if (info.networkClass == 0 || info.chainId == 0) {
    print('${red('Error!')} The bridge network does not exist');
    return;
  }

  bool found = false;
  for (TokenPair tokenPair in info.tokenPairs) {
    if (tokenPair.tokenStandard == tokenStandard) {
      found = true;
      if (amount < tokenPair.minAmount) {
        print(
            '${red('Error!')} Invalid amount. Must be at least ${AmountUtils.addDecimals(tokenPair.minAmount, token.decimals)} ${token.symbol}');
        return;
      }
      break;
    }
  }

  if (!found) {
    print('${red('Error!')} That token cannot be wrapped');
    return;
  }

  print('Wrapping token ...');
  AccountBlockTemplate block = znnClient.embedded.bridge
      .wrapToken(networkClass, chainId, toAddress, amount, tokenStandard);
  block = await znnClient.send(block);
  print('Done');
}

Future<void> _wrapList() async {
  WrapTokenRequestList list =
      await znnClient.embedded.bridge.getAllWrapTokenRequests();
  print('All wrap token requests:');
  print('Count: ${list.count}');

  if (list.count > 0) {
    for (WrapTokenRequest request in list.list) {
      print('   ${request.toJson()}');
    }
  }
}

Future<void> _wrapListByAddress() async {
  if (args.length != 2 && args.length != 4) {
    print('Incorrect number of arguments. Expected:');
    print('bridge.wrap.listByAddress address [networkClass] [chainId]');
    return;
  }
  WrapTokenRequestList list;
  String toAddress = args[1];
  var fromAddress;
  try {
    fromAddress = Address.parse(args[1]);
  } catch (e) {
    /* assume input is an EVM-compatible address */
  }

  if (fromAddress != null) {
    var blocks = await znnClient.ledger.getAccountBlocksByPage(fromAddress);
    if (blocks.count! > 0) {
      List<WrapTokenRequest> list = [];
      for (var block in blocks.list!) {
        if (block.toAddress == bridgeAddress && block.data.isNotEmpty) {
          Function eq = const ListEquality().equals;
          late AbiFunction f;
          for (var entry in Definitions.bridge.entries) {
            if (eq(AbiFunction.extractSignature(entry.encodeSignature()),
                AbiFunction.extractSignature(block.data))) {
              f = AbiFunction(entry.name!, entry.inputs!);
            }
          }
          if (f.name == 'WrapToken') {
            var request = await znnClient.embedded.bridge
                .getWrapTokenRequestById(block.hash);
            if (args.length == 4) {
              int networkClass = int.parse(args[2]);
              int chainId = int.parse(args[3]);
              if (request.chainId != chainId ||
                  request.networkClass != networkClass) {
                continue;
              }
            }
            list.add(request);
          }
        }
      }
      if (list.isNotEmpty) {
        print('Count: ${list.length}');
        for (WrapTokenRequest request in list) {
          await _printWrapTokenRequest(request);
        }
      } else {
        print('No wrap requests found for $fromAddress');
      }
    }
  } else {
    if (args.length == 4) {
      int networkClass = int.parse(args[2]);
      int chainId = int.parse(args[3]);
      list = await znnClient.embedded.bridge
          .getAllWrapTokenRequestsByToAddressNetworkClassAndChainId(
              toAddress, networkClass, chainId);
    } else {
      list = await znnClient.embedded.bridge
          .getAllWrapTokenRequestsByToAddress(toAddress);
    }
    if (list.count > 0) {
      print('Count: ${list.count}');
      for (WrapTokenRequest request in list.list) {
        await _printWrapTokenRequest(request);
      }
    } else {
      print('No wrap requests found for $toAddress');
    }
  }
}

Future<void> _wrapListUnsigned() async {
  WrapTokenRequestList list =
      await znnClient.embedded.bridge.getAllUnsignedWrapTokenRequests();

  print('All unsigned wrap token requests:');
  print('Count: ${list.count}');

  if (list.count > 0) {
    for (var request in list.list) {
      print('   ${request.toJson()}');
    }
  }
}

Future<void> _wrapGet() async {
  if (args.length != 2) {
    print('Incorrect number of arguments. Expected:');
    print('bridge.wrap.get id');
    return;
  }

  Hash id = parseHash(args[1]);
  WrapTokenRequest request =
      await znnClient.embedded.bridge.getWrapTokenRequestById(id);

  await _printWrapTokenRequest(request);
}

Future<void> _unwrapFunctions() async {
  switch (args[0].split('.')[2]) {
    case 'redeem':
      verbose
          ? print(
              'Description: redeem a pending unwrap request for any recipient')
          : null;
      await _unwrapRedeem();
      return;

    case 'redeemAll':
      verbose
          ? print(
              'Description: redeem all pending unwrap requests for yourself or all addresses')
          : null;
      await _unwrapRedeemAll();
      return;

    case 'list':
      verbose ? print('Description: List all unwrap token requests') : null;
      await _unwrapList();
      return;

    case 'listByAddress':
      verbose
          ? print('Description: List all unwrap token requests by NoM address')
          : null;
      await _unwrapListByAddress();
      return;

    case 'listUnredeemed':
      verbose
          ? print('Description: List all unredeemed unwrap token requests')
          : null;
      await _unwrapListUnredeemed();
      return;

    case 'get':
      verbose
          ? print('Description: Get unwrap token request by hash and log index')
          : null;
      await _unwrapGet();
      return;

    default:
      invalidCommand();
  }
}

Future<void> _unwrapRedeem() async {
  if (args.length != 3) {
    print('Incorrect number of arguments. Expected:');
    print('bridge.unwrap.redeem transactionHash logIndex');
    return;
  }

  Hash transactionHash = parseHash(args[1]);
  int logIndex = int.parse(args[2]);

  UnwrapTokenRequest request = await znnClient.embedded.bridge
      .getUnwrapTokenRequestByHashAndLog(transactionHash, logIndex);

  if (request.redeemed == 0 && request.revoked == 0) {
    _printRedeem(request);

    AccountBlockTemplate block = znnClient.embedded.bridge
        .redeem(request.transactionHash, request.logIndex);
    await znnClient.send(block);

    print('Done');
    if (request.toAddress == address) {
      print(
          'Use ${green('receiveAll')} to collect your unwrapped tokens after 2 momentums');
    }
  } else {
    print('The unwrap request cannot be redeemed');
  }
}

Future<void> _unwrapRedeemAll() async {
  if (args.length > 2) {
    print('Incorrect number of arguments. Expected:');
    print('bridge.unwrap.redeemAll [bool]');
    print(
        'Note: if the boolean is true, all unredeemed transactions will be redeemed');
    return;
  }

  bool redeemAllGlobally = false;
  if (args.length == 2 && bool.parse(args[1]) == true) {
    redeemAllGlobally = true;
  }

  UnwrapTokenRequestList allUnwrapRequests =
      await znnClient.embedded.bridge.getAllUnwrapTokenRequests();

  int redeemedSelf = 0;
  int redeemedTotal = 0;

  for (UnwrapTokenRequest request in allUnwrapRequests.list) {
    if (request.redeemed == 0 && request.revoked == 0) {
      if (redeemAllGlobally ||
          (args.length == 1 && request.toAddress == address)) {
        _printRedeem(request);
        AccountBlockTemplate redeem = znnClient.embedded.bridge
            .redeem(request.transactionHash, request.logIndex);
        redeem = await znnClient.send(redeem);
        if (request.toAddress == address) {
          redeemedSelf += 1;
        }
        redeemedTotal += 1;
      }
    }
  }
  if (redeemedTotal > 0) {
    print('Done');
    if (redeemedSelf > 0) {
      print(
          'Use ${green('receiveAll')} to collect your unwrapped tokens after 2 momentums');
    }
  } else {
    print('No redeemable unwrap requests were found');
  }
}

Future<void> _unwrapList() async {
  UnwrapTokenRequestList list =
      await znnClient.embedded.bridge.getAllUnwrapTokenRequests();
  print('All unwrap token requests:');
  print('Count: ${list.count}');

  if (list.count > 0) {
    for (UnwrapTokenRequest request in list.list) {
      print('   ${request.toJson()}');
    }
  }
}

Future<void> _unwrapListByAddress() async {
  if (args.length != 2) {
    print('Incorrect number of arguments. Expected:');
    print('bridge.unwrap.listByAddress toAddress');
    return;
  }

  Address toAddress = parseAddress(args[1]);

  UnwrapTokenRequestList list = await znnClient.embedded.bridge
      .getAllUnwrapTokenRequestsByToAddress(toAddress.toString());

  if (list.count > 0) {
    print('Count: ${list.count}');
    for (UnwrapTokenRequest request in list.list) {
      await _printUnwrapTokenRequest(request);
    }
  } else {
    print('No unwrap requests found for $toAddress');
  }
}

Future<void> _unwrapListUnredeemed() async {
  if (args.length > 2) {
    print('Incorrect number of arguments. Expected:');
    print('bridge.unwrap.listUnredeemed [toAddress]');
    return;
  }
  UnwrapTokenRequestList allUnwrapRequests =
      await znnClient.embedded.bridge.getAllUnwrapTokenRequests();

  List<UnwrapTokenRequest> unredeemed = [];

  for (UnwrapTokenRequest request in allUnwrapRequests.list) {
    if (request.redeemed == 0 && request.revoked == 0) {
      if ((args.length == 2 && request.toAddress == parseAddress(args[1])) ||
          (args.length == 1)) {
        unredeemed.add(request);
      }
    }
  }
  print(
      'All unredeemed unwrap token requests${args.length == 2 ? ' for ${args[1]}:' : ':'}');
  print('Count: ${unredeemed.length}');

  if (unredeemed.isNotEmpty) {
    for (UnwrapTokenRequest request in unredeemed) {
      await _printUnwrapTokenRequest(request);
    }
  }
}

Future<void> _unwrapGet() async {
  if (args.length != 3) {
    print('Incorrect number of arguments. Expected:');
    print('bridge.unwrap.get transactionHash logIndex');
    return;
  }

  Hash transactionHash = parseHash(args[1]);
  int logIndex = int.parse(args[2]);

  UnwrapTokenRequest request = await znnClient.embedded.bridge
      .getUnwrapTokenRequestByHashAndLog(transactionHash, logIndex);

  await _printUnwrapTokenRequest(request);
}

Future<void> _guardianFunctions() async {
  switch (args[0].split('.')[2]) {
    case 'proposeAdmin':
      verbose
          ? print(
              'Description: Participate in a vote to elect a new bridge administrator when the bridge is in Emergency mode')
          : null;
      await _proposeAdmin();
      return;

    default:
      invalidCommand();
  }
}

Future<void> _proposeAdmin() async {
  if (!await _isGuardian()) return;

  if (args.length != 2) {
    print('Incorrect number of arguments. Expected:');
    print('bridge.guardian.proposeAdmin address');
    return;
  }

  String currentAdmin = (await znnClient.embedded.bridge.getBridgeInfo())
      .administrator
      .toString();
  Address newAdmin = parseAddress(args[1]);
  if (!assertUserAddress(newAdmin)) {
    return;
  }

  if (currentAdmin == '' ||
      currentAdmin.isEmpty ||
      currentAdmin == emptyAddress.toString()) {
    print('Proposing new bridge administrator ...');
    AccountBlockTemplate block =
        znnClient.embedded.bridge.proposeAdministrator(newAdmin);
    await znnClient.send(block);
    print('Done');
  } else {
    print('${red('Permission denied!')} Bridge is not in emergency mode');
  }
}

Future<void> _adminFunctions() async {
  switch (args[0].split('.')[2]) {
    case 'emergency':
      verbose
          ? print('Description: Put the bridge contract in emergency mode')
          : null;
      await _emergency();
      return;

    case 'halt':
      verbose ? print('Description: Halt bridge operations') : null;
      await _halt();
      return;

    case 'unhalt':
      verbose ? print('Description: Unhalt bridge operations') : null;
      await _unhalt();
      return;

    case 'enableKeyGen':
      verbose ? print('Description: Enable bridge key generation') : null;
      await _enableKeyGen();
      return;

    case 'disableKeyGen':
      verbose ? print('Description: Disable bridge key generation') : null;
      await _disableKeyGen();
      return;

    case 'setTokenPair':
      verbose
          ? print('Description: Set a token pair to enable bridging the asset')
          : null;
      await _setTokenPair();
      return;

    case 'removeTokenPair':
      verbose
          ? print(
              'Description: Remove a token pair to disable bridging the asset')
          : null;
      await _removeTokenPair();
      return;

    case 'revokeUnwrapRequest':
      verbose
          ? print(
              'Description: Revoke an unwrap request to prevent it from being redeemed')
          : null;
      await _revokeUnwrapRequest();
      return;

    case 'nominateGuardians':
      verbose ? print('Description: Nominate bridge guardians') : null;
      await _nominateGuardians();
      return;

    case 'changeAdmin':
      verbose ? print('Description: Change bridge administrator') : null;
      await _changeAdmin();
      return;

    case 'setMetadata':
      verbose ? print('Description: Set the bridge metadata') : null;
      await _setMetadata();
      return;

    case 'setOrchestratorInfo':
      verbose ? print('Description: Get the bridge information') : null;
      await _setOrchestratorInfo();
      return;

    case 'setNetwork':
      verbose
          ? print('Description: Configure network parameters to allow bridging')
          : null;
      await _setNetwork();
      return;

    case 'removeNetwork':
      verbose
          ? print('Description: Remove a network to disable bridging')
          : null;
      await _removeNetwork();
      return;

    case 'setNetworkMetadata':
      verbose ? print('Description: Set network metadata') : null;
      await _setNetworkMetadata();
      return;

    default:
      invalidCommand();
  }
}

Future<void> _emergency() async {
  if (!await _isAdmin()) return;
  print('Initializing bridge emergency mode ...');
  AccountBlockTemplate block = znnClient.embedded.bridge.emergency();
  await znnClient.send(block);
  print('Done');
}

Future<void> _halt() async {
  if (!await _isAdmin()) return;
  print('Halting bridge ...');
  AccountBlockTemplate block = znnClient.embedded.bridge.halt('1');
  await znnClient.send(block);
  print('Done');
}

Future<void> _unhalt() async {
  if (!await _isAdmin()) return;
  print('Unhalting the bridge ...');
  AccountBlockTemplate block = znnClient.embedded.bridge.unhalt();
  await znnClient.send(block);
  print('Done');
}

Future<void> _enableKeyGen() async {
  if (!await _isAdmin()) return;
  print('Enabling TSS key generation ...');
  AccountBlockTemplate setAllowKeyGen =
      znnClient.embedded.bridge.setAllowKeyGen(true);
  setAllowKeyGen = await znnClient.send(setAllowKeyGen);
  print('Done');
}

Future<void> _disableKeyGen() async {
  if (!await _isAdmin()) return;
  print('Disabling TSS key generation ...');
  AccountBlockTemplate block = znnClient.embedded.bridge.setAllowKeyGen(false);
  await znnClient.send(block);
  print('Done');
}

Future<void> _setTokenPair() async {
  if (!await _isAdmin()) return;

  if (args.length != 12) {
    print('Incorrect number of arguments. Expected:');
    print(
        'bridge.admin.setTokenPair networkClass chainId tokenStandard tokenAddress bridgeable redeemable owned minAmount feePercentage redeemDelay metadata');
    return;
  }

  int networkClass = int.parse(args[1]);
  int chainId = int.parse(args[2]);
  TokenStandard tokenStandard = getTokenStandard(args[3]);
  Token token = await getToken(tokenStandard);
  String tokenAddress = args[4]; // must be EVM-compatible
  bool bridgeable = bool.parse(args[5]);
  bool redeemable = bool.parse(args[6]);
  bool owned = bool.parse(args[7]);
  BigInt minAmount = AmountUtils.extractDecimals(args[8], token.decimals);
  int feePercentage = int.parse(args[9]) * 100;
  int redeemDelay = int.parse(args[10]);
  String metadata = args[11];
  jsonDecode(metadata);

  if (feePercentage > bridgeMaximumFee) {
    print(
        '${red('Error!')} Fee percentage may not exceed ${bridgeMaximumFee / 100}');
    return;
  }

  if (redeemDelay == 0) {
    print('${red('Error!')} Redeem delay cannot be 0');
    return;
  }

  print('Setting token pair ...');
  AccountBlockTemplate setTokenPair = znnClient.embedded.bridge.setTokenPair(
    networkClass,
    chainId,
    tokenStandard,
    tokenAddress,
    bridgeable,
    redeemable,
    owned,
    minAmount,
    feePercentage,
    redeemDelay,
    metadata,
  );
  setTokenPair = await znnClient.send(setTokenPair);
  print('Done');
}

Future<void> _removeTokenPair() async {
  if (!await _isAdmin()) return;

  if (args.length != 5) {
    print('Incorrect number of arguments. Expected:');
    print(
        'bridge.admin.removeTokenPair networkClass chainId tokenStandard tokenAddress');
    return;
  }

  int networkClass = int.parse(args[1]);
  int chainId = int.parse(args[2]);
  TokenStandard tokenStandard = getTokenStandard(args[3]);
  String tokenAddress = args[4]; // must be EVM-compatible

  print('Removing token pair ...');
  AccountBlockTemplate block = znnClient.embedded.bridge
      .removeTokenPair(networkClass, chainId, tokenStandard, tokenAddress);
  await znnClient.send(block);
  print('Done');
}

Future<void> _revokeUnwrapRequest() async {
  if (!await _isAdmin()) return;

  if (args.length != 3) {
    print('Incorrect number of arguments. Expected:');
    print('bridge.admin.revokeUnwrapRequest transactionHash logIndex');
    return;
  }

  Hash transactionHash = parseHash(args[1]);
  int logIndex = int.parse(args[2]);

  print('Removing unwrap request ...');
  AccountBlockTemplate block =
      znnClient.embedded.bridge.revokeUnwrapRequest(transactionHash, logIndex);
  await znnClient.send(block);
  print('Done');
}

Future<void> _nominateGuardians() async {
  if (!await _isAdmin()) return;

  if (args.length < bridgeMinGuardians + 1) {
    print(
        'Incorrect number of arguments. Expected at least $bridgeMinGuardians addresses:');
    print('bridge.admin.nominateGuardians address1 address2 ... addressN');
    return;
  }

  List<Address> guardians = [];

  for (int i = 1; i < args.length; i++) {
    Address guardian = parseAddress(args[i]);
    if (!assertUserAddress(guardian)) {
      return;
    }
    guardians.add(guardian);
  }

  List<String> addresses = guardians.map((e) => e.toString()).toSet().toList();
  addresses.sort();

  if (addresses.length != guardians.length) {
    print('Duplicate address nomination detected');
    return;
  }

  guardians = addresses.map((e) => Address.parse(e)).toList();

  TimeChallengesList list =
      await znnClient.embedded.bridge.getTimeChallengesInfo();
  TimeChallengeInfo? tc;

  if (list.count > 0) {
    for (var _tc in list.list) {
      if (_tc.methodName == 'NominateGuardians') {
        tc = _tc;
      }
    }
  }

  if (tc != null && tc.paramsHash != emptyHash) {
    Momentum frontierMomentum = await znnClient.ledger.getFrontierMomentum();
    SecurityInfo securityInfo =
        await znnClient.embedded.bridge.getSecurityInfo();

    if (tc.challengeStartHeight + securityInfo.administratorDelay >
        frontierMomentum.height) {
      print('Cannot nominate guardians; wait for time challenge to expire.');
      return;
    }

    ByteData bd = combine(guardians);
    Hash paramsHash = Hash.digest(bd.buffer.asUint8List());

    if (tc.paramsHash == paramsHash) {
      print('Committing guardians ...');
    } else {
      print('Time challenge hash does not match nominated guardians');
      if (!confirm('Are you sure you want to nominate new guardians?',
          defaultValue: false)) return;
      print('Nominating guardians ...');
    }
  } else {
    print('Nominating guardians ...');
  }

  AccountBlockTemplate block =
      znnClient.embedded.bridge.nominateGuardians(guardians);
  await znnClient.send(block);
  print('Done');
}

Future<void> _changeAdmin() async {
  if (!await _isAdmin()) return;

  if (args.length != 2) {
    print('Incorrect number of arguments. Expected:');
    print('bridge.admin.changeAdmin address');
    return;
  }

  Address newAdmin = parseAddress(args[1]);
  if (!assertUserAddress(newAdmin)) {
    return;
  }

  print('Changing bridge administrator ...');
  AccountBlockTemplate block =
      znnClient.embedded.bridge.changeAdministrator(newAdmin);
  await znnClient.send(block);
  print('Done');
}

Future<void> _setMetadata() async {
  if (!await _isAdmin()) return;

  if (args.length != 2) {
    print('Incorrect number of arguments. Expected:');
    print('bridge.admin.setMetadata metadata');
    return;
  }

  String metadata = args[1];
  jsonDecode(metadata);

  print('Setting bridge metadata ...');
  AccountBlockTemplate block =
      znnClient.embedded.bridge.setBridgeMetadata(metadata);
  await znnClient.send(block);
  print('Done');
}

Future<void> _setOrchestratorInfo() async {
  if (!await _isAdmin()) return;

  if (args.length != 5) {
    print('Incorrect number of arguments. Expected:');
    print(
        'bridge.admin.setOrchestratorInfo windowSize keyGenThreshold confirmationsToFinality estimatedMomentumTime');
    return;
  }

  int windowSize = int.parse(args[1]);
  int keyGenThreshold = int.parse(args[2]);
  int confirmationsToFinality = int.parse(args[3]);
  int estimatedMomentumTime = int.parse(args[4]);

  print('Setting orchestrator info ...');
  AccountBlockTemplate block = znnClient.embedded.bridge.setOrchestratorInfo(
      windowSize,
      keyGenThreshold,
      confirmationsToFinality,
      estimatedMomentumTime);
  await znnClient.send(block);
  print('Done');
}

Future<void> _setNetwork() async {
  if (!await _isAdmin()) return;

  if (args.length != 6) {
    print('Incorrect number of arguments. Expected:');
    print(
        'bridge.admin.setNetwork networkClass chainId name contractAddress metadata');
    return;
  }

  int networkClass = int.parse(args[1]);
  int chainId = int.parse(args[2]);
  String name = args[3];
  String contractAddress = args[4];
  String metadata = args[5];
  jsonDecode(metadata);

  print('Setting network ...');
  AccountBlockTemplate block = znnClient.embedded.bridge.setNetwork(
    networkClass,
    chainId,
    name,
    contractAddress,
    metadata,
  );
  await znnClient.send(block);
  print('Done');
}

Future<void> _removeNetwork() async {
  if (!await _isAdmin()) return;

  if (args.length != 3) {
    print('Incorrect number of arguments. Expected:');
    print('bridge.admin.removeNetwork networkClass chainId');
    return;
  }

  int networkClass = int.parse(args[1]);
  int chainId = int.parse(args[2]);

  print('Removing network ...');
  AccountBlockTemplate block =
      znnClient.embedded.bridge.removeNetwork(networkClass, chainId);
  await znnClient.send(block);
  print('Done');
}

Future<void> _setNetworkMetadata() async {
  if (!await _isAdmin()) return;

  if (args.length != 4) {
    print('Incorrect number of arguments. Expected:');
    print('bridge.admin.setNetworkMetadata networkClass chainId metadata');
    return;
  }

  int networkClass = int.parse(args[1]);
  int chainId = int.parse(args[2]);
  String metadata = args[3];
  jsonDecode(metadata);

  print('Setting network metadata ...');
  AccountBlockTemplate block = znnClient.embedded.bridge.setNetworkMetadata(
    networkClass,
    chainId,
    metadata,
  );
  await znnClient.send(block);
  print('Done');
}

Future<bool> _isGuardian() async {
  if (!(await znnClient.embedded.bridge.getSecurityInfo())
      .guardians
      .contains(address)) {
    print(
        '${red('Permission denied!')} This function can only be called by a Guardian');
    return false;
  }
  return true;
}

Future<bool> _isAdmin() async {
  if (!((await znnClient.embedded.bridge.getBridgeInfo()).administrator ==
      address)) {
    print(
        '${red('Permission denied!')} $address is not the Bridge administrator');
    return false;
  }
  return true;
}

Future<void> _printWrapTokenRequest(WrapTokenRequest request) async {
  Token token = await getToken(request.tokenStandard);
  int decimals = token.decimals;
  Function color = getColor(request.tokenStandard);

  print('Id: ${request.id}');
  print('   Network Class: ${request.networkClass}');
  print('   Chain Id: ${request.chainId}');
  print('   To: ${request.toAddress}');
  print(
      '   From: ${(await znnClient.ledger.getAccountBlockByHash(request.id))?.address}');
  print('   Token Standard: ${color(request.tokenStandard)}');
  print(
      '   Amount: ${AmountUtils.addDecimals(request.amount, decimals)} ${color(token.symbol)}');
  print('   Fee: ${AmountUtils.addDecimals(request.fee, decimals)}');
  print('   Signature: ${request.signature}');
  print('   Creation Momentum Height: ${request.creationMomentumHeight}');
  print('');
}

Future<void> _printUnwrapTokenRequest(UnwrapTokenRequest request) async {
  Token token = await getToken(request.tokenStandard);
  int decimals = token.decimals;
  Function color = getColor(request.tokenStandard);

  print('Id: ${request.transactionHash}');
  print('   Network Class: ${request.networkClass}');
  print('   Chain Id: ${request.chainId}');
  print('   Log Index: ${request.logIndex}');
  print('   To: ${request.toAddress}');
  print('   Token Standard: ${color(request.tokenStandard)}');
  print(
      '   Amount: ${AmountUtils.addDecimals(request.amount, decimals)} ${color(token.symbol)}');
  print('   Signature: ${request.signature}');
  print(
      '   Registration Momentum Height: ${request.registrationMomentumHeight}');
  print('   Redeemed: ${request.redeemed == 1 ? 'True' : 'False'}');
  print('   Revoked: ${request.revoked == 1 ? 'True' : 'False'}');
  print('');
}

Future<void> _printRedeem(UnwrapTokenRequest request) async {
  Token token = await getToken(request.tokenStandard);
  int decimals = token.decimals;
  Function color = getColor(request.tokenStandard);

  print('Redeeming id: ${request.transactionHash}');
  print('   Log Index: ${request.logIndex}');
  print(
      '   Amount: ${AmountUtils.addDecimals(request.amount, decimals)} ${color(token.symbol)}');
  print('   To: ${request.toAddress}');
  print('');
}
