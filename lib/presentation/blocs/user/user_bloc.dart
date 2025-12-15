import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:kassam/data/models/user_model.dart';
import 'package:kassam/data/services/api_service.dart';
import 'package:kassam/data/services/app_preferences_service.dart';

part 'user_event.dart';
part 'user_state.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  final ApiService _apiService = ApiService();
  final AppPreferencesService _prefsService = AppPreferencesService();

  UserBloc() : super(UserInitial()) {
    on<UserGetDataEvent>(_onUserGetData);
    on<UserSaveDataEvent>(_onUserSaveData);
    on<UserClearDataEvent>(_onUserClearData);
  }

  // API dan user ma'lumotlarini olish
  Future<void> _onUserGetData(
    UserGetDataEvent event,
    Emitter<UserState> emit,
  ) async {
    try {
      emit(UserLoading());

      final token = await _prefsService.getAuthToken();

      if (token == null || token.isEmpty) {
        emit(const UserError('Token topilmadi'));
        return;
      }

      print('👤 Loading user data...');
      final response = await _apiService.get(
        'Kassam/hs/KassamUrl/getUser',
        token: token,
      );

      print('👤 User response: $response');

      if (response['success'] == true) {
        final data = response['data'];
        final user = UserModel.fromJson(data as Map<String, dynamic>);

        print('✅ User loaded: $user');

        // Serverdan kelgan versiyani saqlash
        if (data['version'] != null) {
          final serverVersion = data['version'] as int;
          await _prefsService.saveAppVersion(serverVersion);
          print('📦 Server version saved: $serverVersion');
        }

        // Hive ga saqlash
        await _saveUserToHive(user);

        emit(UserLoaded(user));
      } else {
        final errorMsg = response['error'] ?? 'Server xatosi';
        print('❌ User API error: $errorMsg');
        emit(UserError(errorMsg));
      }
    } catch (e, stackTrace) {
      print('❌ User fetch error: $e');
      print('Stack trace: $stackTrace');
      emit(UserError('Foydalanuvchi ma\'lumotlarini yuklashda xatolik: ${e.toString()}'));
    }
  }

  // User ma'lumotlarini Hive ga saqlash
  Future<void> _onUserSaveData(
    UserSaveDataEvent event,
    Emitter<UserState> emit,
  ) async {
    try {
      await _saveUserToHive(event.user);
      emit(UserLoaded(event.user));
    } catch (e) {
      print('❌ User save error: $e');
      emit(UserError('Foydalanuvchi ma\'lumotlarini saqlashda xatolik'));
    }
  }

  // User ma'lumotlarini o'chirish
  Future<void> _onUserClearData(
    UserClearDataEvent event,
    Emitter<UserState> emit,
  ) async {
    try {
      await _prefsService.clearUserData();
      emit(UserInitial());
    } catch (e) {
      print('❌ User clear error: $e');
      emit(UserError('Foydalanuvchi ma\'lumotlarini o\'chirishda xatolik'));
    }
  }

  // Helper: Hive ga saqlash
  Future<void> _saveUserToHive(UserModel user) async {
    await _prefsService.saveUserData(user.toJson());
    print('💾 User saved to Hive');
  }

  // Helper: Hive dan olish
  Future<UserModel?> getUserFromHive() async {
    final data = await _prefsService.getUserData();
    if (data != null) {
      return UserModel.fromJson(data);
    }
    return null;
  }
}
