import 'package:dio/dio.dart';
import '../config/server_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dio_factory.dart';

class ApiClientConfig {
  static String get baseUrl => ServerConfig.apiBaseUrl;

  static Dio createDio() {
    final dio = DioFactory.getDio();

    // Add Auth Interceptor
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );

    // Add error handling interceptor
    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException error, handler) {
          print('DIO ERROR: ${error.message}');
          print('DIO ERROR TYPE: ${error.type}');
          print('DIO ERROR RESPONSE: ${error.response?.data}');

          String errorMessage = 'An error occurred';

          switch (error.type) {
            case DioExceptionType.connectionTimeout:
              errorMessage =
                  'Connection timeout. Please check your internet connection and try again.';
              break;
            case DioExceptionType.sendTimeout:
              errorMessage = 'Request timeout. Please try again.';
              break;
            case DioExceptionType.receiveTimeout:
              errorMessage = 'Server response timeout. Please try again.';
              break;
            case DioExceptionType.connectionError:
              errorMessage =
                  'Cannot reach the server. Please ensure the backend is running and try again.';
              break;
            case DioExceptionType.badResponse:
              final statusCode = error.response?.statusCode ?? 0;
              if (statusCode == 401) {
                final serverMessage = error.response?.data?['message'];
                errorMessage = (serverMessage != null && serverMessage.isNotEmpty)
                    ? serverMessage
                    : 'Invalid credentials. Please check your email and password.';
              } else if (statusCode == 404) {
                errorMessage = 'Service not found. Please try again later.';
              } else if (statusCode == 500) {
                errorMessage = 'Server error. Please try again later.';
              } else {
                errorMessage =
                    'Server error ($statusCode). Please try again.';
              }
              break;
            default:
              final rawMessage = error.message ?? '';
              if (rawMessage.contains('Connection refused') ||
                  rawMessage.contains('Failed host lookup') ||
                  rawMessage.contains('SocketException')) {
                errorMessage = 'Cannot reach the server. Please ensure the backend is running and try again.';
              } else {
                errorMessage = 'Network error. Please check your connection and try again.';
              }
          }

          // Update the error message
          error = error.copyWith(message: errorMessage);

          return handler.next(error);
        },
        onResponse: (response, handler) {
          // print('DIO RESPONSE: ${response.data}');
          return handler.next(response);
        },
      ),
    );

    // Add retry interceptor for connection timeouts
    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException error, handler) async {
          if (error.type == DioExceptionType.connectionTimeout &&
              error.requestOptions.extra['retryCount'] == null) {
            // Retry once
            error.requestOptions.extra['retryCount'] = 1;
            print('Retrying request due to connection timeout...');

            try {
              final response = await dio.fetch(error.requestOptions);
              return handler.resolve(response);
            } catch (retryError) {
              return handler.next(error);
            }
          }
          return handler.next(error);
        },
      ),
    );

    return dio;
  }
}

class ApiClient {
  final Dio _dio;

  ApiClient(this._dio);

  // Add your API endpoints here
}
