import 'package:args/args.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:talker/talker.dart';

import 'log.dart';

/// Parse [LogLevel] from CLI string argument.
LogLevel? logLevelFromString(String? s) => logLevelNameMap[s];

String logLevelToString(LogLevel level) => level.name;

/// Parsed command-line arguments.
class CliConfig {
  const CliConfig({
    this.enableTalker = false,
    this.grpcHost,
    this.grpcPort,
    this.logLevel = LogLevel.info,
  });

  /// Enable Talker logging framework.
  final bool enableTalker;

  /// gRPC log server host; null disables gRPC push.
  final String? grpcHost;

  /// gRPC log server port.
  final int? grpcPort;

  /// Log level
  final LogLevel logLevel;

  bool get enableGrpc => grpcHost != null && grpcPort != null;

  @override
  String toString() =>
      'CliConfig(enableTalker: $enableTalker, grpcHost: $grpcHost, '
      'grpcPort: $grpcPort, logLevel: $logLevel)';
}

final _parser = ArgParser()
  ..addFlag(
    'talker',
    abbr: 't',
    help: 'Enable Talker logging',
  )
  ..addOption(
    'talker-grpc-host',
    help: 'gRPC log server host',
    valueHelp: 'HOST',
  )
  ..addOption(
    'talker-grpc-port',
    help: 'gRPC log server port',
    valueHelp: 'PORT',
  )
  ..addOption(
    'log-level',
    defaultsTo: 'info',
    allowed: ['debug', 'info', 'warning', 'error'],
    help: 'Log level (debug/info/warning/error)',
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

  final grpcHost = results['talker-grpc-host'] as String?;
  final grpcPortStr = results['talker-grpc-port'] as String?;
  final grpcPort = grpcPortStr != null ? int.tryParse(grpcPortStr) : null;

  return CliConfig(
    enableTalker: results['talker'] as bool,
    grpcHost: grpcHost,
    grpcPort: grpcPort,
    logLevel: logLevelFromString(results['log-level'] as String?) ?? LogLevel.info,
  );
}
