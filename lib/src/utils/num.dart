extension BigIntHelpers on BigInt {
  int toIntSafe() {
    if (isValidInt) {
      return toInt();
    }
    throw Exception("BigInt $this is not valid int");
  }
}
