class AuthData {
  final String? accessToken;
  final bool isAuth;
  bool? isAuthorized;
  final String? userId;

  AuthData(
      {required this.isAuth, this.accessToken, this.userId, this.isAuthorized});
}
