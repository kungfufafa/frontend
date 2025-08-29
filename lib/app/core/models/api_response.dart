/// Wrapper class untuk standardisasi response API di seluruh aplikasi
/// Menggunakan prinsip KISS untuk handling response yang konsisten
class ApiResponse<T> {
  final bool isSuccess;
  final T? data;
  final String message;
  final int statusCode;
  final Map<String, dynamic>? errors;
  final Map<String, dynamic>? meta;
  final String? errorCode;
  
  const ApiResponse._({
    required this.isSuccess,
    this.data,
    required this.message,
    required this.statusCode,
    this.errors,
    this.meta,
    this.errorCode,
  });
  
  /// Factory constructor untuk response yang berhasil
  factory ApiResponse.success({
    required T data,
    String message = 'Berhasil',
    int statusCode = 200,
    Map<String, dynamic>? meta,
  }) {
    return ApiResponse._(
      isSuccess: true,
      data: data,
      message: message,
      statusCode: statusCode,
      meta: meta,
    );
  }
  
  /// Factory constructor untuk response yang gagal
  factory ApiResponse.error({
    required String message,
    required int statusCode,
    Map<String, dynamic>? errors,
    String? errorCode,
    T? data,
  }) {
    return ApiResponse._(
      isSuccess: false,
      data: data,
      message: message,
      statusCode: statusCode,
      errors: errors,
      errorCode: errorCode,
    );
  }
  
  /// Factory constructor untuk parsing dari response HTTP
  factory ApiResponse.fromResponse(
    dynamic response, {
    T Function(dynamic)? fromJson,
    String? defaultMessage,
  }) {
    try {
      final statusCode = response.statusCode ?? 0;
      final body = response.body;
      
      // Determine if response is successful
      final isSuccessStatus = statusCode >= 200 && statusCode < 300;
      
      if (body == null) {
        return ApiResponse.error(
          message: defaultMessage ?? 'Response kosong',
          statusCode: statusCode,
        );
      }
      
      // Handle different response body types
      if (body is Map<String, dynamic>) {
        return _parseMapResponse(body, statusCode, isSuccessStatus, fromJson, defaultMessage);
      } else if (body is List) {
        return _parseListResponse(body, statusCode, isSuccessStatus, fromJson, defaultMessage);
      } else {
        return _parseStringResponse(body, statusCode, isSuccessStatus, defaultMessage);
      }
    } catch (e) {
      return ApiResponse.error(
        message: defaultMessage ?? 'Gagal memparse response: $e',
        statusCode: 0,
      );
    }
  }
  
  /// Parse Map response (most common API response format)
  static ApiResponse<T> _parseMapResponse<T>(
    Map<String, dynamic> body,
    int statusCode,
    bool isSuccessStatus,
    T Function(dynamic)? fromJson,
    String? defaultMessage,
  ) {
    // Check for explicit success field
    final hasSuccessField = body.containsKey('success');
    final isExplicitSuccess = hasSuccessField ? (body['success'] == true) : null;
    
    // Determine overall success
    final isSuccess = isExplicitSuccess ?? isSuccessStatus;
    
    if (isSuccess) {
      return _createSuccessResponse(body, statusCode, fromJson, defaultMessage);
    } else {
      return _createErrorResponse(body, statusCode, defaultMessage);
    }
  }
  
  /// Parse List response (direct array response)
  static ApiResponse<T> _parseListResponse<T>(
    List<dynamic> body,
    int statusCode,
    bool isSuccessStatus,
    T Function(dynamic)? fromJson,
    String? defaultMessage,
  ) {
    if (isSuccessStatus) {
      final data = fromJson != null ? fromJson(body) : body as T?;
      if (data == null) {
        return ApiResponse.error(
          message: defaultMessage ?? 'Data tidak valid',
          statusCode: statusCode,
        );
      }
      return ApiResponse.success(
        data: data,
        message: defaultMessage ?? 'Berhasil',
        statusCode: statusCode,
      );
    } else {
      return ApiResponse.error(
        message: defaultMessage ?? 'Gagal memuat data',
        statusCode: statusCode,
      );
    }
  }
  
