import 'package:flutter/material.dart';
import 'package:talker_flutter/talker_flutter.dart';

import 'src/app.dart';
import 'src/grpc_server.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final talker =
      TalkerFlutter.init(
          settings: TalkerSettings(),
        )
        ..info('Log UI started')
        ..info('Talker version: 5.1.17');

  // Start the gRPC log server on port 50051.
  final serverManager = LogGrpcServerManager();
  await serverManager.start(talker: talker);

  talker.info(
    'Send logs via: exptlorer --talker --talker-grpc-host=127.0.0.1 --talker-grpc-port=50051',
  );

  //
  // ignore: riverpod_lint/missing_provider_scope
  runApp(LogUiApp(talker: talker));
}
