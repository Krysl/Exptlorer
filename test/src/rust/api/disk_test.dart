import 'package:exptlorer/src/rust/api/disk.dart';
import 'package:exptlorer/src/rust/frb_generated.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() async {
    await RustLib.init();
  });
  test('disk ...', () async {
    final ds = await disks();
    final b = ds.map((v) async => MapEntry(v, await v.mountPoint())).toList();
    final c = await Future.wait(b);
    final d = Map.fromEntries(c);
    ds.sort((a, b) => d[a]!.codeUnits[0].compareTo(d[b]!.codeUnits[0]));
    for (final d in ds) {
      debugPrint(
        'kind:${await d.kind()},mount:${await d.mountPoint()}, name:${await d.name()}',
      );
    }
    expect(d[ds.first], r"C:\");
  });
}