  /// Parse String response
  static ApiResponse<T> _parseStringResponse<T>(
    dynamic body,
    int statusCode,
    bool isSuccessStatus,
    String? defaultMessage,
  ) {
    final message = body.toString();
    
    if (isSuccessStatus) {
      return ApiResponse.success(
        data: body as T,
        message: defaultMessage ?? message,
        statusCode: statusCode,
      );
    } else {
      return ApiResponse.error(
        message: defaultMessage ?? message,
        statusCode: statusCode,
      );
    }
  }
  
  /// Create success response from Map
  static ApiResponse<T> _createSuccessResponse<T>(
    Map<String, dynamic> body,
    int statusCode,
    T Function(dynamic)? fromJson,
    String? defaultMessage,
  ) {
    // Extract data
    T? data;
    if (fromJson != null) {
      final dataField = _extractDataField(body);
      data = dataField != null ? fromJson(dataField) : null;
    } else {
      data = _extractDataField(body) as T?;
    }
    
    // Extract message
    final message = _extractMessage(body) ?? defaultMessage ?? 'Berhasil';
    
    // Extract meta information
    final meta = _extractMeta(body);
    
    if (data == null) {
      return ApiResponse.error(
        message: defaultMessage ?? 'Data tidak tersedia',
        statusCode: statusCode,
      );
    }
    
    return ApiResponse.success(
      data: data,
      message: message,
      statusCode: statusCode,
      meta: meta,
    );
  }
  
  /// Create error response from Map
  static ApiResponse<T> _createErrorResponse<T>(
    Map<String, dynamic> body,
    int statusCode,
    String? defaultMessage,
  ) {
    final message = _extractMessage(body) ?? 
                   defaultMessage ?? 
                   'Terjadi kesalahan';
    
    final errors = _extractErrors(body);
    final errorCode = _extractErrorCode(body);
    
    return ApiResponse.error(
      message: message,
      statusCode: statusCode,
      errors: errors,
      errorCode: errorCode,
    );
  }
  
  /// Extract data field from response body
  static dynamic _extractDataField(Map<String, dynamic> body) {
    // Try different common data field names
    const dataFields = ['data', 'result', 'payload', 'content'];
    
    for (final field in dataFields) {
      if (body.containsKey(field)) {
        return body[field];
      }
    }
    
    // If no explicit data field, return the whole body
    return body;
  }
  
  /// Extract message from response body
  static String? _extractMessage(Map<String, dynamic> body) {
    const messageFields = ['message', 'msg', 'description', 'detail'];
    
    for (final field in messageFields) {
      if (body.containsKey(field) && body[field] != null) {
        return body[field].toString();
      }
    }
    
    return null;
  }
  
  /// Extract errors from response body
  static Map<String, dynamic>? _extractErrors(Map<String, dynamic> body) {
    const errorFields = ['errors', 'validation_errors', 'field_errors'];
    
    for (final field in errorFields) {
      if (body.containsKey(field) && body[field] is Map) {
        return body[field] as Map<String, dynamic>;
      }
    }
    
    return null;
  }
  
  /// Extract error code from response body
  static String? _extractErrorCode(Map<String, dynamic> body) {
    const codeFields = ['error_code', 'code', 'error_type'];
    
    for (final field in codeFields) {
      if (body.containsKey(field) && body[field] != null) {
        return body[field].toString();
      }
    }
    
    return null;
  }
  
  /// Extract meta information from response body
  static Map<String, dynamic>? _extractMeta(Map<String, dynamic> body) {
    const metaFields = ['meta', 'pagination', 'info'];
    
    for (final field in metaFields) {
      if (body.containsKey(field) && body[field] is Map) {
        return body[field] as Map<String, dynamic>;
      }
    }
    
    // Extract pagination fields directly from body
    const paginationFields = [
      'current_page', 'last_page', 'per_page', 'total',
      'from', 'to', 'has_more_pages', 'next_page_url', 'prev_page_url'
    ];
    
    final Map<String, dynamic> extractedMeta = {};
    for (final field in paginationFields) {
      if (body.containsKey(field)) {
        extractedMeta[field] = body[field];
      }
    }
    
    return extractedMeta.isNotEmpty ? extractedMeta : null;
  }
  
