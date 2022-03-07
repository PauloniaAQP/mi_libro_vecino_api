import 'package:firebase_auth/firebase_auth.dart';
import 'package:mi_libro_vecino_api/utils/constants/enums/user_enums.dart';
// import 'package:paulonia_error_service/paulonia_error_service.dart';

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
  static Future<User?> emailPasswordSignIn(
      String email, String password) async {
    try {
      final User? user = (await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      ))
          .user;
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

  /// Sign Out the session of the user.
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
        // PauloniaErrorService.sendErrorWithoutStacktrace(error);
        return LoginState.unknownError;
    }
  }
}
