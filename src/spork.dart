import 'package:dcli/dcli.dart' hide verbose;
import 'package:znn_sdk_dart/znn_sdk_dart.dart';
import 'src.dart';

void sporkMenu() {
  print('  ${white('Spork')}');
  print('    spork.list');
  print('    spork.create name description');
  print('    spork.activate id');
}

Future<void> sporkFunctions() async {
  switch (args[0].split('.')[1]) {
    case 'list':
      verbose ? print('Description: List all sporks') : null;
      await _list();
      return;

    case 'create':
      verbose ? print('Description: Create a new spork') : null;
      await _create();
      return;

    case 'activate':
      verbose ? print('Description: Activate a spork') : null;
      await _activate();
      return;

    default:
      invalidCommand();
  }
}

Future<void> _list() async {
  if (!(args.length == 1 || args.length == 3)) {
    print('Incorrect number of arguments. Expected:');
    print('spork.list [pageIndex pageSize]');
    return;
  }
  int pageIndex = 0;
  int pageSize = rpcMaxPageSize;
  if (args.length == 3) {
    pageIndex = int.parse(args[1]);
    pageSize = int.parse(args[2]);
  }

  SporkList sporks = await znnClient.embedded.spork
      .getAll(pageIndex: pageIndex, pageSize: pageSize);
  if (sporks.list.isNotEmpty) {
    print('Sporks:');
    for (Spork spork in sporks.list) {
      print('Name: ${spork.name}');
      print('  Description: ${spork.description}');
      print('  Activated: ${spork.activated}');
      if (spork.activated) {
        print('  EnforcementHeight: ${spork.enforcementHeight}');
      }
      print('  Hash: ${spork.id}');
    }
  } else {
    print('No sporks found');
  }
}

Future<void> _create() async {
  if (args.length != 3) {
    print('Incorrect number of arguments. Expected:');
    print('spork.create name description');
    return;
  }

  String name = args[1];
  String description = args[2];

  if (name.length < sporkNameMinLength || name.length > sporkNameMaxLength) {
    print(
        '${red('Error!')} Spork name must be $sporkNameMinLength to $sporkNameMaxLength characters in length');
    return;
  }
  if (description.isEmpty) {
    print('${red('Error!')} Spork description cannot be empty');
    return;
  }
  if (description.length > sporkDescriptionMaxLength) {
    print(
        '${red('Error!')} Spork description cannot exceed $sporkDescriptionMaxLength characters in length');
    return;
  }

  print('Creating spork...');
  await znnClient.send(znnClient.embedded.spork.createSpork(name, description));
  print('Done');
}

Future<void> _activate() async {
  if (args.length != 2) {
    print('Incorrect number of arguments. Expected:');
    print('spork.activate id');
    return;
  }

  Hash id = Hash.parse(args[1]);
  print('Activating spork...');
  await znnClient.send(znnClient.embedded.spork.activateSpork(id));
  print('Done');
}
