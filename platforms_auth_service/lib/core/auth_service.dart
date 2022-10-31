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
  AuthConfigurations configurations;
  final Future<SharedPreferences> storageInstance;
  final bool logOutPrompt;
  final bool enableLog;
  AuthService({
    this.enableLog = false,
    this.logOutPrompt = false,
    required this.authDbKey,
    required this.storageInstance,
    required this.configurations,
  });

  void setConfigurations(AuthConfigurations intputConfigurations) {
    configurations = intputConfigurations;
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
        .removeLast(test: (e) => e.endsWith("/"));
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

    final result = await _showWebWindow(url, configurations.redirectUrl);

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
    if (platformIsWeb) {
      return await webLogoutRequest();
    }
    if (platformIsAndroid || platformIsIOS) {
      return await logoutMobile();
    }
    throw Exception("Platform not valid");
  }

  Future<bool> logoutMobile() async {
    if (logOutPrompt) {
      const FlutterAppAuth appAuth = FlutterAppAuth();

      await appAuth.endSession(
        EndSessionRequest(
          preferEphemeralSession: false,
          serviceConfiguration: AuthorizationServiceConfiguration(
            authorizationEndpoint: configurations.authorizationEndpoint,
            tokenEndpoint: configurations.tokenEndpoint,
            endSessionEndpoint: _getLogoutUrl(await getTokensSaved()),
          ),
        ),
      );
    }
    return await _clearStorage();
  }

  Future<bool> webLogoutRequest() async {
    if (logOutPrompt) {
      await _showWebWindow(
        _getLogoutUrl(await getTokensSaved()),
        configurations.postLogoutRedirectUrl,
      );
    }

    return await _clearStorage();
  }

  String _getLogoutUrl(AuthTokens tokens) {
    String url = "${configurations.endSessionEndpoint}?";

    final queryParameters = {
      "id_token_hint": tokens.idToken,
      "post_logout_redirect_uri": configurations.postLogoutRedirectUrl,
    };
    if (configurations.state != null) {
      queryParameters.addAll({"state": configurations.state!});
    }

    queryParameters.addAll(configurations.additionalParameter);

    queryParameters.forEach((key, value) {
      url += "$key=$value";
      url += "&";
    });
    _log("Logout URL =>  $url");
    return url;
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

  Future<String> _showWebWindow(String url, String callbackUrlScheme) async {
    return await FlutterWebAuth.authenticate(
      url: url,
      callbackUrlScheme: callbackUrlScheme,
      preferEphemeral: false,
    );
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

  void _log(Object? object) {
    if (enableLog) {
      if (kDebugMode) {
        return print(object);
      }
    }
  }

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
}
