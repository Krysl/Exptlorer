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

  Future<Empty> _sendLog(ServiceCall call, Future<LogEntry> entryFuture) async {
    final entry = await entryFuture;
    final level = entry.level.toLogLevel();

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
  LogGrpcServerManager({
    required this.talker,
  });
  Talker talker;
  Server? _server;

  bool get isRunning => _server != null;

  /// Start the gRPC server.
  Future<void> start({
    String host = '0.0.0.0',
    int port = 50051,
  }) async {
    await stop();

    _server = Server.create(
      services: [
        LogGrpcService(talker), //
      ],
    );

    await _server!.serve(
      address: host, //
      port: port,
    );
    talker.info('gRPC log server started: $host:$port');
  }

  /// Stop the gRPC server.
  Future<void> stop() async {
    await _server?.shutdown();
    if (_server != null) {
      talker.info('gRPC log server stoped');
    }
    _server = null;
  }
}
