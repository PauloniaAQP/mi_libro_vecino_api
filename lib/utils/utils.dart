import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mi_libro_vecino_api/utils/constants/storage/storage_constants.dart';
import 'package:diacritic/diacritic.dart';
import 'package:paulonia_error_service/paulonia_error_service.dart';

class ApiUtils {
  /// Loads an asset from a path
  static Future<String> loadFromAsset(String asset) async {
    return await rootBundle.loadString(asset);
  }

  /// Parse an asset to a map
  static Future<Map<String, dynamic>> parseAssetToJson(String asset) async {
    String jsonString = await loadFromAsset(asset);
    return jsonDecode(jsonString);
  }

  /// Convert TimeOfDay to String
  static String timeOfDayToString(TimeOfDay time) {
    String sufix = time.hour < 12 ? 'AM' : 'PM';
    String minutes = time.minute < 10 ? '0${time.minute}' : '${time.minute}';
    int tempHour = time.hour;
    if (time.hour > 12) tempHour -= 12;
    String hour = time.hour < 10 ? '0$tempHour' : '$tempHour';
    return '$hour:$minutes $sufix';
  }

  /// Parse String to TimeOfDay
  /// String must be like '00:00'
  static TimeOfDay timeOfDayFromString(String time) {
    final subTime = time.substring(0, 5);
    int hour = int.parse(subTime.split(':')[0]);
    int minute = int.parse(subTime.split(':')[1]);
    if (time.contains('PM')) hour += 12;
    return TimeOfDay(hour: hour, minute: minute);
  }

  /// Upload a file to storage
  static Future<bool> uploadFile(
    String id,
    int photoVersion,
    XFile image,
    String photoName,
    Reference reference, {
    bool delAns = false,
  }) async {
    String prefix = photoName;
    Uint8List img = await image.readAsBytes();
    try {
      if (delAns) {
        await reference
            .child(id)
            .child(
                prefix + "${photoVersion - 1}" + StorageConstants.jpgExtension)
            .delete();
      }
      await reference
          .child(id)
          .child(
              prefix + photoVersion.toString() + StorageConstants.jpgExtension)
          .putData(
              img,
              SettableMetadata(
                contentType: 'image/png',
              ));
      return true;
    } on FirebaseException catch (e, stacktrace) {
      PauloniaErrorService.sendError(e, stacktrace);
      return false;
    }
  }

  /// Returned separate words formatted to lowerCase & remove diacritics
  static List<String> preprocessWord(String word) {
    word = word.toLowerCase();
    word = word.trim();
    word = removeDiacritics(word);
    return word.split(' ');
  }

  static Coordinates? getCenterFromCoordinates(List<Coordinates> coordinates) {
    if (coordinates.isEmpty) return null;
    double x = 0, y = 0;
    for (var i = 0; i < coordinates.length; i++) {
      x += coordinates[i].latitude;
      y += coordinates[i].longitude;
    }
    return Coordinates(x / coordinates.length, y / coordinates.length);
  }
}

class Coordinates {
  Coordinates(
    this.latitude,
    this.longitude,
  );

  double latitude;
  double longitude;

  bool isEquals(Coordinates other) {
    return latitude == other.latitude && longitude == other.longitude;
  }

  Coordinates.fromGeopoint(GeoPoint geoPoint)
      : latitude = geoPoint.latitude,
        longitude = geoPoint.longitude;

  /// Parse own coordinates class to firestore geopoint
  GeoPoint toGeoPoint() {
    return GeoPoint(latitude, longitude);
  }
}
