import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bip39/bip39.dart' as bip39;
import 'package:dcli/dcli.dart';
import 'package:path/path.dart' as path;
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import 'init_znn.dart';

Future<int> main(List<String> args) async {
  return initZnn(args, handleCli);
}

Future<void> handleCli(List<String> args) async {
  final Zenon znnClient = Zenon();
  Address? address = (await znnClient.defaultKeyPair?.address);

  switch (args[0]) {
    case 'version':
      if (args.length != 1) {
        print('Incorrect number of arguments. Expected:');
        print('version');
        break;
      }
      print('$znnCli v$znnCliVersion using Zenon SDK v$znnSdkVersion');
      print(getZnndVersion());
      break;

    case 'send':
      if (!(args.length == 4 || args.length == 5)) {
        print('Incorrect number of arguments. Expected:');
        print(
            'send toAddress amount [${green('ZNN')}/${blue('QSR')}/${magenta('ZTS')}]');
        break;
      }
      Address newAddress = Address.parse(args[1]);
      late BigInt amount;
      TokenStandard tokenStandard;
      if (args[3] == 'znn' || args[3] == 'ZNN') {
        tokenStandard = znnZts;
      } else if (args[3] == 'qsr' || args[3] == 'QSR') {
        tokenStandard = qsrZts;
      } else {
        tokenStandard = TokenStandard.parse(args[3]);
      }

      AccountInfo info =
          await znnClient.ledger.getAccountInfoByAddress(address!);
      bool ok = true;
      bool found = false;
      for (BalanceInfoListItem entry in info.balanceInfoList!) {
        if (entry.token!.tokenStandard.toString() == tokenStandard.toString()) {
          amount = AmountUtils.extractDecimals(
              num.parse(args[2]), entry.token!.decimals);
          if (entry.balance! < amount) {
            print(
                '${red("Error!")} You only have ${AmountUtils.addDecimals(entry.balance!, entry.token!.decimals)} ${entry.token!.symbol} tokens');
            ok = false;
            break;
          }
          found = true;
        }
      }

      if (!ok) break;
      if (!found) {
        print(
            '${red("Error!")} You only have ${AmountUtils.addDecimals(BigInt.zero, 0)} ${tokenStandard.toString()} tokens');
        break;
      }
      Token? token = await znnClient.embedded.token.getByZts(tokenStandard);
      var block = AccountBlockTemplate.send(newAddress, tokenStandard, amount);

      if (args.length == 5) {
        block.data = AsciiEncoder().convert(args[4]);
        print(
            'Sending ${AmountUtils.addDecimals(amount, token!.decimals)} ${args[3]} to ${args[1]} with a message "${args[4]}"');
      } else {
        print(
            'Sending ${AmountUtils.addDecimals(amount, token!.decimals)} ${args[3]} to ${args[1]}');
      }

      await znnClient.send(block);
      print('Done');
      break;

    case 'receive':
      if (args.length != 2) {
        print('Incorrect number of arguments. Expected:');
        print('receive blockHash');
        break;
      }
      Hash sendBlockHash = Hash.parse(args[1]);
      print('Please wait ...');
      await znnClient.send(AccountBlockTemplate.receive(sendBlockHash));
      print('Done');
      break;

    case 'receiveAll':
      if (args.length != 1) {
        print('Incorrect number of arguments. Expected:');
        print('receiveAll');
        break;
      }
      var unreceived = (await znnClient.ledger
          .getUnreceivedBlocksByAddress(address!, pageIndex: 0, pageSize: 5));
      if (unreceived.count == 0) {
        print('Nothing to receive');
        break;
      } else {
        if (unreceived.more!) {
          print(
              'You have ${red("more")} than ${green(unreceived.count.toString())} transaction(s) to receive');
        } else {
          print(
              'You have ${green(unreceived.count.toString())} transaction(s) to receive');
        }
      }

      print('Please wait ...');
      while (unreceived.count! > 0) {
        for (var block in unreceived.list!) {
          await znnClient.send(AccountBlockTemplate.receive(block.hash));
        }
        unreceived = (await znnClient.ledger
            .getUnreceivedBlocksByAddress(address, pageIndex: 0, pageSize: 5));
      }
      print('Done');
      break;

    case 'autoreceive':
      znnClient.wsClient
          .addOnConnectionEstablishedCallback((broadcaster) async {
        print('Subscribing for account-block events ...');
        await znnClient.subscribe.toAllAccountBlocks();
        print('Subscribed successfully!');

        broadcaster.listen((json) async {
          if (json!["method"] == "ledger.subscription") {
            for (var i = 0; i < json["params"]["result"].length; i += 1) {
              var tx = json["params"]["result"][i];
              if (tx["toAddress"] != address.toString()) {
                continue;
              }
              var hash = tx["hash"];
              print("receiving transaction with hash $hash");
              var template = await znnClient
                  .send(AccountBlockTemplate.receive(Hash.parse(hash)));
              print(
                  "successfully received $hash. Receive-block-hash ${template.hash}");
              await Future.delayed(Duration(seconds: 1));
            }
          }
        });
      });

      for (;;) {
        await Future.delayed(Duration(seconds: 1));
      }

    case 'unreceived':
      if (args.length != 1) {
        print('Incorrect number of arguments. Expected:');
        print('unreceived');
        break;
      }
      var unreceived = await znnClient.ledger
          .getUnreceivedBlocksByAddress(address!, pageIndex: 0, pageSize: 5);

      if (unreceived.count == 0) {
        print('Nothing to receive');
      } else {
        if (unreceived.more!) {
          print(
              'You have ${red("more")} than ${green(unreceived.count.toString())} transaction(s) to receive');
        } else {
          print(
              'You have ${green(unreceived.count.toString())} transaction(s) to receive');
        }
        print('Showing the first ${unreceived.list!.length}');
      }

      for (var block in unreceived.list!) {
        print(
            'Unreceived ${AmountUtils.addDecimals(block.amount, block.token!.decimals)} ${block.token!.symbol} from ${block.address.toString()}. Use the hash ${block.hash} to receive');
      }
      break;

    case 'unconfirmed':
      if (args.length != 1) {
        print('Incorrect number of arguments. Expected:');
        print('unconfirmed');
        break;
      }
      var unconfirmed = await znnClient.ledger
          .getUnconfirmedBlocksByAddress(address!, pageIndex: 0, pageSize: 5);

      if (unconfirmed.count == 0) {
        print('No unconfirmed transactions');
      } else {
        print(
            'You have ${green(unconfirmed.count.toString())} unconfirmed transaction(s)');
        print('Showing the first ${unconfirmed.list!.length}');
      }

      var encoder = JsonEncoder.withIndent("     ");
      for (var block in unconfirmed.list!) {
        print(encoder.convert(block.toJson()));
      }
      break;

    case 'balance':
      if (args.length != 1) {
        print('Incorrect number of arguments. Expected:');
        print('balance');
        break;
      }
      AccountInfo info =
          await znnClient.ledger.getAccountInfoByAddress(address!);
      print(
          'Balance for account-chain ${info.address!.toString()} having height ${info.blockCount}');
      if (info.balanceInfoList!.isEmpty) {
        print('  No coins or tokens at address ${address.toString()}');
      }
      for (BalanceInfoListItem entry in info.balanceInfoList!) {
        print(
            '  ${AmountUtils.addDecimals(entry.balance!, entry.token!.decimals)} ${entry.token!.symbol} '
            '${entry.token!.domain} ${entry.token!.tokenStandard.toString()}');
      }
      break;

    case 'frontierMomentum':
      if (args.length != 1) {
        print('Incorrect number of arguments. Expected:');
        print('frontierMomentum');
        break;
      }
      Momentum currentFrontierMomentum =
          await znnClient.ledger.getFrontierMomentum();
      print('Momentum height: ${currentFrontierMomentum.height.toString()}');
      print('Momentum hash: ${currentFrontierMomentum.hash.toString()}');
      print(
          'Momentum previousHash: ${currentFrontierMomentum.previousHash.toString()}');
      print(
          'Momentum timestamp: ${currentFrontierMomentum.timestamp.toString()}');
      break;

    case 'plasma.fuse':
      if (args.length != 3) {
        print('Incorrect number of arguments. Expected:');
        print('plasma.fuse toAddress amount (in ${blue('QSR')})');
        break;
      }
      Address beneficiary = Address.parse(args[1]);
      BigInt amount = AmountUtils.extractDecimals(
          num.parse(args[2] * oneQsr), coinDecimals);
      if (amount < fuseMinQsrAmount) {
        print(
            '${red('Invalid amount')}: ${AmountUtils.addDecimals(amount, coinDecimals)} ${blue('QSR')}. Minimum amount for fusing is ${AmountUtils.addDecimals(fuseMinQsrAmount, coinDecimals)}');
        break;
      } else if (amount % BigInt.from(oneQsr) != BigInt.zero) {
        print('${red('Error!')} Amount has to be integer');
         break;
      }
      print(
          'Fusing ${AmountUtils.addDecimals(amount, coinDecimals)} ${blue('QSR')} to ${args[1]}');
      await znnClient.send(znnClient.embedded.plasma.fuse(beneficiary, amount));
      print('Done');
      break;

    case 'plasma.get':
      if (args.length != 1) {
        print('Incorrect number of arguments. Expected:');
        print('plasma.get');
        break;
      }
      PlasmaInfo plasmaInfo = await znnClient.embedded.plasma.get(address!);
      print(
          '${green(address.toString())} has ${plasmaInfo.currentPlasma} / ${plasmaInfo.maxPlasma}'
          ' plasma with ${AmountUtils.addDecimals(plasmaInfo.qsrAmount, coinDecimals)} ${blue('QSR')} fused.');
      break;

    case 'plasma.list':
      if (!(args.length == 1 || args.length == 3)) {
        print('Incorrect number of arguments. Expected:');
        print('plasma.list [pageIndex pageSize]');
        break;
      }
      int pageIndex = 0;
      int pageSize = 25;
      if (args.length == 3) {
        pageIndex = int.parse(args[1]);
        pageSize = int.parse(args[2]);
      }
      FusionEntryList fusionEntryList = (await znnClient.embedded.plasma
          .getEntriesByAddress(address!,
              pageIndex: pageIndex, pageSize: pageSize));

      if (fusionEntryList.count > 0) {
        print(
            'Fusing ${AmountUtils.addDecimals(fusionEntryList.qsrAmount, coinDecimals)} ${blue('QSR')} for Plasma in ${fusionEntryList.count} entries');
      } else {
        print('No Plasma fusion entries found');
      }

      for (FusionEntry entry in fusionEntryList.list) {
        print(
            '  ${AmountUtils.addDecimals(entry.qsrAmount, coinDecimals)} ${blue('QSR')} for ${entry.beneficiary.toString()}');
        print(
            'Can be canceled at momentum height: ${entry.expirationHeight}. Use id ${entry.id} to cancel');
      }
      break;

    case 'plasma.cancel':
      if (args.length != 2) {
        print('Incorrect number of arguments. Expected:');
        print('plasma.cancel id');
        break;
      }
      Hash id = Hash.parse(args[1]);

      int pageIndex = 0;
      bool found = false;
      bool gotError = false;

      FusionEntryList fusions =
          await znnClient.embedded.plasma.getEntriesByAddress(address!);
      while (fusions.list.isNotEmpty) {
        var index = fusions.list.indexWhere((entry) => entry.id == id);
        if (index != -1) {
          found = true;
          if (fusions.list[index].expirationHeight >
              (await znnClient.ledger.getFrontierMomentum()).height) {
            print('${red('Error!')} Fuse entry can not be cancelled yet');
            gotError = true;
          }
          break;
        }
        pageIndex++;
        fusions = await znnClient.embedded.plasma
            .getEntriesByAddress(address, pageIndex: pageIndex);
      }

      if (!found) {
        print('${red('Error!')} Fuse entry was not found');
        break;
      }
      if (gotError) {
        break;
      }
      print('Canceling Plasma fuse entry with id ${args[1]}');
      await znnClient.send(znnClient.embedded.plasma.cancel(id));
      print('Done');
      break;

    case 'sentinel.list':
      if (args.length != 1) {
        print('Incorrect number of arguments. Expected:');
        print('sentinel.list');
        break;
      }
      SentinelInfoList sentinels =
          (await znnClient.embedded.sentinel.getAllActive());
      bool one = false;
      for (SentinelInfo entry in sentinels.list) {
        if (entry.owner.toString() == address!.toString()) {
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
        print('No Sentinel registered at address ${address!.toString()}');
      }
      break;

    case 'sentinel.register':
      if (args.length != 1) {
        print('Incorrect number of arguments. Expected:');
        print('sentinel.register');
        break;
      }
      AccountInfo accountInfo =
          await znnClient.ledger.getAccountInfoByAddress(address!);
      var depositedQsr =
          await znnClient.embedded.sentinel.getDepositedQsr(address);
      print('You have $depositedQsr ${blue('QSR')} deposited for the Sentinel');
      if (accountInfo.znn()! < sentinelRegisterZnnAmount ||
          accountInfo.qsr()! < sentinelRegisterQsrAmount) {
        print('Cannot register Sentinel with address ${address.toString()}');
        print(
            'Required ${AmountUtils.addDecimals(sentinelRegisterZnnAmount, coinDecimals)} ${green('ZNN')} and ${AmountUtils.addDecimals(sentinelRegisterQsrAmount, coinDecimals)} ${blue('QSR')}');
        print(
            'Available ${AmountUtils.addDecimals(accountInfo.znn()!, coinDecimals)} ${green('ZNN')} and ${AmountUtils.addDecimals(accountInfo.qsr()!, coinDecimals)} ${blue('QSR')}');
        break;
      }

      if (depositedQsr < sentinelRegisterQsrAmount) {
        await znnClient.send(znnClient.embedded.sentinel
            .depositQsr(sentinelRegisterQsrAmount - depositedQsr));
      }
      await znnClient.send(znnClient.embedded.sentinel.register());
      print('Done');
      print(
          'Check after 2 momentums if the Sentinel was successfully registered using ${green('sentinel.list')} command');
      break;

    case 'sentinel.revoke':
      if (args.length != 1) {
        print('Incorrect number of arguments. Expected:');
        print('sentinel.revoke');
        break;
      }
      SentinelInfo? entry = await znnClient.embedded.sentinel
          .getByOwner(address!)
          .catchError((e) {
        print("Error: ${e.toString()}");
        if (e.toString().contains('data non existent')) {
          return null;
        }
      });

      if (entry == null) {
        print('No Sentinel found for address ${address.toString()}');
        break;
      }

      if (entry.isRevocable == false) {
        print(
            'Cannot revoke Sentinel. Revocation window will open in ${formatDuration(entry.revokeCooldown)}');
        break;
      }

      await znnClient.send(znnClient.embedded.sentinel.revoke());
      print('Done');
      print(
          'Use ${green('receiveAll')} to collect back the locked amount of ${green('ZNN')} and ${blue('QSR')}');
      break;

    case 'sentinel.collect':
      if (args.length != 1) {
        print('Incorrect number of arguments. Expected:');
        print('sentinel.collect');
        break;
      }
      await znnClient.send(znnClient.embedded.sentinel.collectReward());
      print('Done');
      print(
          'Use ${green('receiveAll')} to collect your Sentinel reward(s) after 1 momentum');
      break;

    case 'sentinel.withdrawQsr':
      if (args.length != 1) {
        print('Incorrect number of arguments. Expected:');
        print('sentinel.withdrawQsr');
        break;
      }

      BigInt? depositedQsr =
          await znnClient.embedded.sentinel.getDepositedQsr(address!);
      if (depositedQsr == BigInt.zero) {
        print('No deposited ${blue('QSR')} to withdraw');
        break;
      }
      print(
          'Withdrawing ${AmountUtils.addDecimals(depositedQsr, coinDecimals)} ${blue('QSR')} ...');
      await znnClient.send(znnClient.embedded.sentinel.withdrawQsr());
      print('Done');
      break;

    case 'stake.list':
      if (!(args.length == 1 || args.length == 3)) {
        print('Incorrect number of arguments. Expected:');
        print(' stake.list [pageIndex pageSize]');
        break;
      }
      int pageIndex = 0;
      int pageSize = 25;
      if (args.length == 3) {
        pageIndex = int.parse(args[1]);
        pageSize = int.parse(args[2]);
      }
      final currentTime =
          (DateTime.now().millisecondsSinceEpoch / 1000).round();
      StakeList stakeList = await znnClient.embedded.stake.getEntriesByAddress(
          address!,
          pageIndex: pageIndex,
          pageSize: pageSize);

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
      break;

    case 'stake.register':
      if (args.length != 3) {
        print('Incorrect number of arguments. Expected:');
        print('stake.register amount duration (in months)');
        break;
      }
      BigInt amount = AmountUtils.extractDecimals(
          num.parse(args[1]) * oneZnn, coinDecimals);
      final duration = int.parse(args[2]);
      if (duration < 1 || duration > 12) {
        print(
            '${red('Invalid duration')}: ($duration) $stakeUnitDurationName. It must be between 1 and 12');
        break;
      }
      if (amount < stakeMinZnnAmount) {
        print(
            '${red('Invalid amount')}: ${AmountUtils.addDecimals(amount, coinDecimals)} ${green('ZNN')}. Minimum staking amount is ${AmountUtils.addDecimals(stakeMinZnnAmount, coinDecimals)}');
        break;
      }
      AccountInfo balance =
          await znnClient.ledger.getAccountInfoByAddress(address!);
      if (balance.znn()! < amount) {
        print(red('Not enough ZNN to stake'));
        break;
      }

      print(
          'Staking ${AmountUtils.addDecimals(amount, coinDecimals)} ${green('ZNN')} for $duration $stakeUnitDurationName(s)');
      await znnClient.send(
          znnClient.embedded.stake.stake(stakeTimeUnitSec * duration, amount));
      print('Done');
      break;

    case 'stake.revoke':
      if (args.length != 2) {
        print('Incorrect number of arguments. Expected:');
        print('stake.revoke id');
        break;
      }
      Hash hash = Hash.parse(args[1]);

      final currentTime =
          (DateTime.now().millisecondsSinceEpoch / 1000).round();
      int pageIndex = 0;
      bool one = false;
      bool gotError = false;

      StakeList entries = await znnClient.embedded.stake
          .getEntriesByAddress(address!, pageIndex: pageIndex);
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
        break;
      } else if (!one) {
        print(
            '${red('Error!')} No stake entry found with id ${hash.toString()}');
        break;
      }

      await znnClient.send(znnClient.embedded.stake.cancel(hash));
      print('Done');
      print(
          'Use ${green('receiveAll')} to collect your stake amount and uncollected reward(s) after 2 momentums');
      break;

    case 'stake.collect':
      if (args.length != 1) {
        print('Incorrect number of arguments. Expected:');
        print('stake.collect');
        break;
      }
      await znnClient.send(znnClient.embedded.stake.collectReward());
      print('Done');
      print(
          'Use ${green('receiveAll')} to collect your stake reward(s) after 1 momentum');
      break;

    case 'pillar.list':
      if (args.length != 1) {
        print('Incorrect number of arguments. Expected:');
        print('pillar.list');
        break;
      }
      PillarInfoList pillarList = (await znnClient.embedded.pillar.getAll());
      for (PillarInfo pillar in pillarList.list) {
        print(
            '#${pillar.rank + 1} Pillar ${green(pillar.name)} has a delegated weight of ${AmountUtils.addDecimals(pillar.weight, coinDecimals)} ${green('ZNN')}');
        print('    Producer address ${pillar.producerAddress}');
        print(
            '    Momentums ${pillar.currentStats.producedMomentums} / expected ${pillar.currentStats.expectedMomentums}');
      }
      break;

    case 'pillar.register':
      if (args.length != 6) {
        print('Incorrect number of arguments. Expected:');
        print(
            'pillar.register name producerAddress rewardAddress giveBlockRewardPercentage giveDelegateRewardPercentage');
        break;
      }

      int giveBlockRewardPercentage = int.parse(args[4]);
      int giveDelegateRewardPercentage = int.parse(args[5]);

      AccountInfo balance =
          await znnClient.ledger.getAccountInfoByAddress(address!);
      BigInt? qsrAmount =
          (await znnClient.embedded.pillar.getQsrRegistrationCost());
      BigInt? depositedQsr =
          await znnClient.embedded.pillar.getDepositedQsr(address);
      if ((balance.znn()! < pillarRegisterZnnAmount ||
              balance.qsr()! < qsrAmount) &&
          qsrAmount > depositedQsr) {
        print('Cannot register Pillar with address ${address.toString()}');
        print(
            'Required ${AmountUtils.addDecimals(pillarRegisterZnnAmount, coinDecimals)} ${green('ZNN')} and ${AmountUtils.addDecimals(qsrAmount, coinDecimals)} ${blue('QSR')}');
        print(
            'Available ${AmountUtils.addDecimals(balance.znn()!, coinDecimals)} ${green('ZNN')} and ${AmountUtils.addDecimals(balance.qsr()!, coinDecimals)} ${blue('QSR')}');
        break;
      }

      print(
          'Creating a new ${green('Pillar')} will burn the deposited ${blue('QSR')} required for the Pillar slot');
      if (!confirm('Do you want to proceed?', defaultValue: false)) break;

      String newName = args[1];
      bool ok =
          (await znnClient.embedded.pillar.checkNameAvailability(newName));
      while (!ok) {
        newName = ask(
            'This Pillar name is already reserved. Please choose another name for the Pillar');
        ok = (await znnClient.embedded.pillar.checkNameAvailability(newName));
      }
      if (depositedQsr < qsrAmount) {
        print(
            'Depositing ${AmountUtils.addDecimals(qsrAmount - depositedQsr, coinDecimals)} ${blue('QSR')} for the Pillar registration');
        await znnClient.send(
            znnClient.embedded.pillar.depositQsr(qsrAmount - depositedQsr));
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
      break;

    case 'pillar.collect':
      if (args.length != 1) {
        print('Incorrect number of arguments. Expected:');
        print('pillar.collect');
        break;
      }
      await znnClient.send(znnClient.embedded.pillar.collectReward());
      print('Done');
      print(
          'Use ${green('receiveAll')} to collect your Pillar reward(s) after 1 momentum');
      break;

    case 'pillar.revoke':
      if (args.length != 2) {
        print('Incorrect number of arguments. Expected:');
        print('pillar.revoke name');
        break;
      }
      PillarInfoList pillarList = (await znnClient.embedded.pillar.getAll());
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
      break;

    case 'pillar.delegate':
      if (args.length != 2) {
        print('Incorrect number of arguments. Expected:');
        print('pillar.delegate name');
        break;
      }
      print('Delegating to Pillar ${args[1]} ...');
      await znnClient.send(znnClient.embedded.pillar.delegate(args[1]));
      print('Done');
      break;

    case 'pillar.undelegate':
      if (args.length != 1) {
        print('Incorrect number of arguments. Expected:');
        print('pillar.undelegate');
        break;
      }

      print('Undelegating ...');
      await znnClient.send(znnClient.embedded.pillar.undelegate());
      print('Done');
      break;

    case 'pillar.withdrawQsr':
      if (args.length != 1) {
        print('Incorrect number of arguments. Expected:');
        print('pillar.withdrawQsr');
        break;
      }
      BigInt? depositedQsr =
          await znnClient.embedded.pillar.getDepositedQsr(address!);
      if (depositedQsr == BigInt.zero) {
        print('No deposited ${blue('QSR')} to withdraw');
        break;
      }
      print(
          'Withdrawing ${AmountUtils.addDecimals(depositedQsr, coinDecimals)} ${blue('QSR')} ...');
      await znnClient.send(znnClient.embedded.pillar.withdrawQsr());
      print('Done');
      break;

    case 'token.list':
      if (!(args.length == 1 || args.length == 3)) {
        print('Incorrect number of arguments. Expected:');
        print('token.list [pageIndex pageSize]');
        break;
      }
      int pageIndex = 0;
      int pageSize = 25;
      if (args.length == 3) {
        pageIndex = int.parse(args[1]);
        pageSize = int.parse(args[2]);
      }
      TokenList tokenList = await znnClient.embedded.token
          .getAll(pageIndex: pageIndex, pageSize: pageSize);
      for (Token token in tokenList.list!) {
        if (token.tokenStandard == znnZts || token.tokenStandard == qsrZts) {
          print(
              '${token.tokenStandard == znnZts ? green(token.name) : blue(token.name)} with symbol ${token.tokenStandard == znnZts ? green(token.symbol) : blue(token.symbol)} and standard ${token.tokenStandard == znnZts ? green(token.tokenStandard.toString()) : blue(token.tokenStandard.toString())}');
          print(
              '   Created by ${token.tokenStandard == znnZts ? green(token.owner.toString()) : blue(token.owner.toString())}');
          print(
              '   ${token.tokenStandard == znnZts ? green(token.name) : blue(token.name)} has ${token.decimals} decimals, ${token.isMintable ? 'is mintable' : 'is not mintable'}, ${token.isBurnable ? 'can be burned' : 'cannot be burned'}, and ${token.isUtility ? 'is a utility coin' : 'is not a utility coin'}');
          print(
              '   The total supply is ${AmountUtils.addDecimals(token.totalSupply, token.decimals)} and the maximum supply is ${AmountUtils.addDecimals(token.maxSupply, token.decimals)}');
        } else {
          print(
              'Token ${token.name} with symbol ${token.symbol} and standard ${magenta(token.tokenStandard.toString())}');
          print('   Issued by ${token.owner.toString()}');
          print(
              '   ${token.name} has ${token.decimals} decimals, ${token.isMintable ? 'can be minted' : 'cannot be minted'}, ${token.isBurnable ? 'can be burned' : 'cannot be burned'}, and ${token.isUtility ? 'is a utility token' : 'is not a utility token'}');
        }
        print('   Domain `${token.domain}`');
      }
      break;

    case 'token.getByStandard':
      if (args.length != 2) {
        print('Incorrect number of arguments. Expected:');
        print('token.getByStandard tokenStandard');
        break;
      }
      TokenStandard tokenStandard = TokenStandard.parse(args[1]);
      Token token = (await znnClient.embedded.token.getByZts(tokenStandard))!;
      String type = 'Token';
      if (token.tokenStandard.toString() == qsrTokenStandard ||
          token.tokenStandard.toString() == znnTokenStandard) {
        type = 'Coin';
      }
      print(
          '$type ${token.name} with symbol ${token.symbol} and standard ${token.tokenStandard.toString()}');
      print('   Created by ${green(token.owner.toString())}');
      print(
          '   The total supply is ${AmountUtils.addDecimals(token.totalSupply, token.decimals)} and a maximum supply is ${AmountUtils.addDecimals(token.maxSupply, token.decimals)}');
      print(
          '   The token has ${token.decimals} decimals ${token.isMintable ? 'can be minted' : 'cannot be minted'} and ${token.isBurnable ? 'can be burned' : 'cannot be burned'}');
      break;

    case 'token.getByOwner':
      if (args.length != 2) {
        print('Incorrect number of arguments. Expected:');
        print('token.getByOwner ownerAddress');
        break;
      }
      String type = 'Token';
      Address ownerAddress = Address.parse(args[1]);
      TokenList tokens =
          await znnClient.embedded.token.getByOwner(ownerAddress);
      for (Token token in tokens.list!) {
        type = 'Token';
        if (token.tokenStandard.toString() == znnTokenStandard ||
            token.tokenStandard.toString() == qsrTokenStandard) {
          type = 'Coin';
        }
        print(
            '$type ${token.name} with symbol ${token.symbol} and standard ${token.tokenStandard.toString()}');
        print('   Created by ${green(token.owner.toString())}');
        print(
            '   The total supply is ${AmountUtils.addDecimals(token.totalSupply, token.decimals)} and a maximum supply is ${AmountUtils.addDecimals(token.maxSupply, token.decimals)}');
        print(
            '   The token ${token.decimals} decimals ${token.isMintable ? 'can be minted' : 'cannot be minted'} and ${token.isBurnable ? 'can be burned' : 'cannot be burned'}');
      }
      break;

    case 'token.issue':
      if (args.length != 10) {
        print('Incorrect number of arguments. Expected:');
        print(
            'token.issue name symbol domain totalSupply maxSupply decimals isMintable isBurnable isUtility');
        break;
      }

      RegExp regExpName = RegExp(r'^([a-zA-Z0-9]+[-._]?)*[a-zA-Z0-9]$');
      if (!regExpName.hasMatch(args[1])) {
        print('${red("Error!")} The ZTS name contains invalid characters');
        break;
      }

      RegExp regExpSymbol = RegExp(r'^[A-Z0-9]+$');
      if (!regExpSymbol.hasMatch(args[2])) {
        print('${red("Error!")} The ZTS symbol must be all uppercase');
        break;
      }

      RegExp regExpDomain = RegExp(
          r'^([A-Za-z0-9][A-Za-z0-9-]{0,61}[A-Za-z0-9]\.)+[A-Za-z]{2,}$');
      if (args[3].isEmpty || !regExpDomain.hasMatch(args[3])) {
        print('${red("Error!")} Invalid domain');
        print('Examples of ${green('valid')} domain names:');
        print('    zenon.network');
        print('    www.zenon.network');
        print('    quasar.zenon.network');
        print('    zenon.community');
        print('Examples of ${red('invalid')} domain names:');
        print('    zenon.network/index.html');
        print('    www.zenon.network/quasar');
        break;
      }

      if (args[1].isEmpty || args[1].length > 40) {
        print(
            '${red("Error!")} Invalid ZTS name length (min 1, max 40, current ${args[1].length})');
        break;
      }

      if (args[2].isEmpty || args[2].length > 10) {
        print(
            '${red("Error!")} Invalid ZTS symbol length (min 1, max 10, current ${args[2].length})');
        break;
      }

      if (args[3].length > 128) {
        print(
            '${red("Error!")} Invalid ZTS domain length (min 0, max 128, current ${args[3].length})');
        break;
      }

      bool mintable;
      if (args[7] == '0' || args[7] == 'false') {
        mintable = false;
      } else if (args[7] == '1' || args[7] == 'true') {
        mintable = true;
      } else {
        print(
            '${red("Error!")} Mintable flag variable of type "bool" should be provided as either "true", "false", "1" or "0"');
        break;
      }

      bool burnable;
      if (args[8] == '0' || args[8] == 'false') {
        burnable = false;
      } else if (args[8] == '1' || args[8] == 'true') {
        burnable = true;
      } else {
        print(
            '${red("Error!")} Burnable flag variable of type "bool" should be provided as either "true", "false", "1" or "0"');
        break;
      }

      bool utility;
      if (args[9] == '0' || args[9] == 'false') {
        utility = false;
      } else if (args[9] == '1' || args[9] == 'true') {
        utility = true;
      } else {
        print(
            '${red("Error!")} Utility flag variable of type "bool" should be provided as either "true", "false", "1" or "0"');
        break;
      }

      BigInt totalSupply =
          AmountUtils.extractDecimals(num.parse(args[4]), coinDecimals);
      BigInt maxSupply =
          AmountUtils.extractDecimals(num.parse(args[5]), coinDecimals);
      int decimals = int.parse(args[6]);

      if (mintable == true) {
        if (maxSupply < totalSupply) {
          print(
              '${red("Error!")} Max supply must to be larger than the total supply');
          break;
        }
        if (maxSupply > kBigP255m1) {
          print('${red("Error!")} Max supply must to be less than $kBigP255m1');
          break;
        }
      } else {
        if (maxSupply != totalSupply) {
          print(
              '${red("Error!")} Max supply must be equal to totalSupply for non-mintable tokens');
          break;
        }
        if (totalSupply == BigInt.zero) {
          print(
              '${red("Error!")} Total supply cannot be "0" for non-mintable tokens');
          break;
        }
      }

      print('Issuing a new ${green('ZTS token')} will burn 1 ZNN');
      if (!confirm('Do you want to proceed?', defaultValue: false)) break;

      print('Issuing ${args[1]} ZTS token ...');
      await znnClient.send(znnClient.embedded.token.issueToken(
          args[1],
          args[2],
          args[3],
          totalSupply,
          maxSupply,
          decimals,
          mintable,
          burnable,
          utility));
      print('Done');
      break;

    case 'token.mint':
      if (args.length != 4) {
        print('Incorrect number of arguments. Expected:');
        print('token.mint tokenStandard amount receiveAddress');
        break;
      }
      TokenStandard tokenStandard = TokenStandard.parse(args[1]);
      BigInt amount =
          AmountUtils.extractDecimals(num.parse(args[2]), coinDecimals);
      Address mintAddress = Address.parse(args[3]);

      Token? token = await znnClient.embedded.token.getByZts(tokenStandard);
      if (token == null) {
        print('${red("Error!")} The token does not exist');
        break;
      } else if (token.isMintable == false) {
        print('${red("Error!")} The token is not mintable');
        break;
      }

      print('Minting ZTS token ...');
      await znnClient.send(znnClient.embedded.token
          .mintToken(tokenStandard, amount, mintAddress));
      print('Done');
      break;

    case 'token.burn':
      if (args.length != 3) {
        print('Incorrect number of arguments. Expected:');
        print('token.burn tokenStandard amount');
        break;
      }
      TokenStandard tokenStandard = TokenStandard.parse(args[1]);
      BigInt amount =
          AmountUtils.extractDecimals(num.parse(args[2]), coinDecimals);
      AccountInfo info =
          await znnClient.ledger.getAccountInfoByAddress(address!);
      bool ok = true;
      for (BalanceInfoListItem entry in info.balanceInfoList!) {
        if (entry.token!.tokenStandard.toString() == tokenStandard.toString() &&
            entry.balance! < amount) {
          print(
              '${red("Error!")} You only have ${AmountUtils.addDecimals(entry.balance!, entry.token!.decimals)} ${entry.token!.symbol} tokens');
          ok = false;
          break;
        }
      }
      if (!ok) break;
      print('Burning ${args[1]} ZTS token ...');
      await znnClient
          .send(znnClient.embedded.token.burnToken(tokenStandard, amount));
      print('Done');
      break;

    case 'token.transferOwnership':
      if (args.length != 3) {
        print('Incorrect number of arguments. Expected:');
        print('token.transferOwnership tokenStandard newOwnerAddress');
        break;
      }
      print('Transferring ZTS token ownership ...');
      TokenStandard tokenStandard = TokenStandard.parse(args[1]);
      Address newOwnerAddress = Address.parse(args[2]);
      var token = (await znnClient.embedded.token.getByZts(tokenStandard))!;
      if (token.owner.toString() != address!.toString()) {
        print('${red('Error!')} Not owner of token ${args[1]}');
        break;
      }
      await znnClient.send(znnClient.embedded.token.updateToken(
          tokenStandard, newOwnerAddress, token.isMintable, token.isBurnable));
      print('Done');
      break;

    case 'token.disableMint':
      if (args.length != 2) {
        print('Incorrect number of arguments. Expected:');
        print('token.disableMint tokenStandard');
        break;
      }
      print('Disabling ZTS token mintable flag ...');
      TokenStandard tokenStandard = TokenStandard.parse(args[1]);
      var token = (await znnClient.embedded.token.getByZts(tokenStandard))!;
      if (token.owner.toString() != address!.toString()) {
        print('${red('Error!')} Not owner of token ${args[1]}');
        break;
      }
      await znnClient.send(znnClient.embedded.token
          .updateToken(tokenStandard, token.owner, false, token.isBurnable));
      print('Done');
      break;

    case 'wallet.createNew':
      if (!(args.length == 2 || args.length == 3)) {
        print('Incorrect number of arguments. Expected:');
        print('wallet.createNew passphrase [keyStoreName]');
        break;
      }

      String? name;
      if (args.length == 3) name = args[2];

      File keyStore = await znnClient.keyStoreManager.createNew(args[1], name);
      print(
          'keyStore ${green('successfully')} created: ${path.basename(keyStore.path)}');
      break;

    case 'wallet.createFromMnemonic':
      if (!(args.length == 3 || args.length == 4)) {
        print('Incorrect number of arguments. Expected:');
        print(
            'wallet.createFromMnemonic "${green('mnemonic')}" passphrase [keyStoreName]');
        break;
      }
      if (!bip39.validateMnemonic(args[1])) {
        throw AskValidatorException(red('Invalid mnemonic'));
      }

      String? name;
      if (args.length == 4) name = args[3];
      File keyStore = await znnClient.keyStoreManager
          .createFromMnemonic(args[1], args[2], name);
      print(
          'keyStore ${green('successfully')} created from mnemonic: ${path.basename(keyStore.path)}');
      break;

    case 'wallet.dumpMnemonic':
      if (args.length != 1) {
        print('Incorrect number of arguments. Expected:');
        print('wallet.dumpMnemonic');
        break;
      }

      print('Mnemonic for keyStore ${znnClient.defaultKeyStorePath!}');
      print(znnClient.defaultKeyStore!.mnemonic);
      break;

    case 'wallet.export':
      if (args.length != 2) {
        print('Incorrect number of arguments. Expected:');
        print('wallet.export filePath');
        break;
      }

      await znnClient.defaultKeyStorePath!.copy(args[1]);
      print('Done! Check the current directory');
      break;

    case 'wallet.list':
      if (args.length != 1) {
        print('Incorrect number of arguments. Expected:');
        print('wallet.list');
        break;
      }
      List<File> stores = await znnClient.keyStoreManager.listAllKeyStores();
      if (stores.isNotEmpty) {
        print('Available keyStores:');
        for (File store in stores) {
          print(path.basename(store.path));
        }
      } else {
        print('No keyStores found');
      }
      break;

    case 'wallet.deriveAddresses':
      if (args.length != 3) {
        print('Incorrect number of arguments. Expected:');
        print('wallet.deriveAddresses');
        break;
      }

      print('Addresses for keyStore ${znnClient.defaultKeyStorePath!}');
      int left = int.parse(args[1]);
      int right = int.parse(args[2]);
      List<Address?> addresses =
          await znnClient.defaultKeyStore!.deriveAddressesByRange(left, right);
      for (int i = 0; i < right - left; i += 1) {
        print('  ${i + left}\t${addresses[i].toString()}');
      }
      break;

    default:
      print('${red('Error!')} Unrecognized command ${red(args[0])}');
      help();
      break;
  }
  return;
}
