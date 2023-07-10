import 'dart:math';

import 'package:dcli/dcli.dart' hide verbose;
import 'package:znn_sdk_dart/znn_sdk_dart.dart';
import 'src.dart';

void statsMenu() {
  print('  ${white('Stats')}');
  print('    stats.networkInfo');
  print('    stats.osInfo');
  print('    stats.processInfo');
  print('    stats.syncInfo');
}

Future<void> statsFunctions() async {
  switch (args[0].split('.')[1]) {
    case 'networkInfo':
      verbose ? print('Description: Get the network info') : null;
      await _networkInfo();
      return;

    case 'osInfo':
      verbose ? print('Description: Get the os info') : null;
      await _osInfo();
      return;

    case 'processInfo':
      verbose ? print('Description: Get the process info') : null;
      await _processInfo();
      return;

    case 'syncInfo':
      verbose ? print('Description: Get the sync info') : null;
      await _syncInfo();
      return;

    default:
      invalidCommand();
  }
}

Future<void> _networkInfo() async {
  NetworkInfo networkInfo = await znnClient.stats.networkInfo();
  print('numPeers: ${networkInfo.numPeers}');
  for (var peer in networkInfo.peers) {
    print('    publicKey: ${peer.publicKey}');
    print('    ip: ${peer.ip}');
  }
  //print('self.ip: ${networkInfo.self.ip}');
  print('self.publicKey: ${networkInfo.self.publicKey}');
}

Future<void> _osInfo() async {
  OsInfo osInfo = (await znnClient.stats.osInfo());
  print('os: ${osInfo.os}');
  print('platform: ${osInfo.platform}');
  print('platformFamily: ${osInfo.platformFamily}');
  print('platformVersion: ${osInfo.platformVersion}');
  print('kernelVersion: ${osInfo.kernelVersion}');
  print(
      'memoryTotal: ${osInfo.memoryTotal} (${formatMemory(osInfo.memoryTotal)})');
  print(
      'memoryFree: ${osInfo.memoryFree} (${formatMemory(osInfo.memoryFree)})');
  print('numCPU: ${osInfo.numCPU}');
  print('numGoroutine: ${osInfo.numGoroutine}');
}

Future<void> _processInfo() async {
  ProcessInfo processInfo = await znnClient.stats.processInfo();
  print('version: ${processInfo.version}');
  print('commit: ${processInfo.commit}');
}

Future<void> _syncInfo() async {
  SyncInfo syncInfo = await znnClient.stats.syncInfo();
  print('state: ${syncInfo.state.name} (${syncInfo.state.index})');
  print('currentHeight: ${syncInfo.currentHeight}');
  print('targetHeight: ${syncInfo.targetHeight}');
}

String formatMemory(size) {
  var i = size == 0 ? 0 : (log(size) / log(1024)).floor();
  return ((size / pow(1024, i)) * 1).toStringAsFixed(2) +
      ' ${['B', 'kB', 'MB', 'GB', 'TB'][i]}';
}
