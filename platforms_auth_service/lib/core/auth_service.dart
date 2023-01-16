import 'dart:convert';
import 'dart:developer';
import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:extension_methods/core/string.dart';
import 'package:flutter/foundation.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:native_oauth_ids/native_oauth_ids.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/auth_configurations.dart';
import 'models/auth_data.dart';
import 'models/auth_tokens.dart';
import 'models/code_data.dart';
import 'models/token_response.dart';

class AuthService {
  final String authDbKey;
  AuthConfigurations configurations;
  final bool logOutPromptWeb;
  final bool enableLog;
  AuthService({
    this.enableLog = false,
    this.logOutPromptWeb = false,
    required this.authDbKey,
    required this.configurations,
  });

  static Future<AuthService> initAndRefreshSession({
    bool enableLog = false,
    bool logOutPromptWeb = false,
    required String authDbKey,
    required AuthConfigurations configurations,
  }) async {
    final instance = AuthService(
      enableLog: enableLog,
      logOutPromptWeb: logOutPromptWeb,
      authDbKey: authDbKey,
      configurations: configurations,
    );
    await instance.refreshSession();

    return instance;
  }

  void setConfigurations(AuthConfigurations intputConfigurations) {
    configurations = intputConfigurations;
  }

  Future<AuthData> login() async {
    final UrlData urlData = getLoginUrl();
    final NativeOauthIds auth = NativeOauthIds();
    final result = await auth.login(urlData.url);
    _log("login URL : ${urlData.url}");
    if (result == null || result.code.isEmpty) {
      throw Exception("code not received");
    }
    _log("login CODE : ${result.code}");
    final TokenResponse requestToken = await _tokenRequest(
      tokenEndpoint: configurations.tokenEndpoint,
      clientId: configurations.clientId,
      redirectUrl: configurations.redirectUrl,
      clientSecret: configurations.clientSecret,
      codeVerifier: urlData.codeVerifier,
      code: result.code,
      grantType: grantTypeAuthRequest,
      additionalParameter: configurations.additionalParameter,
    );

    if (requestToken.accessToken == null ||
        requestToken.accessTokenExpirationDateTime == null) {
      throw Exception("requestLogin value null");
    }

    final AuthTokens authData = AuthTokens(
      accessToken: requestToken.accessToken!,
      idToken: requestToken.idToken, // nullable refresh token
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

  Future<AuthData> loginWithTokens({
    required String accessToken,
    String? idToken,
    DateTime? accessTokenExpirationDateTime,
    String? refreshToken,
  }) async {
    _log("loginWithTokens started : $accessToken");
    final AuthTokens refreshData = AuthTokens(
      accessToken: accessToken,
      idToken: idToken, // nullable refresh token
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
    _log("TOKEN request Success => ${requestRefreshToken.accessToken ?? ''}");
    if (requestRefreshToken.accessToken == null ||
        requestRefreshToken.accessTokenExpirationDateTime == null) {
      throw Exception("requestRefresh value null");
    }

    final AuthTokens refreshData = AuthTokens(
      accessToken: requestRefreshToken.accessToken!,
      idToken: requestRefreshToken.idToken, // nullable refresh token
      expiryDate: requestRefreshToken.accessTokenExpirationDateTime!,
      refreshToken: requestRefreshToken.refreshToken, // nullable refresh token
    );

    final storageResult = await _writeStorage(refreshData);

    if (storageResult) {
      _log("Refresh Session => $refreshData");
      return AuthData(
        isAuth: true,
        accessToken: refreshData.accessToken,
      );
    } else {
      throw Exception("tokens not saved");
    }
  }

  Future<bool> logout() async {
    if (platformIsWeb && logOutPromptWeb) {
      final String urlData = await getLogoutUrl();
      final NativeOauthIds auth = NativeOauthIds();
      await auth.login(urlData);
      _log("logout URL : $urlData");
    }
    return await _clearStorage();
  }

  Future<AuthTokens> getTokensSaved() async {
    final stringDb =
        (await SharedPreferences.getInstance()).getString(authDbKey);

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

  UrlData getLoginUrl() {
    final codeData = _getCode();
    final authorizationEndpoint = configurations.authorizationEndpoint
        .removeLast(test: (e) => e.endsWith("/"));
    String url = "$authorizationEndpoint?";

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
    final urr = url.removeLast(test: (e) => e.endsWith("&"));
    _log("Login Web URL =>  $urr");

    return UrlData(
      url: url.trim(),
      codeVerifier: codeData.codeVerifier,
      codeChallenge: codeData.codeChallenge,
    );
  }

  Future<String> getLogoutUrl() async {
    final tokens = await getTokensSaved();
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
    final urr = url.removeLast(test: (e) => e.endsWith("&"));
    _log("Logout URL =>  $urr");
    return urr;
  }

  Future<bool> _writeStorage(AuthTokens data) async {
    return await (await SharedPreferences.getInstance())
        .setString(authDbKey, data.toJson());
  }

  Future<bool> _clearStorage() async {
    return await (await SharedPreferences.getInstance()).remove(authDbKey);
  }

  static Map<String, dynamic> decodeToken(String accessToken) {
    return JwtDecoder.decode(accessToken);
  }

  CodeData _getCode() {
    const String charset =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';

    final codeVerifier = List.generate(
            128, (i) => charset[math.Random.secure().nextInt(charset.length)])
        .join();

    final codeChallenge = base64Url
        .encode(
            SHA256Digest().process(Uint8List.fromList(codeVerifier.codeUnits)))
        .replaceAll('=', '');

    return CodeData(codeVerifier: codeVerifier, codeChallenge: codeChallenge);
  }

  void _log(String object) {
    if (enableLog) {
      if (kDebugMode) {
        return log(object);
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
}
