import 'package:flutter/material.dart';
// ignore: implementation_imports
import 'package:talker_flutter/src/ui/widgets/base_card.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// Log viewer page.
///
/// Displays all [Talker] logs via [TalkerScreen].
class LogViewerPage extends StatelessWidget {
  const LogViewerPage({super.key, required this.talker});

  final Talker talker;

  @override
  Widget build(BuildContext context) {
    return TalkerScreen(
      talker: talker,
      itemsBuilder: (context, data) {
        return TalkerBaseCard(
          color: data.getFlutterColor(const TalkerScreenTheme()),
          child: Row(
            children: [
              SizedBox(width: 140, child: Text(data.title ?? '')),
              SizedBox(width: 120, child: Text(data.displayTime())),
              Text('${data.message}'),
            ],
          ),
        );
      },
    );
  }
}
