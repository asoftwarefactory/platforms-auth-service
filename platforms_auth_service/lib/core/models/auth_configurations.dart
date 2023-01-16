import 'dart:convert';

class AuthConfigurations {
  final String clientId;
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
  final String? state;

  AuthConfigurations({
    this.clientId = "",
    this.redirectUrl = "",
    this.issuer = "",
    this.discoveryUrl = "",
    this.postLogoutRedirectUrl = "",
    this.authorizationEndpoint = "",
    this.tokenEndpoint = "",
    this.endSessionEndpoint = "",
    this.additionalParameter = const {},
    this.scopes = const [],
    this.clientSecret = "",
    this.promptValues = const [],
    this.state,
  });

  AuthConfigurations copyWith({
    String? clientId,
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
    String? state,
  }) {
    return AuthConfigurations(
      clientId: clientId ?? this.clientId,
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
      state: state ?? this.state,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
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
      'state': state,
    };
  }

  factory AuthConfigurations.fromMap(Map<String, dynamic> map) {
    return AuthConfigurations(
      clientId: map['clientId'] ?? '',
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
      state: map['state'],
    );
  }

  String toJson() => json.encode(toMap());

  factory AuthConfigurations.fromJson(String source) =>
      AuthConfigurations.fromMap(json.decode(source));

  @override
  String toString() {
    return 'AuthConfigurations(clientId: $clientId, redirectUrl: $redirectUrl, issuer: $issuer, discoveryUrl: $discoveryUrl, postLogoutRedirectUrl: $postLogoutRedirectUrl, authorizationEndpoint: $authorizationEndpoint, tokenEndpoint: $tokenEndpoint, endSessionEndpoint: $endSessionEndpoint, additionalParameter: $additionalParameter, scopes: $scopes, clientSecret: $clientSecret, promptValues: $promptValues, state: $state)';
  }
}
