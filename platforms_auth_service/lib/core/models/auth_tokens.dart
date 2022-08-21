import 'dart:convert';

class AuthTokens {
  final String accessToken;
  final String idToken;
  final DateTime expiryDate;
  final String? refreshToken;

  AuthTokens({
    required this.accessToken,
    required this.idToken,
    required this.expiryDate,
    this.refreshToken,
  });

  AuthTokens copyWith({
    String? accessToken,
    String? idToken,
    DateTime? expiryDate,
    String? refreshToken,
  }) {
    return AuthTokens(
      accessToken: accessToken ?? this.accessToken,
      idToken: idToken ?? this.idToken,
      expiryDate: expiryDate ?? this.expiryDate,
      refreshToken: refreshToken ?? this.refreshToken,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'accessToken': accessToken,
      'idToken': idToken,
      'expiryDate': expiryDate.millisecondsSinceEpoch,
      'refreshToken': refreshToken,
    };
  }

  factory AuthTokens.fromMap(Map<String, dynamic> map) {
    return AuthTokens(
      accessToken: map['accessToken'] ?? '',
      idToken: map['idToken'] ?? '',
      expiryDate: DateTime.fromMillisecondsSinceEpoch(map['expiryDate']),
      refreshToken: map['refreshToken'],
    );
  }

  String toJson() => json.encode(toMap());

  factory AuthTokens.fromJson(String source) =>
      AuthTokens.fromMap(json.decode(source));

  @override
  String toString() {
    return 'AuthTokens(accessToken: $accessToken, idToken: $idToken, expiryDate: $expiryDate, refreshToken: $refreshToken)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AuthTokens &&
        other.accessToken == accessToken &&
        other.idToken == idToken &&
        other.expiryDate == expiryDate &&
        other.refreshToken == refreshToken;
  }

  @override
  int get hashCode {
    return accessToken.hashCode ^
        idToken.hashCode ^
        expiryDate.hashCode ^
        refreshToken.hashCode;
  }
}
