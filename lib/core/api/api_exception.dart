import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';

/// Validation error for form fields
class ValidationError extends Equatable {
  final String field;
  final String message;

  const ValidationError({required this.field, required this.message});

  factory ValidationError.fromJson(Map<String, dynamic> json) {
    return ValidationError(
      field: json['field']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
    );
  }

  @override
  List<Object?> get props => [field, message];
}

/// Custom API Exception for handling API errors
class ApiException implements Exception {
  final String message;
  final String? code;
  final int? statusCode;
  final List<ValidationError>? errors;
  final dynamic originalError;

  const ApiException({
    required this.message,
    this.code,
    this.statusCode,
    this.errors,
    this.originalError,
  });

  /// Create ApiException from Dio Response
  factory ApiException.fromResponse(Response response) {
    final data = response.data;

    if (data is Map<String, dynamic>) {
      return ApiException(
        message: data['message']?.toString() ?? 'Unknown error',
        code: data['code']?.toString(),
        statusCode: response.statusCode,
        errors:
            (data['errors'] as List?)
                ?.map(
                  (e) => ValidationError.fromJson(e as Map<String, dynamic>),
                )
                .toList(),
        originalError: response,
      );
    }

    return ApiException(
      message: 'Unknown error',
      statusCode: response.statusCode,
      originalError: response,
    );
  }

  /// Create ApiException from DioException
  factory ApiException.fromDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(
          message: 'Connection timeout. Please check your internet connection.',
          code: 'TIMEOUT',
        );

      case DioExceptionType.connectionError:
        return const ApiException(
          message: 'No internet connection. Please check your network.',
          code: 'NO_CONNECTION',
        );

      case DioExceptionType.badResponse:
        if (error.response != null) {
          return ApiException.fromResponse(error.response!);
        }
        return ApiException(
          message: 'Server error',
          statusCode: error.response?.statusCode,
          originalError: error,
        );

      case DioExceptionType.cancel:
        return const ApiException(
          message: 'Request cancelled',
          code: 'CANCELLED',
        );

      case DioExceptionType.unknown:
      case DioExceptionType.badCertificate:
        return ApiException(
          message: error.message ?? 'Unknown error occurred',
          code: 'UNKNOWN',
          originalError: error,
        );
    }
  }

  /// Check if error is related to authentication
  bool get isUnauthorized => statusCode == 401;

  /// Check if error is forbidden
  bool get isForbidden => statusCode == 403;

  /// Check if resource was not found
  bool get isNotFound => statusCode == 404;

  /// Check if it's a validation error
  bool get isValidationError => code == 'VALIDATION_ERROR' || statusCode == 400;

  /// Check if it's a low stock error
  bool get isLowStock => code == 'LOW_STOCK';

  /// Check if it's a payment error
  bool get isPaymentFailed => code == 'PAYMENT_FAILED' || statusCode == 402;

  /// Check if it's a server error
  bool get isServerError => statusCode != null && statusCode! >= 500;

  /// Check if it's a network error
  bool get isNetworkError => code == 'NO_CONNECTION' || code == 'TIMEOUT';

  /// Check if it's rate limited
  bool get isRateLimited => code == 'RATE_LIMIT_EXCEEDED' || statusCode == 429;

  /// Get first validation error for a specific field
  String? getFieldError(String field) {
    return errors
        ?.firstWhere(
          (e) => e.field == field,
          orElse: () => const ValidationError(field: '', message: ''),
        )
        .message;
  }

  @override
  String toString() =>
      'ApiException: $message (code: $code, status: $statusCode)';
}

/// Offline mode exception
class OfflineException implements Exception {
  final String message;

  const OfflineException([
    this.message = 'You are offline. Please check your connection.',
  ]);

  @override
  String toString() => 'OfflineException: $message';
}

/// Sync exception for offline data sync issues
class SyncException implements Exception {
  final String message;
  final dynamic data;

  const SyncException(this.message, [this.data]);

  @override
  String toString() => 'SyncException: $message';
}
