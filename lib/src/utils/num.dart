extension BigIntHelpers on BigInt {
  int toIntSafe() {
    if (isValidInt) {
      return toInt();
    }
    throw Exception("BigInt $this is not valid int");
  }
}

(T, T) sort2<T extends Comparable<dynamic>>(T x, T y) {
  return Comparable.compare(x, y) <= 0 ? (x, y) : (y, x);
}

extension IntHelper on int {
  double get inGB => this / (1 << 30);
  double get inMB => this / (1 << 20);
  double get inKB => this / (1 << 10);
}

extension DoubleHelper on double {
  String get fixed1 => toStringAsFixed(1);
  String get fixed2 => toStringAsFixed(2);
  String get fixed3 => toStringAsFixed(3);
}
