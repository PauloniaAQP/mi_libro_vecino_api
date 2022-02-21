import 'package:firebase_auth/firebase_auth.dart';
import 'package:mi_libro_vecino_api/utils/constants/enums/UserEnums.dart';
import 'package:paulonia_error_service/paulonia_error_service.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

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
  /// It sends an email verification
  static Future<User?> emailPasswordSignUp(
      String email, String password, String name) async {
    try {
      User? user = (await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      )).user;
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
  static Future<User?> emailPasswordSignIn(String email, String password) async {
    try {
      final User? user = (await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      )).user;
      return user;
    } catch (error) {
      throw (_handlerLoginError(error));
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

  /// Handle all login errors
  static LoginState _handlerLoginError(dynamic error) {
    signOut();
    if (error.runtimeType == NoSuchMethodError || error.code == null) {
      return LoginState.CANCELED_BY_THE_USER;
    }
    switch (error.code) {
      case LoginErrorStrings.ERROR_ACCOUNT_EXISTS_WITH_DIFFERENT_CREDENTIAL:
        return LoginState.ERROR_ACCOUNT_EXISTS_WITH_DIFFERENT_CREDENTIAL;
      case LoginErrorStrings.ERROR_EMAIL_ALREADY_IN_USE:
        return LoginState.ERROR_EMAIL_ALREADY_IN_USE;
      case LoginErrorStrings.ERROR_NETWORK_REQUEST_FAILED:
        return LoginState.ERROR_NETWORK_REQUEST_FAILED;
      case LoginErrorStrings.ERROR_WEAK_PASSWORD:
        return LoginState.ERROR_WEAK_PASSWORD;
      case LoginErrorStrings.ERROR_INVALID_EMAIL:
        return LoginState.ERROR_INVALID_EMAIL;
      case LoginErrorStrings.ERROR_USER_NOT_FOUND:
        return LoginState.ERROR_USER_NOT_FOUND;
      case LoginErrorStrings.ERROR_WRONG_PASSWORD:
        return LoginState.ERROR_WRONG_PASSWORD;
      case LoginErrorStrings.ERROR_TOO_MANY_REQUESTS:
        return LoginState.ERROR_TOO_MANY_REQUESTS;
      default:
        PauloniaErrorService.sendErrorWithoutStacktrace(error);
        return LoginState.UNKNOWN_ERROR;
    }
  }

}
