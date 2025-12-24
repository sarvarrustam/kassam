import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';


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
  
  // Wallet endpoints
  final String getWalletsTotalBalans = 'Kassam/hs/KassamUrl/getWalletsTotalBalans';
  final String getWalletsBalans = 'Kassam/hs/KassamUrl/getWalletsBalans';
  final String walletCreate = 'Kassam/hs/KassamUrl/walletCreate';
  final String getKurs = 'Kassam/hs/KassamUrl/getKurs';
  final String kursCreate = 'Kassam/hs/KassamUrl/kursCreate';
  
  // Transaction endpoints
  final String transactionCreate = 'Kassam/hs/KassamUrl/transactionCreate';
  final String getTransaction = 'Kassam/hs/KassamUrl/getTransaction';
  final String getTransactionTypes = 'Kassam/hs/KassamUrl/getTransactionTypes';
  final String transactionTypesCreate = 'Kassam/hs/KassamUrl/transactionTypesCreate';
  final String getWalletBalance = 'Kassam/hs/KassamUrl/getWalletBalance';
  final String getDebtorsCreditors = 'Kassam/hs/KassamUrl/getDebtorsCreditors';
  final String transactionDebtsCreate = 'Kassam/hs/KassamUrl/transactionDebtsCreate';
  final String debtorCreditorCreate = 'Kassam/hs/KassamUrl/debtorCreditorCreate';



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
        if (response.data is String) {
          final dataStr = response.data.toString().trim();
          // HTML response ni tekshirish
          if (dataStr.startsWith('<!DOCTYPE') || dataStr.startsWith('<html')) {
            print('⚠️ Server HTML qaytardi (500 error)');
            // HTML ni error ga o'tkazish
            throw DioException(
              requestOptions: response.requestOptions,
              response: response,
              type: DioExceptionType.badResponse,
              message: 'Server ichki xatolik (500)',
            );
          }
          // JSON parse qilish
          if (dataStr.startsWith('{')) {
            try {
              response.data = jsonDecode(response.data);
            } catch (e) {
              print('JSON parse error: $e');
            }
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
      
      // Headers (getHeaders() ni ishlatish - Basic Auth bilan)
      final headers = getHeaders();
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
            final errorMessage = responseData['errorMassage'] ?? 
                                responseData['message'] ?? 
                                'Xatolik';
            return {
              'success': false,
              'error': errorMessage,
              'errorCode': responseData['errorCode'] ?? 0,
              'data': responseData['data'] ?? {},
            };
          } else {
            // Success holati
            final successMessage = responseData['errorMassage'] ?? 
                                  responseData['message'] ?? 
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
    String? token,
  }) async {
    try {
      print('🔵 POST Request: $baseUrl$endpoint');
      print('🔵 POST Body: $body');
      print('🔵 POST Headers will include:');
      print('   - Authorization: Basic ... (username: $_username)');
      print('   - Content-Type: application/json');
      if (token != null) {
        print('   - token: $token');
      }
      
      // Headers (getHeaders() ni ishlatish - Basic Auth bilan)
      final headers = getHeaders();
      if (token != null) {
        headers['token'] = token;
      }
      
      print('🔵 Final headers: $headers');
      
      Response response;
      try {
        response = await _dio.post(
          endpoint,
          data: body,
          options: Options(
            headers: headers,
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
          if (errorData['errorMassage'] != null) {
            errorMsg = errorData['errorMassage'].toString();
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
          final errorMessage = responseData['errorMassage'] ?? 
                              responseData['message'] ?? 
                              'Xatolik';
          return {
            'success': false,
            'error': errorMessage,
            'errorCode': responseData['errorCode'] ?? 0,
            'data': responseData['data'] ?? {},
          };
        } else {
          // Success holati
          final successMessage = responseData['errorMassage'] ?? 
                                responseData['message'] ?? 
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

  /// Kurs yangilash
  Future<Map<String, dynamic>> updateExchangeRate(double kurs) async {
    try {
      // SharedPreferences'dan token olish
      final sp = await SharedPreferences.getInstance();
      final token = sp.getString('auth_token') ?? _authToken;
      
      print('💵 Token: $token');
      
      final body = {
        'kurs': kurs.toInt(),
        'currency': 'usd',
      };

      final response = await post(
        kursCreate,
        body: body,
        token: token,
      );
      return response;
    } catch (e) {
      return {
        'success': false,
        'error': 'Kurs yangilashda xatolik: $e',
        'errorCode': 0,
        'data': {},
      };
    }
  }

  /// Transaction qo'shish (yangi API format)
  Future<Map<String, dynamic>> createTransaction({
    required String walletId,
    required String transactionTypesId,
    required String type, // 'chiqim' yoki 'kirim'
    required String comment,
    required double amount,
  }) async {
    try {
      final sp = await SharedPreferences.getInstance();
      final token = sp.getString('auth_token') ?? _authToken;
      
      print('📝 Creating transaction: type=$type, amount=$amount');
      print('📝 Token: $token');
      
      final body = {
        'walletId': walletId,
        'transactionTypesId': transactionTypesId,
        'type': type,
        'comment': comment,
        'amount': amount,
      };

      final response = await post(
        transactionCreate,
        body: body,
        token: token,
      );
      
      print('📝 Transaction response: $response');
      return response;
    } catch (e) {
      print('❌ Transaction error: $e');
      return {
        'success': false,
        'error': 'Tranzaksiya qo\'shishda xatolik: $e',
        'errorCode': 0,
        'data': {},
      };
    }
  }

  /// Transaction qo'shish (eski format)
  Future<Map<String, dynamic>> createTransactionOld({
    required String walletId,
    required double amount,
    required String type, // 'expense' yoki 'income'
    required String category,
    String? description,
    String? date,
  }) async {
    try {
      final sp = await SharedPreferences.getInstance();
      final token = sp.getString('auth_token') ?? _authToken;
      
      print('📝 Transaction creating: type=$type, amount=$amount, category=$category');
      print('📝 Token: $token');
      
      final body = {
        'walletId': walletId,
        'amount': amount,
        'type': type,
        'category': category,
        'description': description ?? '',
        'date': date ?? DateTime.now().toIso8601String(),
      };

      final response = await post(
        transactionCreate,
        body: body,
        token: token,
      );
      return response;
    } catch (e) {
      return {
        'success': false,
        'error': 'Tranzaksiya qo\'shishda xatolik: $e',
        'errorCode': 0,
        'data': {},
      };
    }
  }

  /// Transaction turlarini olish
  Future<Map<String, dynamic>> getTransactionTypesData(String type) async {
    try {
      final sp = await SharedPreferences.getInstance();
      final token = sp.getString('auth_token') ?? _authToken;
      
      print('📊 Getting transaction types: $type...');
      print('📊 Token: $token');

      final queryParams = {'type': type};
      
      final response = await get(
        getTransactionTypes,
        queryParams: queryParams,
        token: token,
      );
      return response;
    } catch (e) {
      return {
        'success': false,
        'error': 'Tranzaksiya turlarini olishda xatolik: $e',
        'errorCode': 0,
        'data': {},
      };
    }
  }

  /// Transaction turini yaratish
  Future<Map<String, dynamic>> createTransactionType({
    required String name,
    required String type,
  }) async {
    try {
      final sp = await SharedPreferences.getInstance();
      final token = sp.getString('auth_token') ?? _authToken;

      print('➕ Creating transaction type: name=$name, type=$type');

      final body = {
        'name': name,
        'type': type,
      };

      final response = await post(
        transactionTypesCreate,
        body: body,
        token: token,
      );

      return response;
    } catch (e) {
      return {
        'success': false,
        'error': 'Tranzaksiya turini qo\'shishda xatolik: $e',
        'errorCode': 0,
        'data': {},
      };
    }
  }

  /// Tranzaksiyalarni olish
  Future<Map<String, dynamic>> getTransactions({
    required String walletId,
    required String fromDate, // Format: dd.MM.yyyy
    required String toDate,   // Format: dd.MM.yyyy
  }) async {
    try {
      final sp = await SharedPreferences.getInstance();
      final token = sp.getString('auth_token') ?? _authToken;

      print('📊 Getting transactions: walletId=$walletId, from=$fromDate, to=$toDate');
      print('📊 Token: $token');

      final queryParams = {
        'walletId': walletId,
        'fromDate': fromDate,
        'toDate': toDate,
      };

      final response = await get(
        getTransaction,
        queryParams: queryParams,
        token: token,
      );

      print('📊 Transactions response: $response');
      return response;
    } catch (e) {
      print('❌ Get transactions error: $e');
      return {
        'success': false,
        'error': 'Tranzaksiyalarni yuklashda xatolik: $e',
        'errorCode': 0,
        'data': [],
      };
    }
  }

  /// Hamyon balansi statistikasini olish (chiqim/kirim breakdown)
  Future<Map<String, dynamic>> getWalletBalanceData({
    required String walletId,
    required String fromDate, // Format: dd.MM.yyyy
    required String toDate,   // Format: dd.MM.yyyy
  }) async {
    try {
      final sp = await SharedPreferences.getInstance();
      final token = sp.getString('auth_token') ?? _authToken;

      print('💰 Getting wallet balance: walletId=$walletId, from=$fromDate, to=$toDate');
      print('💰 Token: $token');

      final queryParams = {
        'walletId': walletId,
        'fromDate': fromDate,
        'toDate': toDate,
      };

      final response = await get(
        getWalletBalance,
        queryParams: queryParams,
        token: token,
      );

      print('💰 Wallet balance response: $response');
      return response;
    } catch (e) {
      print('❌ Get wallet balance error: $e');
      return {
        'success': false,
        'error': 'Hamyon balansi yuklashda xatolik: $e',
        'errorCode': 0,
        'data': {},
      };
    }
  }

  /// Qarzkorlar va kreditorlar ro'yxatini olish
  Future<Map<String, dynamic>> getDebtorsCreditorsList() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final token = sp.getString('auth_token') ?? _authToken;

      print('👥 Getting debtors/creditors list');
      print('👥 Token: $token');

      final response = await get(
        getDebtorsCreditors,
        token: token,
      );

      print('👥 Debtors/creditors response: $response');
      return response;
    } catch (e) {
      print('❌ Get debtors/creditors error: $e');
      return {
        'success': false,
        'error': 'Qarzkorlar ro\'yxatini yuklashda xatolik: $e',
        'errorCode': 0,
        'data': [],
      };
    }
  }

  // Yangi qarzkor/kreditor yaratish
  Future<Map<String, dynamic>> createDebtorCreditor({
    required String name,
    required String telephoneNumber,
  }) async {
    print('👤 Creating debtor/creditor: $name, $telephoneNumber');
    
    try {
      // SharedPreferences'dan token olish
      final sp = await SharedPreferences.getInstance();
      final token = sp.getString('auth_token') ?? _authToken;
      print('👤 Token: $token');
      
      final body = {
        'name': name,
        'telephoneNumber': telephoneNumber,
      };
      
      // Custom headers bilan
      final headers = getHeaders();
      if (token != null && token.isNotEmpty) {
        headers['token'] = token;
      }
      
      Response response;
      try {
        response = await _dio.post(
          debtorCreditorCreate,
          data: body,
          options: Options(
            headers: headers,
            validateStatus: (status) {
              return status != null && status >= 200 && status < 600;
            },
          ),
        );
      } on DioException catch (e) {
        print('👤 DioException: ${e.message}');
        return {
          'success': false,
          'message': 'Internetga ulanishda xatolik: ${e.message}',
          'data': null,
        };
      }
      
      print('👤 Response: ${response.data}');
      
      if (response.statusCode == 200) {
        final data = response.data;
        
        if (data['error'] == false) {
          print('👤 Debtor/creditor created successfully');
          return {
            'success': true,
            'message': data['errorMassage'] ?? 'Muvaffaqiyatli qo\'shildi',
            'data': data['data'],
          };
        } else {
          print('👤 Error in response: ${data['errorMassage']}');
          return {
            'success': false,
            'message': data['errorMassage'] ?? 'Xatolik yuz berdi',
            'data': null,
          };
        }
      } else {
        print('👤 HTTP Error: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Server xatosi: ${response.statusCode}',
          'data': null,
        };
      }
    } catch (e) {
      print('👤 Exception in createDebtorCreditor: $e');
      return {
        'success': false,
        'message': 'Internetga ulanishda xatolik',
        'data': null,
      };
    }
  }

Future<Map<String, dynamic>> createTransactionDebt({
    //required String transactionTypesId,
    required String type, // qarzPulBerish, qarzPulOlish
    required String walletId,
    required String debtorCreditorId,
    required bool previousDebt,
    required String currency, // uzs, usd
    required double amount,
    required double amountDebt,
    String? comment,
  }) async {
    print('💰 Creating transaction debt: $type, amount: $amount');
    
    try {
      // SharedPreferences'dan token olish
      final sp = await SharedPreferences.getInstance();
      final token = sp.getString('auth_token') ?? _authToken;
      print('💰 Token: $token');
      
      final body = {
        'type': type,
        'walletId': walletId,
        'debtorCreditorId': debtorCreditorId,
        'previousDebt': previousDebt,
        'currency': currency.toLowerCase(),
        'amount': amount.toInt(),
        'amountDebt': amountDebt.toInt(),
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      };
      
      print('💰 Request body: $body');
      
      final response = await post(
        transactionDebtsCreate,
        body: body,
        token: token,
      );
      
      print('💰 Response: $response');
      return response;
    } catch (e) {
      print('💰 Exception in createTransactionDebt: $e');
      return {
        'success': false,
        'message': 'Internetga ulanishda xatolik',
        'data': null,
      };
    }
  }

}

