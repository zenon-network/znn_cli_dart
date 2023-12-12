import 'dart:io';

import 'package:dcli/dcli.dart' hide verbose;
import 'package:znn_cli_dart/lib.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

void tokenMenu() {
  print('  ${white('ZTS Tokens')}');
  print('    token.list [pageIndex pageCount]');
  print('    token.getByStandard tokenStandard');
  print('    token.getByOwner ownerAddress');
  print(
      '    token.issue name symbol domain totalSupply maxSupply decimals isMintable isBurnable isUtility');
  print('    token.mint tokenStandard amount receiveAddress');
  print('    token.burn tokenStandard amount');
  print('    token.transferOwnership tokenStandard newOwnerAddress');
  print('    token.disableMint tokenStandard');
}

Future<void> tokenFunctions() async {
  switch (args[0].split('.')[1]) {
    case 'list':
      verbose ? print('Description: List all tokens') : null;
      await _list();
      return;

    case 'getByStandard':
      verbose ? print('Description: List tokens by standard') : null;
      await _getByStandard();
      return;

    case 'getByOwner':
      verbose ? print('Description: List tokens by owner') : null;
      await _getByOwner();
      return;

    case 'issue':
      verbose ? print('Description: Issue token') : null;
      await _issue();
      return;

    case 'mint':
      verbose ? print('Description: Mint token') : null;
      await _mint();
      return;

    case 'burn':
      verbose ? print('Description: Burn token') : null;
      await _burn();
      return;

    case 'transferOwnership':
      verbose
          ? print('Description: Transfer token ownership to another address')
          : null;
      await _transferOwnership();
      return;

    case 'disableMint':
      verbose
          ? print('Description: Disable a token\'s minting capability')
          : null;
      await _disableMint();
      return;

    default:
      invalidCommand();
  }
}

Future<void> _list() async {
  if (!(args.length == 1 || args.length == 3)) {
    print('Incorrect number of arguments. Expected:');
    print('token.list [pageIndex pageSize]');
    return;
  }
  int pageIndex = 0;
  int pageSize = 25;
  if (args.length == 3) {
    pageIndex = int.parse(args[1]);
    pageSize = int.parse(args[2]);
  }
  if (!areValidPageVars(pageIndex, pageSize)) {
    return;
  }
  TokenList tokenList = await znnClient.embedded.token
      .getAll(pageIndex: pageIndex, pageSize: pageSize);
  for (Token token in tokenList.list!) {
    Function color = getColor(token.tokenStandard);
    String issuance = 'Created';
    if (token.tokenStandard.toString() != qsrTokenStandard &&
        token.tokenStandard.toString() != znnTokenStandard) {
      stdout.write('Token ');
      issuance = 'Issued';
    }
    print(
        '${color(token.name)} with symbol ${color(token.symbol)} and standard ${color(token.tokenStandard.toString())}');
    print('   $issuance by ${color(token.owner.toString())}');
    print(
        '   ${color(token.name)} has ${token.decimals} decimals, ${token.isMintable ? 'is mintable' : 'is not mintable'}, ${token.isBurnable ? 'can be burned' : 'cannot be burned'}, and ${token.isUtility ? 'is a utility coin' : 'is not a utility coin'}');
    print(
        '   The total supply is ${AmountUtils.addDecimals(token.totalSupply, token.decimals)} and the maximum supply is ${AmountUtils.addDecimals(token.maxSupply, token.decimals)}');
    print('   Domain `${token.domain}`');
  }
}

Future<void> _getByStandard() async {
  if (args.length != 2) {
    print('Incorrect number of arguments. Expected:');
    print('token.getByStandard tokenStandard');
    return;
  }
  TokenStandard tokenStandard = getTokenStandard(args[1]);
  Token token = await getToken(tokenStandard);
  String type = 'Token';
  if (token.tokenStandard.toString() == qsrTokenStandard ||
      token.tokenStandard.toString() == znnTokenStandard) {
    type = 'Coin';
  }
  Function color = getColor(token.tokenStandard);
  print(
      '${color(type)} ${token.name} with symbol ${color(token.symbol)} and standard ${color(token.tokenStandard.toString())}');
  print('   Created by ${green(token.owner.toString())}');
  print(
      '   The total supply is ${AmountUtils.addDecimals(token.totalSupply, token.decimals)} and a maximum supply is ${AmountUtils.addDecimals(token.maxSupply, token.decimals)}');
  print(
      '   The token has ${token.decimals} decimals ${token.isMintable ? 'can be minted' : 'cannot be minted'} and ${token.isBurnable ? 'can be burned' : 'cannot be burned'}');
}

