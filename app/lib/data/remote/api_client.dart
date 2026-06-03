import 'package:dio/dio.dart';

import '../../core/config/env.dart';

/// Thin Dio wrapper. All remote calls go through this — UI never touches Dio.
class ApiClient {
  ApiClient([Dio? dio])
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: Env.apiBaseUrl,
                connectTimeout: Env.connectTimeout,
                receiveTimeout: Env.receiveTimeout,
                headers: {'Content-Type': 'application/json'},
              ),
            );

  final Dio _dio;

  Future<Response<dynamic>> get(String path, {Map<String, dynamic>? query}) =>
      _dio.get(path, queryParameters: query);

  Future<Response<dynamic>> post(String path, {Object? data}) =>
      _dio.post(path, data: data);

  Future<Response<dynamic>> put(String path, {Object? data}) =>
      _dio.put(path, data: data);

  Future<Response<dynamic>> delete(String path) => _dio.delete(path);
}
