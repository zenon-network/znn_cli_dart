import 'package:dcli/dcli.dart' hide verbose;
import 'package:znn_sdk_dart/znn_sdk_dart.dart';
import 'src.dart';

void liquidityMenu() {
  print('  ${white('Liquidity')}');
  print('    liquidity.info');
  print('    liquidity.security');
  print('    liquidity.timeChallenges');
  print('    liquidity.getFrontierReward address');
  print('    liquidity.getStakeEntries address');
  print('    liquidity.getUncollectedReward address');
  print('    liquidity.stake duration (in months) amount tokenStandard');
  print('    liquidity.cancelStake id');
  print('    liquidity.collectRewards');
  print('    liquidity.guardian.proposeAdmin address');
}

void liquidityAdminMenu() {
  print('  ${white('Liquidity Admin')}');
  print('    liquidity.admin.emergency');
  print('    liquidity.admin.halt');
  print('    liquidity.admin.unhalt');
  print('    liquidity.admin.changeAdmin');
  print('    liquidity.admin.nominateGuardians');
  print('    liquidity.admin.unlockStakeEntries');
  print('    liquidity.admin.setAdditionalReward');
  print('    liquidity.admin.setTokenTuple');
}

Future<void> liquidityFunctions() async {
  switch (args[0].split('.')[1]) {
    case 'info':
      verbose ? print('Description: Get the liquidity information') : null;
      await _info();
      return;

    case 'security':
      verbose ? print('Description: Get the liquidity security info') : null;
      await _security();
      return;

    case 'timeChallenges':
      verbose ? print('Description: List the liquidity time challenges') : null;
      await _timeChallenges();
      return;

    case 'getRewardTotal':
      verbose
          ? print('Description: Display total rewards an address has earned')
          : null;
      await _getRewardTotal();
      return;

    case 'getStakeEntries':
      verbose
          ? print('Description: Display all stake entries for an address')
          : null;
      await _getStakeEntries();
      return;

    case 'getUncollectedReward':
      verbose
          ? print('Description: Display uncollected rewards for an address')
          : null;
      await _getUncollectedReward();
      return;

    case 'stake':
      verbose ? print('Description: Stake LP tokens') : null;
      await _stake();
      return;

    case 'cancelStake':
      verbose
          ? print(
              'Description: Cancel an unlocked stake and receive your LP tokens')
          : null;
      await _cancelStake();
      return;

    case 'collectRewards':
      verbose ? print('Description: Collect liquidity rewards') : null;
      await _collectRewards();
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
  LiquidityInfo info = await znnClient.embedded.liquidity.getLiquidityInfo();

  print('Liquidity info:');
  print('   Administrator: ${info.administrator}');
  print('   ${green('ZNN')} reward: ${green('${info.znnReward}')}');
  print('   ${blue('QSR')} reward: ${blue('${info.qsrReward}')}');
  print('   Is halted: ${info.isHalted}');
  print('   Tokens:');

  for (TokenTuple tuple in info.tokenTuples) {
    {
      Token token =
          (await znnClient.embedded.token.getByZts(tuple.tokenStandard))!;

      var type = "Token";

      if (token.tokenStandard == qsrZts || token.tokenStandard == znnZts) {
        type = "Coin";
      }
      print(
          '      $type ${token.name} with symbol ${token.symbol} and standard ${token.tokenStandard}');
      print(
          '        ${green('ZNN ${tuple.znnPercentage / 100}%')} ${blue('QSR ${tuple.qsrPercentage / 100}%')} minimum amount ${AmountUtils.addDecimals(tuple.minAmount, token.decimals)}');
      print('');
    }
  }
}

Future<void> _security() async {
  SecurityInfo info = await znnClient.embedded.liquidity.getSecurityInfo();
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
      await znnClient.embedded.liquidity.getTimeChallengesInfo();

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

Future<void> _getRewardTotal() async {
  if (args.length != 2) {
    print('Incorrect number of arguments. Expected:');
    print('liquidity.getRewardTotal address');
    return;
  }

  Address address = Address.parse(args[1]);
  RewardHistoryList list =
      await znnClient.embedded.liquidity.getFrontierRewardByPage(address);

  BigInt znnRewards = BigInt.zero;
  BigInt qsrRewards = BigInt.zero;

  if (list.count > 0) {
    for (RewardHistoryEntry entry in list.list) {
      if (entry.znnAmount != BigInt.zero || entry.qsrAmount != BigInt.zero) {
        znnRewards += entry.znnAmount;
        qsrRewards += entry.qsrAmount;
      }
    }
    if (znnRewards == BigInt.zero && qsrRewards == BigInt.zero) {
      print('No rewards found.');
    } else {
      print('Total Rewards:');
      print(
          '   ${green('ZNN')}: ${green(AmountUtils.addDecimals(znnRewards, coinDecimals))}');
      print(
          '   ${blue('QSR')}: ${blue(AmountUtils.addDecimals(qsrRewards, coinDecimals))}');
    }
  } else {
    print('No rewards found.');
  }
}

Future<void> _getStakeEntries() async {
  if (args.length != 2) {
    print('Incorrect number of arguments. Expected:');
    print('liquidity.getStakeEntries address');
    return;
  }

  Address address = Address.parse(args[1]);
  LiquidityStakeList list = await znnClient.embedded.liquidity
      .getLiquidityStakeEntriesByAddress(address);

  if (list.count == 0) {
    print('No stake entries found.');
    return;
  }

  print('Stake Entries:');
  print('   Total Amount: ${list.totalAmount}');
  print('   Total Weighted Amount: ${list.totalWeightedAmount}');
  for (LiquidityStakeEntry info in list.list) {
    Token token =
        (await znnClient.embedded.token.getByZts(info.tokenStandard))!;

    int currentTime = ((DateTime.now().millisecondsSinceEpoch) / 1000).floor();
    format(Duration d) => d.toString().split('.').first.padLeft(8, '0');
    double duration = (info.expirationTime - info.startTime) / stakeTimeUnitSec;
    int timeRemaining = info.expirationTime - currentTime;

    print('      Id: ${info.id}');
    print(
        '      Status: ${info.amount != BigInt.zero && info.revokeTime == 0 ? 'Active' : 'Cancelled'}');
    print('      Token: ${token.name}');
    print(
        '      Amount: ${AmountUtils.addDecimals(info.amount, token.decimals)} ${token.symbol}');
    print(
        '      Weighted Amount: ${AmountUtils.addDecimals(info.weightedAmount, token.decimals)} ${token.symbol}');
    print(
        '      Duration: $duration $stakeUnitDurationName${duration > 1 ? 's' : null}');
    print(
        '      Time Remaining: ${format(Duration(seconds: timeRemaining))} day${timeRemaining > (24 * 60 * 60) ? 's' : null}');
    print('      Revoke Time: ${info.revokeTime}');
    print('');
  }
}

Future<void> _getUncollectedReward() async {
  if (args.length != 2) {
    print('Incorrect number of arguments. Expected:');
    print('liquidity.getUncollectedReward address');
    return;
  }

  Address address = Address.parse(args[1]);
  RewardDeposit uncollectedRewards =
      await znnClient.embedded.liquidity.getUncollectedReward(address);

  if (uncollectedRewards.znnAmount != BigInt.zero ||
      uncollectedRewards.qsrAmount != BigInt.zero) {
    print('Uncollected Rewards:');
    print(
        '   ${green('ZNN')}: ${green(AmountUtils.addDecimals(uncollectedRewards.znnAmount, coinDecimals))}');
    print(
        '   ${blue('QSR')}: ${blue(AmountUtils.addDecimals(uncollectedRewards.qsrAmount, coinDecimals))}');
  } else {
    print('No uncollected rewards');
  }
}

Future<void> _stake() async {
  if (args.length != 4) {
    print('Incorrect number of arguments. Expected:');
    print('liquidity.stake duration (in months) amount tokenStandard');
    return;
  }

  int months = int.parse(args[1]);
  int duration = months * 24 * 60 * 60;
  TokenStandard tokenStandard = TokenStandard.parse(args[3]);
  Token token = (await znnClient.embedded.token.getByZts(tokenStandard))!;
  BigInt amount =
      AmountUtils.extractDecimals(num.parse(args[2]), token.decimals);

  if (duration < stakeTimeMinSec ||
      duration > stakeTimeMaxSec ||
      duration % stakeTimeUnitSec != 0) {
    print('${red('Error!')} Invalid staking duration');
    return;
  }

  if (!await hasBalance(znnClient, address, tokenStandard, amount)) {
    return;
  }

  LiquidityInfo info = await znnClient.embedded.liquidity.getLiquidityInfo();
  if (info.isHalted) {
    print('${red('Error!')} Liquidity contract is halted');
    return;
  }

  bool found = false;
  late TokenTuple liquidityToken;
  for (TokenTuple token in info.tokenTuples) {
    if (token.tokenStandard == tokenStandard) {
      found = true;
      liquidityToken = token;
      break;
    }
  }

  if (found) {
    if (amount < liquidityToken.minAmount) {
      print(
          '${red('Error!')} Minimum staking requirement: ${AmountUtils.addDecimals(liquidityToken.minAmount, token.decimals)} ${token.symbol}');
      return;
    }
  } else {
    print(
        '${red('Error!')} ${token.name} cannot be staked in the Liquidity contract');
    return;
  }

  print(
      'Staking ${AmountUtils.addDecimals(amount, token.decimals)} ${token.symbol} for $months month${months > 1 ? 's' : null} ...');
  AccountBlockTemplate liquidityStake = znnClient.embedded.liquidity
      .liquidityStake(duration, amount, tokenStandard);
  liquidityStake = await znnClient.send(liquidityStake);
  print('Done');
}

Future<void> _cancelStake() async {
  if (args.length != 2) {
    print('Incorrect number of arguments. Expected:');
    print('liquidity.cancelStake id');
    return;
  }

  Hash id = Hash.parse(args[1]);

  LiquidityStakeList list = await znnClient.embedded.liquidity
      .getLiquidityStakeEntriesByAddress(address);

  if (list.count == 0) {
    print('No stake entries found.');
    return;
  }

  LiquidityStakeEntry? entry;
  bool found = false;
  for (LiquidityStakeEntry info in list.list) {
    if (info.id == id) {
      entry = info;
      found = true;
      break;
    }
  }

  if (found) {
    int currentTime = ((DateTime.now().millisecondsSinceEpoch) / 1000).floor();

    if (currentTime > entry!.expirationTime) {
      print('Cancelling liquidity stake ...');
      AccountBlockTemplate cancelLiquidityStake =
          znnClient.embedded.liquidity.cancelLiquidityStake(id);
      cancelLiquidityStake = await znnClient.send(cancelLiquidityStake);
      print('Done');
      print(
          'Use ${green('receiveAll')} to collect your staked amount after 2 momentums');
    } else {
      format(Duration d) => d.toString().split('.').first.padLeft(8, '0');
      print('That staking entry is not unlocked yet.');
      print(
          'Time Remaining: ${format(Duration(seconds: entry.expirationTime - currentTime))}');
    }
  } else {
    print('Staking entry not found');
  }
}

Future<void> _collectRewards() async {
  RewardDeposit uncollectedRewards =
      await znnClient.embedded.liquidity.getUncollectedReward(address);

  if (uncollectedRewards.znnAmount != BigInt.zero ||
      uncollectedRewards.qsrAmount != BigInt.zero) {
    print('Uncollected Rewards:');
    print(
        '   ${green('ZNN')}: ${green(AmountUtils.addDecimals(uncollectedRewards.znnAmount, coinDecimals))}');
    print(
        '   ${blue('QSR')}: ${blue(AmountUtils.addDecimals(uncollectedRewards.qsrAmount, coinDecimals))}');
    print('');
    print('Collecting rewards ...');
    AccountBlockTemplate collectReward =
        znnClient.embedded.liquidity.collectReward();
    collectReward = await znnClient.send(collectReward);
    print('Done');
  } else {
    print('No uncollected rewards');
  }
}

Future<void> _guardianFunctions() async {
  switch (args[0].split('.')[2]) {
    case 'proposeAdmin':
      verbose
          ? print(
              'Description: Participate in a vote to elect a new liquidity administrator when the contract is in Emergency mode')
          : null;
      await _proposeAdmin();
      return;

    default:
      invalidCommand();
  }
}

Future<void> _proposeAdmin() async {
  _isGuardian();

  if (args.length != 2) {
    print('Incorrect number of arguments. Expected:');
    print('liquidity.guardian.proposeAdmin address');
    return;
  }

  String currentAdmin = (await znnClient.embedded.liquidity.getLiquidityInfo())
      .administrator
      .toString();
  Address newAdmin = Address.parse(args[1]);

  if (currentAdmin == '' ||
      currentAdmin.isEmpty ||
      currentAdmin == emptyAddress.toString()) {
    print('Proposing new liquidity administrator ...');
    AccountBlockTemplate proposeAdministrator =
        znnClient.embedded.liquidity.proposeAdministrator(newAdmin);
    proposeAdministrator = await znnClient.send(proposeAdministrator);
    print('Done');
  } else {
    print(
        '${red('Permission denied!')} Liquidity contract is not in emergency mode');
  }
}

Future<void> _adminFunctions() async {
  switch (args[0].split('.')[2]) {
    case 'emergency':
      verbose
          ? print('Description: Put the liquidity contract in emergency mode')
          : null;
      await _emergency();
      return;

    case 'halt':
      verbose ? print('Description: Halt liquidity operations') : null;
      await _halt();
      return;

    case 'unhalt':
      verbose ? print('Description: Unhalt liquidity operations') : null;
      await _unhalt();
      return;

    case 'changeAdmin':
      verbose ? print('Description: Change liquidity administrator') : null;
      await _changeAdmin();
      return;

    case 'nominateGuardians':
      verbose ? print('Description: Nominate liquidity guardians') : null;
      await _nominateGuardians();
      return;

    case 'unlockStakeEntries':
      verbose
          ? print(
              'Description: Allows all staked entries to be cancelled immediately')
          : null;
      await _unlockStakeEntries();
      return;

    case 'setAdditionalReward':
      verbose
          ? print('Description: Set additional liquidity reward percentages')
          : null;
      await _setAdditionalReward();
      return;

    case 'setTokenTuple':
      verbose
          ? print('Description: Configure token tuples that can be staked')
          : null;
      print('This function is currently unsupported');
      return;

    default:
      invalidCommand();
  }
}

Future<void> _emergency() async {
  _isAdmin();
  print('Initializing liquidity emergency mode ...');
  AccountBlockTemplate emergency = znnClient.embedded.liquidity.emergency();
  emergency = await znnClient.send(emergency);
  print('Done');
}

Future<void> _halt() async {
  _isAdmin();
  print('Halting the liquidity ...');
  AccountBlockTemplate halt = znnClient.embedded.liquidity.setIsHalted(false);
  halt = await znnClient.send(halt);
  print('Done');
}

Future<void> _unhalt() async {
  _isAdmin();
  print('Unhalting the liquidity ...');
  AccountBlockTemplate unhalt = znnClient.embedded.liquidity.setIsHalted(false);
  unhalt = await znnClient.send(unhalt);
  print('Done');
}

Future<void> _changeAdmin() async {
  _isAdmin();

  if (args.length != 2) {
    print('Incorrect number of arguments. Expected:');
    print('liquidity.admin.changeAdmin address');
    return;
  }

  Address newAdmin = Address.parse(args[1]);

  print('Changing liquidity administrator ...');
  AccountBlockTemplate changeAdministrator =
      znnClient.embedded.liquidity.changeAdministrator(newAdmin);
  changeAdministrator = await znnClient.send(changeAdministrator);
  print('Done');
}

Future<void> _nominateGuardians() async {
  _isAdmin();

  if (args.length < bridgeMinGuardians + 1) {
    print(
        'Incorrect number of arguments. Expected at least $bridgeMinGuardians addresses:');
    print('liquidity.admin.nominateGuardians address1 address2 ... addressN');
    return;
  }

  List<Address> guardians = [];

  for (int i = 1; i < args.length; i++) {
    try {
      Address guardian = Address.parse(args[i]);
      if (guardian != emptyAddress) {
        guardians.add(guardian);
      }
    } catch (e) {
      print('${red('Error!')} ${args[i]} is not a valid address');
      return;
    }
  }

  print('Nominating guardians ...');
  AccountBlockTemplate nominateGuardians =
      znnClient.embedded.liquidity.nominateGuardians(guardians);
  nominateGuardians = await znnClient.send(nominateGuardians);
  print('Done');
}

Future<void> _unlockStakeEntries() async {
  AccountBlockTemplate unlockLiquidityStakeEntries =
      znnClient.embedded.liquidity.unlockLiquidityStakeEntries(
          TokenStandard.parse('zts17d6yr02kh0r9qr566p7tg6'));
  unlockLiquidityStakeEntries =
      await znnClient.send(unlockLiquidityStakeEntries);
  print(unlockLiquidityStakeEntries.toJson());
}

Future<void> _setAdditionalReward() async {
  _isAdmin();

  if (args.length != 3) {
    print('Incorrect number of arguments. Expected:');
    print('liquidity.admin.setAdditionalReward znnReward qsrReward');
    return;
  }

  int znnReward = int.parse(args[1]);
  int qsrReward = int.parse(args[2]);

  print('Setting additional liquidity reward ...');
  AccountBlockTemplate setAdditionalReward =
      znnClient.embedded.liquidity.setAdditionalReward(znnReward, qsrReward);
  setAdditionalReward = await znnClient.send(setAdditionalReward);
  print('Done');
}

Future<void> _isGuardian() async {
  if (!(await znnClient.embedded.liquidity.getSecurityInfo())
      .guardians
      .contains(address)) {
    print(
        '${red('Permission denied!')} This function can only be called by a Guardian');
    return;
  }
}

Future<void> _isAdmin() async {
  if (!((await znnClient.embedded.liquidity.getLiquidityInfo()).administrator ==
      address)) {
    print(
        '${red('Permission denied!')} $address is not the Liquidity administrator');
    return;
  }
}
