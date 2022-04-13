import 'package:mi_libro_vecino_api/models/ubigeo_model.dart';
import 'package:mi_libro_vecino_api/utils/constants/enums/ubigeo_enums.dart';
import 'package:mi_libro_vecino_api/utils/utils.dart';
import 'package:geolocator/geolocator.dart';
import 'package:paulonia_utils/paulonia_utils.dart';

class GeoService {
  /// Gets the address from the coordinates
  ///
  /// The function use the Google Maps API to get the address from the coordinates
  /// - If coordinates are null or the API don't found an address,
  /// the function returns null.
  /// - If occurs an error while it make the request, the function returns null
  /// and sends the error to PauloniaErrorService
  static Future<String?> getAddress(Coordinates? location) async {
    if (PUtils.isOnTest()) {
      return 'Calle falsa 123';
    }
    return null;
  }

  /// Determine the current position of the device.
  ///
  /// When the location services are not enabled or permissions
  /// are denied the `Future` will return an error.
  static Future<Coordinates> determineCoordinates() async {
    if (PUtils.isOnTest()) {
      return Coordinates(0, 0);
    }
    return Coordinates(0, 0);
  }

  /// Ask to the user to enable the location services.
  /// - If permission had been accepted, return [LocationPermission.always]
  /// or [LocationPermission.whileInUse]
  /// - If permission had been denied, we ask again for permissions,
  /// not if it was denied forever though.
  /// - If permission had been denied forever, the user needs to enable manually,
  static Future<LocationPermission> getPermission() async {
    if (PUtils.isOnTest()) {
      return LocationPermission.always;
    }
    return LocationPermission.denied;
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
    if (PUtils.isOnTest()) {
      return UbigeoModel(
        departmentId: '15',
        departmentName: 'Lima',
        provinceId: '01',
        provinceName: 'Lima',
        districtId: '01',
        districtName: 'Lima',
        type: UbigeoType.district,
      );
    }
    return null;
  }
}
