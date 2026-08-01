import 'package:dio/dio.dart';
import 'package:mandiapp/models/mandi_model.dart';
import 'package:mandiapp/models/user_model.dart';
import 'package:mandiapp/services/api_service.dart';

class AuthApi {
  final _dio = ApiService.instance.dio;

  /// GET /api/mandi_list
  /// Response format: [{ "mandi_id": 92917804, "mandi_name": "Sanjeev Mandi" }]
  Future<List<Mandi>> mandiList() async {
    try {
      final response = await _dio.get('/api/mandi_list');
      final data = response.data as List<dynamic>;
      return data
          .map((e) => Mandi.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } on DioException catch (e) {
      final message = _errorMessage(e) ?? e.message ?? 'Failed to load mandis';
      throw Exception(message);
    }
  }

  /// POST /api/login
  Future<User> login({required String mobile, required String password}) async {
    try {
      final response = await _dio.post('/api/login', data: {
        'mobile': mobile,
        'password': password,
      });

      return User.fromJson(_userMap(response));
    } on DioException catch (e) {
      final message = _errorMessage(e) ?? e.message ?? 'Login failed';
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
        (data['user'] as Map<String, dynamic>)['password'] = password;
      }

      final response = await _dio.post('/api/signup', data: data);

      return User.fromJson(_userMap(response));
    } on DioException catch (e) {
      final message = _errorMessage(e) ?? e.message ?? 'Signup failed';
      throw Exception(message);
    }
  }

  /// POST /api/customer_login
  Future<User> customerLogin({
    required int mandiId,
    required String mobile,
  }) async {
    try {
      final response = await _dio.post('/api/customer_login', data: {
        'mandi_id': mandiId,
        'mobile': mobile,
      });

      return User.fromJson(_userMap(response));
    } on DioException catch (e) {
      final message = _errorMessage(e) ?? e.message ?? 'Customer login failed';
      throw Exception(message);
    }
  }

  /// POST /api/customer_sync
  /// Returns bulk data for the customer (orders, payments, stocks, etc.)
  /// Response format: { 'data': { 'tables': { 'customers': [...], 'orders': [...], ... } } }
  Future<Map<String, dynamic>> customerSync({
    required int mandiId,
    required int customerId,
  }) async {
    try {
      final response = await _dio.post(
        '/api/customer_sync',
        data: {
          'mandi_id': mandiId,
          'customer_id': customerId,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final payload = data['data'] as Map<String, dynamic>?;
      final tables = payload?['tables'] as Map<String, dynamic>?;
      return tables ?? {};
    } on DioException catch (e) {
      final message = _errorMessage(e) ?? e.message ?? 'Customer sync failed';
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
        (data['staff'] as Map<String, dynamic>)['password'] = password;
      }

      final response = await _dio.post('/api/add_staff', data: data);

      return User.fromJson(_userMap(response));
    } on DioException catch (e) {
      final message = _errorMessage(e) ?? e.message ?? 'Failed to add staff';
      throw Exception(message);
    }
  }

  Map<String, dynamic> _userMap(Response<dynamic> response) {
    final data = response.data as Map<String, dynamic>;
    final payload = data['data'] as Map<String, dynamic>;
    return payload['user'] as Map<String, dynamic>;
  }

  String? _errorMessage(DioException e) {
    final data = e.response?.data;
    if (data is! Map) return null;
    final body = Map<String, dynamic>.from(data);
    final errors = body['errors'];
    if (errors is Map) {
      return (Map<String, dynamic>.from(errors)['detail'])?.toString();
    }
    return body['error']?.toString();
  }
}
