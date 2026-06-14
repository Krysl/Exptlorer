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
