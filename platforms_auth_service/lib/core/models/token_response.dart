class TokenResponse {
  TokenResponse(
    this.accessToken,
    this.refreshToken,
    this.accessTokenExpirationDateTime,
    this.idToken,
    this.tokenType,
    this.scopes,
    this.tokenAdditionalParameters,
  );

  final String? accessToken;
  final String? refreshToken;
  final DateTime? accessTokenExpirationDateTime;
  final String? idToken;
  final String? tokenType;
  final List<String>? scopes;
  final Map<String, dynamic>? tokenAdditionalParameters;
}
