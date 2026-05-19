abstract class AuthRepository {
  Future<String> getJwtToken();
  Future<String> getUserId();
}

class InMemoryAuthRepository implements AuthRepository {
  final String jwtToken;
  final String userId;

  InMemoryAuthRepository({required this.jwtToken, required this.userId});

  @override
  Future<String> getJwtToken() async => jwtToken;

  @override
  Future<String> getUserId() async => userId;
}

class DynamicAuthRepository implements AuthRepository {
  final String Function() jwtTokenGetter;
  final String Function() userIdGetter;

  const DynamicAuthRepository({required this.jwtTokenGetter, required this.userIdGetter});

  @override
  Future<String> getJwtToken() async => jwtTokenGetter();

  @override
  Future<String> getUserId() async => userIdGetter();
}
