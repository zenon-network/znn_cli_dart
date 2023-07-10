import 'package:dcli/dcli.dart' hide verbose;
import 'package:znn_sdk_dart/znn_sdk_dart.dart';
import 'src.dart';

void stakingMenu() {
  print('  ${white('Staking')}');
  print('    stake.list [pageIndex pageCount]');
  print('    stake.register amount duration (in months)');
  print('    stake.revoke id');
  print('    stake.collect');
}

Future<void> stakingFunctions() async {
  switch (args[0].split('.')[1]) {
    case 'list':
      verbose ? print('Description: List all stakes') : null;
      await _list();
      return;

    case 'register':
      verbose ? print('Description: Register stake') : null;
      await _register();
      return;

    case 'revoke':
      verbose ? print('Description: Revoke stake') : null;
      await _revoke();
      return;

    case 'collect':
      verbose ? print('Description: Collect staking rewards') : null;
      await _collect();
      return;

    default:
      invalidCommand();
  }
}

Future<void> _list() async {
  if (!(args.length == 1 || args.length == 3)) {
    print('Incorrect number of arguments. Expected:');
    print(' stake.list [pageIndex pageSize]');
    return;
  }
  int pageIndex = 0;
  int pageSize = 25;
  if (args.length == 3) {
    pageIndex = int.parse(args[1]);
    pageSize = int.parse(args[2]);
  }
  final currentTime = (DateTime.now().millisecondsSinceEpoch / 1000).round();
  StakeList stakeList = await znnClient.embedded.stake
      .getEntriesByAddress(address, pageIndex: pageIndex, pageSize: pageSize);

  if (stakeList.count > 0) {
    print(
        'Showing ${stakeList.list.length} out of a total of ${stakeList.count} staking entries');
  } else {
    print('No staking entries found');
  }

  for (StakeEntry entry in stakeList.list) {
    print(
        'Stake id ${entry.id.toString()} with amount ${AmountUtils.addDecimals(entry.amount, coinDecimals)} ${green('ZNN')}');
    if (entry.expirationTimestamp > currentTime) {
      print(
          '    Can be revoked in ${formatDuration(entry.expirationTimestamp - currentTime)}');
    } else {
      print('    ${green('Can be revoked now')}');
    }
  }
}

Future<void> _register() async {
  if (args.length != 3) {
    print('Incorrect number of arguments. Expected:');
    print('stake.register amount duration (in months)');
    return;
  }
  BigInt amount = AmountUtils.extractDecimals(num.parse(args[1]), coinDecimals);
  final duration = int.parse(args[2]);
  if (duration < 1 || duration > 12) {
    print(
        '${red('Invalid duration')}: ($duration) $stakeUnitDurationName. It must be between 1 and 12');
    return;
  }
  if (amount < stakeMinAmount) {
    print(
        '${red('Invalid amount')}: ${AmountUtils.addDecimals(amount, coinDecimals)} ${green('ZNN')}. Minimum staking amount is ${AmountUtils.addDecimals(stakeMinAmount, coinDecimals)}');
    return;
  }
  AccountInfo balance = await znnClient.ledger.getAccountInfoByAddress(address);
  if (balance.znn()! < amount) {
    print(red('Not enough ZNN to stake'));
    return;
  }

  print(
      'Staking ${AmountUtils.addDecimals(amount, coinDecimals)} ${green('ZNN')} for $duration $stakeUnitDurationName(s)');
  await znnClient.send(
      znnClient.embedded.stake.stake(stakeTimeUnitSec * duration, amount));
  print('Done');
}

Future<void> _revoke() async {
  if (args.length != 2) {
    print('Incorrect number of arguments. Expected:');
    print('stake.revoke id');
    return;
  }
  Hash hash = Hash.parse(args[1]);

  final currentTime = (DateTime.now().millisecondsSinceEpoch / 1000).round();
  int pageIndex = 0;
  bool one = false;
  bool gotError = false;

  StakeList entries = await znnClient.embedded.stake
      .getEntriesByAddress(address, pageIndex: pageIndex);
  while (entries.list.isNotEmpty) {
    for (StakeEntry entry in entries.list) {
      if (entry.id.toString() == hash.toString()) {
        if (entry.expirationTimestamp > currentTime) {
          print(
              '${red('Cannot revoke!')} Try again in ${formatDuration(entry.expirationTimestamp - currentTime)}');
          gotError = true;
        }
        one = true;
      }
    }
    pageIndex++;
    entries = await znnClient.embedded.stake
        .getEntriesByAddress(address, pageIndex: pageIndex);
  }

  if (gotError) {
    return;
  } else if (!one) {
    print('${red('Error!')} No stake entry found with id ${hash.toString()}');
    return;
  }

  await znnClient.send(znnClient.embedded.stake.cancel(hash));
  print('Done');
  print(
      'Use ${green('receiveAll')} to collect your stake amount and uncollected reward(s) after 2 momentums');
}

Future<void> _collect() async {
  await znnClient.send(znnClient.embedded.stake.collectReward());
  print('Done');
  print(
      'Use ${green('receiveAll')} to collect your stake reward(s) after 1 momentum');
}
