import 'package:mi_libro_vecino_api/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mi_libro_vecino_api/utils/constants/firestore/collections/user.dart';
import 'package:mi_libro_vecino_api/utils/constants/firestore/firestore_constants.dart';
import 'package:paulonia_document_service/paulonia_document_service.dart';
import 'package:paulonia_repository/PauloniaRepository.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserRepository extends PauloniaRepository<String, UserModel> {
  @override
  CollectionReference get collectionReference => _collectionReference;

  final CollectionReference _collectionReference = FirebaseFirestore.instance
      .collection(FirestoreCollections.userCollection);

  /// Get a User model from a document snapshot
  @override
  UserModel getFromDocSnap(DocumentSnapshot docSnap, {User? user}) {
    int photoVersion = docSnap.data()?[UserCollectionNames.PHOTO_VERSION] ?? -1;
    return UserModel(
      photoVersion: photoVersion,
      id: docSnap.id,
      name: docSnap.get(UserCollectionNames.NAME),
      phone: docSnap.data()?[UserCollectionNames.PHONE],
      email: docSnap.get(UserCollectionNames.EMAIL),
      created: _fromTimestamp(docSnap.get(UserCollectionNames.CREATED)),
      firebaseUser: user,

      /// TODO: Add photo url from firebase storage
      // photoUrl: docSnap.data()?[UserCollectionNames.PHOTO_URL],
    );
  }

  /// Creates an user in a batch and returns it
  ///
  /// The [userId] is the uid of firebase auth
  WriteBatch createUserInBatch({
    required String userId,
    required String name,
    required String email,
    String? phone,
    int? photoVersion,
  }) {
    Map<String, dynamic> data = _getUserDataMap(
      name: name,
      email: email,
      phone: phone,
      photoVersion: photoVersion ?? -1,
    );
    data[UserCollectionNames.CREATED] = FieldValue.serverTimestamp();
    WriteBatch batch = FirebaseFirestore.instance.batch();
    batch.set(_collectionReference.doc(userId), data);
    UserModel user = UserModel(
      id: userId,
      name: name,
      email: email,
      created: data[UserCollectionNames.CREATED],
      phone: phone,
      photoVersion: photoVersion ?? -1,
    );
    addInRepository([user]);
    return batch;
  }

  /// Creates an user
  ///
  /// The [userId] is the uid of firebase auth
  Future<void> createUser({
    required String userId,
    required String name,
    required String email,
    required String phone,
  }) async {
    Map<String, dynamic> data = _getUserDataMap(
      name: name,
      email: email,
      phone: phone,
      photoVersion: -1,
    );
    data[UserCollectionNames.CREATED] = FieldValue.serverTimestamp();
    await _collectionReference.doc(userId).set(data);
    DocumentSnapshot? docSnap = await PauloniaDocumentService.getDoc(
        _collectionReference.doc(userId), false);
    if (docSnap == null) return;
    UserModel user = getFromDocSnap(docSnap);
    addInRepository([user]);
  }

  /// Updates the user
  Future<UserModel> updateUser(
    UserModel user, {
    String? name,
    String? email,
    String? phone,
  }) async {
    Map<String, dynamic> data = {};
    if (name != null) {
      user.name = name;
      data[UserCollectionNames.NAME] = name;
    }
    if (email != null) {
      user.email = email;
      data[UserCollectionNames.EMAIL] = email;
    }
    if (phone != null) {
      user.phone = phone;
      data[UserCollectionNames.PHONE] = phone;
    }
    _collectionReference.doc(user.id).update(data);
    addInRepository([user]);
    return user;
  }

  /// Gets an userModel from a userId
  Future<UserModel?> getUserById(String userId, {bool cache = true}) async {
    DocumentSnapshot? userDoc = await PauloniaDocumentService.getDoc(
        _collectionReference.doc(userId), cache);
    if (userDoc == null) return null;
    UserModel user = getFromDocSnap(userDoc);
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
    if (name != null) data[UserCollectionNames.NAME] = name;
    if (email != null) data[UserCollectionNames.EMAIL] = email;
    if (phone != null) data[UserCollectionNames.PHONE] = phone;
    if (photoVersion != null) {
      data[UserCollectionNames.PHOTO_VERSION] = photoVersion;
    }
    return data;
  }

  DateTime _fromTimestamp(Timestamp timestamp) => timestamp.toDate();
}
