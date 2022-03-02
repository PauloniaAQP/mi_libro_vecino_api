import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mi_libro_vecino_api/api_configuration.dart';
import 'package:mi_libro_vecino_api/models/library_model.dart';
import 'package:mi_libro_vecino_api/utils/constants/enums/library_enums.dart';
import 'package:mi_libro_vecino_api/utils/constants/firestore/collections/library.dart';
import 'package:mi_libro_vecino_api/utils/constants/firestore/firestore_constants.dart';
import 'package:mi_libro_vecino_api/utils/constants/storage/storage_constants.dart';
import 'package:mi_libro_vecino_api/utils/utils.dart';
import 'package:paulonia_document_service/paulonia_document_service.dart';
import 'package:paulonia_repository/PauloniaRepository.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class LibraryRepository extends PauloniaRepository<String, LibraryModel> {
  @override
  CollectionReference get collectionReference => _collectionReference;

  final CollectionReference _collectionReference = FirebaseFirestore.instance
      .collection(FirestoreCollections.libraryCollection);

  final Reference _storageReference = FirebaseStorage.instance
      .ref()
      .child(StorageConstants.entity_directory_name)
      .child(StorageConstants.images_directory_name)
      .child(StorageConstants.library_directory_name);

  /// Gets a [LibraryModel] from a DocumentSnapshot
  /// openHour and closeHour are converted from String to TimeOfDay directly
  @override
  LibraryModel getFromDocSnap(DocumentSnapshot docSnap) {
    int photoVersion =
        docSnap.data()?[LibraryCollectionNames.PHOTO_VERSION] ?? -1;
    LibraryType type =
        LibraryType.values[docSnap.get(LibraryCollectionNames.TYPE)];
    TimeOfDay openingHour = ApiUtils.timeOfDayFromString(
        docSnap.get(LibraryCollectionNames.OPENING_HOUR));
    TimeOfDay closingHour = ApiUtils.timeOfDayFromString(
        docSnap.get(LibraryCollectionNames.CLOSING_HOUR));
    Coordinates location =
        Coordinates.fromGeopoint(docSnap.get(LibraryCollectionNames.LOCATION));
    List<String> services =
        List.from(docSnap.get(LibraryCollectionNames.SERVICES));
    List<String> tags = List.from(docSnap.get(LibraryCollectionNames.TAGS));
    LibraryState state =
        LibraryState.values[docSnap.get(LibraryCollectionNames.STATE)];
    List<String> searchKeys =
        List.from(docSnap.get(LibraryCollectionNames.SEARCH_KEYS));

    return LibraryModel(
      id: docSnap.id,
      created: docSnap.get(LibraryCollectionNames.CREATED).toDate(),
      ownerId: docSnap.get(LibraryCollectionNames.OWNER_ID),
      name: docSnap.get(LibraryCollectionNames.NAME),
      openingHour: openingHour,
      closingHour: closingHour,
      type: type,
      address: docSnap.get(LibraryCollectionNames.ADDRESS),
      location: location,
      services: services,
      tags: tags,
      photoVersion: photoVersion,
      state: state,
      searchKeys: searchKeys,
      departmentId: docSnap.data()?[LibraryCollectionNames.DEPARTMENT_ID],
      provinceId: docSnap.data()?[LibraryCollectionNames.PROVINCE_ID],
      districtId: docSnap.data()?[LibraryCollectionNames.DISTRICT_ID],
      website: docSnap.data()?[LibraryCollectionNames.WEBSITE],
      gsUrl: _getBigGsUrl(docSnap.id, photoVersion),
    );
  }

  /// Create a library and returns its
  Future<LibraryModel?> createLibrary({
    required String id,
    required String userId,
    required String name,
    required LibraryType type,
    required TimeOfDay openingHour,
    required TimeOfDay closingHour,
    required String address,
    required Coordinates location,
    required List<String> services,
    required List<String>? tags,
    PickedFile? photo,
    List<String>? searchKeys,
    String? departmentId,
    String? provinceId,
    String? districtId,
    String? website,
  }) async {
    int photoVersion = -1;
    if (photo != null) {
      photoVersion++;

      /// TODO: It must be tested
      await ApiUtils.uploadFile(id, photoVersion, photo, _storageReference);
    }
    Map<String, dynamic> data = _getLibraryMap(
      userId: userId,
      name: name,
      type: type,
      openingHour: openingHour,
      closingHour: closingHour,
      address: address,
      location: location,
      services: services,
      tags: tags,
      photoVersion: photoVersion,
      searchKeys: searchKeys,
      departmentId: departmentId,
      provinceId: provinceId,
      districtId: districtId,
      website: website,
      state: LibraryState.inReview,
    );
    data[LibraryCollectionNames.CREATED] = FieldValue.serverTimestamp();
    await _collectionReference.doc(id).set(data);
    DocumentSnapshot? docSnap = await PauloniaDocumentService.getDoc(
        _collectionReference.doc(id), false);
    if (docSnap == null) return null;
    LibraryModel library = getFromDocSnap(docSnap);
    addInRepository([library]);
    return library;
  }

  /// Create a library in batch and returns it
  WriteBatch createLibraryInBatch({
    required WriteBatch batch,
    required String id,
    required String ownerId,
    required String name,
    required LibraryType type,
    required TimeOfDay openingHour,
    required TimeOfDay closingHour,
    required String address,
    required Coordinates location,
    required List<String> services,
    required List<String>? tags,
    PickedFile? photo,
    List<String>? searchKeys,
    String? departmentId,
    String? provinceId,
    String? districtId,
    String? website,
  }) {
    int photoVersion = -1;
    if (photo != null) {
      photoVersion++;

      /// TODO: It should be tested
      ApiUtils.uploadFile(id, photoVersion, photo, _storageReference);
    }
    Map<String, dynamic> data = _getLibraryMap(
      userId: ownerId,
      name: name,
      type: type,
      openingHour: openingHour,
      closingHour: closingHour,
      address: address,
      location: location,
      services: services,
      tags: tags,
      photoVersion: photoVersion,
      searchKeys: searchKeys,
      departmentId: departmentId,
      provinceId: provinceId,
      districtId: districtId,
      website: website,
      state: LibraryState.inReview,
    );
    data[LibraryCollectionNames.CREATED] = FieldValue.serverTimestamp();
    batch.set(_collectionReference.doc(id), data);
    LibraryModel library = LibraryModel(
        id: id,
        created: data[LibraryCollectionNames.CREATED].toDate(),
        ownerId: ownerId,
        name: name,
        openingHour: openingHour,
        closingHour: closingHour,
        type: type,
        address: address,
        location: location,
        services: services,
        tags: tags ?? [],
        photoVersion: photoVersion,
        state: LibraryState.inReview,
        searchKeys: searchKeys ?? [],
        departmentId: departmentId,
        provinceId: provinceId,
        districtId: districtId,
        gsUrl: _getBigGsUrl(id, photoVersion));
    addInRepository([library]);
    return batch;
  }

  /// Gets a library from an ownerId
  Future<LibraryModel?> getLibraryByOwnerId(String ownerId) async {
    QuerySnapshot? querySnap = await _collectionReference
        .where(LibraryCollectionNames.OWNER_ID, isEqualTo: ownerId)
        .get();
    if (querySnap.docs.isEmpty) return null;
    DocumentSnapshot? docSnap = querySnap.docs.first;
    LibraryModel library = getFromDocSnap(docSnap);
    addInRepository([library]);
    return library;
  }

  /// Remove a library from the repository using its id
  Future<void> removeLibrary(String id) async {
    await _collectionReference.doc(id).delete();
    deleteInRepository([id]);
  }

  /// Update a library in the repository
  Future<LibraryModel?> updateLibrary(
    LibraryModel library, {
    String? ownerId,
    String? name,
    LibraryType? type,
    TimeOfDay? openingHour,
    TimeOfDay? closingHour,
    String? address,
    Coordinates? location,
    List<String>? services,
    List<String>? tags,
    PickedFile? photo,
    List<String>? searchKeys,
    String? departmentId,
    String? provinceId,
    String? districtId,
    String? website,
  }) async {
    Map<String, dynamic> data = {};
    int photoVersion = library.photoVersion;
    if (photo != null) {
      photoVersion++;
      await ApiUtils.uploadFile(
          library.id, photoVersion, photo, _storageReference);
      library.photoVersion = photoVersion;
      library.gsUrl = _getBigGsUrl(library.id, photoVersion);
      data[LibraryCollectionNames.PHOTO_VERSION] = photoVersion;
    }
    if (ownerId != null) {
      library.ownerId = ownerId;
      data[LibraryCollectionNames.OWNER_ID] = ownerId;
    }
    if (name != null) {
      library.name = name;
      data[LibraryCollectionNames.NAME] = name;
    }
    if (type != null) {
      library.type = type;
      data[LibraryCollectionNames.TYPE] = type.index;
    }
    if (openingHour != null) {
      library.openingHour = openingHour;
      data[LibraryCollectionNames.OPENING_HOUR] =
          ApiUtils.timeOfDayToString(openingHour);
    }
    if (closingHour != null) {
      library.closingHour = closingHour;
      data[LibraryCollectionNames.CLOSING_HOUR] =
          ApiUtils.timeOfDayToString(closingHour);
    }
    if (address != null) {
      library.address = address;
      data[LibraryCollectionNames.ADDRESS] = address;
    }
    if (location != null) {
      library.location = location;
      data[LibraryCollectionNames.LOCATION] = location.toGeoPoint();
    }
    if (services != null) {
      library.services = services;
      data[LibraryCollectionNames.SERVICES] = services;
    }
    if (tags != null) {
      library.tags = tags;
      data[LibraryCollectionNames.TAGS] = tags;
    }
    if (searchKeys != null) {
      library.searchKeys = searchKeys;
      data[LibraryCollectionNames.SEARCH_KEYS] = searchKeys;
    }
    if (departmentId != null) {
      library.departmentId = departmentId;
      data[LibraryCollectionNames.DEPARTMENT_ID] = departmentId;
    }
    if (provinceId != null) {
      library.provinceId = provinceId;
      data[LibraryCollectionNames.PROVINCE_ID] = provinceId;
    }
    if (districtId != null) {
      library.districtId = districtId;
      data[LibraryCollectionNames.DISTRICT_ID] = districtId;
    }
    if (website != null) {
      library.website = website;
      data[LibraryCollectionNames.WEBSITE] = website;
    }
    _collectionReference.doc(library.id).update(data);
    addInRepository([library]);
    return library;
  }

  Map<String, dynamic> _getLibraryMap({
    String? userId,
    String? name,
    LibraryType? type,
    TimeOfDay? openingHour,
    TimeOfDay? closingHour,
    String? address,
    Coordinates? location,
    List<String>? services,
    List<String>? tags,
    int? photoVersion = -1,
    List<String>? searchKeys,
    String? departmentId,
    String? provinceId,
    String? districtId,
    String? website,
    LibraryState? state,
  }) {
    Map<String, dynamic> data = {};
    if (userId != null) data[LibraryCollectionNames.OWNER_ID] = userId;
    if (name != null) data[LibraryCollectionNames.NAME] = name;
    if (type != null) data[LibraryCollectionNames.TYPE] = type.index;
    if (state != null) data[LibraryCollectionNames.STATE] = state.index;
    if (openingHour != null) {
      data[LibraryCollectionNames.OPENING_HOUR] =
          ApiUtils.timeOfDayToString(openingHour);
    }
    if (closingHour != null) {
      data[LibraryCollectionNames.CLOSING_HOUR] =
          ApiUtils.timeOfDayToString(closingHour);
    }
    if (address != null) data[LibraryCollectionNames.ADDRESS] = address;
    if (location != null) {
      data[LibraryCollectionNames.LOCATION] = location.toGeoPoint();
    }
    if (services != null) data[LibraryCollectionNames.SERVICES] = services;
    if (tags != null) data[LibraryCollectionNames.TAGS] = tags;
    if (searchKeys != null) {
      data[LibraryCollectionNames.SEARCH_KEYS] = searchKeys;
    }
    if (photoVersion != null) {
      data[LibraryCollectionNames.PHOTO_VERSION] = photoVersion;
    }
    if (website != null) data[LibraryCollectionNames.WEBSITE] = website;
    if (departmentId != null) {
      data[LibraryCollectionNames.DEPARTMENT_ID] = departmentId;
    }
    if (provinceId != null) {
      data[LibraryCollectionNames.PROVINCE_ID] = provinceId;
    }
    if (districtId != null) {
      data[LibraryCollectionNames.DISTRICT_ID] = districtId;
    }
    return data;
  }

  /// Gets the gsUrl for the big picture
  String _getBigGsUrl(String userId, int photoVersion) {
    if (photoVersion > 0) {
      return ApiConfiguration.gsBucketUrl +
          StorageConstants.images_directory_name +
          '/' +
          StorageConstants.library_directory_name +
          '/' +
          userId +
          '/' +
          StorageConstants.big_prefix +
          photoVersion.toString() +
          StorageConstants.jpg_extension;
    }
    return ApiConfiguration.gsBucketUrl +
        StorageConstants.images_directory_name +
        '/' +
        StorageConstants.default_directory_name +
        '/' +
        StorageConstants.default_library_profile +
        StorageConstants.jpg_extension;
  }
}
