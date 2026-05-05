import 'package:equatable/equatable.dart';
import 'package:template_app/core/errors/exceptions/parsing_exception.dart';

import 'package:template_app/core/services/region/models/region.dart';
import 'package:template_app/core/services/region/models/region_meta.dart';

class RegionResponse extends Equatable {
  final List<Region> data;
  final RegionMeta meta;

  const RegionResponse({required this.data, required this.meta});

  @override
  List<Object> get props => [data, meta];

  RegionResponse copyWith({List<Region>? data, RegionMeta? meta}) {
    return RegionResponse(data: data ?? this.data, meta: meta ?? this.meta);
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'data': data.map((x) => x.toJson()).toList(),
      'meta': meta.toJson(),
    };
  }

  factory RegionResponse.fromJson(Map<String, dynamic> map) {
    try {
      return RegionResponse(
        data: (map['data'] as List).map((e) => Region.fromJson(e)).toList(),
        meta: RegionMeta.fromJson(map['meta']),
      );
    } catch (e, st) {
      throw ParsingException(original: e, stackTrace: st);
    }
  }
}
