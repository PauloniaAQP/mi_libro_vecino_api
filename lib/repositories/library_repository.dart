import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mi_libro_vecino_api/api_configuration.dart';
import 'package:mi_libro_vecino_api/models/library_model.dart';
import 'package:mi_libro_vecino_api/services/auth_service.dart';
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
import 'package:geoflutterfire/geoflutterfire.dart' as geofire;

class LibraryRepository extends PauloniaRepository<String, LibraryModel> {
  @override
  CollectionReference get collectionReference => _collectionReference;

  final CollectionReference _collectionReference = FirebaseFirestore.instance
      .collection(FirestoreCollections.libraryCollection);

  final Reference _storageReference = FirebaseStorage.instance
      .ref()
      .child(StorageConstants.imagesDirectoryName)
      .child(StorageConstants.libraryDirectoryName);

  final HashMap<LibraryState, DocumentSnapshot?> _librariesByState = HashMap();
  final HashMap<UbigeoType, DocumentSnapshot?> _librariesByUbigeoPagination =
      HashMap();

  final _geoFire = geofire.Geoflutterfire();

  /// Gets a [LibraryModel] from a DocumentSnapshot
  /// openHour and closeHour are converted from String to TimeOfDay directly
  @override
  LibraryModel getFromDocSnap(DocumentSnapshot docSnap) {
    int photoVersion =
        docSnap.data()?[LibraryCollectionNames.photoVersion] ?? -1;
    LibraryType type =
        LibraryType.values[docSnap.get(LibraryCollectionNames.type)];
    TimeOfDay openingHour = ApiUtils.timeOfDayFromString(
        docSnap.get(LibraryCollectionNames.openingHour));
    TimeOfDay closingHour = ApiUtils.timeOfDayFromString(
        docSnap.get(LibraryCollectionNames.closingHour));
    Coordinates location =
        Coordinates.fromGeopoint(docSnap.get(LibraryCollectionNames.location));
    List<String> services =
        List.from(docSnap.get(LibraryCollectionNames.services));
    List<String> tags = List.from(docSnap.get(LibraryCollectionNames.tags));
    LibraryState state =
        LibraryState.values[docSnap.get(LibraryCollectionNames.state)];
    List<String> searchKeys =
        List.from(docSnap.get(LibraryCollectionNames.searchKeys));
    return LibraryModel(
      id: docSnap.id,
      created: docSnap.get(LibraryCollectionNames.created).toDate(),
      ownerId: docSnap.get(LibraryCollectionNames.ownerId),
      name: docSnap.get(LibraryCollectionNames.name),
      openingHour: openingHour,
      closingHour: closingHour,
      type: type,
      address: docSnap.get(LibraryCollectionNames.address),
      location: location,
      services: services,
      tags: tags,
      photoVersion: photoVersion,
      state: state,
      searchKeys: searchKeys,
      departmentId: docSnap.get(LibraryCollectionNames.departmentId),
      provinceId: docSnap.get(LibraryCollectionNames.provinceId),
      districtId: docSnap.get(LibraryCollectionNames.districtId),
      website: docSnap.data()![LibraryCollectionNames.website],
      gsUrl: _getBigGsUrl(docSnap.id, photoVersion),
      description: docSnap.get(LibraryCollectionNames.description),
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
    XFile? photo,
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

      bool response = await ApiUtils.uploadFile(docRef.id, photoVersion, photo,
          StorageConstants.bigPrefix, _storageReference);
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
    data[LibraryCollectionNames.created] = FieldValue.serverTimestamp();
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
    XFile? photo,
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

      bool response = await ApiUtils.uploadFile(docRef.id, photoVersion, photo,
          StorageConstants.bigPrefix, _storageReference);
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
    data[LibraryCollectionNames.created] = FieldValue.serverTimestamp();
    batch.set(docRef, data);
    LibraryModel library = LibraryModel(
      id: docRef.id,
      created: data[LibraryCollectionNames.created].toDate(),
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
        .where(LibraryCollectionNames.ownerId, isEqualTo: ownerId)
        .get();
    if (querySnap.docs.isEmpty) return null;
    DocumentSnapshot? docSnap = querySnap.docs.first;
    LibraryModel library = getFromDocSnap(docSnap);
    addInRepository([library]);
    return library;
  }

  /// Gets a library from an id
  ///
  /// If [cache] is true but it is not in the repository, it will be added
  Future<LibraryModel?> getLibraryById(String id, {bool cache = false}) async {
    if (cache && repositoryMap[id] != null) return repositoryMap[id];
    DocumentSnapshot? docSnap = await PauloniaDocumentService.getDoc(
        _collectionReference.doc(id), cache);
    if (docSnap == null) return null;
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
    XFile? photo,
    List<String>? searchKeys,
    String? departmentId,
    String? provinceId,
    String? districtId,
    String? website,
    String? description,
    LibraryState? state,
  }) async {
    Map<String, dynamic> data = {};
    if (photo != null) {
      bool response = await ApiUtils.uploadFile(
          library.id,
          library.photoVersion,
          photo,
          StorageConstants.bigPrefix,
          _storageReference);
      if (response) {
        library.photoVersion++;
        library.gsUrl = _getBigGsUrl(library.id, library.photoVersion);
        data[LibraryCollectionNames.photoVersion] = library.photoVersion;
      }
    }
    if (ownerId != null) {
      library.ownerId = ownerId;
      data[LibraryCollectionNames.ownerId] = ownerId;
    }
    if (name != null) {
      library.name = name;
      data[LibraryCollectionNames.name] = name;
    }
    if (type != null) {
      library.type = type;
      data[LibraryCollectionNames.type] = type.index;
    }
    if (openingHour != null) {
      library.openingHour = openingHour;
      data[LibraryCollectionNames.openingHour] =
          ApiUtils.timeOfDayToString(openingHour);
    }
    if (closingHour != null) {
      library.closingHour = closingHour;
      data[LibraryCollectionNames.closingHour] =
          ApiUtils.timeOfDayToString(closingHour);
    }
    if (address != null) {
      library.address = address;
      data[LibraryCollectionNames.address] = address;
    }
    if (location != null) {
      library.location = location;
      data[LibraryCollectionNames.location] = location.toGeoPoint();
    }
    if (services != null) {
      library.services = services;
      data[LibraryCollectionNames.services] = services;
    }
    if (tags != null) {
      library.tags = tags;
      data[LibraryCollectionNames.tags] = tags;
    }
    if (searchKeys != null) {
      library.searchKeys = searchKeys;
      data[LibraryCollectionNames.searchKeys] = searchKeys;
    }
    if (departmentId != null) {
      library.departmentId = departmentId;
      data[LibraryCollectionNames.departmentId] = departmentId;
    }
    if (provinceId != null) {
      library.provinceId = provinceId;
      data[LibraryCollectionNames.provinceId] = provinceId;
    }
    if (districtId != null) {
      library.districtId = districtId;
      data[LibraryCollectionNames.districtId] = districtId;
    }
    if (website != null) {
      library.website = website;
      data[LibraryCollectionNames.website] = website;
    }
    if (description != null) {
      library.description = description;
      data[LibraryCollectionNames.description] = description;
    }
    if (state != null) {
      library.state = state;
      data[LibraryCollectionNames.state] = state.index;
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
    if (userId != null) data[LibraryCollectionNames.ownerId] = userId;
    if (name != null) data[LibraryCollectionNames.name] = name;
    if (type != null) data[LibraryCollectionNames.type] = type.index;
    if (state != null) data[LibraryCollectionNames.state] = state.index;
    if (openingHour != null) {
      data[LibraryCollectionNames.openingHour] =
          ApiUtils.timeOfDayToString(openingHour);
    }
    if (closingHour != null) {
      data[LibraryCollectionNames.closingHour] =
          ApiUtils.timeOfDayToString(closingHour);
    }
    if (address != null) data[LibraryCollectionNames.address] = address;
    if (location != null) {
      data[LibraryCollectionNames.location] = location.toGeoPoint();
    }
    if (services != null) data[LibraryCollectionNames.services] = services;
    if (tags != null) data[LibraryCollectionNames.tags] = tags;
    if (searchKeys != null) {
      data[LibraryCollectionNames.searchKeys] = searchKeys;
    }
    if (photoVersion != null) {
      data[LibraryCollectionNames.photoVersion] = photoVersion;
    }
    if (website != null) data[LibraryCollectionNames.website] = website;
    if (departmentId != null) {
      data[LibraryCollectionNames.departmentId] = departmentId;
    }
    if (provinceId != null) {
      data[LibraryCollectionNames.provinceId] = provinceId;
    }
    if (districtId != null) {
      data[LibraryCollectionNames.districtId] = districtId;
    }
    if (description != null) {
      data[LibraryCollectionNames.description] = description;
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

  /// Accept a library, only admin can call this function
  Future<bool> acceptLibrary(String id) async {
    final user = AuthService.currentUser;
    if (user == null) return false;
    final isAdmin = await AuthService.isAdmin(user);
    if (isAdmin == true) {
      final library = await getFromId(id);
      if (library == null) return false;
      updateLibrary(library, state: LibraryState.accepted);
      return true;
    } else {
      return false;
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
    Query query = _collectionReference.where(LibraryCollectionNames.state,
        isEqualTo: LibraryState.inReview.index);
    query = query.orderBy(LibraryCollectionNames.created, descending: true);
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
    Query query = _collectionReference.where(LibraryCollectionNames.state,
        isEqualTo: LibraryState.accepted.index);
    if (resetPagination) {
      _librariesByState[LibraryState.accepted] = null;
    }
    query = query.orderBy(LibraryCollectionNames.name);
    query = query.limit(limit);
    if (_librariesByState[LibraryState.accepted] != null) {
      query =
          query.startAfterDocument(_librariesByState[LibraryState.accepted]!);
    }
    QuerySnapshot? queryRes =
        await PauloniaDocumentService.runQuery(query, cache);
    if (queryRes == null || queryRes.docs.isEmpty) return [];
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
        query = _collectionReference.where(LibraryCollectionNames.departmentId,
            isEqualTo: ubigeoCode);
        break;
      case UbigeoType.province:
        query = _collectionReference.where(LibraryCollectionNames.provinceId,
            isEqualTo: ubigeoCode);
        break;
      case UbigeoType.district:
        query = _collectionReference.where(LibraryCollectionNames.districtId,
            isEqualTo: ubigeoCode);
        break;
    }
    query = query.orderBy(LibraryCollectionNames.name);
    query = query.limit(limit);
    if (_librariesByUbigeoPagination[type] != null) {
      query = query.startAfterDocument(_librariesByUbigeoPagination[type]!);
    }
    QuerySnapshot? queryRes =
        await PauloniaDocumentService.runQuery(query, cache);
    if (queryRes == null || queryRes.docs.isEmpty) return [];
    _librariesByUbigeoPagination[type] = queryRes.docs.last;
    List<LibraryModel> res = await getFromDocSnapList(queryRes.docs);
    addInRepository(res);
    return res;
  }

  /// Search libraries by [searchKey]
  ///
  /// Set [cache] to true to get the data from cache
  Future<List<LibraryModel>> searchLibraries(String searchKey,
      {bool cache = false}) async {
    List<String> searchKeys = ApiUtils.preprocessWord(searchKey);
    Query query = _collectionReference
        .where(LibraryCollectionNames.state,
            isEqualTo: LibraryState.accepted.index)
        .where(LibraryCollectionNames.searchKeys, arrayContainsAny: searchKeys);
    QuerySnapshot? queryRes =
        await PauloniaDocumentService.runQuery(query, cache);
    if (queryRes == null || queryRes.docs.isEmpty) return [];
    List<LibraryModel> res = await getFromDocSnapList(queryRes.docs);
    addInRepository(res);
    return res;
  }

  /// Get a list of libraries near to [coordinates]
  ///
  /// Set [cache] to true to get the data from cache
  /// Set [radius] to the radius of the search, it's in kilometers
  Future<List<LibraryModel>> getLibrariesByLocation(Coordinates coordinates,
      {bool cache = false, double radius = 5}) async {
    Query query = _collectionReference.where(LibraryCollectionNames.state,
        isEqualTo: LibraryState.inReview.index);
    geofire.GeoFirePoint center = _geoFire.point(
        latitude: coordinates.latitude, longitude: coordinates.longitude);
    Stream<List<DocumentSnapshot>> stream = _geoFire
        .collection(collectionRef: query)
        .within(
            center: center,
            radius: radius,
            field: LibraryCollectionNames.location);
    List<DocumentSnapshot> docSnapList = await stream.first;
    if (docSnapList.isEmpty) return [];
    List<LibraryModel> libraries = await getFromDocSnapList(docSnapList);
    addInRepository(libraries);
    return libraries;
  }

  /// Gets the gsUrl for the big picture
  String _getBigGsUrl(String userId, int photoVersion) {
    if (photoVersion >= 0) {
      return ApiConfiguration.gsBucketUrl +
          StorageConstants.imagesDirectoryName +
          '/' +
          StorageConstants.libraryDirectoryName +
          '/' +
          userId +
          '/' +
          StorageConstants.bigPrefix +
          photoVersion.toString() +
          StorageConstants.jpgExtension;
    }
    return ApiConfiguration.gsBucketUrl +
        StorageConstants.imagesDirectoryName +
        '/' +
        StorageConstants.defaultDirectoryName +
        '/' +
        StorageConstants.defaultLibraryProfile +
        StorageConstants.jpgExtension;
  }
}
