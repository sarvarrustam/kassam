import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';
import 'package:kassam/data/services/api_service.dart';
import 'package:kassam/data/services/app_preferences_service.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  ApiService apiService = ApiService();
  final AppPreferencesService _prefsService = AppPreferencesService();
  
  AuthBloc() : super(AuthInitial()) {

   on<AuthRequestedSmsCode>(_onAuthRequestedSmsCode);
   on<AuthVerifySmsCode>(_onAuthVerifySmsCode);
   on<AuthCreateProfile>(_onAuthCreateProfile);
  }

  Future<void> _onAuthRequestedSmsCode(
      AuthRequestedSmsCode event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final response = await apiService.get(
        apiService.getSms, 
        queryParams: {'telephoneNumber': event.phoneNumber}  // kichik t
      );
      
      if (response['success'] == true) {
        emit(AuthSmsCodeSent());
      } else {
        emit(AuthError(response['error'] ?? 'Xatolik yuz berdi'));
      }
      
    } catch (e) {
      emit(AuthError('Kutilmagan xatolik: ${e.toString()}'));
    }
  }

  Future<void> _onAuthVerifySmsCode(
      AuthVerifySmsCode event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final response = await apiService.get(
        apiService.checkSms,
        queryParams: {
          'telephoneNumber': event.phoneNumber,  // kichik t
          'smsKod': event.smsCode
        },
      );

      if (response['success'] == true) {
        // SMS to'g'ri - endi user bazada bormi yo'qmi tekshirish
        final data = response['data'];
        final isRegistered = data['isRegistered'] ?? false;
        final token = data['token'] ?? '';

        print('🔍 Full response data: $data');
        print('🔍 isRegistered: $isRegistered (type: ${isRegistered.runtimeType})');
        print('🔍 Token: $token');

        // Token va telefon raqamni saqlash
        await _prefsService.setAuthToken(token);
        await _prefsService.setPhoneNumber(event.phoneNumber);

        if (isRegistered == true) {
          // User bazada BOR - ma'lumotlarni yuklash
          try {
            final userResponse = await apiService.get(
              apiService.getUser,
              token: token,
            );
            
            if (userResponse['success'] == true) {
              final userData = userResponse['data'];
              final userName = userData['name'] ?? '';
              
              // Ismni saqlash
              if (userName.isNotEmpty) {
                await _prefsService.setUserName(userName);
                print('💾 User name saved: $userName');
              }
            }
          } catch (e) {
            print('⚠️ getUser error: $e');
          }
          
          await _prefsService.setOnboardingCompleted();
          emit(AuthVerifiedUserExists());
        } else {
          // User bazada YO'Q - registration'ga
          emit(AuthVerifiedUserNew());
        }
      } else {
        // SMS noto'g'ri yoki boshqa xato
        emit(AuthError(response['error'] ?? 'SMS kod noto\'g\'ri'));
      }
    } catch (e) {
   
      emit(AuthError('Kutilmagan xatolik: ${e.toString()}'));
    }
  }

  Future<void> _onAuthCreateProfile(
      AuthCreateProfile event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      // Token va telefon raqamni olish
      final token = await _prefsService.getAuthToken();
      final phoneNumber = await _prefsService.getPhoneNumber();

      print('📝 Creating user profile:');
      print('   Phone: $phoneNumber');
      print('   Token: $token');
      print('   Name: ${event.name}');
      print('   Surname: ${event.surname}');
      print('   Birthday: ${event.birthday}');
      print('   Address: ${event.address}');

      // Telefon raqam formatini to'g'rilash: 998995160075 (+ va bo'shliqsiz)
      final formattedPhone = (phoneNumber ?? '')
          .replaceAll('+', '')
          .replaceAll(' ', '')
          .replaceAll('-', '');

      // Sanani 1C formati uchun o'zgartirish: dd.MM.yyyy
      String formattedBirthday = event.birthday;
      try {
        // Agar yyyy-MM-dd formatda bo'lsa, dd.MM.yyyy ga o'tkazish
        if (event.birthday.contains('-')) {
          final date = DateTime.parse(event.birthday);
          formattedBirthday = DateFormat('dd.MM.yyyy').format(date);
        }
      } catch (e) {
        print('⚠️ Birthday format error: $e');
        // Agar parse bo'lmasa, asl qiymatni qoldiramiz
      }

      print('📅 Formatted birthday: $formattedBirthday');

      // POST API body
      final body = {
        'telephoneNumber': formattedPhone,
        'name': event.name,
        'surName': event.surname,
        'birthday': formattedBirthday,
        'address': event.address,
      };

      // Location ID'larni qo'shish (agar tanlangan bo'lsa)
      if (event.stateId != null) {
        body['stateId'] = event.stateId!;
        print('✅ stateId: ${event.stateId}');
      }
      if (event.regionId != null) {
        body['regionId'] = event.regionId!;
        print('✅ regionId: ${event.regionId}');
      }
      if (event.districtsId != null) {
        body['districtsId'] = event.districtsId!;
        print('✅ districtsId: ${event.districtsId}');
      }

      print('📦 POST Body: $body');

      // POST API
      final response = await apiService.post(
        apiService.profileSave,
        body: body,
      );

      print('✅ Response: $response');

      if (response['success'] == true) {
        // Token'ni saqlash
        final newToken = response['data']['token']?.toString();
        if (newToken != null) {
          await _prefsService.setAuthToken(newToken);
        }
        
        // Profil muvaffaqiyatli yaratildi
        await _prefsService.setUserName(event.name);
        print('💾 Registration: User name saved: ${event.name}');
        
        await _prefsService.setOnboardingCompleted();
        emit(AuthProfileCreated());
      } else {
        // Xatolik
        emit(AuthError(response['errorMessage'] ?? 'Profil yaratishda xatolik'));
      }
    } catch (e) {
      print('❌ Error: $e');
      emit(AuthError('Kutilmagan xatolik: ${e.toString()}'));
    }
  }
}