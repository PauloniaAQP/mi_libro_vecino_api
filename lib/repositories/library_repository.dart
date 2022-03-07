import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mi_libro_vecino_api/api_configuration.dart';
import 'package:mi_libro_vecino_api/models/library_model.dart';
import 'package:mi_libro_vecino_api/utils/constants/enums/library_enums.dart';
import 'package:mi_libro_vecino_api/utils/constants/enums/ubigeo_enums.dart';
import 'package:mi_libro_vecino_api/utils/constants/firestore/collections/library.dart';
import 'package:mi_libro_vecino_api/utils/constants/firestore/firestore_constants.dart';
import 'package:mi_libro_vecino_api/utils/constants/storage/storage_constants.dart';
import 'package:mi_libro_vecino_api/utils/utils.dart';
import 'package:paulonia_document_service/paulonia_document_service.dart';
import 'package:paulonia_repository/PauloniaRepository.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:collection';

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

  HashMap<LibraryState, DocumentSnapshot?> _librariesByState = HashMap();
  HashMap<UbigeoType, DocumentSnapshot?> _librariesByUbigeoPagination =
      HashMap();

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
      departmentId: docSnap.get(LibraryCollectionNames.DEPARTMENT_ID),
      provinceId: docSnap.get(LibraryCollectionNames.PROVINCE_ID),
      districtId: docSnap.get(LibraryCollectionNames.DISTRICT_ID),
      website: docSnap.data()![LibraryCollectionNames.WEBSITE],
      gsUrl: _getBigGsUrl(docSnap.id, photoVersion),
      description: docSnap.get(LibraryCollectionNames.DESCRIPTION),
    );
  }

  /// Create a library and returns its
  Future<LibraryModel?> createLibrary({
    required String userId,
    required String name,
    required LibraryType type,
    required TimeOfDay openingHour,
    required TimeOfDay closingHour,
    required String address,
    required Coordinates location,
    required List<String> services,
    required List<String> tags,
    PickedFile? photo,
    required List<String> searchKeys,
    required String departmentId,
    required String provinceId,
    required String districtId,
    String? website,
    required String description,
  }) async {
    int photoVersion = -1;
    DocumentReference docRef = _collectionReference.doc();
    if (photo != null) {
      photoVersion++;

      /// TODO: It must be tested
      bool response = await ApiUtils.uploadFile(
          docRef.id, photoVersion, photo, _storageReference);
      if (!response) photoVersion--;
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
      description: description,
    );
    data[LibraryCollectionNames.CREATED] = FieldValue.serverTimestamp();
    await docRef.set(data);
    DocumentSnapshot? docSnap = await PauloniaDocumentService.getDoc(
        _collectionReference.doc(docRef.id), false);
    if (docSnap == null) return null;
    LibraryModel library = getFromDocSnap(docSnap);
    addInRepository([library]);
    return library;
  }

  /// Create a library in batch and returns it
  Future<WriteBatch> createLibraryInBatch({
    required WriteBatch batch,
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
    required String departmentId,
    required String provinceId,
    required String districtId,
    String? website,
    required String description,
  }) async {
    DocumentReference docRef = _collectionReference.doc();
    int photoVersion = -1;
    if (photo != null) {
      photoVersion++;

      /// TODO: It should be tested
      bool response = await ApiUtils.uploadFile(
          docRef.id, photoVersion, photo, _storageReference);
      if (!response) photoVersion--;
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
      description: description,
    );
    data[LibraryCollectionNames.CREATED] = FieldValue.serverTimestamp();
    batch.set(docRef, data);
    LibraryModel library = LibraryModel(
      id: docRef.id,
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
      gsUrl: _getBigGsUrl(docRef.id, photoVersion),
      description: description,
    );
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
    String? description,
  }) async {
    Map<String, dynamic> data = {};
    if (photo != null) {
      bool response = await ApiUtils.uploadFile(
          library.id, library.photoVersion, photo, _storageReference);
      if (response) {
        library.photoVersion++;
        library.gsUrl = _getBigGsUrl(library.id, library.photoVersion);
        data[LibraryCollectionNames.PHOTO_VERSION] = library.photoVersion;
      }
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
    if (description != null) {
      library.description = description;
      data[LibraryCollectionNames.DESCRIPTION] = description;
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
    String? description,
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
    if (description != null) {
      data[LibraryCollectionNames.DESCRIPTION] = description;
    }
    return data;
  }

  /// Parse a query stream to a list of libraries stream
  Stream<List<LibraryModel>> parseLibraries(
      Stream<QuerySnapshot> queryRes) async* {
    await for (QuerySnapshot query in queryRes) {
      List<LibraryModel> libraries = await getFromDocSnapList(query.docs);
      addInRepository(libraries);
      yield libraries;
    }
  }

  /// This function returns a stream of [LibraryModel]s.
  /// It's only for admin use.
  ///
  /// Set [resetPagination] to true to reset the pagination
  /// Set [limit] to the number of libraries to be returned per page
  /// Set [cache] to true to get the data from cache
  Stream<List<LibraryModel>> getPendingLibraries(
      {bool cache = false, int limit = 7, bool resetPagination = false}) {
    if (resetPagination) {
      _librariesByState[LibraryState.inReview] = null;
    }
    Query query = _collectionReference.where(LibraryCollectionNames.STATE,
        isEqualTo: LibraryState.inReview.index);
    query = query.orderBy(LibraryCollectionNames.CREATED, descending: true);
    query = query.limit(limit);
    return parseLibraries(PauloniaDocumentService.getStreamByQuery(query));
  }

  /// Get a list of accepted libraries
  ///
  /// Set [resetPagination] to true to reset the pagination
  /// Set [limit] to the number of libraries to be returned per page
  /// Set [cache] to true to get the data from cache
  Future<List<LibraryModel>> getAcceptedLibraries(
      {bool cache = false, int limit = 7, bool resetPagination = false}) async {
    Query query = _collectionReference.where(LibraryCollectionNames.STATE,
        isEqualTo: LibraryState.accepted.index);
    if (resetPagination) {
      _librariesByState[LibraryState.accepted] = null;
    }
    query = query.orderBy(LibraryCollectionNames.NAME);
    query = query.limit(limit);
    if (_librariesByState[LibraryState.accepted] != null) {
      query =
          query.startAfterDocument(_librariesByState[LibraryState.accepted]!);
    }
    QuerySnapshot? queryRes =
        await PauloniaDocumentService.runQuery(query, cache);
    if (queryRes == null) return [];
    print(queryRes.docs.last.data());
    _librariesByState[LibraryState.accepted] = queryRes.docs.last;
    List<LibraryModel> res = await getFromDocSnapList(queryRes.docs);
    addInRepository(res);
    return res;
  }

  /// Get a list of LibraryModel by [ubigeoCode] and [type]
  ///
  /// Set [resetPagination] to true to reset the pagination
  /// Set [limit] to the number of libraries to be returned per page
  /// Set [cache] to true to get the data from cache
  Future<List<LibraryModel>> getLibrariesByUbigeo(
    UbigeoType type,
    String ubigeoCode, {
    bool cache = false,
    int limit = 7,
    bool resetPagination = false,
  }) async {
    Query query;
    if (resetPagination) {
      _librariesByUbigeoPagination[type] = null;
    }
    switch (type) {
      case UbigeoType.department:
        query = _collectionReference.where(LibraryCollectionNames.DEPARTMENT_ID,
            isEqualTo: ubigeoCode);
        break;
      case UbigeoType.province:
        query = _collectionReference.where(LibraryCollectionNames.PROVINCE_ID,
            isEqualTo: ubigeoCode);
        break;
      case UbigeoType.district:
        query = _collectionReference.where(LibraryCollectionNames.DISTRICT_ID,
            isEqualTo: ubigeoCode);
        break;
    }
    query = query.orderBy(LibraryCollectionNames.NAME);
    query = query.limit(limit);
    if (_librariesByUbigeoPagination[type] != null) {
      query = query.startAfterDocument(_librariesByUbigeoPagination[type]!);
    }
    QuerySnapshot? queryRes =
        await PauloniaDocumentService.runQuery(query, cache);
    if (queryRes == null) return [];
    _librariesByUbigeoPagination[type] = queryRes.docs.last;
    List<LibraryModel> res = await getFromDocSnapList(queryRes.docs);
    addInRepository(res);
    return res;
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
