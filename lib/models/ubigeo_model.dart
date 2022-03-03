import 'package:mi_libro_vecino_api/utils/constants/enums/ubigeo_enums.dart';

/// Ubigeo model class must have at least [departmentId]
class UbigeoModel {
  String departmentId;
  String departmentName;
  String? provinceId;
  String? provinceName;
  String? districtId;
  String? districtName;
  UbigeoType type;

  UbigeoModel({
    required this.departmentId,
    required this.departmentName,
    required this.type,
    this.provinceId,
    this.provinceName,
    this.districtId,
    this.districtName,
  });

  @override
  String toString() {
    return '''UbigeoModel{
      type: $type,
      departmentId: $departmentId,
      departmentName: $departmentName,
      provinceId: $provinceId,
      provinceName: $provinceName,
      districtId: $districtId,
      districName: $districtName }''';
  }
}
