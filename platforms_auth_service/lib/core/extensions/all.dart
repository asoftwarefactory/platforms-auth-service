extension ExString on String {
  String removeLast({bool Function(String)? test}) {
    if (test?.call(this) ?? fn(this)) {
      List<String> c = split("");
      c.removeLast();
      return c.join();
    }
    return this;
  }
}

bool fn(String v) => true;
