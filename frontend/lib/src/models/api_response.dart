import 'user_model.dart';

class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final Map<String, dynamic>? errors;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
  });

  factory ApiResponse.fromJson(
      Map<String, dynamic> json,
      T Function(dynamic)? fromJsonT,
      ) {
    return ApiResponse<T>(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'],
      errors: json['errors'] as Map<String, dynamic>?,
    );
  }

  // Static factory methods
  factory ApiResponse.success({
    required T data,
    String message = 'Success',
  }) {
    return ApiResponse<T>(
      success: true,
      message: message,
      data: data,
      errors: null,
    );
  }

  factory ApiResponse.error({
    required String message,
    T? data,
    Map<String, dynamic>? errors,
  }) {
    return ApiResponse<T>(
      success: false,
      message: message,
      data: data,
      errors: errors,
    );
  }

  Map<String, dynamic> toJson(Object? Function(T)? toJsonT) {
    return {
      'success': success,
      'message': message,
      'data': data != null && toJsonT != null ? toJsonT(data as T) : data,
      'errors': errors,
    };
  }
}

class AuthResponse {
  final UserModel user;
  final String token;

  AuthResponse({
    required this.user,
    required this.token,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: UserModel.fromJson(json['user']),
      token: json['token'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'token': token,
    };
  }
}

class ApiError {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors;
  final String? type;

  ApiError({
    required this.message,
    this.statusCode,
    this.errors,
    this.type,
  });

  factory ApiError.fromDioError(dynamic error) {
    if (error.response != null) {
      final data = error.response?.data;

      if (data is Map<String, dynamic>) {
        return ApiError(
          message: data['message'] ?? 'An error occurred',
          statusCode: error.response?.statusCode,
          errors: data['errors'] as Map<String, dynamic>?,
          type: 'api_error',
        );
      }
    }

    return ApiError(
      message: error.message ?? 'Network error occurred',
      type: 'network_error',
    );
  }

  factory ApiError.networkError([String? message]) {
    return ApiError(
      message: message ?? 'Network connection error. Please check your internet connection.',
      type: 'network_error',
    );
  }

  factory ApiError.timeoutError() {
    return ApiError(
      message: 'Request timeout. Please try again.',
      type: 'timeout_error',
    );
  }

  factory ApiError.serverError() {
    return ApiError(
      message: 'Server error occurred. Please try again later.',
      type: 'server_error',
    );
  }

  String get displayMessage {
    if (errors != null && errors!.isNotEmpty) {
      // Format validation errors in a user-friendly way
      final errorMessages = <String>[];

      errors!.forEach((field, messages) {
        if (messages is List) {
          for (var message in messages) {
            String formattedMessage = message.toString();

            // Special handling for general/non-field errors
            if (field == 'detail' || field == 'non_field_errors' || field == 'error') {
              errorMessages.add(formattedMessage);
              continue;
            }

            // Make field names more user-friendly
            String fieldName = _formatFieldName(field);

            // Create user-friendly error message
            if (formattedMessage.toLowerCase().contains('already exists')) {
              errorMessages.add('$fieldName is already taken. Please choose a different one.');
            } else if (formattedMessage.toLowerCase().contains('required')) {
              errorMessages.add('$fieldName is required.');
            } else if (formattedMessage.toLowerCase().contains('invalid')) {
              errorMessages.add('Please enter a valid $fieldName.');
            } else if (formattedMessage.toLowerCase().contains('password')) {
              errorMessages.add(formattedMessage);
            } else {
              errorMessages.add('$fieldName: $formattedMessage');
            }
          }
        } else {
          String fieldName = _formatFieldName(field);
          String formattedMessage = messages.toString();

          if (formattedMessage.toLowerCase().contains('already exists')) {
            errorMessages.add('$fieldName is already taken. Please choose a different one.');
          } else {
            errorMessages.add('$fieldName: $formattedMessage');
          }
        }
      });

      return errorMessages.join('\n');
    }
    return message;
  }

  String _formatFieldName(String field) {
    // Convert field names to user-friendly labels
    switch (field.toLowerCase()) {
      case 'email':
        return 'Email address';
      case 'full_name':
        return 'Full name';
      case 'password':
        return 'Password';
      case 'password_confirm':
        return 'Password confirmation';
      case 'agreed_to_terms':
        return 'Terms agreement';
      default:
      // Convert snake_case to Title Case
        return field
            .split('_')
            .map((word) => word[0].toUpperCase() + word.substring(1))
            .join(' ');
    }
  }

  @override
  String toString() {
    return 'ApiError(message: $message, statusCode: $statusCode, errors: $errors, type: $type)';
  }
}