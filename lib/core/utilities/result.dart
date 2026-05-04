import '../errors/app_error.dart';

typedef AppResult<T> = Result<T, AppError>;

sealed class Result<S, E> {
  const Result();

  factory Result.success(S data) => Success<S, E>(data);
  factory Result.failure(E error) => Failure<S, E>(error);

  static AppResult<T> ok<T>(T data) => Success<T, AppError>(data);
  static AppResult<T> err<T>(AppError error) => Failure<T, AppError>(error);

  T when<T>({
    required T Function(S data) success,
    required T Function(E error) failure,
  }) {
    return switch (this) {
      Success<S, E>(data: final data) => success(data),
      Failure<S, E>(error: final error) => failure(error),
    };
  }

  bool get isSuccess => this is Success<S, E>;
  bool get isFailure => this is Failure<S, E>;

  S? get dataOrNull => switch (this) {
    Success<S, E>(data: final data) => data,
    _ => null,
  };

  E? get errorOrNull => switch (this) {
    Failure<S, E>(error: final error) => error,
    _ => null,
  };
}

class Success<S, E> extends Result<S, E> {
  final S data;
  const Success(this.data);
}

class Failure<S, E> extends Result<S, E> {
  final E error;
  const Failure(this.error);
}

extension ResultX<S, E> on Result<S, E> {
  Result<T, E> map<T>(T Function(S data) transform) {
    return switch (this) {
      Success<S, E>(data: final data) => Success<T, E>(transform(data)),
      Failure<S, E>(error: final error) => Failure<T, E>(error),
    };
  }

  Result<S, F> mapError<F>(F Function(E error) transform) {
    return switch (this) {
      Success<S, E>(data: final data) => Success<S, F>(data),
      Failure<S, E>(error: final error) => Failure<S, F>(transform(error)),
    };
  }

  Result<T, E> flatMap<T>(Result<T, E> Function(S data) transform) {
    return switch (this) {
      Success<S, E>(data: final data) => transform(data),
      Failure<S, E>(error: final error) => Failure<T, E>(error),
    };
  }

  S getOrElse(S Function() fallback) {
    return switch (this) {
      Success<S, E>(data: final data) => data,
      Failure<S, E>() => fallback(),
    };
  }
}
