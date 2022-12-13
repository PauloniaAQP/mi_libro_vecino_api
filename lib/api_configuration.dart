class ApiConfiguration {
  static const String gsBucketUrl = "gs://mi-libro-vecino.appspot.com/";
  static const String cfEntryPoint = "";
  static const String sentryDSNString = "";
  static const String mapsAPIUrl =
      "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png";

  /// This is for OpenCageData API, provide address from coordinates
  static const String geolocationAddressKey =
      "03c48dae07364cabb7f121d8c1519492"; // Open Cage Data API Key
  static const String geolocationAPIUrl =
      "api.opencagedata.com"; // If change this, change the one in GeoService.getAddress
  static const String geolocationAPIPath = '/geocode/v1/json/';

  /// This is for openDataSoft API, provide ubigeo code form address
  /// dataset only for Peru
  static const String openDataSoftAPIUrl = 'data.opendatasoft.com';
  static const String openDataSoftAPIPath = '/api/records/1.0/search/';
  static const String openDataSoftDataset = 'distritos-peru@bogota-laburbano';

  static const String fcmAPIString = "";
  static const String dynamicLinkURL = "";
  static const String dynamicLinkURLPrefix = "";
  static const String androidPackageName = "";
  static const String iOSPackageName = "";
  static const String iOSAppStoreId = "";
  static const String fcmPostSend =
      "https://fcm.googleapis.com/fcm/send"; // No cambia
  static const String senderId = '';
}
