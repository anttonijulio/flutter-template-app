import 'package:equatable/equatable.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:template_app/core/errors/exceptions/parsing_exception.dart';

class LocationData extends Equatable {
  final Position position;
  final Placemark? placemark;

  const LocationData({required this.position, this.placemark});

  LocationData copyWith({
    Position? position,
    Placemark? placemark,
    bool clearPlacemark = false,
  }) {
    return LocationData(
      position: position ?? this.position,
      placemark: clearPlacemark ? null : (placemark ?? this.placemark),
    );
  }

  Map<String, dynamic> toJson() {
    return {'position': position.toJson(), 'placemark': placemark?.toJson()};
  }

  factory LocationData.fromJson(Map<String, dynamic> json) {
    try {
      final pos = json['position'] as Map<String, dynamic>;
      final pm = json['placemark'] as Map<String, dynamic>?;
      return LocationData(
        position: Position.fromMap(pos),
        placemark: pm == null ? null : Placemark.fromMap(pm),
      );
    } catch (e, st) {
      throw ParsingException(original: e, stackTrace: st);
    }
  }

  @override
  List<Object?> get props => [position, placemark];
}
