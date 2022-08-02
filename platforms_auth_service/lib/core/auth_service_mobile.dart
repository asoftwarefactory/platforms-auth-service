import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/auth_configurations.dart';
import 'models/auth_data.dart';
import 'models/auth_storage.dart';

class AuthServiceMobile {
  AuthServiceMobile({required this.configurations, required this.dbLoginKey});

  final AuthConfigurations configurations;

  final FlutterAppAuth _appAuthService = const FlutterAppAuth();

  final String dbLoginKey;

  Future<SharedPreferences> get _storage async {
    return await SharedPreferences.getInstance();
  }

  bool get isWeb {
    return kIsWeb;
  }

  Future<AuthData> login() async {
    final AuthorizationTokenResponse? requestLogin =
        await _appAuthService.authorizeAndExchangeCode(
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

    // required refreshToken
    /* if (!(requestLogin?.accessToken != null &&
        requestLogin?.idToken != null &&
        requestLogin?.accessTokenExpirationDateTime != null &&
        requestLogin?.refreshToken != null)) {
      throw Exception("requestLogin value null");
    } */

    if (!(requestLogin?.accessToken != null &&
        requestLogin?.idToken != null &&
        requestLogin?.accessTokenExpirationDateTime != null)) {
      throw Exception("requestLogin value null");
    }

    final userId =
        JwtDecoder.decode(requestLogin!.accessToken!)['UserId'] as String?;

    if (userId == null) {
      throw Exception("UserId Null");
    }

    final AuthStorageData authData = AuthStorageData(
      accessToken: requestLogin.accessToken!,
      expiryDate: requestLogin.accessTokenExpirationDateTime!,
      refreshToken: requestLogin.refreshToken,
      idToken: requestLogin.idToken!,
      userId: userId,
    );

    final setLoginTokens =
        await (await _storage).setString(dbLoginKey, authData.toJson());

    if (setLoginTokens) {
      return AuthData(
          isAuth: true, accessToken: authData.accessToken, userId: userId);
    } else {
      throw Exception("tokens not saved");
    }
  }

  Future<AuthData> refreshSession() async {
    final String? loginDataString = (await _storage).getString(dbLoginKey);
    if (loginDataString != null) {
      final loginData = AuthStorageData.fromJson(loginDataString);

      final TokenResponse requestRefreshToken = await _doRefreshToken(
        tokenEndpoint: configurations.tokenEndpoint,
        clientId: configurations.clientId,
        redirectUrl: configurations.redirectUrl,
        clientSecret: configurations.clientSecret,
        refreshToken: loginData.refreshToken,
        grantType: configurations.grantType,
        additionalParameter: configurations.additionalParameter,
      );

      if (!(requestRefreshToken.accessToken != null &&
          requestRefreshToken.idToken != null &&
          requestRefreshToken.accessTokenExpirationDateTime != null &&
          requestRefreshToken.refreshToken != null)) {
        throw Exception("requestRefresh value null");
      }

      final userId =
          JwtDecoder.decode(requestRefreshToken.accessToken!)['UserId']
              as String?;

      if (userId == null) {
        throw Exception("UserId Null");
      }

      final AuthStorageData refreshData = AuthStorageData(
        accessToken: requestRefreshToken.accessToken!,
        expiryDate: requestRefreshToken.accessTokenExpirationDateTime!,
        refreshToken: requestRefreshToken.refreshToken!,
        idToken: requestRefreshToken.idToken!,
        userId: userId,
      );

      final setRefreshTokens =
          await (await _storage).setString(dbLoginKey, refreshData.toJson());

      if (setRefreshTokens) {
        return AuthData(
          isAuth: true,
          accessToken: refreshData.accessToken,
          userId: userId,
        );
      } else {
        throw Exception("tokens not saved");
      }
    } else {
      throw Exception("accessToken not found");
    }
  }

  Future<bool> logout() async {
    // TODO: check if it is required to delete the access token
    return await (await _storage).remove(dbLoginKey);
  }

  Future<AuthStorageData> getDataSaved() async {
    final storageInstance = (await _storage).getString(dbLoginKey);

    if (storageInstance != null) {
      final loginData = AuthStorageData.fromJson(storageInstance);

      return loginData;
    } else {
      throw Exception("Storage Null value");
    }
  }

  Future<TokenResponse> _doRefreshToken({
    required String tokenEndpoint,
    required String clientId,
    required String redirectUrl,
    required String clientSecret,
    String? refreshToken,
    required String grantType,
    Map<String, String>? additionalParameter,
  }) async {
    Map<String, String> data = {};

    data.addAll({
      "client_id": clientId,
      "client_secret": clientSecret,
      "redirect_uri": redirectUrl,
      "grant_type": grantType,
    });

    if (refreshToken != null) {
      data.addAll({"refresh_token": refreshToken});
    }

    if (additionalParameter != null) {
      data.addAll(additionalParameter);
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
}
