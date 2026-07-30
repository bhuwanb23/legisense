import 'package:dio/dio.dart';

import '../config/api_config.dart';
import 'api_exception.dart';
import 'token_store.dart';

/// Shared Dio client — unwraps `{ success, data }` and refreshes on 401.
class ApiClient {
  ApiClient._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(minutes: 2),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await TokenStore.accessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401 &&
              !(error.requestOptions.extra['retried'] == true)) {
            final refreshed = await _tryRefresh();
            if (refreshed) {
              final opts = error.requestOptions;
              opts.extra['retried'] = true;
              final token = await TokenStore.accessToken();
              opts.headers['Authorization'] = 'Bearer $token';
              try {
                final response = await _dio.fetch(opts);
                return handler.resolve(response);
              } catch (e) {
                return handler.next(error);
              }
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  static final ApiClient instance = ApiClient._();

  late final Dio _dio;
  bool _refreshing = false;

  Dio get dio => _dio;

  Future<bool> _tryRefresh() async {
    if (_refreshing) return false;
    _refreshing = true;
    try {
      final refresh = await TokenStore.refreshToken();
      if (refresh == null || refresh.isEmpty) return false;
      final res = await Dio(
        BaseOptions(baseUrl: ApiConfig.baseUrl),
      ).post<Map<String, dynamic>>(
        '/api/auth/refresh-token',
        data: {'refreshToken': refresh},
      );
      final body = res.data;
      if (body == null || body['success'] != true) return false;
      final data = body['data'] as Map<String, dynamic>;
      await TokenStore.saveTokens(
        accessToken: data['accessToken'] as String,
        refreshToken: (data['refreshToken'] as String?) ?? refresh,
      );
      return true;
    } catch (_) {
      await TokenStore.clear();
      return false;
    } finally {
      _refreshing = false;
    }
  }

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? query,
    T Function(dynamic data)? parse,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(path, queryParameters: query);
      return _unwrap(res.data, parse);
    } on DioException catch (e) {
      throw _mapDio(e);
    }
  }

  Future<T> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? query,
    T Function(dynamic data)? parse,
    Options? options,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        path,
        data: data,
        queryParameters: query,
        options: options,
      );
      return _unwrap(res.data, parse);
    } on DioException catch (e) {
      throw _mapDio(e);
    }
  }

  Future<T> put<T>(
    String path, {
    Object? data,
    T Function(dynamic data)? parse,
  }) async {
    try {
      final res = await _dio.put<Map<String, dynamic>>(path, data: data);
      return _unwrap(res.data, parse);
    } on DioException catch (e) {
      throw _mapDio(e);
    }
  }

  Future<T> delete<T>(
    String path, {
    T Function(dynamic data)? parse,
  }) async {
    try {
      final res = await _dio.delete<Map<String, dynamic>>(path);
      return _unwrap(res.data, parse);
    } on DioException catch (e) {
      throw _mapDio(e);
    }
  }

  Future<T> postMultipart<T>(
    String path, {
    required FormData formData,
    T Function(dynamic data)? parse,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        path,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return _unwrap(res.data, parse);
    } on DioException catch (e) {
      throw _mapDio(e);
    }
  }

  T _unwrap<T>(Map<String, dynamic>? body, T Function(dynamic data)? parse) {
    if (body == null) {
      throw ApiException(message: 'Empty response', statusCode: 0);
    }
    if (body['success'] != true) {
      final err = body['error'];
      if (err is Map<String, dynamic>) {
        throw ApiException(
          message: err['message'] as String? ?? 'Request failed',
          code: err['code'] as String?,
          statusCode: err['statusCode'] as int?,
          details: err['details'],
        );
      }
      throw ApiException(message: 'Request failed');
    }
    final data = body['data'];
    if (parse != null) return parse(data);
    return data as T;
  }

  ApiException _mapDio(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final err = data['error'];
      if (err is Map<String, dynamic>) {
        return ApiException(
          message: err['message'] as String? ?? e.message ?? 'Network error',
          code: err['code'] as String?,
          statusCode: err['statusCode'] as int? ?? e.response?.statusCode,
          details: err['details'],
        );
      }
    }
    return ApiException(
      message: e.message ?? 'Network error',
      statusCode: e.response?.statusCode,
    );
  }
}
