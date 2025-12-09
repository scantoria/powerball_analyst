import 'package:dio/dio.dart';

/// Client for the NY Open Data API
/// Fetches Powerball lottery drawing results
///
/// API Documentation: https://data.ny.gov/resource/d6yy-54nr.json
class NYLotteryApi {
  final Dio _dio;
  static const String _baseUrl = 'https://data.ny.gov/resource/d6yy-54nr.json';

  NYLotteryApi({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: _baseUrl,
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
                headers: {
                  'Accept': 'application/json',
                },
              ),
            );

  /// Fetch all drawings (use with caution - can be large)
  /// Returns raw API response data
  Future<List<dynamic>> fetchAllDrawings() async {
    try {
      final response = await _dio.get('');
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw ApiException._fromDioException(e);
    }
  }

  /// Fetch drawings since a specific date
  /// Date format: YYYY-MM-DD
  Future<List<dynamic>> fetchDrawingsSince(DateTime sinceDate) async {
    try {
      final dateStr = _formatDate(sinceDate);
      final response = await _dio.get(
        '',
        queryParameters: {
          '\$where': 'draw_date >= "$dateStr"',
          '\$order': 'draw_date ASC',
        },
      );
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw ApiException._fromDioException(e);
    }
  }

  /// Fetch drawings within a date range
  Future<List<dynamic>> fetchDrawingsBetween(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final startStr = _formatDate(startDate);
      final endStr = _formatDate(endDate);
      final response = await _dio.get(
        '',
        queryParameters: {
          '\$where': 'draw_date >= "$startStr" AND draw_date <= "$endStr"',
          '\$order': 'draw_date ASC',
        },
      );
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw ApiException._fromDioException(e);
    }
  }

  /// Fetch latest N drawings
  Future<List<dynamic>> fetchLatestDrawings(int limit) async {
    try {
      final response = await _dio.get(
        '',
        queryParameters: {
          '\$order': 'draw_date DESC',
          '\$limit': limit,
        },
      );
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw ApiException._fromDioException(e);
    }
  }

  /// Format DateTime to YYYY-MM-DD for API
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

/// Custom exception for API errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final ApiExceptionType type;

  ApiException(this.message, this.statusCode, this.type);

  factory ApiException._fromDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          'Connection timeout. Please check your internet connection.',
          null,
          ApiExceptionType.timeout,
        );
      case DioExceptionType.badResponse:
        return ApiException(
          'Server error: ${e.response?.statusCode}',
          e.response?.statusCode,
          ApiExceptionType.serverError,
        );
      case DioExceptionType.cancel:
        return ApiException(
          'Request cancelled',
          null,
          ApiExceptionType.cancelled,
        );
      case DioExceptionType.connectionError:
        return ApiException(
          'No internet connection',
          null,
          ApiExceptionType.network,
        );
      default:
        return ApiException(
          'Unknown error: ${e.message}',
          null,
          ApiExceptionType.unknown,
        );
    }
  }

  @override
  String toString() => 'ApiException: $message';
}

/// Types of API exceptions
enum ApiExceptionType {
  timeout,
  serverError,
  cancelled,
  network,
  unknown,
}
