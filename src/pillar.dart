import 'package:dcli/dcli.dart' hide verbose;
import 'package:znn_sdk_dart/znn_sdk_dart.dart';
import 'src.dart';

void pillarMenu() {
  print('  ${white('Pillar')}');
  print('    pillar.list');
  print(
      '    pillar.register name producerAddress rewardAddress giveBlockRewardPercentage giveDelegateRewardPercentage');
  print('    pillar.revoke name');
  print('    pillar.delegate name');
  print('    pillar.undelegate');
  print('    pillar.collect');
  print('    pillar.depositQsr');
  print('    pillar.withdrawQsr');
}

Future<void> pillarFunctions() async {
  switch (args[0].split('.')[1]) {
    case 'list':
      verbose ? print('Description: List all pillars') : null;
      await _list();
      return;

    case 'register':
      verbose ? print('Description: Register pillar') : null;
      await _register();
      return;

    case 'revoke':
      verbose ? print('Description: Revoke pillar') : null;
      await _revoke();
      return;

    case 'delegate':
      verbose ? print('Description: Delegate to pillar') : null;
      await _delegate();
      return;

    case 'undelegate':
      verbose ? print('Description: Undelegate pillar') : null;
      await _undelegate();
      return;

    case 'collect':
      verbose ? print('Description: Collect pillar rewards') : null;
      await _collect();
      return;

    case 'depositQsr':
      verbose ? print('Description: Deposit QSR to the pillar contract') : null;
      await _depositQsr();
      return;

    case 'withdrawQsr':
      verbose
          ? print(
              'Description: Withdraw deposited QSR from the pillar contract')
          : null;
      await _withdrawQsr();
      return;

    default:
      invalidCommand();
  }
}

Future<void> _list() async {
  PillarInfoList pillarList = await znnClient.embedded.pillar.getAll();
  for (PillarInfo pillar in pillarList.list) {
    print(
        '#${pillar.rank + 1} Pillar ${green(pillar.name)} has a delegated weight of ${AmountUtils.addDecimals(pillar.weight, coinDecimals)} ${green('ZNN')}');
    print('    Producer address ${pillar.producerAddress}');
    print(
        '    Momentums ${pillar.currentStats.producedMomentums} / expected ${pillar.currentStats.expectedMomentums}');
  }
}

Future<void> _register() async {
  if (args.length != 6) {
    print('Incorrect number of arguments. Expected:');
    print(
        'pillar.register name producerAddress rewardAddress giveBlockRewardPercentage giveDelegateRewardPercentage');
    return;
  }

  int giveBlockRewardPercentage = int.parse(args[4]);
  int giveDelegateRewardPercentage = int.parse(args[5]);

  AccountInfo balance = await znnClient.ledger.getAccountInfoByAddress(address);
  BigInt qsrAmount = await znnClient.embedded.pillar.getQsrRegistrationCost();
  BigInt depositedQsr =
      await znnClient.embedded.pillar.getDepositedQsr(address);
  if ((balance.znn()! < pillarRegisterZnnAmount ||
          balance.qsr()! < qsrAmount) &&
      qsrAmount > depositedQsr) {
    print('Cannot register Pillar with address ${address.toString()}');
    print(
        'Required ${AmountUtils.addDecimals(pillarRegisterZnnAmount, coinDecimals)} ${green('ZNN')} and ${AmountUtils.addDecimals(qsrAmount, coinDecimals)} ${blue('QSR')}');
    print(
        'Available ${AmountUtils.addDecimals(balance.znn()!, coinDecimals)} ${green('ZNN')} and ${AmountUtils.addDecimals(balance.qsr()!, coinDecimals)} ${blue('QSR')}');
    return;
  }

  print(
      'Creating a new ${green('Pillar')} will burn the deposited ${blue('QSR')} required for the Pillar slot');
  if (!confirm('Do you want to proceed?', defaultValue: false)) return;

  String newName = args[1];
  bool ok = await znnClient.embedded.pillar.checkNameAvailability(newName);
  while (!ok) {
    newName = ask(
        'This Pillar name is already reserved. Please choose another name for the Pillar');
    ok = await znnClient.embedded.pillar.checkNameAvailability(newName);
  }
  if (depositedQsr < qsrAmount) {
    print(
        'Depositing ${AmountUtils.addDecimals(qsrAmount - depositedQsr, coinDecimals)} ${blue('QSR')} for the Pillar registration');
    await znnClient
        .send(znnClient.embedded.pillar.depositQsr(qsrAmount - depositedQsr));
  }
  print('Registering Pillar ...');
  await znnClient.send(znnClient.embedded.pillar.register(
      newName,
      Address.parse(args[2]),
      Address.parse(args[3]),
      giveBlockRewardPercentage,
      giveDelegateRewardPercentage));
  print('Done');
  print(
      'Check after 2 momentums if the Pillar was successfully registered using ${green('pillar.list')} command');
}

