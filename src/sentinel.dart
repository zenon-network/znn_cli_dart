import 'package:dcli/dcli.dart' hide verbose;
import 'package:znn_sdk_dart/znn_sdk_dart.dart';
import 'src.dart';

void sentinelMenu() {
  print('  ${white('Sentinel')}');
  print('    sentinel.list');
  print('    sentinel.register');
  print('    sentinel.revoke');
  print('    sentinel.collect');
  print('    sentinel.depositQsr');
  print('    sentinel.withdrawQsr');
}

Future<void> sentinelFunctions() async {
  switch (args[0].split('.')[1]) {
    case 'list':
      verbose ? print('Description: List all sentinels') : null;
      await _list();
      return;

    case 'register':
      verbose ? print('Description: Register a sentinel') : null;
      await _register();
      return;

    case 'revoke':
      verbose ? print('Description: Revoke a sentinel') : null;
      await _revoke();
      return;

    case 'collect':
      verbose ? print('Description: Collect sentinel rewards') : null;
      await _collect();
      return;

    case 'depositQsr':
      verbose
          ? print('Description: Deposit QSR to the sentinel contract')
          : null;
      await _depositQsr();
      return;

    case 'withdrawQsr':
      verbose
          ? print(
              'Description: Withdraw deposited QSR from the sentinel contract')
          : null;
      await _withdrawQsr();
      return;

    default:
      invalidCommand();
  }
}

Future<void> _list() async {
  if (args.length != 1) {
    print('Incorrect number of arguments. Expected:');
    print('sentinel.list');
    return;
  }
  SentinelInfoList sentinels =
      (await znnClient.embedded.sentinel.getAllActive());
  bool one = false;
  for (SentinelInfo entry in sentinels.list) {
    if (entry.owner.toString() == address.toString()) {
      if (entry.isRevocable) {
        print(
            'Revocation window will close in ${formatDuration(entry.revokeCooldown)}');
      } else {
        print(
            'Revocation window will open in ${formatDuration(entry.revokeCooldown)}');
      }
      one = true;
    }
  }
  if (!one) {
    print('No Sentinel registered at address ${address.toString()}');
  }
}

Future<void> _register() async {
  if (args.length != 1) {
    print('Incorrect number of arguments. Expected:');
    print('sentinel.register');
    return;
  }
  AccountInfo accountInfo =
      await znnClient.ledger.getAccountInfoByAddress(address);
  var depositedQsr = await znnClient.embedded.sentinel.getDepositedQsr(address);
  print('You have $depositedQsr ${blue('QSR')} deposited for the Sentinel');
  if (accountInfo.znn()! < sentinelRegisterZnnAmount ||
      accountInfo.qsr()! < sentinelRegisterQsrAmount) {
    print('Cannot register Sentinel with address ${address.toString()}');
    print(
        'Required ${AmountUtils.addDecimals(sentinelRegisterZnnAmount, coinDecimals)} ${green('ZNN')} and ${AmountUtils.addDecimals(sentinelRegisterQsrAmount, coinDecimals)} ${blue('QSR')}');
    print(
        'Available ${AmountUtils.addDecimals(accountInfo.znn()!, coinDecimals)} ${green('ZNN')} and ${AmountUtils.addDecimals(accountInfo.qsr()!, coinDecimals)} ${blue('QSR')}');
    return;
  }

  if (depositedQsr < sentinelRegisterQsrAmount) {
    await znnClient.send(znnClient.embedded.sentinel
        .depositQsr(sentinelRegisterQsrAmount - depositedQsr));
  }
  await znnClient.send(znnClient.embedded.sentinel.register());
  print('Done');
  print(
      'Check after 2 momentums if the Sentinel was successfully registered using ${green('sentinel.list')} command');
}

Future<void> _revoke() async {
  if (args.length != 1) {
    print('Incorrect number of arguments. Expected:');
    print('sentinel.revoke');
    return;
  }
  SentinelInfo? entry =
      await znnClient.embedded.sentinel.getByOwner(address).catchError((e) {
    if (e.toString().contains('data non existent')) {
      return null;
    } else {
      print('Error: ${e.toString()}');
    }
  });

  if (entry == null) {
    print('No Sentinel found for address ${address.toString()}');
    return;
  }

  if (entry.isRevocable == false) {
    print(
        'Cannot revoke Sentinel. Revocation window will open in ${formatDuration(entry.revokeCooldown)}');
    return;
  }

  await znnClient.send(znnClient.embedded.sentinel.revoke());
  print('Done');
  print(
      'Use ${green('receiveAll')} to collect back the locked amount of ${green('ZNN')} and ${blue('QSR')}');
}

Future<void> _collect() async {
  if (args.length != 1) {
    print('Incorrect number of arguments. Expected:');
    print('sentinel.collect');
    return;
  }
  await znnClient.send(znnClient.embedded.sentinel.collectReward());
  print('Done');
  print(
      'Use ${green('receiveAll')} to collect your Sentinel reward(s) after 1 momentum');
}

Future<void> _depositQsr() async {
  AccountInfo balance = await znnClient.ledger.getAccountInfoByAddress(address);
  BigInt depositedQsr =
      await znnClient.embedded.sentinel.getDepositedQsr(address);
  print(
      'You have $depositedQsr / $sentinelRegisterQsrAmount ${blue('QSR')} deposited for the Sentinel');

  if (balance.qsr()! < sentinelRegisterQsrAmount) {
    print(
        'Required ${AmountUtils.addDecimals(sentinelRegisterQsrAmount, coinDecimals)} ${blue('QSR')}');
    print(
        'Available ${AmountUtils.addDecimals(balance.qsr()!, coinDecimals)} ${blue('QSR')}');
    return;
  }

  if (depositedQsr < sentinelRegisterQsrAmount) {
    print(
        'Depositing ${sentinelRegisterQsrAmount - depositedQsr} ${blue('QSR')} for the Sentinel');
    await znnClient.send(znnClient.embedded.sentinel
        .depositQsr(sentinelRegisterQsrAmount - depositedQsr));
  }
  print('Done');
}

Future<void> _withdrawQsr() async {
  BigInt depositedQsr =
      await znnClient.embedded.sentinel.getDepositedQsr(address);
  if (depositedQsr == BigInt.zero) {
    print('No deposited ${blue('QSR')} to withdraw');
    return;
  }
  print(
      'Withdrawing ${AmountUtils.addDecimals(depositedQsr, coinDecimals)} ${blue('QSR')} ...');
  await znnClient.send(znnClient.embedded.sentinel.withdrawQsr());
  print('Done');
}
