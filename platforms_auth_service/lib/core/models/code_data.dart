import 'dart:convert';

class CodeData {
  final String codeVerifier;
  final String codeChallenge;
  CodeData({
    required this.codeVerifier,
    required this.codeChallenge,
  });

  CodeData copyWith({
    String? codeVerifier,
    String? codeChallenge,
  }) {
    return CodeData(
      codeVerifier: codeVerifier ?? this.codeVerifier,
      codeChallenge: codeChallenge ?? this.codeChallenge,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'codeVerifier': codeVerifier,
      'codeChallenge': codeChallenge,
    };
  }

  factory CodeData.fromMap(Map<String, dynamic> map) {
    return CodeData(
      codeVerifier: map['codeVerifier'] ?? '',
      codeChallenge: map['codeChallenge'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory CodeData.fromJson(String source) =>
      CodeData.fromMap(json.decode(source));

  @override
  String toString() =>
      'CodeData(codeVerifier: $codeVerifier, codeChallenge: $codeChallenge)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CodeData &&
        other.codeVerifier == codeVerifier &&
        other.codeChallenge == codeChallenge;
  }

  @override
  int get hashCode => codeVerifier.hashCode ^ codeChallenge.hashCode;
}
