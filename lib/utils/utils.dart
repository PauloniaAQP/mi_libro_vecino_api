import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mi_libro_vecino_api/utils/constants/storage/storage_constants.dart';
import 'package:diacritic/diacritic.dart';

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
    return '${time.hour}:${time.minute}';
  }

  /// Parse String to TimeOfDay
  /// String must be like '00:00'
  static TimeOfDay timeOfDayFromString(String time) {
    int hour = int.parse(time.split(':')[0]);
    int minute = int.parse(time.split(':')[1]);
    return TimeOfDay(hour: hour, minute: minute);
  }

  /// Upload a file to storage
  static Future<bool> uploadFile(
    String id,
    int photoVersion,
    PickedFile image,
    Reference reference, {
    bool delAns = false,
  }) async {
    String prefix = id + '_';
    Uint8List img = await image.readAsBytes();
    try {
      if (delAns) {
        await reference
            .child(
                prefix + "${photoVersion - 1}" + StorageConstants.png_extension)
            .delete();
      }
      await reference
          .child(
              prefix + photoVersion.toString() + StorageConstants.png_extension)
          .putData(
              img,
              SettableMetadata(
                contentType: 'image/png',
              ));
      return true;
    } on FirebaseException catch (e, stacktrace) {
      /// fii on web doesn't work
      // PauloniaErrorService.sendError(e, stacktrace);
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
