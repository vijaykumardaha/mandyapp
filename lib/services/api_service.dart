import 'package:dio/dio.dart';

class ApiService {
  static final ApiService _instance = ApiService._();
  static ApiService get instance => _instance;

  late final Dio _dio;

  // static const String baseUrl = 'http://192.168.1.4:4000';
  static const String baseUrl = 'http://169.58.87.214:4000';

  

  ApiService._() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
    ));
  }

  Dio get dio => _dio;
}
