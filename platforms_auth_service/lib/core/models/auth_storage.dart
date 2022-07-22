import 'dart:convert';

class AuthStorageData {
  final String accessToken;
  final String idToken;
  final DateTime expiryDate;
  final String refreshToken;
  final String userId;
  AuthStorageData({
    required this.accessToken,
    required this.idToken,
    required this.expiryDate,
    required this.refreshToken,
    required this.userId,
  });

  AuthStorageData copyWith({
    String? accessToken,
    String? idToken,
    DateTime? expiryDate,
    String? refreshToken,
    String? userId,
  }) {
    return AuthStorageData(
      accessToken: accessToken ?? this.accessToken,
      idToken: idToken ?? this.idToken,
      expiryDate: expiryDate ?? this.expiryDate,
      refreshToken: refreshToken ?? this.refreshToken,
      userId: userId ?? this.userId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'accessToken': accessToken,
      'idToken': idToken,
      'expiryDate': expiryDate.millisecondsSinceEpoch,
      'refreshToken': refreshToken,
      'userId': userId,
    };
  }

  factory AuthStorageData.fromMap(Map<String, dynamic> map) {
    return AuthStorageData(
      accessToken: map['accessToken'] ?? '',
      idToken: map['idToken'] ?? '',
      expiryDate: DateTime.fromMillisecondsSinceEpoch(map['expiryDate']),
      refreshToken: map['refreshToken'] ?? '',
      userId: map['userId'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory AuthStorageData.fromJson(String source) =>
      AuthStorageData.fromMap(json.decode(source));

  @override
  String toString() {
    return 'AuthStorageData(accessToken: $accessToken, idToken: $idToken, expiryDate: $expiryDate, refreshToken: $refreshToken, userId: $userId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AuthStorageData &&
        other.accessToken == accessToken &&
        other.idToken == idToken &&
        other.expiryDate == expiryDate &&
        other.refreshToken == refreshToken &&
        other.userId == userId;
  }

  @override
  int get hashCode {
    return accessToken.hashCode ^
        idToken.hashCode ^
        expiryDate.hashCode ^
        refreshToken.hashCode ^
        userId.hashCode;
  }
}
