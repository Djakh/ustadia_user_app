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
