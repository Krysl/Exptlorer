import 'package:exptlorer/src/rust/api/opener.dart';
import 'package:exptlorer/src/rust/frb_generated.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() async {
    await RustLib.init();
  });
  test('open path', () async {
    await openPath(path: r'C:\Windows\Web\Wallpaper\Windows\img0.jpg');
  });
  test('open url', () async {
    await openUrl(url: r'https://www.google.com/');
  });
}
