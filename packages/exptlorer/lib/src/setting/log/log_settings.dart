import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talker/talker.dart';

import '../../utils/cli_args.dart';
import '../../utils/log.dart';
import '../../utils/log_observer.dart';

part 'log_settings.freezed.dart';
part 'log_settings.g.dart';

/// gRPC connection status.
enum GrpcConnectionStatus {
  disconnected,
  connecting,
  connected,
  error;

  String get label {
    switch (this) {
      case GrpcConnectionStatus.disconnected:
        return 'Disconnected';
      case GrpcConnectionStatus.connecting:
        return 'Connecting…';
      case GrpcConnectionStatus.connected:
        return 'Connected';
      case GrpcConnectionStatus.error:
        return 'Error';
    }
  }
}

class FakeObserver extends TalkerObserver {
  const FakeObserver();
}

/// Log settings state.
@freezed
abstract class LogSettingsState with _$LogSettingsState {
  const factory LogSettingsState({
    @Default(false) bool enableTalker,
    String? grpcHost,
    @Default(50051) int grpcPort,
    @Default(LogLevel.info) LogLevel logLevel,
    @Default(GrpcConnectionStatus.disconnected) GrpcConnectionStatus connectionStatus,
  }) = _LogSettingsState;
}

@Riverpod(keepAlive: true)
class LogSettingsController extends _$LogSettingsController {
  final _grpcClient = LogGrpcClient();
  LogGrpcObserver? _observer;

  @override
  LogSettingsState build() {
    ref.onDispose(() async {
      await _grpcClient.disconnect();
      log.configure(observer: const FakeObserver());
      log.settings.enabled = false;
    });

    final cliConfig = ref.watch(cliConfigProvider);
    if (cliConfig.enableTalker) {
      log
        ..settings.enabled = true
        ..info('Talker logging enabled (from CLI)')
        ..info('Config: $cliConfig');
    }
    return LogSettingsState(
      enableTalker: cliConfig.enableTalker,
      grpcHost: cliConfig.grpcHost,
      grpcPort: cliConfig.grpcPort ?? 50051,
      logLevel: cliConfig.logLevel,
    );
  }

  void setEnabled({required bool enable}) {
    log.settings.enabled = enable;
    if (enable) {
      log.info('Talker logging enabled');
      // Re-inject observer if previously connected.
      if (_grpcClient.isConnected && _observer != null) {
        log.configure(observer: _observer);
      }
    }
    state = state.copyWith(enableTalker: enable);
  }

  void setGrpcHost(String? host) {
    state = state.copyWith(grpcHost: host);
  }

  void setGrpcPort(int port) {
    state = state.copyWith(grpcPort: port);
  }

  void setLogLevel(LogLevel level) {
    state = state.copyWith(logLevel: level);
  }

  /// Connect to gRPC server.
  ///
  /// DNS lookup → create client → register observer.
  Future<void> connect(String host, int port) async {
    state = state.copyWith(connectionStatus: GrpcConnectionStatus.connecting);
    log.info('Resolving $host …');

    setGrpcHost(host);
    setGrpcPort(port);

    // Disconnect old session.
    await _grpcClient.disconnect();
    log.configure(observer: const FakeObserver());

    try {
      // 1. Verify DNS resolution.
      await InternetAddress.lookup(host).timeout(const Duration(seconds: 5));

      // 2. Create gRPC client.
      _grpcClient.connect(host, port);

      // 3. Ensure Talker is enabled.
      setEnabled(enable: true);

      // 4. Register log observer.
      _observer = LogGrpcObserver(_grpcClient);
      log
        ..configure(observer: _observer)
        ..info('Connected to log server $host:$port, forwarding logs…');
      state = state.copyWith(connectionStatus: GrpcConnectionStatus.connected);
    } on SocketException catch (e) {
      await _grpcClient.disconnect();
      log.error('DNS lookup failed: $e');
      state = state.copyWith(connectionStatus: GrpcConnectionStatus.error);
    } on Object catch (e) {
      await _grpcClient.disconnect();
      log.error('gRPC connection failed: $e');
      state = state.copyWith(connectionStatus: GrpcConnectionStatus.error);
    }
  }

  /// Disconnect from gRPC server.
  Future<void> disconnect() async {
    log.configure(observer: const FakeObserver());
    _observer = null;
    await _grpcClient.disconnect();
    log.info('Disconnected from gRPC server');
    state = state.copyWith(connectionStatus: GrpcConnectionStatus.disconnected);
  }
}

/// Provides the shared [log] instance for dependency injection.
final talkerProvider = Provider<Talker>((ref) {
  ref.watch(logSettingsControllerProvider);
  return log;
});
