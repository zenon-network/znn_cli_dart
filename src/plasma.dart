import 'package:dcli/dcli.dart' hide verbose;
import 'package:znn_sdk_dart/znn_sdk_dart.dart';
import 'src.dart';

void plasmaMenu() {
  print('  ${white('Plasma')}');
  print('    plasma.list [pageIndex pageCount]');
  print('    plasma.get address');
  print('    plasma.fuse toAddress amount (in ${blue('QSR')})');
  print('    plasma.cancel id');
}

Future<void> plasmaFunctions() async {
  switch (args[0].split('.')[1]) {
    case 'list':
      verbose ? print('Description: List plasma fusion entries') : null;
      await _list();
      break;

    case 'get':
      verbose
          ? print(
              'Description: Display the amount of plasma and QSR fused for an address')
          : null;
      await _get();
      break;

    case 'fuse':
      verbose
          ? print('Description: Fuse QSR to an address to generate plasma')
          : null;
      await _fuse();
      break;

    case 'cancel':
      verbose
          ? print(
              'Description: Cancel a plasma fusion and receive the QSR back')
          : null;
      await _cancel();
      break;

    default:
      invalidCommand();
  }
}

Future<void> _list() async {
  if (!(args.length == 1 || args.length == 3)) {
    print('Incorrect number of arguments. Expected:');
    print('plasma.list [pageIndex pageSize]');
    return;
  }
  int pageIndex = 0;
  int pageSize = 25;
  if (args.length == 3) {
    pageIndex = int.parse(args[1]);
    pageSize = int.parse(args[2]);
  }
  FusionEntryList fusionEntryList = await znnClient.embedded.plasma
      .getEntriesByAddress(address, pageIndex: pageIndex, pageSize: pageSize);

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
}

Future<void> _get() async {
  if (args.length != 2) {
    print('Incorrect number of arguments. Expected:');
    print('plasma.get address');
    return;
  }
  Address address = Address.parse(args[1]);
  PlasmaInfo plasmaInfo = await znnClient.embedded.plasma.get(address);
  print(
      '${green(address.toString())} has ${plasmaInfo.currentPlasma} / ${plasmaInfo.maxPlasma}'
      ' plasma with ${AmountUtils.addDecimals(plasmaInfo.qsrAmount, coinDecimals)} ${blue('QSR')} fused.');
}

Future<void> _fuse() async {
  if (args.length != 3) {
    print('Incorrect number of arguments. Expected:');
    print('plasma.fuse toAddress amount (in ${blue('QSR')})');
    return;
  }
  Address beneficiary = Address.parse(args[1]);
  BigInt amount = AmountUtils.extractDecimals(num.parse(args[2]), coinDecimals);

  if (amount < fuseMinQsrAmount) {
    print(
        '${red('Invalid amount')}: ${AmountUtils.addDecimals(amount, coinDecimals)} ${blue('QSR')}. Minimum staking amount is ${AmountUtils.addDecimals(fuseMinQsrAmount, coinDecimals)}');
    return;
  } else if (amount % BigInt.from(oneQsr) != BigInt.zero) {
    print('${red('Error!')} Amount has to be integer');
    return;
  }
  print(
      'Fusing ${AmountUtils.addDecimals(amount, coinDecimals)} ${blue('QSR')} to ${args[1]}');
  await znnClient.send(znnClient.embedded.plasma.fuse(beneficiary, amount));
  print('Done');
}

Future<void> _cancel() async {
  if (args.length != 2) {
    print('Incorrect number of arguments. Expected:');
    print('plasma.cancel id');
    return;
  }
  Hash id = Hash.parse(args[1]);

  int pageIndex = 0;
  bool found = false;
  bool gotError = false;

  FusionEntryList fusions =
      await znnClient.embedded.plasma.getEntriesByAddress(address);
  while (fusions.list.isNotEmpty) {
    var index = fusions.list.indexWhere((entry) => entry.id == id);
    if (index != -1) {
      found = true;
      if (fusions.list[index].expirationHeight >
          (await znnClient.ledger.getFrontierMomentum()).height) {
        print('${red('Error!')} Fuse entry can not be cancelled yet');
        gotError = true;
      }
      return;
    }
    pageIndex++;
    fusions = await znnClient.embedded.plasma
        .getEntriesByAddress(address, pageIndex: pageIndex);
  }

  if (!found) {
    print('${red('Error!')} Fuse entry was not found');
    return;
  }
  if (gotError) {
    return;
  }
  print('Canceling Plasma fuse entry with id ${args[1]}');
  await znnClient.send(znnClient.embedded.plasma.cancel(id));
  print('Done');
}
