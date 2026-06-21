import 'package:talker/talker.dart';

final Map<String, LogLevel> logLevelNameMap = Map.fromEntries(
  LogLevel.values.map((lv) => MapEntry(lv.name, lv)),
);

extension LogLevelFrom on LogLevel {
  static LogLevel? fromString(String name) => logLevelNameMap[name];
}

/// Shared Talker instance used across the app.
final log = Talker();

extension TalkerEx on Talker {
  void debugEx(dynamic msg, {String? title, List<String>? tags}) {
    logCustom(
      TalkerLog(msg.toString(), title: title, tags: tags, logLevel: LogLevel.debug),
    );
  }
}

// Intentionally printed to console
// ignore: avoid_print
void printToConsole(Object? object) => print(object);
