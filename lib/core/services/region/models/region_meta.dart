import 'package:equatable/equatable.dart';
import 'package:template_app/core/errors/exceptions/parsing_exception.dart';

class RegionMeta extends Equatable {
  final int administrativeAreaLevel;
  final String updatedAt; // string date format: "2025-07-04"

  const RegionMeta({
    required this.administrativeAreaLevel,
    required this.updatedAt,
  });

  @override
  List<Object> get props => [administrativeAreaLevel, updatedAt];

  RegionMeta copyWith({int? administrativeAreaLevel, String? updatedAt}) {
    return RegionMeta(
      administrativeAreaLevel:
          administrativeAreaLevel ?? this.administrativeAreaLevel,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'administrative_area_level': administrativeAreaLevel,
      'updated_at': updatedAt,
    };
  }

  factory RegionMeta.fromJson(Map<String, dynamic> map) {
    try {
      return RegionMeta(
        administrativeAreaLevel: map['administrative_area_level'] as int,
        updatedAt: map['updated_at'] as String,
      );
    } catch (e, st) {
      throw ParsingException(original: e, stackTrace: st);
    }
  }
}
