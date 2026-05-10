/// Failure types for the Result pattern in repositories / use cases.
sealed class Failure {
  const Failure(this.message);
  final String message;
}

final class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server error.']);
}

final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection.']);
}

final class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache error.']);
}

final class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication failed.']);
}

final class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Validation failed.']);
}

final class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Unknown error occurred.']);
}
