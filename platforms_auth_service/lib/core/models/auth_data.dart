import 'dart:convert';

class AuthData {
  final String? accessToken;
  final bool isAuth;

  AuthData({
    this.accessToken,
    required this.isAuth,
  });

  AuthData copyWith({
    String? accessToken,
    bool? isAuth,
  }) {
    return AuthData(
      accessToken: accessToken ?? this.accessToken,
      isAuth: isAuth ?? this.isAuth,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'accessToken': accessToken,
      'isAuth': isAuth,
    };
  }

  factory AuthData.fromMap(Map<String, dynamic> map) {
    return AuthData(
      accessToken: map['accessToken'],
      isAuth: map['isAuth'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory AuthData.fromJson(String source) =>
      AuthData.fromMap(json.decode(source));

  @override
  String toString() => 'AuthData(accessToken: $accessToken, isAuth: $isAuth)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AuthData &&
        other.accessToken == accessToken &&
        other.isAuth == isAuth;
  }

  @override
  int get hashCode => accessToken.hashCode ^ isAuth.hashCode;
}
