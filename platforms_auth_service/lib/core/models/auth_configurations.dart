import 'dart:convert';

import 'package:collection/collection.dart';

class AuthConfigurations {
  final String clientId;
  final String tenantId;
  final String redirectUrl;
  final String issuer;
  final String discoveryUrl;
  final String postLogoutRedirectUrl;
  final String authorizationEndpoint;
  final String tokenEndpoint;
  final String endSessionEndpoint;
  final Map<String, String> additionalParameter;
  final List<String> scopes;
  final String clientSecret;
  final List<String> promptValues;

  AuthConfigurations({
    required this.clientId,
    required this.tenantId,
    required this.redirectUrl,
    required this.issuer,
    required this.discoveryUrl,
    required this.postLogoutRedirectUrl,
    required this.authorizationEndpoint,
    required this.tokenEndpoint,
    required this.endSessionEndpoint,
    required this.additionalParameter,
    required this.scopes,
    required this.clientSecret,
    required this.promptValues,
  });

  AuthConfigurations copyWith({
    String? clientId,
    String? tenantId,
    String? redirectUrl,
    String? issuer,
    String? discoveryUrl,
    String? postLogoutRedirectUrl,
    String? authorizationEndpoint,
    String? tokenEndpoint,
    String? endSessionEndpoint,
    Map<String, String>? additionalParameter,
    List<String>? scopes,
    String? clientSecret,
    List<String>? promptValues,
  }) {
    return AuthConfigurations(
      clientId: clientId ?? this.clientId,
      tenantId: tenantId ?? this.tenantId,
      redirectUrl: redirectUrl ?? this.redirectUrl,
      issuer: issuer ?? this.issuer,
      discoveryUrl: discoveryUrl ?? this.discoveryUrl,
      postLogoutRedirectUrl:
          postLogoutRedirectUrl ?? this.postLogoutRedirectUrl,
      authorizationEndpoint:
          authorizationEndpoint ?? this.authorizationEndpoint,
      tokenEndpoint: tokenEndpoint ?? this.tokenEndpoint,
      endSessionEndpoint: endSessionEndpoint ?? this.endSessionEndpoint,
      additionalParameter: additionalParameter ?? this.additionalParameter,
      scopes: scopes ?? this.scopes,
      clientSecret: clientSecret ?? this.clientSecret,
      promptValues: promptValues ?? this.promptValues,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'tenantId': tenantId,
      'redirectUrl': redirectUrl,
      'issuer': issuer,
      'discoveryUrl': discoveryUrl,
      'postLogoutRedirectUrl': postLogoutRedirectUrl,
      'authorizationEndpoint': authorizationEndpoint,
      'tokenEndpoint': tokenEndpoint,
      'endSessionEndpoint': endSessionEndpoint,
      'additionalParameter': additionalParameter,
      'scopes': scopes,
      'clientSecret': clientSecret,
      'promptValues': promptValues,
    };
  }

  factory AuthConfigurations.fromMap(Map<String, dynamic> map) {
    return AuthConfigurations(
      clientId: map['clientId'] ?? '',
      tenantId: map['tenantId'] ?? '',
      redirectUrl: map['redirectUrl'] ?? '',
      issuer: map['issuer'] ?? '',
      discoveryUrl: map['discoveryUrl'] ?? '',
      postLogoutRedirectUrl: map['postLogoutRedirectUrl'] ?? '',
      authorizationEndpoint: map['authorizationEndpoint'] ?? '',
      tokenEndpoint: map['tokenEndpoint'] ?? '',
      endSessionEndpoint: map['endSessionEndpoint'] ?? '',
      additionalParameter: Map<String, String>.from(map['additionalParameter']),
      scopes: List<String>.from(map['scopes']),
      clientSecret: map['clientSecret'] ?? '',
      promptValues: List<String>.from(map['promptValues']),
    );
  }

  String toJson() => json.encode(toMap());

  factory AuthConfigurations.fromJson(String source) =>
      AuthConfigurations.fromMap(json.decode(source));

  @override
  String toString() {
    return 'AuthConfigurations(clientId: $clientId, tenantId: $tenantId, redirectUrl: $redirectUrl, issuer: $issuer, discoveryUrl: $discoveryUrl, postLogoutRedirectUrl: $postLogoutRedirectUrl, authorizationEndpoint: $authorizationEndpoint, tokenEndpoint: $tokenEndpoint, endSessionEndpoint: $endSessionEndpoint, additionalParameter: $additionalParameter, scopes: $scopes, clientSecret: $clientSecret, promptValues: $promptValues)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    final collectionEquals = const DeepCollectionEquality().equals;

    return other is AuthConfigurations &&
        other.clientId == clientId &&
        other.tenantId == tenantId &&
        other.redirectUrl == redirectUrl &&
        other.issuer == issuer &&
        other.discoveryUrl == discoveryUrl &&
        other.postLogoutRedirectUrl == postLogoutRedirectUrl &&
        other.authorizationEndpoint == authorizationEndpoint &&
        other.tokenEndpoint == tokenEndpoint &&
        other.endSessionEndpoint == endSessionEndpoint &&
        collectionEquals(other.additionalParameter, additionalParameter) &&
        collectionEquals(other.scopes, scopes) &&
        other.clientSecret == clientSecret &&
        collectionEquals(other.promptValues, promptValues);
  }

  @override
  int get hashCode {
    return clientId.hashCode ^
        tenantId.hashCode ^
        redirectUrl.hashCode ^
        issuer.hashCode ^
        discoveryUrl.hashCode ^
        postLogoutRedirectUrl.hashCode ^
        authorizationEndpoint.hashCode ^
        tokenEndpoint.hashCode ^
        endSessionEndpoint.hashCode ^
        additionalParameter.hashCode ^
        scopes.hashCode ^
        clientSecret.hashCode ^
        promptValues.hashCode;
  }
}
