import 'package:fixnum/fixnum.dart' as fixnum;
import 'package:grpc/grpc.dart';
import 'package:log_ui_proto/log_ui_proto.dart';
import 'package:talker/talker.dart';

/// gRPC client that sends [TalkerLog] entries to the log_ui server.
class LogGrpcClient {
  ClientChannel? _channel;
  final _method = ClientMethod<LogEntry, Empty>(
    '/logui.LogService/SendLog',
    (value) => value.writeToBuffer(),
    Empty.fromBuffer,
  );

  /// Connect to the gRPC log server.
  void connect(String host, int port) {
    _channel = ClientChannel(
      host,
      port: port,
      options: const ChannelOptions(
        credentials: ChannelCredentials.insecure(),
        connectionTimeout: Duration(seconds: 5),
      ),
    );
  }

  /// Disconnect from the gRPC log server.
  Future<void> disconnect() async {
    await _channel?.shutdown();
    _channel = null;
  }

  bool get isConnected => _channel != null;

  /// Map [LogLevel] to proto [Level].
  static Level _level(LogLevel l) => switch (l) {
    LogLevel.debug => Level.LEVEL_DEBUG,
    LogLevel.info => Level.LEVEL_INFO,
    LogLevel.warning => Level.LEVEL_WARNING,
    LogLevel.error => Level.LEVEL_ERROR,
    LogLevel.critical => Level.LEVEL_CRITICAL,
    LogLevel.verbose => Level.LEVEL_VERBOSE,
  };

  /// Send one log entry (fire-and-forget).
  void sendLog(TalkerLog log, {LogLevel level = LogLevel.info}) {
    final channel = _channel;
    if (channel == null) return;

    final entry = LogEntry(
      level: _level(level),
      title: log.title ?? '',
      message: log.message,
      time: fixnum.Int64(DateTime.now().microsecondsSinceEpoch),
    );

    // Fire-and-forget: consume the response stream to avoid unhandled errors.
    try {
      final call = channel.createCall(
        _method,
        Stream.value(entry),
        CallOptions(),
      );
      call.response.listen(null, onError: (_) {});
    } on Object catch (_) {
      // Silently ignore send failures — logging must not block the main app.
    }
  }
}

/// [TalkerObserver] that forwards logs to log_ui via gRPC.
///
/// Created and injected by [LogSettingsController.connect].
class LogGrpcObserver extends TalkerObserver {
  LogGrpcObserver(this._client);

  final LogGrpcClient _client;

  @override
  void onLog(TalkerData log) {
    if (log is TalkerLog) {
      _client.sendLog(log);
    }
    super.onLog(log);
  }

  @override
  void onError(TalkerError err) {
    _client.sendLog(
      TalkerLog(err.message, title: 'Error'),
      level: LogLevel.error,
    );
    super.onError(err);
  }

  @override
  void onException(TalkerException err) {
    _client.sendLog(
      TalkerLog(err.message, title: 'Exception'),
      level: LogLevel.error,
    );
    super.onException(err);
  }
}
