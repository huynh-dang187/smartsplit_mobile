import 'dart:io';
import 'package:dio/dio.dart';
import 'package:smartsplit_mobile/src/common/configs/app_config.dart';
import 'package:smartsplit_mobile/src/core/domain/entities/base_result.dart';
import 'package:smartsplit_mobile/src/core/infrastructure/datasources/local/secured_storage.dart';
import 'endpoint_type.dart';

/// Client mạng Dio bọc chuẩn hóa cho ứng dụng SmartSplit.
/// 
/// Tự động gắn Bearer Token, chuẩn hóa phản hồi và bắt lỗi API từ Express Backend
/// theo định dạng `BaseResult<T>` quy định tại contract.md.
class RestfulRequest {
  final Dio _dio;
  final SecuredStorage _securedStorage;

  RestfulRequest({
    required SecuredStorage securedStorage,
    Dio? dio,
  })  : _securedStorage = securedStorage,
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: AppConfig.baseUrl,
                connectTimeout: AppConfig.connectTimeout,
                receiveTimeout: AppConfig.receiveTimeout,
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            ) {
    _initInterceptors();
  }

  void _initInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _securedStorage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );
  }

  /// Thực hiện GET Request
  Future<BaseResult<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic data)? fromJson,
  }) {
    return _request<T>(
      path,
      type: EndpointType.get,
      queryParameters: queryParameters,
      fromJson: fromJson,
    );
  }

  /// Thực hiện POST Request
  Future<BaseResult<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic data)? fromJson,
  }) {
    return _request<T>(
      path,
      type: EndpointType.post,
      data: data,
      queryParameters: queryParameters,
      fromJson: fromJson,
    );
  }

  /// Thực hiện PUT Request
  Future<BaseResult<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic data)? fromJson,
  }) {
    return _request<T>(
      path,
      type: EndpointType.put,
      data: data,
      queryParameters: queryParameters,
      fromJson: fromJson,
    );
  }

  /// Thực hiện DELETE Request
  Future<BaseResult<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic data)? fromJson,
  }) {
    return _request<T>(
      path,
      type: EndpointType.delete,
      data: data,
      queryParameters: queryParameters,
      fromJson: fromJson,
    );
  }

  /// Upload file hình ảnh hóa đơn qua Multipart/Form-Data (field: `receipt`)
  Future<BaseResult<T>> postMultipart<T>(
    String path, {
    required FormData formData,
    T Function(dynamic data)? fromJson,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: formData,
        onSendProgress: onSendProgress,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );
      return _handleSuccessResponse<T>(response, fromJson);
    } on DioException catch (e) {
      return _handleDioError<T>(e);
    } catch (e) {
      return BaseResult<T>.fail(
        'Lỗi không xác định: ${e.toString()}',
        errorCode: 'UNEXPECTED_ERROR',
      );
    }
  }

  /// Hàm điều phối Request chính
  Future<BaseResult<T>> _request<T>(
    String path, {
    required EndpointType type,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic data)? fromJson,
  }) async {
    try {
      Response response;
      switch (type) {
        case EndpointType.get:
          response = await _dio.get(path, queryParameters: queryParameters);
          break;
        case EndpointType.post:
          response = await _dio.post(path, data: data, queryParameters: queryParameters);
          break;
        case EndpointType.put:
          response = await _dio.put(path, data: data, queryParameters: queryParameters);
          break;
        case EndpointType.delete:
          response = await _dio.delete(path, data: data, queryParameters: queryParameters);
          break;
        default:
          response = await _dio.get(path, queryParameters: queryParameters);
      }

      return _handleSuccessResponse<T>(response, fromJson);
    } on DioException catch (e) {
      return _handleDioError<T>(e);
    } catch (e) {
      return BaseResult<T>.fail(
        'Lỗi không xác định: ${e.toString()}',
        errorCode: 'UNEXPECTED_ERROR',
      );
    }
  }

  /// Xử lý phản hồi thành công từ Backend
  BaseResult<T> _handleSuccessResponse<T>(
    Response response,
    T Function(dynamic data)? fromJson,
  ) {
    final rawData = response.data;
    if (rawData is Map<String, dynamic>) {
      final bool isSuccess = rawData['success'] == true;
      final String? message = rawData['message'] as String?;
      final String? errorCode = rawData['errorCode'] as String?;

      if (!isSuccess) {
        return BaseResult<T>.fail(
          message ?? 'Yêu cầu không thành công',
          errorCode: errorCode,
        );
      }

      final dynamic payload = rawData['data'];
      T? parsedData;
      if (fromJson != null && payload != null) {
        parsedData = fromJson(payload);
      } else if (payload is T) {
        parsedData = payload;
      }

      return BaseResult<T>.ok(parsedData as T, message: message);
    }

    return BaseResult<T>.fail('Định dạng phản hồi không hợp lệ');
  }

  /// Bắt và chuẩn hóa các lỗi mạng/HTTP từ Backend Express
  BaseResult<T> _handleDioError<T>(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return BaseResult<T>.fail(
        'Kết nối quá hạn, vui lòng thử lại sau',
        errorCode: 'TIMEOUT_ERROR',
      );
    }

    if (error.error is SocketException ||
        error.type == DioExceptionType.connectionError) {
      return BaseResult<T>.fail(
        'Không thể kết nối đến máy chủ. Vui lòng kiểm tra mạng và URL',
        errorCode: 'NETWORK_ERROR',
      );
    }

    // Đọc thông báo lỗi chi tiết từ Backend Express trả về
    final responseData = error.response?.data;
    if (responseData is Map<String, dynamic>) {
      final message = responseData['message'] as String?;
      final errorCode = responseData['errorCode'] as String?;
      if (message != null && message.isNotEmpty) {
        return BaseResult<T>.fail(
          message,
          errorCode: errorCode ?? 'API_ERROR',
        );
      }
    }

    // Trường hợp mã lỗi HTTP cụ thể
    final statusCode = error.response?.statusCode;
    switch (statusCode) {
      case 400:
        return BaseResult<T>.fail('Dữ liệu yêu cầu không hợp lệ', errorCode: 'BAD_REQUEST');
      case 401:
        return BaseResult<T>.fail('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại', errorCode: 'UNAUTHORIZED');
      case 403:
        return BaseResult<T>.fail('Bạn không có quyền thực hiện thao tác này', errorCode: 'FORBIDDEN');
      case 404:
        return BaseResult<T>.fail('Không tìm thấy tài nguyên yêu cầu', errorCode: 'NOT_FOUND');
      case 500:
        return BaseResult<T>.fail('Lỗi máy chủ nội bộ. Vui lòng thử lại sau', errorCode: 'INTERNAL_SERVER_ERROR');
      default:
        return BaseResult<T>.fail(
          error.message ?? 'Đã xảy ra lỗi kết nối',
          errorCode: 'UNKNOWN_HTTP_ERROR',
        );
    }
  }
}
