import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:dcli/dcli.dart';
import 'package:path/path.dart' as path;
import 'package:znn_cli_dart/global.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

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
    throw ('${red('Error!')} tokenStandard must be a valid token standard\nExamples: ${green('ZNN')}/${blue('QSR')}/${magenta('ZTS')}');
  }
}

Future<Token> getToken(TokenStandard tokenStandard) async {
  try {
    Token? token = await znnClient.embedded.token.getByZts(tokenStandard);
    return token!;
  } catch (e) {
    throw ('${red('Error!')} $tokenStandard does not exist');
  }
}

Function getColor(TokenStandard tokenStandard) {
  switch (tokenStandard.toString()) {
    case znnTokenStandard:
      return green;
    case qsrTokenStandard:
      return blue;
    default:
      return magenta;
  }
}

List<int> generatePreimage([int length = htlcPreimageDefaultLength]) {
  const maxInt = 256;
  return List<int>.generate(length, (i) => Random.secure().nextInt(maxInt));
}

ByteData combine(List values) {
  try {
    List<List<int>> byteArrays = [];
    values.map((e) => byteArrays.add(e.getBytes()!)).toList();

    int offset = 0;
    int length = 0;
    for (List<int> data in byteArrays) {
      length += Uint8List.fromList(data).length;
    }
    ByteData bd = ByteData(length);

    for (List<int> data in byteArrays) {
      for (var byte in Uint8List.fromList(data)) {
        bd.setUint8(offset, byte);
        offset++;
      }
    }
    return bd;
  } catch (e) {
    throw ('${red('Error!')} Error while reading address data');
  }
}
