import 'package:dcli/dcli.dart' hide verbose;
import 'package:znn_sdk_dart/znn_sdk_dart.dart';
import 'src.dart';

void acceleratorMenu() {
  print('  ${white('Accelerator Z')}');
  print('    az.donate amount ${green('ZNN')}/${blue('QSR')}');
}

Future<void> acceleratorFunctions() async {
  switch (args[0].split('.')[1]) {
    case 'donate':
      verbose
          ? print('Description: Donate ZNN and QSR as fuel for the Mothership')
          : null;
      await _donate();
      return;

    default:
      invalidCommand();
  }
}

Future<void> _donate() async {
  if (args.length != 3) {
    print('Incorrect number of arguments. Expected:');
    print('az.donate amount tokenStandard');
    return;
  }

  TokenStandard tokenStandard = getTokenStandard(args[2]);
  if (tokenStandard != znnZts || tokenStandard != qsrZts) {
    print(
        '${red('Error!')} You can only send ${green('ZNN')} or ${blue('QSR')}.');
    return;
  }

  Token token = (await znnClient.embedded.token.getByZts(tokenStandard))!;
  BigInt amount =
      AmountUtils.extractDecimals(num.parse(args[1]), token.decimals);
  if (amount == BigInt.zero) {
    print('${red('Error!')} You cannot send that amount.');
    return;
  }

  if (!await hasBalance(znnClient, address, tokenStandard, amount)) {
    return;
  }

  print(
      'Donating ${AmountUtils.addDecimals(amount, token.decimals)} ${token.symbol} to Accelerator Z ...');
  await znnClient
      .send(znnClient.embedded.accelerator.donate(amount, tokenStandard));

  print('Done');
}
