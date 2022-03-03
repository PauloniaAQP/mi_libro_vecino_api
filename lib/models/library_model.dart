import 'package:flutter/material.dart';
import 'package:mi_libro_vecino_api/models/user_model.dart';
import 'package:mi_libro_vecino_api/repositories/user_repository.dart';
import 'package:mi_libro_vecino_api/utils/constants/enums/library_enums.dart';
import 'package:mi_libro_vecino_api/utils/utils.dart';
import 'package:paulonia_repository/PauloniaModel.dart';
import 'package:get/get.dart';

class LibraryModel extends PauloniaModel<String> {
  String ownerId;
  String name;
  String? website;
  TimeOfDay openingHour;
  TimeOfDay closingHour;
  LibraryType type;
  String address;
  Coordinates location;
  List<String> services;
  List<String> tags;
  int photoVersion;
  LibraryState state;
  List<String> searchKeys;
  String departmentId;
  String provinceId;
  String districtId;
  String gsUrl;
  String description;

  @override
  DateTime created;

  @override
  String id;

  LibraryModel({
    required this.id,
    required this.created,
    required this.ownerId,
    required this.name,
    this.website,
    required this.openingHour,
    required this.closingHour,
    required this.type,
    required this.address,
    required this.location,
    required this.services,
    required this.tags,
    required this.photoVersion,
    required this.state,
    required this.searchKeys,
    required this.departmentId,
    required this.provinceId,
    required this.districtId,
    required this.gsUrl,
    required this.description,
  });

  Future<UserModel?> getOwner() async {
    UserRepository userRepository = Get.find<UserRepository>();
    UserModel? owner = await userRepository.getFromId(ownerId);
    return owner;
  }

  @override
  String toString() {
    return '''LibraryModel
      ownerId: $ownerId,
      name: $name,
      website: $website,
      openingHour: $openingHour,
      closingHour: $closingHour,
      type: $type,
      address: $address,
      location: $location,
      services: $services,
      tags: $tags,
      photoVersion: $photoVersion,
      state: $state,
      searchKeys: $searchKeys,
      departmentId: $departmentId,
      provinceId: $provinceId,
      districtId: $districtId''';
  }
}
