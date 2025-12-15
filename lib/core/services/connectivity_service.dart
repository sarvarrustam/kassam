import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  // Internet ulanishini tekshirish
  Future<bool> hasInternetConnection() async {
    try {
      final List<ConnectivityResult> result = await _connectivity.checkConnectivity();
      
      // Agar natija bo'sh yoki faqat "none" bo'lsa - internet yo'q
      if (result.isEmpty || (result.length == 1 && result.first == ConnectivityResult.none)) {
        return false;
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // Internet ulanishini real-time kuzatish
  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map((List<ConnectivityResult> result) {
      if (result.isEmpty || (result.length == 1 && result.first == ConnectivityResult.none)) {
        return false;
      }
      return true;
    });
  }
}