Future<void> _revoke() async {
  if (args.length != 2) {
    print('Incorrect number of arguments. Expected:');
    print('pillar.revoke name');
    return;
  }
  PillarInfoList pillarList = await znnClient.embedded.pillar.getAll();
  bool ok = false;
  for (PillarInfo pillar in pillarList.list) {
    if (args[1].compareTo(pillar.name) == 0) {
      ok = true;
      if (pillar.isRevocable) {
        print('Revoking Pillar ${pillar.name} ...');
        await znnClient.send(znnClient.embedded.pillar.revoke(args[1]));
        print(
            'Use ${green('receiveAll')} to collect back the locked amount of ${green('ZNN')}');
      } else {
        print(
            'Cannot revoke Pillar ${pillar.name}. Revocation window will open in ${formatDuration(pillar.revokeCooldown)}');
      }
    }
  }
  if (ok) {
    print('Done');
  } else {
    print('There is no Pillar with this name');
  }
}

Future<void> _delegate() async {
  if (args.length != 2) {
    print('Incorrect number of arguments. Expected:');
    print('pillar.delegate name');
    return;
  }
  print('Delegating to Pillar ${args[1]} ...');
  await znnClient.send(znnClient.embedded.pillar.delegate(args[1]));
  print('Done');
}

Future<void> _undelegate() async {
  print('Undelegating ...');
  await znnClient.send(znnClient.embedded.pillar.undelegate());
  print('Done');
}

Future<void> _collect() async {
  await znnClient.send(znnClient.embedded.pillar.collectReward());
  print('Done');
  print(
      'Use ${green('receiveAll')} to collect your Pillar reward(s) after 1 momentum');
}

Future<void> _depositQsr() async {
  AccountInfo balance = await znnClient.ledger.getAccountInfoByAddress(address);
  BigInt qsrAmount = await znnClient.embedded.pillar.getQsrRegistrationCost();
  BigInt depositedQsr =
      await znnClient.embedded.pillar.getDepositedQsr(address);

  print(
      'You have $depositedQsr / $qsrAmount ${blue('QSR')} deposited for the Pillar registration');

  if (balance.qsr()! < qsrAmount) {
    print(
        'Required ${AmountUtils.addDecimals(qsrAmount, coinDecimals)} ${blue('QSR')}');
    print(
        'Available ${AmountUtils.addDecimals(balance.qsr()!, coinDecimals)} ${blue('QSR')}');
    return;
  }

  if (depositedQsr < qsrAmount) {
    print(
        'Depositing ${AmountUtils.addDecimals(qsrAmount - depositedQsr, coinDecimals)} ${blue('QSR')} for the Pillar registration');
    await znnClient
        .send(znnClient.embedded.pillar.depositQsr(qsrAmount - depositedQsr));
  }
  print('Done');
}

Future<void> _withdrawQsr() async {
  BigInt depositedQsr =
      await znnClient.embedded.pillar.getDepositedQsr(address);
  if (depositedQsr == BigInt.zero) {
    print('No deposited ${blue('QSR')} to withdraw');
    return;
  }
  print(
      'Withdrawing ${AmountUtils.addDecimals(depositedQsr, coinDecimals)} ${blue('QSR')} ...');
  await znnClient.send(znnClient.embedded.pillar.withdrawQsr());
  print('Done');
}
