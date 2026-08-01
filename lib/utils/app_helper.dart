import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:krishimandi/models/user_model.dart';
import 'package:krishimandi/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppHelper {
  static Future<void> savePreferences(String key, dynamic value) async {
    final SharedPreferences sharedPreferences =
        await SharedPreferences.getInstance();
    sharedPreferences.setString(key, jsonEncode(value));
  }

  static Future<dynamic> getPreferences(String key) async {
    final SharedPreferences sharedPreferences =
        await SharedPreferences.getInstance();
    final String? value = sharedPreferences.getString(key);
    if (value == null) return null;
    return jsonDecode(value);
  }

  static Future<void> removePreferences(String key) async {
    final SharedPreferences sharedPreferences =
        await SharedPreferences.getInstance();
    sharedPreferences.remove(key);
  }

  static Future<int?> getCurrentMandiId() async {
    final userData = await getPreferences(PrefsKeys.user);
    if (userData == null) return null;
    return (userData as Map<String, dynamic>)['mandi_id'] as int?;
  }

  static Future<User?> getCurrentUser() async {
    final userData = await getPreferences(PrefsKeys.user);
    if (userData == null) return null;
    return User.fromJson(userData);
  }

  static Future<bool> isOnline() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult.isNotEmpty;
  }

  static Future<bool> isOffline() async {
    return !(await isOnline());
  }
}
