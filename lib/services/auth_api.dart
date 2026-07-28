import 'package:dio/dio.dart';
import 'package:mandiapp/models/user_model.dart';
import 'package:mandiapp/services/api_service.dart';

class AuthApi {
  final _dio = ApiService.instance.dio;

  /// POST /api/login
  Future<User> login({required String mobile, required String password}) async {
    try {
      final response = await _dio.post('/api/login', data: {
        'mobile': mobile,
        'password': password,
      });

      final userData = response.data['data']['user'];
      return User.fromJson(userData);
    } on DioException catch (e) {
      final message = e.response?.data['errors']['detail'] ?? e.message ?? 'Login failed';
      throw Exception(message);
    }
  }

  /// POST /api/signup
  Future<User> signup({
    required String name,
    required String mobile,
    String? password,
  }) async {
    try {
      final data = <String, dynamic>{
        'user': {
          'name': name,
          'mobile': mobile,
          'role': 'admin',
        },
      };
      if (password != null && password.isNotEmpty) {
        data['user']['password'] = password;
      }

      final response = await _dio.post('/api/signup', data: data);

      final userData = response.data['data']['user'];
      return User.fromJson(userData);
    } on DioException catch (e) {
      final message = e.response?.data['error'] ?? e.message ?? 'Signup failed';
      throw Exception(message);
    }
  }

  /// POST /api/add_staff
  Future<User> addStaff({
    required int mandiId,
    required String name,
    required String mobile,
    String? password,
  }) async {
    try {
      final data = <String, dynamic>{
        'staff': {
          'mandi_id': mandiId,
          'name': name,
          'mobile': mobile,
        },
      };
      if (password != null && password.isNotEmpty) {
        data['staff']['password'] = password;
      }

      final response = await _dio.post('/api/add_staff', data: data);

      final userData = response.data['data']['user'];
      return User.fromJson(userData);
    } on DioException catch (e) {
      final message = e.response?.data['errors']['detail'] ?? e.message ?? 'Failed to add staff';
      throw Exception(message);
    }
  }
}
