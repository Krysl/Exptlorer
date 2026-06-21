import 'dart:async';

import 'package:flutter/material.dart';
// ignore: implementation_imports
import 'package:talker_flutter/src/controller/talker_view_controller.dart';
// ignore: implementation_imports
import 'package:talker_flutter/src/ui/widgets/base_card.dart';
import 'package:talker_flutter/talker_flutter.dart';

class FilterButton extends StatelessWidget {
  const FilterButton({
    super.key,
    required this.enable,
    required this.name,
    this.onChanged,
    this.onTap,
  });
  final bool enable;
  final String name;
  final ValueChanged<bool>? onChanged;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 15,
      mainAxisAlignment: .spaceAround,
      children: [
        ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: switch (enable) {
              true => Colors.blue,
              false => Colors.grey,
            }, // 🟢 按钮背景色
            foregroundColor: Colors.white, // ⚪ 文本和图标颜色
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), // 按钮内边距
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8), // 圆角大小
            ),
          ),
          child: Text(name),
        ),
      ],
    );
  }
}

/// Log viewer page.
///
/// Displays all [Talker] logs via [TalkerScreen].
class LogViewerPage extends StatefulWidget {
  const LogViewerPage({super.key, required this.talker});

  final Talker talker;

  @override
  State<LogViewerPage> createState() => _LogViewerPageState();
}

class _LogViewerPageState extends State<LogViewerPage> {
  late final TalkerViewController controller;
  final GlobalKey _filterOutsKey = GlobalKey();
  final Map<Pattern, bool> filterOuts = {
    'fileIcon': true,
  };
  TalkerData? selected;

  @override
  void initState() {
    super.initState();
    controller = TalkerViewController(
      talker: widget.talker,
    );
  }

  void updateFilter() {
    controller.filter = TalkerFilter(
      tagsFilter: (tags) {
        if (tags.isEmpty) return true;
        return !filterOuts.entries
            .where((e) => !e.value)
            .any(
              (e) => tags.any(
                (tag) => (tag as String).contains(e.key),
              ),
            );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    widget.talker.debug(filterOuts);
    return Column(
      children: [
        Expanded(
          child: TalkerView(
            talker: widget.talker,
            controller: controller,
            beforeKeyFilters: SingleChildScrollView(
              key: _filterOutsKey,
              scrollDirection: .horizontal,
              child: Row(
                children: filterOuts.entries
                    .map<Widget>(
                      (e) => FilterButton(
                        enable: e.value,
                        name: e.key.toString(),
                        onTap: () {
                          setState(() {
                            filterOuts[e.key] = !filterOuts[e.key]!;
                            updateFilter();
                          });
                        },
                      ),
                    )
                    .toList(),
              ),
            ),

            itemsBuilder: (context, data) {
              if (data.tags != null) {
                var changed = false;
                for (final tag in data.tags!) {
                  if (tag is String && !filterOuts.containsKey(tag)) {
                    filterOuts[tag] = true;
                    changed = true;
                  }
                }
                if (changed) {
                  unawaited(Future.microtask(() => setState(() {})));
                }
              }
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selected = data;
                  });
                },
                child: TalkerBaseCard(
                  padding: const EdgeInsets.only(top: 2),
                  color: data.getFlutterColor(const TalkerScreenTheme()),
                  backgroundColor: data != selected
                      ? data.getFlutterColor(const TalkerScreenTheme()).withAlpha(80)
                      : data.getFlutterColor(const TalkerScreenTheme()).withAlpha(40),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 140,
                        child: Text(
                          data.title ?? '',
                          style: const .new(color: Colors.blue),
                        ),
                      ),
                      SizedBox(
                        width: 140,
                        child: Text(
                          data.key ?? '',
                          style: const .new(color: Colors.red),
                        ),
                      ),
                      SizedBox(
                        width: 140,
                        child: Text(
                          data.tags?.join(',') ?? '',
                          style: const .new(color: Colors.green),
                        ),
                      ),
                      SizedBox(width: 120, child: Text(data.displayTime())),
                      Expanded(
                        child: Tooltip(
                          message: data.message,
                          child: Text(
                            '${data.message}',
                            overflow: .ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            customSettings: [
              .new(
                title: 'Filter',
                enabled: true,
                items: [
                  CustomSettingsItemBool(
                    name: 'Show only errors',
                    value: false,
                    onChanged: (val) {
                      if (val) {
                        controller.filter = TalkerFilter(
                          enabledKeys: [TalkerKey.error, TalkerKey.critical],
                        );
                      } else {
                        controller.filter = TalkerFilter();
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        if (selected != null)
          SizedBox(
            height: 100,
            child: TalkerBaseCard(
              color: selected!.getFlutterColor(const TalkerScreenTheme()),
              backgroundColor: selected!.getFlutterColor(const TalkerScreenTheme()).withAlpha(80),
              child: Row(
                children: [
                  SizedBox(
                    width: 140,
                    child: Text(
                      selected!.title ?? '',
                      style: const .new(color: Colors.blue),
                    ),
                  ),
                  SizedBox(
                    width: 140,
                    child: Text(
                      selected!.key ?? '',
                      style: const .new(color: Colors.red),
                    ),
                  ),
                  SizedBox(
                    width: 140,
                    child: Text(
                      selected!.tags?.join('\n') ?? '',
                      style: const .new(color: Colors.green),
                    ),
                  ),
                  SizedBox(width: 120, child: Text(selected!.displayTime())),
                  Expanded(
                    child: Text(
                      '${selected!.message}',
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
