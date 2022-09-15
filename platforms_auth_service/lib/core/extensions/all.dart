extension ExString on String {
  String removeLast(bool test) {
    if (test) {
      List<String> c = split("");
      c.removeLast();
      return c.join();
    }
    return this;
  }
}
