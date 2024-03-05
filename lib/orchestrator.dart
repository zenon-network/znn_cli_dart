import 'package:dcli/dcli.dart' hide verbose;

void orchestratorMenu() {
  print('  ${white('Orchestrator')}');
  print('    orchestrator.changePubKey');
  print('    orchestrator.haltBridge');
  print('    orchestrator.updateWrapRequest');
  print('    orchestrator.unwrapToken');
}

Future<void> orchestatorFunctions() async {
  print('Orchestrator-only functions are currently unsupported');
  return;
}
