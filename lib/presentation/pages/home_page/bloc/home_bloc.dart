import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:kassam/data/services/api_service.dart';
import 'package:kassam/data/services/app_preferences_service.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final ApiService _apiService = ApiService();
  final AppPreferencesService _prefsService = AppPreferencesService();

  HomeBloc() : super(HomeInitial()) {
    on<HomeLoadUserData>(_onHomeLoadUserData);
    on<HomeRefreshData>(_onHomeRefreshData);
    on<HomeLoadWalletBalances>(_onHomeLoadWalletBalances);
    on<HomeLoadWallets>(_onHomeLoadWallets);
  }

  Future<void> _onHomeLoadUserData(
      HomeLoadUserData event, Emitter<HomeState> emit) async {
    emit(HomeLoading());
    try {
      // SharedPreferences dan ma'lumotlarni olish
      final userName = await _prefsService.getUserName();
      final phoneNumber = await _prefsService.getPhoneNumber();
      final token = await _prefsService.getAuthToken();

      print('🏠 Home: Loading user data');
      print('   Username: $userName');
      print('   Phone: $phoneNumber');
      print('   Token: $token');

      if (userName != null && userName.isNotEmpty) {
        emit(HomeLoaded(
          userName: userName,
          phoneNumber: phoneNumber ?? '',
        ));
        
        // User yuklangandan keyin wallet balanslarini yuklash
        if (token != null && token.isNotEmpty) {
          await _loadWalletBalances(token, emit);
          // Wallet balanslar yuklangandan keyin hamyonlar ro'yxatini yuklash
          await _loadWalletsList(token, emit);
        }
      } else {
        // Agar username bo'lmasa, API dan olishga harakat qilish
        if (token != null && token.isNotEmpty) {
          await _fetchUserFromApi(token, emit);
          // API dan user yuklangandan keyin walletlarni yuklash
          await _loadWalletBalances(token, emit);
          await _loadWalletsList(token, emit);
        } else {
          emit(const HomeError('Foydalanuvchi ma\'lumotlari topilmadi'));
        }
      }
    } catch (e) {
      print('❌ Home error: $e');
      emit(HomeError('Xatolik: ${e.toString()}'));
    }
  }

  Future<void> _onHomeRefreshData(
      HomeRefreshData event, Emitter<HomeState> emit) async {
    try {
      final token = await _prefsService.getAuthToken();

      if (token != null && token.isNotEmpty) {
        await _fetchUserFromApi(token, emit);
      } else {
        emit(const HomeError('Token topilmadi'));
      }
    } catch (e) {
      print('❌ Home refresh error: $e');
      emit(HomeError('Yangilashda xatolik: ${e.toString()}'));
    }
  }

  Future<void> _onHomeLoadWalletBalances(
      HomeLoadWalletBalances event, Emitter<HomeState> emit) async {
    try {
      final token = await _prefsService.getAuthToken();

      if (token == null || token.isEmpty) {
        emit(const HomeError('Token topilmadi'));
        return;
      }

      print('💰 Loading wallet balances...');
      final response = await _apiService.get(
        _apiService.getWalletsTotalBalans,
        token: token,
      );

      print('💰 Wallet response: $response');

      if (response['success'] == true) {
        final data = response['data'];
        
        // API dan UZS va USD balanslarini olish
        final totalUZS = (data['totalUZS'] ?? 0).toDouble();
        final totalUSD = (data['totalUSD'] ?? 0).toDouble();

        print('✅ Wallet balances loaded: UZS=$totalUZS, USD=$totalUSD');

        // Agar hozirgi state HomeLoaded bo'lsa, uni yangilaymiz
        if (state is HomeLoaded) {
          final currentState = state as HomeLoaded;
          emit(currentState.copyWith(
            totalUZS: totalUZS,
            totalUSD: totalUSD,
          ));
        } else {
          // Aks holda username bilan birga emit qilamiz
          final userName = await _prefsService.getUserName() ?? 'Foydalanuvchi';
          final phoneNumber = await _prefsService.getPhoneNumber() ?? '';
          
          emit(HomeLoaded(
            userName: userName,
            phoneNumber: phoneNumber,
            totalUZS: totalUZS,
            totalUSD: totalUSD,
          ));
        }
      } else {
        print('❌ Wallet API error: ${response['error']}');
        emit(HomeError(response['error'] ?? 'Wallet ma\'lumotlarini olishda xatolik'));
      }
    } catch (e) {
      print('❌ Wallet fetch error: $e');
      emit(HomeError('Wallet balanslarini olishda xatolik: ${e.toString()}'));
    }
  }

  Future<void> _onHomeLoadWallets(
      HomeLoadWallets event, Emitter<HomeState> emit) async {
    try {
      final token = await _prefsService.getAuthToken();

      if (token == null || token.isEmpty) {
        emit(const HomeError('Token topilmadi'));
        return;
      }

      print('👛 Loading wallets list...');
      final response = await _apiService.get(
        _apiService.getWalletsBalans,
        token: token,
      );

      print('👛 Wallets response: $response');

      if (response['success'] == true) {
        final data = response['data'];
        
        // API dan hamyonlar ro'yxatini olish
        List<Map<String, dynamic>> walletsList = [];
        
        if (data is List) {
          walletsList = data.map((wallet) => wallet as Map<String, dynamic>).toList();
        } else if (data is Map && data.containsKey('wallets')) {
          final wallets = data['wallets'];
          if (wallets is List) {
            walletsList = wallets.map((wallet) => wallet as Map<String, dynamic>).toList();
          }
        }

        print('✅ Wallets loaded: ${walletsList.length} hamyonlar');
        
        // Har bir hamyon ma'lumotini chop etish
        for (var i = 0; i < walletsList.length; i++) {
          final wallet = walletsList[i];
          print('   Wallet #$i: ${wallet['name']} - ${wallet['value']} (type: ${wallet['type']})');
        }

        // Agar hozirgi state HomeLoaded bo'lsa, uni yangilaymiz
        if (state is HomeLoaded) {
          final currentState = state as HomeLoaded;
          emit(currentState.copyWith(wallets: walletsList));
        } else {
          // Aks holda username bilan birga emit qilamiz
          final userName = await _prefsService.getUserName() ?? 'Foydalanuvchi';
          final phoneNumber = await _prefsService.getPhoneNumber() ?? '';
          
          emit(HomeLoaded(
            userName: userName,
            phoneNumber: phoneNumber,
            wallets: walletsList,
          ));
        }
      } else {
        print('❌ Wallets API error: ${response['error']}');
        emit(HomeError(response['error'] ?? 'Hamyonlar ma\'lumotlarini olishda xatolik'));
      }
    } catch (e) {
      print('❌ Wallets fetch error: $e');
      emit(HomeError('Hamyonlar ro\'yxatini olishda xatolik: ${e.toString()}'));
    }
  }

  Future<void> _fetchUserFromApi(
      String token, Emitter<HomeState> emit) async {
    try {
      print('📡 Fetching user data from API...');
      final response = await _apiService.get(
        _apiService.getUser,
        token: token,
      );

      if (response['success'] == true) {
        final data = response['data'];
        final userName = data['name'] ?? 'Foydalanuvchi';
        final phoneNumber = data['telephoneNumber'] ?? '';

        // Ma'lumotlarni saqlash
        await _prefsService.setUserName(userName);
        if (phoneNumber.isNotEmpty) {
          await _prefsService.setPhoneNumber(phoneNumber);
        }

        print('✅ User data loaded from API');
        emit(HomeLoaded(
          userName: userName,
          phoneNumber: phoneNumber,
        ));
      } else {
        emit(HomeError(response['error'] ?? 'API xatolik'));
      }
    } catch (e) {
      print('❌ API fetch error: $e');
      emit(HomeError('API dan ma\'lumot olishda xatolik: ${e.toString()}'));
    }
  }
  
  // Helper method: Wallet balanslarini yuklash
  Future<void> _loadWalletBalances(String token, Emitter<HomeState> emit) async {
    try {
      print('💰 Loading wallet balances...');
      final response = await _apiService.get(
        _apiService.getWalletsTotalBalans,
        token: token,
      );

      print('💰 Wallet response: $response');

      if (response['success'] == true) {
        final data = response['data'];
        
        // API formatiga mos: som, dollar, somTotal, dollarTotal
        final totalUZS = (data['somTotal'] ?? data['som'] ?? 0).toDouble();
        final totalUSD = (data['dollarTotal'] ?? data['dollar'] ?? 0).toDouble();

        print('✅ Wallet balances loaded: som=$totalUZS, dollar=$totalUSD');
        print('   Raw data: som=${data['som']}, dollar=${data['dollar']}, somTotal=${data['somTotal']}, dollarTotal=${data['dollarTotal']}');

        if (state is HomeLoaded) {
          final currentState = state as HomeLoaded;
          emit(currentState.copyWith(
            totalUZS: totalUZS,
            totalUSD: totalUSD,
          ));
        }
      } else {
        print('❌ Wallet API error: ${response['error']}');
      }
    } catch (e) {
      print('❌ Wallet fetch error: $e');
    }
  }
  
  // Helper method: Hamyonlar ro'yxatini yuklash
  Future<void> _loadWalletsList(String token, Emitter<HomeState> emit) async {
    try {
      print('👛 Loading wallets list...');
      final response = await _apiService.get(
        _apiService.getWalletsBalans,
        token: token,
      );

      print('👛 Wallets response: $response');

      if (response['success'] == true) {
        final data = response['data'];
        
        List<Map<String, dynamic>> walletsList = [];
        
        if (data is List) {
          walletsList = data.map((wallet) => wallet as Map<String, dynamic>).toList();
        } else if (data is Map && data.containsKey('wallets')) {
          final wallets = data['wallets'];
          if (wallets is List) {
            walletsList = wallets.map((wallet) => wallet as Map<String, dynamic>).toList();
          }
        }

        print('✅ Wallets loaded: ${walletsList.length} hamyonlar');

        if (state is HomeLoaded) {
          final currentState = state as HomeLoaded;
          emit(currentState.copyWith(wallets: walletsList));
        }
      } else {
        print('❌ Wallets API error: ${response['error']}');
      }
    } catch (e) {
      print('❌ Wallets fetch error: $e');
    }
  }
}
