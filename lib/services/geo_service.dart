import 'dart:convert';

import 'package:mi_libro_vecino_api/api_configuration.dart';
import 'package:mi_libro_vecino_api/models/ubigeo_model.dart';
import 'package:mi_libro_vecino_api/utils/constants/enums/ubigeo_enums.dart';
import 'package:mi_libro_vecino_api/utils/utils.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:paulonia_error_service/paulonia_error_service.dart';

class GeoService {
  /// Open Cage Data API to parse coordinates to an Address
  ///
  /// Temporal solution for this problem on web, to get the address from coordinates
  /// I use an external API, but it's not the best solution, because it's not free (i'm not sure)
  /// it could be illegal to use it, but it's a good solution for this problem.
  /// This API returns a lot of information like postcode, address, country, etc.
  ///
  /// To use we need to pass the coordinates and the API key like this:
  /// https://api.opencagedata.com/geocode/v1/json?q=[latitud]+[longitud]&key=03c48dae07364cabb7f121d8c1519492&no_annotations=1&language=en
  ///
  /// For more information about the API, see: https://www.gps-coordinates.net/api
  static Future<String?> getAddress(Coordinates? location) async {
    if (location == null) {
      return null;
    }
    final String coordinates = '${location.latitude},${location.longitude}';

    /// q: is the coordinates (lat, lng)
    final Map<String, String> query = {
      'q': coordinates,
      'key': ApiConfiguration.geolocationAddressKey,
      'no_annotations': '1',
      'language': 'es',
    };
    http.Response response = await http.get(Uri.https(
      ApiConfiguration.geolocationAPIUrl,
      ApiConfiguration.geolocationAPIPath,
      query,
    ));
    try {
      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);
        return responseData['results'][0]['formatted'];
      } else {
        return null;
      }
    } catch (e, stacktrace) {
      PauloniaErrorService.sendError(e, stacktrace);
      return null;
    }
  }

  /// Determine the current position of the device.
  ///
  /// When the location services are not enabled or permissions
  /// are denied the `Future` will return an error.
  static Future<Coordinates> determineCoordinates() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    final position = await Geolocator.getCurrentPosition();

    return Coordinates(position.latitude, position.longitude);
  }

  /// Ask to the user to enable the location services.
  /// - If permission had been accepted, return [LocationPermission.always]
  /// or [LocationPermission.whileInUse]
  /// - If permission had been denied, we ask again for permissions,
  /// not if it was denied forever though.
  /// - If permission had been denied forever, the user needs to enable manually,
  static Future<LocationPermission> getPermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }
    return permission;
  }

  /// Get the ubigeo model from coodinates.
  /// This function make a GET request to the API to get a lof of information
  /// about the place, like the name, the country, ubigeo, etc.
  /// - If coordinates are null, return null
  /// - If coordinates don't belong to Peru, return null
  ///
  /// Example of get request: https://data.opendatasoft.com/api/records/1.0/search/?dataset=distritos-peru%40bogota-laburbano&geofilter.distance=-15.1887963%2C-71.772737%2C0
  ///
  /// It could have quota of API calls per day, I don't found more information about this.
  /// To get more information about the API, see: https://data.opendatasoft.com/
  static Future<UbigeoModel?> getUbigeoFromCoordinates(
      Coordinates? location) async {
    if (location == null) {
      return null;
    }

    /// geofilter.distance: Limit the result set to a geographical area defined
    /// by a circle center (WGS84) and radius (in meters): latitude, longitude, distance
    final Map<String, String> query = {
      'dataset': ApiConfiguration.openDataSoftDataset,
      'geofilter.distance': '${location.latitude},${location.longitude},0',
    };
    http.Response response = await http.get(Uri.https(
        ApiConfiguration.openDataSoftAPIUrl,
        ApiConfiguration.openDataSoftAPIPath,
        query));
    try {
      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);
        if (responseData['records'].isEmpty) {
          return null;
        }
        final ubigeoCode = responseData['records'][0]['fields']['ubigeo'];
        final provCode = responseData['records'][0]['fields']['idprov'];
        final depaCode = responseData['records'][0]['fields']['ccdd'];
        final provinceName = responseData['records'][0]['fields']['nombprov'];
        final departmentName = responseData['records'][0]['fields']['nombdep'];
        final districtName = responseData['records'][0]['fields']['nombdist'];
        return UbigeoModel(
          districtId: ubigeoCode,
          districtName: districtName,
          departmentId: depaCode,
          departmentName: departmentName,
          provinceId: provCode,
          provinceName: provinceName,
          type: UbigeoType.district,
        );
      } else {
        return null;
      }
    } catch (e, stacktrace) {
      PauloniaErrorService.sendError(e, stacktrace);
      return null;
    }
  }
}
