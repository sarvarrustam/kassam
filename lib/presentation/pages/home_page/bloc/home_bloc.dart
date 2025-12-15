import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:kassam/data/models/wallet_balance_model.dart';
import 'package:kassam/data/services/api_service.dart';
import 'package:kassam/data/services/app_preferences_service.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final ApiService _apiService = ApiService();
  final AppPreferencesService _prefsService = AppPreferencesService();

  HomeBloc() : super(HomeInitial()) {
    on<HomeGetWalletsEvent>(_onHomeGetWallets);
    on<HomeGetTotalBalancesEvent>(_onHomeGetTotalBalances);
    on<HomeGetInitialDataEvent>(_onHomeGetInitialData);
    on<HomeCreateWalletEvent>(_onHomeCreateWallet);
    on<HomeGetExchangeRateEvent>(_onHomeGetExchangeRate);
    on<HomeUpdateExchangeRateEvent>(_onHomeUpdateExchangeRate);
  }

  // Initial data - barcha ma'lumotlarni yuklash
  Future<void> _onHomeGetInitialData(
    HomeGetInitialDataEvent event,
    Emitter<HomeState> emit,
  ) async {
    emit(HomeLoading());
    
    // Hamyonlarni yuklash
    add(HomeGetWalletsEvent());
 
    // Total balanslarni yuklash
    add(HomeGetTotalBalancesEvent());
  }

  // Hamyonlar ro'yxatini yuklash
  Future<void> _onHomeGetWallets(
    HomeGetWalletsEvent event,
    Emitter<HomeState> emit,
  ) async {
    try {
      emit(HomeWalletsLoading());
      
      final token = await _prefsService.getAuthToken();
      
      if (token == null || token.isEmpty) {
        emit(const HomeError('Token topilmadi'));
        return;
      }

      print('👛 Loading wallets...');
      final response = await _apiService.get(
        _apiService.getWalletsBalans,
        token: token,
      );

      print('👛 Wallets response: $response');

      if (response['success'] == true) {
        final data = response['data'];
        
        List<WalletBalance> walletsList = [];
        
        if (data is List) {
          walletsList = data
              .map((wallet) => WalletBalance.fromJson(wallet as Map<String, dynamic>))
              .toList();
        } else if (data is Map && data.containsKey('wallets')) {
          final wallets = data['wallets'];
          if (wallets is List) {
            walletsList = wallets
                .map((wallet) => WalletBalance.fromJson(wallet as Map<String, dynamic>))
                .toList();
          }
        }

        print('✅ Wallets loaded: ${walletsList.length} hamyonlar');
        walletsList.asMap().forEach((index, wallet) {
          print('   👛 Wallet #$index: $wallet');
        });

        emit(HomeGetWalletsSuccess(walletsList));
      } else {
        final errorMsg = response['error'] ?? 'Server xatosi';
        print('❌ Wallets API error: $errorMsg');
        emit(HomeError(errorMsg));
      }
    } catch (e, stackTrace) {
      print('❌ Wallets fetch error: $e');
      print('Stack trace: $stackTrace');
      emit(HomeError('Hamyonlarni yuklashda xatolik: ${e.toString()}'));
    }
  }

  // Total balanslarni yuklash
  Future<void> _onHomeGetTotalBalances(
    HomeGetTotalBalancesEvent event,
    Emitter<HomeState> emit,
  ) async {
    try {
      emit(HomeTotalBalancesLoading());
      
      final token = await _prefsService.getAuthToken();
      
      if (token == null || token.isEmpty) {
        emit(const HomeError('Token topilmadi'));
        return;
      }

      print('💰 Loading total balances...');
      final response = await _apiService.get(
        _apiService.getWalletsTotalBalans,
        token: token,
      );

      print('💰 Total balances response: $response');

      if (response['success'] == true) {
        final data = response['data'];
        
        // API format: uzs va usd (joriy balans), uzsTotal va usdTotal (jami)
        // Biz joriy balansni ko'rsatamiz
        final somTotal = (data['uzs'] ?? 0).toDouble();
        final dollarTotal = (data['usd'] ?? 0).toDouble();

        print('✅ Total balances loaded: som=$somTotal, dollar=$dollarTotal');

        emit(HomeGetTotalBalancesSuccess(
          somTotal: somTotal,
          dollarTotal: dollarTotal,
        ));
      } else {
        final errorMsg = response['error'] ?? 'Server xatosi';
        print('⚠️ Total balances API error: $errorMsg (continuing with 0 balance)');
        // Xatolik bo'lsa ham 0 balans bilan davom etish
        emit(const HomeGetTotalBalancesSuccess(
          somTotal: 0,
          dollarTotal: 0,
        ));
      }
    } catch (e, stackTrace) {
      print('❌ Total balances fetch error: $e');
      print('Stack trace: $stackTrace');
      emit(HomeError('Balanslarni yuklashda xatolik: ${e.toString()}'));
    }
  }

  // Yangi hamyon yaratish
  Future<void> _onHomeCreateWallet(
    HomeCreateWalletEvent event,
    Emitter<HomeState> emit,
  ) async {
    try {
      emit(HomeLoading());
      
      final token = await _prefsService.getAuthToken();
      
      if (token == null || token.isEmpty) {
        emit(const HomeError('Token topilmadi'));
        return;
      }

      print('🆕 Creating wallet: ${event.name} (${event.currency})');
      
      final response = await _apiService.post(
        _apiService.walletCreate,
        body: {
          'name': event.name,
          'currency': event.currency.toLowerCase(),
        },
        token: token,
      );

      print('🆕 Create wallet response: $response');

      if (response['success'] == true) {
        print('✅ Wallet created successfully');
        emit(HomeWalletCreatedSuccess());
        // Hamyonlarni yangilash
        add(HomeGetWalletsEvent());
        add(HomeGetTotalBalancesEvent());
      } else {
        final errorMsg = response['error'] ?? 'Hamyon yaratishda xatolik';
        print('❌ Create wallet API error: $errorMsg');
        emit(HomeError(errorMsg));
      }
    } catch (e, stackTrace) {
      print('❌ Create wallet error: $e');
      print('Stack trace: $stackTrace');
      emit(HomeError('Hamyon yaratishda xatolik: ${e.toString()}'));
    }
  }

  // Kurs olish
  Future<void> _onHomeGetExchangeRate(
    HomeGetExchangeRateEvent event,
    Emitter<HomeState> emit,
  ) async {
    try {
      final token = await _prefsService.getAuthToken();
      
      if (token == null || token.isEmpty) {
        emit(const HomeError('Token topilmadi'));
        return;
      }

      print('💱 Loading exchange rate...');
      final response = await _apiService.get(
        _apiService.getKurs,
        token: token,
      );

      print('💱 Exchange rate response: $response');

      if (response['success'] == true) {
        final data = response['data'];
        final kurs = (data['kurs'] ?? 12000).toDouble();

        print('✅ Exchange rate loaded: $kurs');
        emit(HomeGetExchangeRateSuccess(kurs));
      } else {
        final errorMsg = response['error'] ?? 'Kurs yuklashda xatolik';
        print('❌ Exchange rate API error: $errorMsg');
        emit(HomeError(errorMsg));
      }
    } catch (e, stackTrace) {
      print('❌ Exchange rate fetch error: $e');
      print('Stack trace: $stackTrace');
      emit(HomeError('Kurs yuklashda xatolik: ${e.toString()}'));
    }
  }

  // Kurs yangilash
  Future<void> _onHomeUpdateExchangeRate(
    HomeUpdateExchangeRateEvent event,
    Emitter<HomeState> emit,
  ) async {
    try {
      print('💵 Updating exchange rate: ${event.kurs}');
      final response = await _apiService.updateExchangeRate(event.kurs);

      if (response['success'] == true) {
        print('✅ Exchange rate updated: ${event.kurs}');
        emit(HomeGetExchangeRateSuccess(event.kurs));
      } else {
        final errorMsg = response['error'] ?? 'Kurs yangilashda xatolik';
        print('❌ Exchange rate update error: $errorMsg');
        emit(HomeError(errorMsg));
      }
    } catch (e, stackTrace) {
      print('❌ Exchange rate update error: $e');
      print('Stack trace: $stackTrace');
      emit(HomeError('Kurs yangilashda xatolik: ${e.toString()}'));
    }
  }
}
