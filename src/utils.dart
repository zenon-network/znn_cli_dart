import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dcli/dcli.dart' hide verbose;
import 'package:path/path.dart' as path;
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import 'global.dart';

final znndConfigPath = File(path.join(znnDefaultDirectory.path, 'config.json'));

String formatJSON(Map<dynamic, dynamic> j) {
  var spaces = ' ' * 4;
  var encoder = JsonEncoder.withIndent(spaces);
  return encoder.convert(j);
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

String getZnndVersion(String executableName) {
  switch (Platform.operatingSystem) {
    case 'linux':
      return Process.runSync('./' + executableName, ['-v'], runInShell: true)
          .stdout
          .toString();
    case 'windows':
      return Process.runSync('$executableName.exe', ['-v'], runInShell: true)
          .stdout
          .toString();
    case 'macos':
      return Process.runSync('./' + executableName, ['-v'], runInShell: true)
          .stdout
          .toString();
    default:
      return 'Unknown znnd version';
  }
}

Future<bool> hasBalance(Zenon znnClient, Address address,
    TokenStandard tokenStandard, BigInt amount) async {
  AccountInfo info = await znnClient.ledger.getAccountInfoByAddress(address);
  bool ok = true;
  bool found = false;
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

List<int> generatePreimage([int length = htlcPreimageDefaultLength]) {
  const maxInt = 256;
  return List<int>.generate(length, (i) => Random.secure().nextInt(maxInt));
}

void invalidCommand() {
  print('${red('Error!')} Unrecognized command ${red(args[0])}');
}

TokenStandard getTokenStandard(String zts) {
  try {
    TokenStandard tokenStandard;
    if (zts.toLowerCase() == 'znn') {
      tokenStandard = znnZts;
    } else if (zts.toLowerCase() == 'qsr') {
      tokenStandard = qsrZts;
    } else {
      tokenStandard = TokenStandard.parse(zts);
    }
    return tokenStandard;
  } catch (e) {
    print('${red('Error!')} tokenStandard must be a valid token standard');
    print('Examples: ${green('ZNN')}/${blue('QSR')}/${magenta('ZTS')}');
    rethrow;
  }
}
