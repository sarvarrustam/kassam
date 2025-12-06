import 'dart:convert';
import 'package:dio/dio.dart';


class ApiService {

  String baseUrl = 'https://master.cloudhoff.uz/'; 

  //https://master.cloudhoff.uz/Kassam/hs/KassamUrl/getSms

  String  _username = "Администратор";  
  String  _password = "1230";  

   String? apiKey = null;  
   Duration connectTimeout = Duration(seconds: 30);
   Duration receiveTimeout = Duration(seconds: 30);
  
  

  //final String getSms = 'Agrowide/hs/KassamUrl/getSms';
  final String getSms = 'Kassam/hs/KassamUrl/getSms';
  final String checkSms = 'Kassam/hs/KassamUrl/getCheckSms';
  final String profileSave = 'Kassam/hs/KassamUrl/profileSave';
  final String getUser = 'Kassam/hs/KassamUrl/getUser';
  
  // Location endpoints
  final String getState = 'Kassam/hs/KassamUrl/getState';
  final String getRegion = 'Kassam/hs/KassamUrl/getRegion';
  final String getDistricts = 'Kassam/hs/KassamUrl/getDistricts';



  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal() {
    _initDio();
  }



  late final Dio _dio;
  String? _authToken;

  void _initDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout,
        headers: getHeaders(),
        responseType: ResponseType.json, // JSON sifatida parse qilish
        contentType: 'application/json',
      ),
    );
    
    // JSON Interceptor - String bo'lsa parse qilish
    _dio.interceptors.add(InterceptorsWrapper(
      onResponse: (response, handler) {
        if (response.data is String && response.data.toString().trim().startsWith('{')) {
          try {
            response.data = jsonDecode(response.data);
          } catch (e) {
            print('JSON parse error: $e');
          }
        }
        handler.next(response);
      },
    ));
  }
  
  /// Headers qurish
  Map<String, String> getHeaders() {
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      
    };
    
    // API Key
    if (apiKey != null) {
      headers['X-API-Key'] = apiKey!;
    }
    
    // Basic Auth
    if (_username.isNotEmpty && _password.isNotEmpty) {
      final credentials = '$_username:$_password';
      final base64Credentials = base64.encode(utf8.encode(credentials));
      headers['Authorization'] = 'Basic $base64Credentials';
    }
    
    return headers;
  }

  /// Token sozlash
  void setToken(String token) {
    _authToken = token;
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  
  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    String? token,
  }) async {
    try {
      print('GET Request: $baseUrl$endpoint');
      print('Query Params: $queryParams');
      if (token != null) print('Token: $token');
      
      // Headers
      final headers = <String, dynamic>{};
      if (token != null) {
        headers['token'] = token;
      }
      
      final response = await _dio.get(
        endpoint,
        queryParameters: queryParams,
        options: Options(headers: headers),
      );

      print('Response Status: ${response.statusCode}');
      print('Response Data: ${response.data}');
     

      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data;
        
        // Agar Map bo'lmasa
        if (responseData is! Map) {
          print('WARNING: Response Map emas: ${responseData.runtimeType}');
          return {
            'success': false,
            'error': 'Server noto\'g\'ri format qaytardi',
            'errorCode': 0,
            'data': {},
          };
        }
        
        // 1C formatini tekshirish
        if (responseData.containsKey('error')) {
          final hasError = responseData['error'] == true;
          
          if (hasError) {
            // Error holati
            final errorMessage = responseData['message'] ?? 
                                responseData['errormassage'] ?? 
                                'Xatolik';
            return {
              'success': false,
              'error': errorMessage,
              'errorCode': responseData['errorCode'] ?? 0,
              'data': responseData['data'] ?? {},
            };
          } else {
            // Success holati
            final successMessage = responseData['message'] ?? 
                                  responseData['errormassage'] ?? 
                                  'Muvaffaqiyatli';
            return {
              'success': true,
              'message': successMessage,
              'errorCode': 0,
              'data': responseData['data'] ?? {},
            };
          }
        }
        
        // Agar 1C formati bo'lmasa, oddiy success qaytarish
        return {
          'success': true,
          'data': responseData,
          'errorCode': 0,
        };
      }

      return {
        'success': false,
        'error': 'Server xatosi',
        'errorCode': response.statusCode ?? 0,
        'data': {},
      };
    } on DioException catch (e) {
      print('DioException: ${e.type}');
      print('Error Message: ${e.message}');
      if (e.response?.data != null) {
        print('Response Data Type: ${e.response?.data.runtimeType}');
        print('Response Data (first 200 chars): ${e.response?.data.toString().substring(0, 200)}...');
      }
      
      return {
        'success': false,
        'error': _handleError(e),
        'errorCode': e.response?.statusCode ?? 0,
        'data': {},
      };
    } catch (e, stackTrace) {

      print('Unexpected Error: $e');
      print('Stack Trace: $stackTrace');
      
      return {
        'success': false,
        'error': 'Kutilmagan xatolik: ${e.toString()}',
        'errorCode': 0,
        'data': {},
      };
    }
  }

 
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    try {
      print('🔵 POST Request: $baseUrl$endpoint');
      print('🔵 POST Body: $body');
      
      Response response;
      try {
        response = await _dio.post(
          endpoint,
          data: body,
          options: Options(
            validateStatus: (status) {
              // Barcha status kodlarni qabul qilamiz (200-599)
              return status != null && status >= 200 && status < 600;
            },
          ),
        );
      } catch (dioError) {
        print('🔴 Dio Error Type: ${dioError.runtimeType}');
        print('🔴 Dio Error: $dioError');
        
        // DioException bo'lsa, response bormi tekshiramiz
        if (dioError is DioException && dioError.response != null) {
          final errorResponse = dioError.response!;
          print('🔴 Error Response Status: ${errorResponse.statusCode}');
          print('🔴 Error Response Data: ${errorResponse.data}');
          
          return {
            'success': false,
            'error': 'Server xatolik (${errorResponse.statusCode})',
            'errorCode': errorResponse.statusCode ?? 0,
            'data': {},
          };
        }
        
        return {
          'success': false,
          'error': 'Tarmoq xatoligi',
          'errorCode': 0,
          'data': {},
        };
      }

      print('🟢 POST Response Status: ${response.statusCode}');
      print('🟢 POST Response Type: ${response.data.runtimeType}');
      print('🟢 POST Response Data: ${response.data}');

      // 500 yoki boshqa xatolik statuslarini tekshirish
      if (response.statusCode != null && response.statusCode! >= 400) {
        String errorMsg = 'Server xatoligi (${response.statusCode})';
        
        // Agar 1C format qaytarsa
        if (response.data is Map) {
          final errorData = response.data as Map;
          if (errorData['errormassage'] != null) {
            errorMsg = errorData['errormassage'].toString();
          } else if (errorData['message'] != null) {
            errorMsg = errorData['message'].toString();
          }
        }
        
        return {
          'success': false,
          'error': errorMsg,
          'errorCode': response.statusCode ?? 0,
          'data': {},
        };
      }

      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data;
        
        // Agar String bo'lsa (HTML)
        if (responseData is String) {
          return {
            'success': false,
            'error': 'Server noto\'g\'ri format qaytardi (HTML)',
            'errorCode': 0,
            'data': {},
          };
        }
        
        // Agar Map bo'lmasa
        if (responseData is! Map) {
          return {
            'success': false,
            'error': 'Server noto\'g\'ri format qaytardi',
            'errorCode': 0,
            'data': {},
          };
        }
        
        // 1C format: error maydonini tekshirish
        final hasError = responseData['error'] == true;
        
        if (hasError) {
          // Error holati
          final errorMessage = responseData['message'] ?? 
                              responseData['errormassage'] ?? 
                              'Xatolik';
          return {
            'success': false,
            'error': errorMessage,
            'errorCode': responseData['errorCode'] ?? 0,
            'data': responseData['data'] ?? {},
          };
        } else {
          // Success holati
          final successMessage = responseData['message'] ?? 
                                responseData['errormassage'] ?? 
                                'Muvaffaqiyatli';
          return {
            'success': true,
            'message': successMessage,
            'errorCode': 0,
            'data': responseData['data'] ?? {},
          };
        }
      }

      return {
        'success': false,
        'error': 'Server xatosi',
        'errorCode': response.statusCode ?? 0,
        'data': {},
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': _handleError(e),
        'errorCode': e.response?.statusCode ?? 0,
        'data': {},
      };
    }
  }

  /// Error handler
  String _handleError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Serverga ulanishda xatolik. Qayta urinib ko\'ring.';
      case DioExceptionType.connectionError:
        return 'Internet bilan aloqa yo\'q.';
      case DioExceptionType.badResponse:
        return e.response?.data['error'] ?? 'Server xatosi';
      default:
        return 'Kutilmagan xatolik yuz berdi';
    }
  }
}
