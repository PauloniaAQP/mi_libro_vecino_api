enum FirstLogin {
  FALSE,
  TRUE,
}

enum LoginType {
  EMAIL_LOGIN_TYPE,
  GMAIL_LOGIN_TYPE,
  FACEBOOK_LOGIN_TYPE,
}

enum LoginState {
  ERROR_USER_NOT_FOUND,
  ERROR_WRONG_PASSWORD,
  ERROR_ACCOUNT_EXISTS_WITH_DIFFERENT_CREDENTIAL,
  ERROR_EMAIL_ALREADY_IN_USE,
  ERROR_NETWORK_REQUEST_FAILED,
  ERROR_WEAK_PASSWORD,
  ERROR_INVALID_EMAIL,
  ERROR_BAD_LOGIN,
  ERROR_IN_SERVER,
  ERROR_TOO_MANY_REQUESTS,
  UNKNOWN_ERROR,
  CANCELED_BY_THE_USER,
  SUCCESS,
}

class LoginErrorStrings {
  static const String ERROR_USER_NOT_FOUND = "user-not-found";
  static const String ERROR_WRONG_PASSWORD = "wrong-password";
  static const String ERROR_ACCOUNT_EXISTS_WITH_DIFFERENT_CREDENTIAL =
      "account-exists-with-different-credential";
  static const String ERROR_EMAIL_ALREADY_IN_USE = "email-already-in-use";
  static const String ERROR_NETWORK_REQUEST_FAILED = "network-request-failed";
  static const String ERROR_WEAK_PASSWORD = "weak-password";
  static const String ERROR_INVALID_EMAIL = "invalid-email";
  static const String ERROR_TOO_MANY_REQUESTS = "too-many-requests";
}
