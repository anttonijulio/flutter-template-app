import 'package:equatable/equatable.dart';
import 'package:template_app/core/errors/exceptions/parsing_exception.dart';

class Region extends Equatable {
  final String code;
  final String name;

  const Region({required this.code, required this.name});

  @override
  List<Object> get props => [code, name];

  Region copyWith({String? code, String? name}) {
    return Region(code: code ?? this.code, name: name ?? this.name);
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'code': code, 'name': name};
  }

  factory Region.fromJson(Map<String, dynamic> map) {
    try {
      return Region(code: map['code'] as String, name: map['name'] as String);
    } catch (e, st) {
      throw ParsingException(original: e, stackTrace: st);
    }
  }
}
