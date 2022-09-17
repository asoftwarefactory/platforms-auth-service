import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:platforms_auth_service/core/extensions/all.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/auth_configurations.dart';
import 'models/auth_data.dart';
import 'models/auth_tokens.dart';
import 'models/code_data.dart';

class AuthService {
  final String authDbKey;
  final AuthConfigurations configurations;
  final Future<SharedPreferences> storageInstance;
  AuthService({
    required this.authDbKey,
    required this.storageInstance,
    required this.configurations,
  });

  String get grantTypeAuthRequest {
    return "authorization_code";
  }

  String get grantTypeRefresh {
    return "refresh_token";
  }

  bool get platformIsWeb {
    return kIsWeb;
  }

  bool get platformIsAndroid {
    return Platform.isAndroid;
  }

  bool get platformIsIOS {
    return Platform.isIOS;
  }

  Future<AuthData> login() async {
    if (platformIsWeb) {
      return await loginWEB();
    }
    if (platformIsAndroid || platformIsIOS) {
      return await loginMobile();
    }
    throw Exception("Platform not valid");
  }

  Future<AuthData> loginWEB() async {
    final authorizationEndpoint = configurations.authorizationEndpoint
        .removeLast(configurations.authorizationEndpoint.endsWith("/"));
    String url = "$authorizationEndpoint?";
    final codeData = _getCode();
    final queryParameters = {
      "client_id": configurations.clientId,
      "redirect_uri": configurations.redirectUrl,
      "response_type": "code",
      "scope": configurations.scopes.join("+"),
      "code_challenge_method": "S256",
      "code_challenge": codeData.codeChallenge,
      "suppressed_prompt": "login",
      "prompt": "login",
    };

    queryParameters.addAll(configurations.additionalParameter);

    queryParameters.forEach((key, value) {
      url += "$key=$value";
      url += "&";
    });

    final result = await FlutterWebAuth.authenticate(
      url: url,
      callbackUrlScheme: configurations.redirectUrl,
      preferEphemeral: false,
    );

    final code = Uri.parse(result).queryParameters['code'];

    final TokenResponse requestToken = await _tokenRequest(
      tokenEndpoint: configurations.tokenEndpoint,
      clientId: configurations.clientId,
      redirectUrl: configurations.redirectUrl,
      clientSecret: configurations.clientSecret,
      codeVerifier: codeData.codeVerifier,
      code: code,
      grantType: grantTypeAuthRequest,
      additionalParameter: configurations.additionalParameter,
    );

    if (requestToken.accessToken == null ||
        requestToken.idToken == null ||
        requestToken.accessTokenExpirationDateTime == null) {
      throw Exception("requestLogin value null");
    }

    final AuthTokens authData = AuthTokens(
      accessToken: requestToken.accessToken!,
      idToken: requestToken.idToken!,
      expiryDate: requestToken.accessTokenExpirationDateTime!,
      refreshToken: requestToken.refreshToken, // nullable refresh token
    );

    final storageResult = await _writeStorage(authData);

    if (storageResult) {
      return AuthData(isAuth: true, accessToken: authData.accessToken);
    } else {
      throw Exception("DB error : tokens not saved");
    }
  }

  Future<AuthData> loginMobile() async {
    const FlutterAppAuth appAuth = FlutterAppAuth();

    final AuthorizationTokenResponse? requestLogin =
        await appAuth.authorizeAndExchangeCode(
      AuthorizationTokenRequest(
        configurations.clientId,
        configurations.redirectUrl,
        scopes: configurations.scopes,
        issuer: configurations.issuer,
        preferEphemeralSession: false,
        promptValues: configurations.promptValues,
        serviceConfiguration: AuthorizationServiceConfiguration(
          authorizationEndpoint: configurations.authorizationEndpoint,
          tokenEndpoint: configurations.tokenEndpoint,
          endSessionEndpoint: configurations.endSessionEndpoint,
        ),
        additionalParameters: configurations.additionalParameter,
      ),
    );

    if (requestLogin == null ||
        requestLogin.accessToken == null ||
        requestLogin.idToken == null ||
        requestLogin.accessTokenExpirationDateTime == null) {
      throw Exception("requestLogin value null");
    }

    final AuthTokens authData = AuthTokens(
      accessToken: requestLogin.accessToken!,
      idToken: requestLogin.idToken!,
      expiryDate: requestLogin.accessTokenExpirationDateTime!,
      refreshToken: requestLogin.refreshToken, // nullable refresh token
    );

    final storageResult = await _writeStorage(authData);

    if (storageResult) {
      return AuthData(isAuth: true, accessToken: authData.accessToken);
    } else {
      throw Exception("DB error : tokens not saved");
    }
  }

