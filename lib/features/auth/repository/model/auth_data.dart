import 'package:equatable/equatable.dart';
import 'package:template_app/core/errors/exceptions/parsing_exception.dart';

class AuthData extends Equatable {
  final String uid;
  final String email;
  final String accessToken;
  final String refreshToken;

  const AuthData({
    required this.uid,
    required this.email,
    required this.accessToken,
    required this.refreshToken,
  });

  @override
  List<Object> get props => [uid, email, accessToken, refreshToken];

  AuthData copyWith({
    String? uid,
    String? email,
    String? accessToken,
    String? refreshToken,
  }) {
    return AuthData(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'uid': uid,
      'email': email,
      'access_token': accessToken,
      'refresh_token': refreshToken,
    };
  }

  factory AuthData.fromJson(Map<String, dynamic> map) {
    try {
      return AuthData(
        uid: map['uid'] as String,
        email: map['email'] as String,
        accessToken: map['access_token'] as String,
        refreshToken: map['refresh_token'] as String,
      );
    } catch (e, st) {
      throw ParsingException(original: e, stackTrace: st);
    }
  }
}
