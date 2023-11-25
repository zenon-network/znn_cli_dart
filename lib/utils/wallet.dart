import 'package:args/args.dart';
import 'package:dcli/dcli.dart';
import 'package:znn_cli_dart/lib.dart';
import 'package:znn_ledger_dart/znn_ledger_dart.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

Future<Iterable<WalletDefinition>> getWalletDefinitions() async {
  List<Future<Iterable<WalletDefinition>>> futures =
      walletManagers.map((manager) => manager.getWalletDefinitions()).toList();

  List<Iterable<WalletDefinition>> listOfDefinitions =
      await Future.wait(futures);

  // Combine all the iterables into a single list using fold or expand
  // For example, using fold:
  List<WalletDefinition> combinedList =
      listOfDefinitions.fold<List<WalletDefinition>>(
    <WalletDefinition>[],
    (previousList, element) => previousList..addAll(element),
  );

  return combinedList;
}

Future<void> unlockWallet(ArgResults argResult) async {
  var walletDefinitions = await getWalletDefinitions();

  if (walletDefinitions.isEmpty) {
    // Make sure at least one wallet exists
    print('${red('Error!')} No wallets founds');
    return;
  } else if (argResult['keyStore'] != null) {
    String? walletName;

    if (argResult['keyStore'] == "nanos" ||
        argResult['keyStore'] == "nanosp" ||
        argResult['keyStore'] == "nanox" ||
        argResult['keyStore'] == "stax") {
      walletName = (argResult['keyStore'].substring(0, 4) +
              ' ' +
              argResult['keyStore'].substring(4))
          .trim();
    } else {
      walletName = argResult['keyStore'];
    }

    if (!walletDefinitions
        .any((x) => x.walletName.toLowerCase() == walletName!.toLowerCase())) {
      print(
          '${red('Error!')} The wallet ${argResult['keyStore']} does not exist');
      return;
    }

    // Use user provided wallet: make sure it exists
    walletDefinition = walletDefinitions.firstWhere(
        (x) => x.walletName.toLowerCase() == walletName!.toLowerCase());
  } else if (walletDefinitions.length == 1) {
    // In case there is just one wallet, use it by default
    print(
        'Using the default wallet ${green(walletDefinitions.first.walletName)}');
    walletDefinition = walletDefinitions.first;
  } else {
    // Multiple wallets present, but none is selected: action required
    print('${red('Error!')} Please provide a wallet name. '
        'Use ${green('wallet.list')} to list all available wallets');
    return;
  }

  WalletOptions? walletOptions;
  if (walletDefinition is KeyStoreDefinition) {
    String? passphrase;
    if (argResult.wasParsed('passphrase')) {
      passphrase = argResult['passphrase'];
    } else {
      passphrase = enterPassphrase();
    }
    walletOptions = KeyStoreOptions(passphrase!);
  }

  int index = 0;
  if (argResult.wasParsed('index')) {
    index = int.parse(argResult['index']);
  }
  
  try {
    for (var walletManager in walletManagers) {
      if (await walletManager.supportsWallet(walletDefinition)) {
        znnClient.defaultKeyStorePath = walletDefinition;
        znnClient.keyStoreManager = walletManager;
        znnClient.defaultKeyStore = await znnClient.keyStoreManager
            .getWallet(walletDefinition, walletOptions);
        znnClient.defaultKeyPair =
            await znnClient.defaultKeyStore!.getAccount(index);
        address = (await znnClient.defaultKeyPair!.getAddress());
        logger.info('Using address ${green(address.toString())}');
        break;
      }
    }
  } on IncorrectPasswordException {
    print(
        '${red('Error!')} Invalid passphrase for wallet ${walletDefinition.walletName}');
  } on LedgerError catch (e) {
    print(
        '${red('Error!')} Unable to access Ledger wallet ${walletDefinition.walletName} $e');
  }
}