Future<void> _getByOwner() async {
  if (args.length != 2) {
    print('Incorrect number of arguments. Expected:');
    print('token.getByOwner ownerAddress');
    return;
  }
  String type = 'Token';
  Address ownerAddress = parseAddress(args[1]);
  TokenList tokens = await znnClient.embedded.token.getByOwner(ownerAddress);
  for (Token token in tokens.list!) {
    type = 'Token';
    if (token.tokenStandard.toString() == znnTokenStandard ||
        token.tokenStandard.toString() == qsrTokenStandard) {
      type = 'Coin';
    }
    Function color = getColor(token.tokenStandard);
    print(
        '${color(type)} ${token.name} with symbol ${color(token.symbol)} and standard ${color(token.tokenStandard.toString())}');
    print('   Created by ${green(token.owner.toString())}');
    print(
        '   The total supply is ${AmountUtils.addDecimals(token.totalSupply, token.decimals)} and a maximum supply is ${AmountUtils.addDecimals(token.maxSupply, token.decimals)}');
    print(
        '   The token ${token.decimals} decimals ${token.isMintable ? 'can be minted' : 'cannot be minted'} and ${token.isBurnable ? 'can be burned' : 'cannot be burned'}');
  }
}

Future<void> _issue() async {
  if (args.length != 10) {
    print('Incorrect number of arguments. Expected:');
    print(
        'token.issue name symbol domain totalSupply maxSupply decimals isMintable isBurnable isUtility');
    return;
  }

  RegExp regExpName = RegExp(r'^([a-zA-Z0-9]+[-._]?)*[a-zA-Z0-9]$');
  if (!regExpName.hasMatch(args[1])) {
    print('${red('Error!')} The ZTS name contains invalid characters');
    return;
  }

  RegExp regExpSymbol = RegExp(r'^[A-Z0-9]+$');
  if (!regExpSymbol.hasMatch(args[2])) {
    print('${red('Error!')} The ZTS symbol must be all uppercase');
    return;
  }

  RegExp regExpDomain =
      RegExp(r'^([A-Za-z0-9][A-Za-z0-9-]{0,61}[A-Za-z0-9]\.)+[A-Za-z]{2,}$');
  if (args[3].isEmpty || !regExpDomain.hasMatch(args[3])) {
    print('${red('Error!')} Invalid domain');
    print('Examples of ${green('valid')} domain names:');
    print('    zenon.network');
    print('    www.zenon.network');
    print('    quasar.zenon.network');
    print('    zenon.community');
    print('Examples of ${red('invalid')} domain names:');
    print('    zenon.network/index.html');
    print('    www.zenon.network/quasar');
    return;
  }

  if (args[1].isEmpty || args[1].length > 40) {
    print(
        '${red('Error!')} Invalid ZTS name length (min 1, max 40, current ${args[1].length})');
    return;
  }

  if (args[2].isEmpty || args[2].length > 10) {
    print(
        '${red('Error!')} Invalid ZTS symbol length (min 1, max 10, current ${args[2].length})');
    return;
  }

  if (args[3].length > 128) {
    print(
        '${red('Error!')} Invalid ZTS domain length (min 0, max 128, current ${args[3].length})');
    return;
  }

  bool mintable;
  if (args[7] == '0' || args[7] == 'false') {
    mintable = false;
  } else if (args[7] == '1' || args[7] == 'true') {
    mintable = true;
  } else {
    print(
        '${red('Error!')} Mintable flag variable of type "bool" should be provided as either "true", "false", "1" or "0"');
    return;
  }

  bool burnable;
  if (args[8] == '0' || args[8] == 'false') {
    burnable = false;
  } else if (args[8] == '1' || args[8] == 'true') {
    burnable = true;
  } else {
    print(
        '${red('Error!')} Burnable flag variable of type "bool" should be provided as either "true", "false", "1" or "0"');
    return;
  }

  bool utility;
  if (args[9] == '0' || args[9] == 'false') {
    utility = false;
  } else if (args[9] == '1' || args[9] == 'true') {
    utility = true;
  } else {
    print(
        '${red('Error!')} Utility flag variable of type "bool" should be provided as either "true", "false", "1" or "0"');
    return;
  }

  int decimals = int.parse(args[6]);
  BigInt totalSupply = AmountUtils.extractDecimals(args[4], decimals);
  BigInt maxSupply = AmountUtils.extractDecimals(args[5], decimals);

  if (mintable == true) {
    if (maxSupply < totalSupply) {
      print(
          '${red('Error!')} Max supply must to be larger than the total supply');
      return;
    }
    if (maxSupply >= BigInt.from(1 << 255)) {
      print(
          '${red('Error!')} Max supply must to be less than ${BigInt.from(1 << 255)}');
      return;
    }
  } else {
    if (maxSupply != totalSupply) {
      print(
          '${red('Error!')} Max supply must be equal to totalSupply for non-mintable tokens');
      return;
    }
    if (totalSupply == BigInt.zero) {
      print(
          '${red('Error!')} Total supply cannot be "0" for non-mintable tokens');
      return;
    }
  }

  print('Issuing a new ${magenta('ZTS token')} will burn 1 ZNN');
  if (!confirm('Do you want to proceed?', defaultValue: false)) return;

  print('Issuing ${magenta(args[1])} ZTS token ...');
  await send(znnClient.embedded.token.issueToken(args[1], args[2], args[3],
      totalSupply, maxSupply, decimals, mintable, burnable, utility));
  print('Done');
}

