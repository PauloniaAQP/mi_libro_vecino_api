import 'package:paulonia_repository/PauloniaModel.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserModel extends PauloniaModel<String> {
  @override
  String id;
  String name;
  String? phone;
  int? photoVersion;
  String? photoUrl;
  String email;
  User? firebaseUser;
  @override
  DateTime created;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.photoVersion,
    this.photoUrl,
    required this.created,
    this.firebaseUser,
  });

  @override
  String toString() {
    return '''UserModel{
      id: $id,
      name: $name,
      phone: $phone,
      photoVersion: $photoVersion,
      photoUrl: $photoUrl,
      email: $email,
      firebaseUser: $firebaseUser,
      created: $created}''';
  }
}