  /// Check if response has more pages (for pagination)
  bool get hasMorePages {
    if (meta == null) return false;
    
    // Check various pagination indicators
    if (meta!.containsKey('has_more_pages')) {
      return meta!['has_more_pages'] == true;
    }
    
    if (meta!.containsKey('current_page') && meta!.containsKey('last_page')) {
      final currentPage = meta!['current_page'] as int? ?? 0;
      final lastPage = meta!['last_page'] as int? ?? 0;
      return currentPage < lastPage;
    }
    
    return false;
  }
  
  /// Get current page number
  int get currentPage {
    return meta?['current_page'] as int? ?? 1;
  }
  
  /// Get total items count
  int get totalItems {
    return meta?['total'] as int? ?? 0;
  }
  
  /// Get items per page
  int get perPage {
    return meta?['per_page'] as int? ?? 0;
  }
  
  /// Get last page number
  int get lastPage {
    return meta?['last_page'] as int? ?? 1;
  }
  
  /// Check if this is a validation error (422)
  bool get isValidationError => statusCode == 422 && errors != null;
  
  /// Check if this is an authentication error (401)
  bool get isAuthError => statusCode == 401;
  
  /// Check if this is a forbidden error (403)
  bool get isForbiddenError => statusCode == 403;
  
  /// Check if this is a not found error (404)
  bool get isNotFoundError => statusCode == 404;
  
  /// Check if this is a server error (5xx)
  bool get isServerError => statusCode >= 500;
  
  /// Get first validation error message
  String? get firstValidationError {
    if (!isValidationError || errors == null) return null;
    
    final firstError = errors!.values.first;
    if (firstError is List && firstError.isNotEmpty) {
      return firstError.first.toString();
    } else if (firstError is String) {
      return firstError;
    }
    
    return null;
  }
  
  /// Convert to JSON representation
  Map<String, dynamic> toJson() {
    return {
      'isSuccess': isSuccess,
      'data': data,
      'message': message,
      'statusCode': statusCode,
      'errors': errors,
      'meta': meta,
      'errorCode': errorCode,
    };
  }
  
  @override
  String toString() {
    return 'ApiResponse(isSuccess: $isSuccess, message: $message, statusCode: $statusCode)';
  }
}

/// Helper class untuk membuat ApiResponse dengan mudah
class ApiResponseBuilder<T> {
  T? data;
  String message = '';
  int statusCode = 200;
  Map<String, dynamic>? errors;
  Map<String, dynamic>? meta;
  String? errorCode;
  
  ApiResponseBuilder<T> setData(T data) {
    this.data = data;
    return this;
  }
  
  ApiResponseBuilder<T> setMessage(String message) {
    this.message = message;
    return this;
  }
  
  ApiResponseBuilder<T> setStatusCode(int statusCode) {
    this.statusCode = statusCode;
    return this;
  }
  
  ApiResponseBuilder<T> setErrors(Map<String, dynamic> errors) {
    this.errors = errors;
    return this;
  }
  
  ApiResponseBuilder<T> setMeta(Map<String, dynamic> meta) {
    this.meta = meta;
    return this;
  }
  
  ApiResponseBuilder<T> setErrorCode(String errorCode) {
    this.errorCode = errorCode;
    return this;
  }
  
  ApiResponse<T> buildSuccess() {
    if (data == null) {
      throw ArgumentError('Data cannot be null for success response');
    }
    return ApiResponse.success(
      data: data as T,
      message: message.isEmpty ? 'Berhasil' : message,
      statusCode: statusCode,
      meta: meta,
    );
  }
  
  ApiResponse<T> buildError() {
    return ApiResponse.error(
      message: message.isEmpty ? 'Terjadi kesalahan' : message,
      statusCode: statusCode,
      errors: errors,
      errorCode: errorCode,
      data: data,
    );
  }
}