Future<void> _mint() async {
  if (args.length != 4) {
    print('Incorrect number of arguments. Expected:');
    print('token.mint tokenStandard amount receiveAddress');
    return;
  }
  TokenStandard tokenStandard = getTokenStandard(args[1]);
  Token token = await getToken(tokenStandard);
  BigInt amount = AmountUtils.extractDecimals(args[2], token.decimals);
  Address mintAddress = parseAddress(args[3]);

  if (token.isMintable == false) {
    print('${red('Error!')} The token is not mintable');
    return;
  }

  print('Minting ZTS token ...');
  await send(
      znnClient.embedded.token.mintToken(tokenStandard, amount, mintAddress));
  print('Done');
}

Future<void> _burn() async {
  if (args.length != 3) {
    print('Incorrect number of arguments. Expected:');
    print('token.burn tokenStandard amount');
    return;
  }
  TokenStandard tokenStandard = getTokenStandard(args[1]);
  Token token = await getToken(tokenStandard);
  BigInt amount = AmountUtils.extractDecimals(args[2], token.decimals);

  if (!await hasBalance(address, tokenStandard, amount)) {
    return;
  }

  print('Burning ${args[1]} ZTS token ...');
  await znnClient
      .send(znnClient.embedded.token.burnToken(tokenStandard, amount));
  print('Done');
}

Future<void> _transferOwnership() async {
  if (args.length != 3) {
    print('Incorrect number of arguments. Expected:');
    print('token.transferOwnership tokenStandard newOwnerAddress');
    return;
  }
  print('Transferring ZTS token ownership ...');
  TokenStandard tokenStandard = getTokenStandard(args[1]);
  Address newOwnerAddress = parseAddress(args[2]);
  Token token = await getToken(tokenStandard);
  if (token.owner.toString() != address.toString()) {
    print('${red('Error!')} Not owner of token ${args[1]}');
    return;
  }
  await send(znnClient.embedded.token.updateToken(
      tokenStandard, newOwnerAddress, token.isMintable, token.isBurnable));
  print('Done');
}

Future<void> _disableMint() async {
  if (args.length != 2) {
    print('Incorrect number of arguments. Expected:');
    print('token.disableMint tokenStandard');
    return;
  }
  print('Disabling ZTS token mintable flag ...');
  TokenStandard tokenStandard = getTokenStandard(args[1]);
  Token token = await getToken(tokenStandard);
  if (token.owner.toString() != address.toString()) {
    print('${red('Error!')} Not owner of token ${args[1]}');
    return;
  }
  await send(znnClient.embedded.token
      .updateToken(tokenStandard, token.owner, false, token.isBurnable));
  print('Done');
}