  Future<AuthData> loginWithTokens({
    required String accessToken,
    String idToken = "",
    DateTime? accessTokenExpirationDateTime,
    String? refreshToken,
  }) async {
    final AuthTokens refreshData = AuthTokens(
      accessToken: accessToken,
      idToken: idToken,
      expiryDate: accessTokenExpirationDateTime ?? DateTime.now(),
      refreshToken: refreshToken, // nullable refresh token
    );

    final storageResult = await _writeStorage(refreshData);

    if (storageResult) {
      return AuthData(
        isAuth: true,
        accessToken: refreshData.accessToken,
      );
    } else {
      throw Exception("tokens not saved");
    }
  }

  Future<AuthData> refreshSession() async {
    final loginData = await getTokensSaved();

    final TokenResponse requestRefreshToken = await _tokenRequest(
      tokenEndpoint: configurations.tokenEndpoint,
      clientId: configurations.clientId,
      redirectUrl: configurations.redirectUrl,
      clientSecret: configurations.clientSecret,
      refreshToken: loginData.refreshToken,
      grantType: grantTypeRefresh,
      additionalParameter: configurations.additionalParameter,
    );

    if (requestRefreshToken.accessToken == null ||
        requestRefreshToken.idToken == null ||
        requestRefreshToken.accessTokenExpirationDateTime == null) {
      throw Exception("requestRefresh value null");
    }

    final AuthTokens refreshData = AuthTokens(
      accessToken: requestRefreshToken.accessToken!,
      idToken: requestRefreshToken.idToken!,
      expiryDate: requestRefreshToken.accessTokenExpirationDateTime!,
      refreshToken: requestRefreshToken.refreshToken, // nullable refresh token
    );

    final storageResult = await _writeStorage(refreshData);

    if (storageResult) {
      return AuthData(
        isAuth: true,
        accessToken: refreshData.accessToken,
      );
    } else {
      throw Exception("tokens not saved");
    }
  }

  Future<bool> logout() async {
    return await _clearStorage();
  }

  Future<AuthTokens> getTokensSaved() async {
    final stringDb = (await storageInstance).getString(authDbKey);

    if (stringDb != null) {
      final loginData = AuthTokens.fromJson(stringDb);

      return loginData;
    } else {
      throw Exception("Storage Null value");
    }
  }

  Future<TokenResponse> _tokenRequest({
    required String tokenEndpoint,
    required String clientId,
    required String redirectUrl,
    required String clientSecret,
    String? refreshToken,
    String? code,
    String? codeVerifier,
    required String grantType,
    Map<String, String> additionalParameter = const {},
  }) async {
    Map<String, String> data = {};

    data.addAll({
      "client_id": clientId,
      "client_secret": clientSecret,
      "redirect_uri": redirectUrl,
      "grant_type": grantType,
    });
    data.addAll(additionalParameter);
    if (refreshToken != null) {
      data.addAll({
        "refresh_token": refreshToken,
      });
    }
    if (code != null) {
      data.addAll({
        "code": code,
      });
    }

    if (codeVerifier != null) {
      data.addAll({
        "code_verifier": codeVerifier,
      });
    }

    final response = await Dio().post(
      tokenEndpoint,
      data: data,
      options: Options(
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
      ),
    );

    final Map<String, dynamic>? dataRequest = response.data;

    if (dataRequest == null) {
      throw Exception("Response Null");
    }

    final String? accessToken = dataRequest["access_token"] as String?;
    final String? newRefreshToken = dataRequest["refresh_token"] as String?;
    final String? idToken = dataRequest["id_token"] as String?;
    final DateTime accessTokenExpirationDateTime = DateTime.now().add(
        Duration(seconds: int.parse(dataRequest["expires_in"].toString())));
    final List<String> scopes = dataRequest["scope"].toString().split(" ");
    final tokenType = dataRequest["token_type"] as String?;

    return TokenResponse(
      accessToken,
      newRefreshToken,
      accessTokenExpirationDateTime,
      idToken,
      tokenType,
      scopes,
      additionalParameter,
    );
  }

  Future<bool> _writeStorage(AuthTokens data) async {
    return await (await storageInstance).setString(authDbKey, data.toJson());
  }

  Future<bool> _clearStorage() async {
    return await (await storageInstance).remove(authDbKey);
  }

  static Map<String, dynamic> decodeToken(String accessToken) {
    return JwtDecoder.decode(accessToken);
  }

  CodeData _getCode() {
    const String charset =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';

    final codeVerifier = List.generate(
        128, (i) => charset[Random.secure().nextInt(charset.length)]).join();

    final codeChallenge = base64Url
        .encode(
            SHA256Digest().process(Uint8List.fromList(codeVerifier.codeUnits)))
        .replaceAll('=', '');

    return CodeData(codeVerifier: codeVerifier, codeChallenge: codeChallenge);
  }
}
