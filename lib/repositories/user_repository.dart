import 'package:mi_libro_vecino_api/api_configuration.dart';
import 'package:mi_libro_vecino_api/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mi_libro_vecino_api/utils/constants/firestore/collections/user.dart';
import 'package:mi_libro_vecino_api/utils/constants/firestore/firestore_constants.dart';
import 'package:mi_libro_vecino_api/utils/constants/storage/storage_constants.dart';
import 'package:mi_libro_vecino_api/utils/utils.dart';
import 'package:paulonia_document_service/paulonia_document_service.dart';
import 'package:paulonia_repository/PauloniaRepository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class UserRepository extends PauloniaRepository<String, UserModel> {
  @override
  CollectionReference get collectionReference => _collectionReference;

  final CollectionReference _collectionReference = FirebaseFirestore.instance
      .collection(FirestoreCollections.userCollection);

  final Reference _storageReference = FirebaseStorage.instance
      .ref()
      .child(StorageConstants.imagesDirectoryName)
      .child(StorageConstants.userDirectoryName);

  /// Get a User model from a document snapshot
  @override
  UserModel getFromDocSnap(DocumentSnapshot docSnap, {User? user}) {
    int photoVersion = docSnap.data()?[UserCollectionNames.photoVersion] ?? -1;
    return UserModel(
      photoVersion: photoVersion,
      id: docSnap.id,
      name: docSnap.get(UserCollectionNames.name),
      phone: docSnap.data()?[UserCollectionNames.phone],
      email: docSnap.get(UserCollectionNames.email),
      created: docSnap.get(UserCollectionNames.created).toDate(),
      firebaseUser: user,
      gsUrl: _getBigGsUrl(docSnap.id, photoVersion),
    );
  }

  /// Creates an user in a batch and returns it
  ///
  /// The [userId] is the uid of firebase auth
  Future<WriteBatch> createUserInBatch(
    WriteBatch batch, {
    required String userId,
    required String name,
    required String email,
    String? phone,
    XFile? photo,
  }) async {
    int photoVersion = -1;
    if (photo != null) {
      photoVersion++;

      bool response = await ApiUtils.uploadFile(
          userId, photoVersion, photo, _storageReference);
      if (!response) photoVersion--;
    }
    Map<String, dynamic> data = _getUserDataMap(
      name: name,
      email: email,
      phone: phone,
      photoVersion: photoVersion,
    );
    data[UserCollectionNames.created] = FieldValue.serverTimestamp();
    batch.set(_collectionReference.doc(userId), data);
    UserModel user = UserModel(
        id: userId,
        name: name,
        email: email,
        created: data[UserCollectionNames.created],
        phone: phone,
        photoVersion: photoVersion,
        gsUrl: _getBigGsUrl(userId, photoVersion));
    addInRepository([user]);
    return batch;
  }

  /// Creates an user
  ///
  /// The [userId] is the uid of firebase auth
  Future<UserModel?> createUser({
    required String userId,
    required String name,
    required String email,
    required String phone,
    XFile? photo,
  }) async {
    int photoVersion = -1;
    if (photo != null) {
      photoVersion++;

      bool response = await ApiUtils.uploadFile(
          userId, photoVersion, photo, _storageReference);
      if (!response) photoVersion--;
    }
    Map<String, dynamic> data = _getUserDataMap(
      name: name,
      email: email,
      phone: phone,
      photoVersion: photoVersion,
    );
    data[UserCollectionNames.created] = FieldValue.serverTimestamp();
    await _collectionReference.doc(userId).set(data);
    DocumentSnapshot? docSnap = await PauloniaDocumentService.getDoc(
        _collectionReference.doc(userId), false);
    if (docSnap == null) return null;
    UserModel user = getFromDocSnap(docSnap);
    addInRepository([user]);
    return user;
  }

  /// Gets an User from a logged FirebaseUser
  ///
  /// Set [cache] to true if you want to get the user from cache.
  Future<UserModel?> getUserFromCredentials(User user,
      {bool cache = false}) async {
    DocumentSnapshot? userDoc = await PauloniaDocumentService.getDoc(
        _collectionReference.doc(user.uid), cache);
    if (userDoc == null) return null;
    if (!userDoc.exists) return null;
    return getFromDocSnap(userDoc, user: user);
  }

  /// Updates the user
  Future<UserModel> updateUser(
    UserModel user, {
    String? name,
    String? email,
    String? phone,
    XFile? photo,
  }) async {
    Map<String, dynamic> data = {};
    if (photo != null) {
      user.photoVersion++;
      bool response = await ApiUtils.uploadFile(
          user.id, user.photoVersion, photo, _storageReference);
      if (!response) user.photoVersion--;
      data[UserCollectionNames.photoVersion] = user.photoVersion;
      user.gsUrl = _getBigGsUrl(user.id, user.photoVersion);
    }
    if (name != null) {
      user.name = name;
      data[UserCollectionNames.name] = name;
    }
    if (email != null) {
      user.email = email;
      data[UserCollectionNames.email] = email;
    }
    if (phone != null) {
      user.phone = phone;
      data[UserCollectionNames.phone] = phone;
    }
    _collectionReference.doc(user.id).update(data);
    addInRepository([user]);
    return user;
  }

  /// Remove an user from a userId
  Future<void> removeUserById(String userId) async {
    await _collectionReference.doc(userId).delete();
    deleteInRepository([userId]);
  }

  /// Gets data map of a user
  Map<String, dynamic> _getUserDataMap({
    String? name,
    String? email,
    String? phone,
    int? photoVersion,
  }) {
    Map<String, dynamic> data = {};
    if (name != null) data[UserCollectionNames.name] = name;
    if (email != null) data[UserCollectionNames.email] = email;
    if (phone != null) data[UserCollectionNames.phone] = phone;
    if (photoVersion != null) {
      data[UserCollectionNames.photoVersion] = photoVersion;
    }
    return data;
  }

  /// Gets the gsUrl for the big picture
  String _getBigGsUrl(String userId, int photoVersion) {
    if (photoVersion >= 0) {
      return ApiConfiguration.gsBucketUrl +
          StorageConstants.imagesDirectoryName +
          '/' +
          StorageConstants.userDirectoryName +
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
        StorageConstants.defaultUserProfile +
        StorageConstants.jpgExtension;
  }
}
