import 'dart:collection';

import 'package:mi_libro_vecino_api/models/ubigeo_model.dart';
import 'package:mi_libro_vecino_api/utils/constants/enums/ubigeo_enums.dart';
import 'package:mi_libro_vecino_api/utils/constants/strings/ubigeo_strings.dart';
import 'package:mi_libro_vecino_api/utils/utils.dart';

class UbigeoService {
  /// Call this funcion only once at the main file of the application.
  /// This function loads the json files of codes of locations (ubigeos).
  Future<void> init() async {
    Map<String, dynamic> distMap =
        await ApiUtils.parseAssetToJson(UbigeoStrings.districtJson);
    Map<String, dynamic> deparMap =
        await ApiUtils.parseAssetToJson(UbigeoStrings.departmentsJson);
    Map<String, dynamic> provMap =
        await ApiUtils.parseAssetToJson(UbigeoStrings.provincesJson);
    _departments = HashMap();
    _provinces = HashMap();
    _districts = HashMap();
    deparMap.forEach((key, value) {
      _departments[key] = UbigeoModel(
        departmentId: key,
        departmentName: value[UbigeoStrings.name],
        type: UbigeoType.department,
      );
    });
    provMap.forEach((key, value) {
      _provinces[key] = UbigeoModel(
        provinceId: key,
        provinceName: value[UbigeoStrings.name],
        departmentId: value[UbigeoStrings.departmentId],
        departmentName:
            _departments[value[UbigeoStrings.departmentId]]?.departmentName ??
                '',
        type: UbigeoType.province,
      );
    });
    distMap.forEach((key, value) {
      _districts[key] = UbigeoModel(
        districtId: key,
        districtName: value[UbigeoStrings.name],
        departmentId: value[UbigeoStrings.departmentId],
        departmentName:
            _departments[value[UbigeoStrings.departmentId]]?.departmentName ??
                '',
        provinceId: value[UbigeoStrings.provinceId],
        provinceName:
            _provinces[value[UbigeoStrings.provinceId]]?.provinceName ?? '',
        type: UbigeoType.district,
      );
    });
  }

  /// This function list the map of locations by the [type] of ubigeo.
  /// Use the [code] of a parent location to list only the locations inside the
  /// [code] of ubigeo.
  List<UbigeoModel> getUbigeoListByType(UbigeoType type, {String? code}) {
    switch (type) {
      case UbigeoType.department:
        if (code == null) return _departments.values.toList();
        return _departments.values
            .where((ubigeo) =>
                ubigeo.departmentId.substring(0, code.length).contains(code, 0))
            .toList();
      case UbigeoType.province:
        if (code == null) return _provinces.values.toList();
        return _provinces.values
            .where((ubigeo) =>
                ubigeo.provinceId!.substring(0, code.length).contains(code, 0))
            .toList();
      case UbigeoType.district:
        if (code == null) return _districts.values.toList();
        return _districts.values
            .where((ubigeo) =>
                ubigeo.districtId!.substring(0, code.length).contains(code, 0))
            .toList();
      default:
        return [];
    }
  }

  /// Gets the department name by the [code] of ubigeo.
  /// Returns null if the [code] is not found.
  String? getDepartmentNameByCode(String code) =>
      _departments[code]?.departmentName;

  /// Gets the province name by the [code] of ubigeo.
  /// Returns null if the [code] is not found.
  String? getProvinceNameByCode(String code) => _provinces[code]?.provinceName;

  /// Gets the district name by the [code] of ubigeo.
  /// Returns null if the [code] is not found.
  String? getDistrictNameByCode(String code) => _districts[code]?.districtName;

  /// Gets the ubigeo model by the name of place.
  ///
  /// In order to avoid repetitions, we use hash maps to store the ubigeos.
  List<UbigeoModel> searchUbigeo(String searchKey) {
    searchKey = searchKey.toLowerCase();
    HashMap<String, UbigeoModel> searchResults = HashMap();
    _districts.forEach((key, value) {
      if (value.districtName!.toLowerCase().contains(searchKey)) {
        searchResults[key] = value;
      } else if (value.provinceName!.toLowerCase().contains(searchKey)) {
        searchResults[value.provinceId!] = _provinces[value.provinceId]!;
      } else if (value.departmentName.toLowerCase().contains(searchKey)) {
        searchResults[value.departmentId] = _departments[value.departmentId]!;
      }
    });
    return searchResults.values.toList();
  }

  late HashMap<String, UbigeoModel> _districts;
  late HashMap<String, UbigeoModel> _provinces;
  late HashMap<String, UbigeoModel> _departments;
}
