import 'dart:io';

import 'package:flutter/widgets.dart';

class FileList extends StatefulWidget {
  const FileList({super.key, required this.dir});

  final Directory dir;

  @override
  State<FileList> createState() => _FileListState();
}

class _FileListState extends State<FileList> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
