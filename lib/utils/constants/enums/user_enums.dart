enum FirstLogin {
  falseFirstLogin,
  trueFirstLogin,
}

enum LoginType {
  emailLoginType,
  gmailLoginType,
  facebookLoginType,
}

enum LoginState {
  errorUserNotFound,
  errorWrongPassword,
  errorAccountExistsWithDifferentCredential,
  errorEmailAlreadyInUse,
  errorNetworkRequestFailed,
  errorWeekPassword,
  errorInvalidEmail,
  errorBadLogin,
  errorInServer,
  errorTooManyRequests,
  unknownError,
  canceledByTheUser,
  success,
}

class LoginErrorStrings {
  static const String errorUserNotFound = "user-not-found";
  static const String errorWrongPassword = "wrong-password";
  static const String errorAccountExistsWithDifferentCredential =
      "account-exists-with-different-credential";
  static const String errorEmailAlreadyInUse = "email-already-in-use";
  static const String errorNetworkRequestFailed = "network-request-failed";
  static const String errorWeekPassword = "weak-password";
  static const String errorInvalidEmail = "invalid-email";
  static const String errorTooManyRequests = "too-many-requests";
}
