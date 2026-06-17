import 'package:talker/talker.dart';

import '../log_ui_proto.dart';

extension ToLogLevel on Level {
  LogLevel toLogLevel() => switch (this) {
    Level.LEVEL_CRITICAL => LogLevel.critical,
    Level.LEVEL_ERROR => LogLevel.error,
    Level.LEVEL_WARNING => LogLevel.warning,
    Level.LEVEL_INFO => LogLevel.info,
    Level.LEVEL_DEBUG => LogLevel.debug,
    Level.LEVEL_VERBOSE => LogLevel.verbose,
    _ => LogLevel.info,
  };
}

extension ToLevel on LogLevel {
  Level toLevel() => switch (this) {
    LogLevel.critical => Level.LEVEL_CRITICAL,
    LogLevel.error => Level.LEVEL_ERROR,
    LogLevel.warning => Level.LEVEL_WARNING,
    LogLevel.info => Level.LEVEL_INFO,
    LogLevel.debug => Level.LEVEL_DEBUG,
    LogLevel.verbose => Level.LEVEL_VERBOSE,
  };
}
