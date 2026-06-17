import 'package:args/args.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:talker/talker.dart';

import 'log.dart';

part 'cli_args.freezed.dart';

const hostDefault = '127.0.0.1';
const portDefault = 50051;
final portDefaultStr = portDefault.toString();

/// Parsed command-line arguments.
@freezed
abstract class CliConfig with _$CliConfig {
  const factory CliConfig({
    /// Enable Talker logging framework.
    @Default(false) bool enableTalker,

    /// gRPC log server host; null disables gRPC push.
    @Default(hostDefault) String grpcHost,

    /// gRPC log server port.
    @Default(portDefault) int grpcPort,

    /// Log level
    @Default(LogLevel.info) LogLevel logLevel,

    /// auto connect at startup
    @Default(false) bool autoConnect,

    /// show console output when connected
    @Default(false) bool showConsoleOutput,
  }) = _CliConfig;
}

class _CmdArgs {
  static const talker = 'talker';
  static const talkerGprcHost = 'talker-grpc-host';
  static const talkerGprcPort = 'talker-grpc-port';
  static const talkerGprcAutoConnect = 'talker-grpc-auto-connect';
  static const talkerGprcShowConsoleOutput = 'talker-grpc--hide-console-output';
  static const logLevel = 'log-level';
}

final _parser = ArgParser()
  ..addFlag(
    _CmdArgs.talker,
    abbr: 't',
    help: 'Enable Talker logging',
  )
  ..addOption(
    _CmdArgs.talkerGprcHost,
    abbr: 'h',
    help: 'gRPC log server host',
    valueHelp: 'HOST',
    defaultsTo: hostDefault,
  )
  ..addOption(
    _CmdArgs.talkerGprcPort,
    abbr: 'p',
    help: 'gRPC log server port',
    valueHelp: 'PORT',
    defaultsTo: portDefaultStr,
  )
  ..addFlag(
    _CmdArgs.talkerGprcAutoConnect,
    abbr: 'a',
    help: 'gRPC log server auto connect',
  )
  ..addFlag(
    _CmdArgs.talkerGprcShowConsoleOutput,
    abbr: 's',
    help: 'show console output when gRPC log server is connected',
  )
  ..addOption(
    _CmdArgs.logLevel,
    defaultsTo: LogLevel.info.name,
    allowed: logLevelNameMap.keys,
    help: 'Log level (${logLevelNameMap.keys.join('/')})',
  )
  ..addFlag('help', abbr: 'h', help: 'Show this help');

/// Print CLI usage.
void printCliHelp() {
  printToConsole('''
Usage: exptlorer [Options]

Options:
${_parser.usage}

Examples:
  exptlorer                                   # Default Launch
  exptlorer --talker                          # Enable Talker Logger
  exptlorer --talker --talker-grpc-host=127.0.0.1 --talker-grpc-port=50051
''');
}

/// Riverpod provider, overridden in main() with parsed CLI args.
final cliConfigProvider = Provider<CliConfig>((ref) => const CliConfig());

CliConfig parseCliArgs(List<String> args) {
  final results = _parser.parse(args);

  if (results['help'] as bool) {
    printCliHelp();
  }

  final grpcHost = results[_CmdArgs.talkerGprcHost] as String;
  final grpcPort = int.tryParse(results[_CmdArgs.talkerGprcPort] as String) ?? portDefault;
  final grpcAutoConnect = results[_CmdArgs.talkerGprcAutoConnect] as bool;
  final grpcShowConsole = results[_CmdArgs.talkerGprcShowConsoleOutput] as bool;

  final logLevel = results['log-level'] as String;
  return CliConfig(
    enableTalker: results['talker'] as bool,
    grpcHost: grpcHost,
    grpcPort: grpcPort,
    logLevel: logLevelNameMap[logLevel] ?? LogLevel.info,
    autoConnect: grpcAutoConnect,
    showConsoleOutput: grpcShowConsole,
  );
}
