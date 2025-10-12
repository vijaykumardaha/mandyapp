import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class AppHelper {

  static Future<void> savePreferences(String key, dynamic value) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.setString(key, jsonEncode(value));
  }

  static Future<dynamic> getPreferences(String key) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String? value = sharedPreferences.getString(key);
    if (value == null) return null;
    return jsonDecode(value);
  }

  static Future<void> removePreferences(String key) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.remove(key);
  }

  static int generateUuidInt() {
    var uuid = const Uuid().v4();
    return uuid.hashCode.abs();
  }

  static Future<bool> isOnline() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult.isNotEmpty;
  }

  static Future<bool> isOffline() async {
    return !(await isOnline());
  }

}
