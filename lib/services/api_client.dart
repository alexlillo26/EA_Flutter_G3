import 'package:dio/dio.dart';
import '../utils/session_manager.dart'; // <-- Nuevo import

class ApiClient {
  final Dio _dio;
  bool _isRefreshing = false;
  final List<RequestOptions> _retryQueue = [];

  ApiClient({required String baseUrl})
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = Session.token;
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException error, handler) async {
        if (error.response?.statusCode == 401 && error.requestOptions.path != '/auth/refresh-token') {
          if (_isRefreshing) {
            _retryQueue.add(error.requestOptions);
            return;
          }
          if (Session.refreshToken != null) {
            _isRefreshing = true;
            try {
              final newTokens = await _refreshToken();
              Session.setSession(
                newToken: newTokens['token'],
                newRefreshToken: newTokens['refreshToken'],
              );
              error.requestOptions.headers['Authorization'] = 'Bearer ${Session.token}';
              _isRefreshing = false;
              await _processRetryQueue();
              return handler.resolve(await _dio.fetch(error.requestOptions));
            } catch (e) {
              _isRefreshing = false;
              Session.clearSession();
              return handler.reject(error);
            }
          } else {
            Session.clearSession();
            return handler.reject(error);
          }
        }
        return handler.next(error);
      },
    ));
  }

  Future<void> _processRetryQueue() async {
    while (_retryQueue.isNotEmpty) {
      final RequestOptions queuedRequest = _retryQueue.removeAt(0);
      queuedRequest.headers['Authorization'] = 'Bearer ${Session.token}';
      try {
        await _dio.fetch(queuedRequest);
      } catch (_) {}
    }
  }

  Future<Map<String, String?>> _refreshToken() async { // <-- String? para refreshToken
    final refreshToken = Session.refreshToken;
    if (refreshToken == null) {
      throw Exception("No refresh token available in session.");
    }
    try {
      final response = await _dio.post(
        '/auth/refresh-token',
        data: {'refreshToken': refreshToken},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );
      if (response.statusCode == 200) {
        final newAccessToken = response.data['token'];
        final newRefreshToken = response.data['refreshToken'];
        if (newAccessToken != null) {
          return {
            'token': newAccessToken as String,
            'refreshToken': newRefreshToken ?? refreshToken // <-- usa el actual si backend no devuelve nuevo
          };
        } else {
          throw Exception("Backend did not return a new access token.");
        }
      } else {
        final errorBody = response.data;
        throw Exception("Failed to refresh token: ${response.statusCode} - ${errorBody['message'] ?? 'Unknown error'}");
      }
    } on DioException catch (e) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    return await _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) async {
    return await _dio.post(path, data: data);
  }

  Dio get dio => _dio;
}

final apiClient = ApiClient(baseUrl: 'http://localhost:9000/api');

// El archivo ya es robusto y correcto para el manejo de tokens y refresco.
// No requiere cambios.
