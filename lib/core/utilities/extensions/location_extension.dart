import 'package:geocoding/geocoding.dart';

extension PlacemarkX on Placemark {
  String getAddress([
    List<PlacemarkPart> parts = const [
      .administrativeArea,
      .subAdministrativeArea,
      .street,
      .country,
    ],
  ]) {
    final values = <String>[];

    for (final part in parts) {
      final value = part.getValue(this);

      if (value != null) {
        final trimmed = value.trim();
        if (trimmed.isNotEmpty) {
          values.add(trimmed);
        }
      }
    }

    if (values.isEmpty) return "-";

    return values.join(', ');
  }
}

enum PlacemarkPart {
  name,
  street,
  isoCountryCode,
  country,
  postalCode,
  administrativeArea,
  subAdministrativeArea,
  locality,
  subLocality,
  thoroughfare,
  subThoroughfare,
}

extension PlacemarkPartX on PlacemarkPart {
  String? getValue(Placemark p) => switch (this) {
    .name => p.name,
    .street => p.street,
    .isoCountryCode => p.isoCountryCode,
    .country => p.country,
    .postalCode => p.postalCode,
    .administrativeArea => p.administrativeArea,
    .subAdministrativeArea => p.subAdministrativeArea,
    .locality => p.locality,
    .subLocality => p.subLocality,
    .thoroughfare => p.thoroughfare,
    .subThoroughfare => p.subThoroughfare,
  };
}
