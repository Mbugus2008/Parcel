import 'dart:async';
import 'dart:io';

import 'package:get/get.dart';

/// Service to monitor network connectivity status
class ConnectivityService extends GetxService {
  final RxBool _isOnline = true.obs;
  final RxBool _isChecking = false.obs;

  Timer? _periodicCheck;

  bool get isOnline => _isOnline.value;
  bool get isOffline => !_isOnline.value;
  bool get isChecking => _isChecking.value;

  RxBool get isOnlineRx => _isOnline;

  @override
  void onInit() {
    super.onInit();
    checkConnectivity();
    // Check connectivity every 30 seconds
    _periodicCheck = Timer.periodic(
      const Duration(seconds: 30),
      (_) => checkConnectivity(),
    );
  }

  @override
  void onClose() {
    _periodicCheck?.cancel();
    super.onClose();
  }

  /// Check network connectivity by attempting to lookup a reliable host
  Future<void> checkConnectivity() async {
    if (_isChecking.value) return;

    _isChecking.value = true;
    try {
      // Try to lookup a reliable host
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));

      final wasOffline = !_isOnline.value;
      _isOnline.value = result.isNotEmpty && result[0].rawAddress.isNotEmpty;

      // Notify if connection restored
      if (wasOffline && _isOnline.value) {
        Get.snackbar(
          'Online',
          'Connection restored',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 2),
        );
      }
    } on SocketException catch (_) {
      final wasOnline = _isOnline.value;
      _isOnline.value = false;

      // Notify if connection lost
      if (wasOnline) {
        Get.snackbar(
          'Offline',
          'No internet connection',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      // Default to offline on error
      _isOnline.value = false;
    } finally {
      _isChecking.value = false;
    }
  }

  /// Force a connectivity check
  Future<void> forceCheck() async {
    await checkConnectivity();
  }
}
