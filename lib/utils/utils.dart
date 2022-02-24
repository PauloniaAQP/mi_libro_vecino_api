import 'dart:convert';

import 'package:flutter/services.dart';

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
}
