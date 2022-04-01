import 'package:firebase_auth/firebase_auth.dart';
import 'package:mi_libro_vecino_api/utils/constants/enums/user_enums.dart';
import 'package:paulonia_error_service/paulonia_error_service.dart';
import 'dart:async';

enum AuthenticationStatus {
  authenticated,
  unauthenticated,
  authenticating,
}

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Stream of [AuthenticationStatus] which will emit the current
  /// user when the authentication state changes.
  static Stream<AuthenticationStatus> get status {
    return _auth.authStateChanges().map((firebaseUser) {
      final state = firebaseUser == null
          ? AuthenticationStatus.unauthenticated
          : AuthenticationStatus.authenticated;
      return state;
    });
  }

  /// Gets if the user is admin.
  static Future<bool> isAdmin(User user) async {
    final idTokenResult = await user.getIdTokenResult();
    if (idTokenResult.claims == null ||
        idTokenResult.claims?['isAdmin'] == null) {
      return false;
    } else {
      if (!idTokenResult.claims?['isAdmin']) return false;
      return true;
    }
  }

  /// Gets the current user
  static User? get currentUser => _auth.currentUser;

  /// Verify if there is a user session is active
  static bool isLoggedIn() {
    return _auth.currentUser != null;
  }

  /// Returns the current user session
  static User? initialVerification({bool cache = false}) {
    return _auth.currentUser;
  }

  /// Sign Up with email an password
  ///
  /// If [isAdmin] is true, then this verifies if the user has the 'isAdmin' claim,
  /// otherwise it returns null
  /// It sends an email verification
  static Future<User?> emailPasswordSignUp(
      String email, String password, String name) async {
    try {
      User? user = (await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      ))
          .user;
      await user?.updateProfile(
        displayName: name,
      );
      await user?.reload();
      user = _auth.currentUser;
      user?.sendEmailVerification();
      return user;
    } catch (error) {
      throw (_handlerLoginError(error));
    }
  }

  /// Sign in with email and password
  static Future<User?> emailPasswordSignIn(String email, String password,
      {bool isAdmin = false}) async {
    try {
      final User? user = (await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      ))
          .user;
      if (isAdmin) {
        if (user == null) {
          return null;
        }
        final idTokenResult = await user.getIdTokenResult();
        if (idTokenResult.claims == null || !idTokenResult.claims!['isAdmin']) {
          return null;
        }
      }
      return user;
    } catch (error) {
      throw (_handlerLoginError(error));
    }
  }

  /// Check if email is already in use
  static Future<bool> isEmailInUse(String email) async {
    final List<String> users = await _auth.fetchSignInMethodsForEmail(email);
    if (users.isEmpty) {
      return false;
    } else {
      return true;
    }
  }

  /// Sends an email verification to [user]
  static void sendEmailVerification(User user) {
    user.sendEmailVerification();
  }

  /// Sign Out the session of the user.
  static Future<void> signOut() async {
    _auth.signOut();
  }

  /// Sign Out and remove the user.
  static Future<void> removeUser(User user) async {
    user.delete();
  }

  /// Handle all login errors
  static LoginState _handlerLoginError(dynamic error) {
    signOut();
    if (error.runtimeType == NoSuchMethodError || error.code == null) {
      return LoginState.canceledByTheUser;
    }
    switch (error.code) {
      case LoginErrorStrings.errorAccountExistsWithDifferentCredential:
        return LoginState.errorAccountExistsWithDifferentCredential;
      case LoginErrorStrings.errorEmailAlreadyInUse:
        return LoginState.errorEmailAlreadyInUse;
      case LoginErrorStrings.errorNetworkRequestFailed:
        return LoginState.errorNetworkRequestFailed;
      case LoginErrorStrings.errorWeekPassword:
        return LoginState.errorWeekPassword;
      case LoginErrorStrings.errorInvalidEmail:
        return LoginState.errorInvalidEmail;
      case LoginErrorStrings.errorUserNotFound:
        return LoginState.errorUserNotFound;
      case LoginErrorStrings.errorWrongPassword:
        return LoginState.errorWrongPassword;
      case LoginErrorStrings.errorTooManyRequests:
        return LoginState.errorTooManyRequests;
      default:
        PauloniaErrorService.sendErrorWithoutStacktrace(error);
        return LoginState.unknownError;
    }
  }
}
