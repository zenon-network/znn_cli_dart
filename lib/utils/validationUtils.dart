import 'dart:io';

import 'package:dcli/dcli.dart';
import 'package:znn_cli_dart/lib.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

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
          .contains(executableName);
    case 'macos':
      return Process.runSync('pgrep', [executableName], runInShell: true)
          .stdout
          .toString()
          .isNotEmpty;
    default:
      return false;
  }
}

Future<bool> hasBalance(
    Address address, TokenStandard tokenStandard, BigInt amount) async {
  AccountInfo info = await znnClient.ledger.getAccountInfoByAddress(address);
  bool ok = true;
  bool found = false;

  if (amount < BigInt.zero) {
    print('${red('Error!')} Negative amount is not supported');
    return found;
  }

  for (BalanceInfoListItem entry in info.balanceInfoList!) {
    if (entry.token!.tokenStandard.toString() == tokenStandard.toString()) {
      if (entry.balance! < amount) {
        if (entry.balance == BigInt.zero) {
          print('${red('Error!')} You do not have any ${entry.token!.symbol}');
        } else {
          print(
              '${red('Error!')} You only have ${AmountUtils.addDecimals(entry.balance!, entry.token!.decimals)} ${entry.token!.symbol} tokens');
        }
        ok = false;
        return false;
      }
      found = true;
    }
  }

  if (!found) {
    print(
        '${red('Error!')} You do not have any ${tokenStandard.toString()} tokens');
    return found;
  }
  return ok;
}

bool areValidPageVars(int pageIndex, int pageSize) {
  if (pageIndex < 0) {
    print('${red('Error!')} The page index must be a positive integer');
    return false;
  }
  if (pageSize < 1 || pageSize > rpcMaxPageSize) {
    print(
        '${red('Error!')} The page size must be greater than 0 and less than or equal to $rpcMaxPageSize');
    return false;
  }
  return true;
}

Hash parseHash(String hash) {
  try {
    return Hash.parse(hash);
  } catch (e) {
    throw ('${red('Error!')} $hash is not a valid hash');
  }
}

Address parseAddress(String address) {
  try {
    return Address.parse(address);
  } catch (e) {
    throw ('${red('Error!')} $address is not a valid address');
  }
}

bool assertUserAddress(Address address) {
  if (address.isEmbedded() || address == emptyAddress) {
    print('${red('Invalid address')}: $address is not a user address');
    return false;
  }
  return true;
}

void invalidCommand() =>
    print('${red('Error!')} Unrecognized command ${red(args[0])}');
