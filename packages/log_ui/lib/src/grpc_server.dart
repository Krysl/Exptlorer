import 'dart:async';

import 'package:grpc/grpc.dart';
import 'package:log_ui_proto/log_ui_proto.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// gRPC log server.
///
/// Listens for incoming log entries from exptlorer
/// and renders them via [TalkerScreen].
class LogGrpcService extends Service {
  LogGrpcService(this._talker) {
    $addMethod(
      ServiceMethod<LogEntry, Empty>(
        'SendLog',
        _sendLog,
        false,
        false,
        LogEntry.fromBuffer,
        (value) => value.writeToBuffer(),
      ),
    );
  }

  @override
  String get $name => 'logui.LogService';

  final Talker _talker;

  /// Map proto [Level] to [LogLevel].
  static LogLevel _level(Level l) {
    if (l == Level.LEVEL_DEBUG) return LogLevel.debug;
    if (l == Level.LEVEL_INFO) return LogLevel.info;
    if (l == Level.LEVEL_WARNING) return LogLevel.warning;
    if (l == Level.LEVEL_ERROR) return LogLevel.error;
    if (l == Level.LEVEL_CRITICAL) return LogLevel.critical;
    if (l == Level.LEVEL_VERBOSE) return LogLevel.verbose;
    return LogLevel.info;
  }

  Future<Empty> _sendLog(ServiceCall call, Future<LogEntry> entryFuture) async {
    final entry = await entryFuture;
    final level = _level(entry.level);

    _talker.logCustom(
      TalkerLog(
        entry.message,
        title: entry.title,
        logLevel: level,
        time: DateTime.fromMicrosecondsSinceEpoch(entry.time.toInt()),
      ),
    );

    return Empty();
  }
}

/// Manages the gRPC server lifecycle.
class LogGrpcServerManager {
  Server? _server;

  bool get isRunning => _server != null;

  /// Start the gRPC server.
  Future<void> start({
    required Talker talker,
    String host = '0.0.0.0',
    int port = 50051,
  }) async {
    await stop();

    _server = Server.create(services: [LogGrpcService(talker)]);

    await _server!.serve(address: host, port: port);
    talker.info('gRPC log server started: $host:$port');
  }

  /// Stop the gRPC server.
  Future<void> stop() async {
    await _server?.shutdown();
    _server = null;
  }
}
