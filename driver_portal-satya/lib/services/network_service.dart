import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum NetworkState { connected, weak, disconnected }

class NetworkService extends GetxService with WidgetsBindingObserver {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription? _connectivitySubscription;
  Timer? _pollingTimer;

  bool _isBackground = false;
  DateTime? _resumedAt;

  final Rx<NetworkState> currentState = NetworkState.connected.obs;
  bool _isDialogShowing = false;
  bool _isSnackbarShowing = false;
  bool _isRetrying = false;

  /// Returns true if the app was resumed less than 4 seconds ago.
  bool get _inResumeGracePeriod {
    if (_resumedAt == null) return false;
    return DateTime.now().difference(_resumedAt!).inSeconds < 4;
  }

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onReady() {
    super.onReady();
    _initNetworkMonitoring();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _isBackground = true;
      debugPrint('NetworkService: App went to background (paused/inactive)');
    } else if (state == AppLifecycleState.resumed) {
      _isBackground = false;
      _resumedAt = DateTime.now();
      debugPrint('NetworkService: App resumed — starting 4s grace period and scheduling fresh check in 3s');
      
      // Fresh connectivity check 3 seconds after resume.
      // grace period (_inResumeGracePeriod) protects against false events before this runs.
      Future.delayed(const Duration(seconds: 3), () async {
        // Clear grace period AFTER triggering the UI update so
        // the polling timer cannot slip through between the clear and the update.
        _resumedAt = null;
        
        final newState = await _determineNetworkState();
        currentState.value = newState;
        // Manually trigger UI update in case value didn’t change
        _handleStateChange(newState);
      });
    }
  }

  void _initNetworkMonitoring() {
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_handleConnectivityChange);
    _pollingTimer = Timer.periodic(
        const Duration(seconds: 10), (_) => _checkRealInternet());
    // Initial check
    _checkRealInternet();
    // Single source of truth for UI updates
    ever(currentState, _handleStateChange);
  }

  Future<void> _handleConnectivityChange(
      List<ConnectivityResult> results) async {
    // Ignore ALL connectivity events during background or resume grace period —
    // these are almost always false positives from the network stack waking up.
    if (_isBackground || _inResumeGracePeriod) {
      debugPrint('NetworkService: Ignoring connectivity event (background=$_isBackground, grace=$_inResumeGracePeriod)');
      return;
    }
    if (results.contains(ConnectivityResult.none)) {
      currentState.value = NetworkState.disconnected;
    } else {
      await _checkRealInternet();
    }
  }

  Future<NetworkState> _determineNetworkState() async {
    final results = await _connectivity.checkConnectivity();
    if (results.contains(ConnectivityResult.none)) {
      return NetworkState.disconnected;
    }
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return NetworkState.connected;
      }
    } catch (_) {}
    return NetworkState.weak;
  }

  Future<void> _checkRealInternet() async {
    if (_isRetrying || _inResumeGracePeriod || _isBackground) return;
    currentState.value = await _determineNetworkState();
  }

  Future<void> _handleRetry() async {
    if (_isRetrying) return;
    _isRetrying = true;

    // Close existing dialog first
    _forceCloseAllUI();
    await Future.delayed(const Duration(milliseconds: 300));

    // Show spinner
    Get.dialog(
      PopScope(
        canPop: false,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const CircularProgressIndicator(),
          ),
        ),
      ),
      barrierDismissible: false,
      barrierColor: Colors.black45,
    );

    await Future.delayed(const Duration(milliseconds: 800));

    // Check internet
    final newState = await _determineNetworkState();

    // Close spinner
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }
    await Future.delayed(const Duration(milliseconds: 200));

    _isRetrying = false;

    // Update observable (fires ever() if value changed)
    currentState.value = newState;

    // Manually trigger UI because ever() won't fire if value is unchanged (still disconnected)
    _handleStateChange(newState);
  }

  void _forceCloseAllUI() {
    if (_isDialogShowing) {
      _isDialogShowing = false;
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
    }
    if (_isSnackbarShowing) {
      _isSnackbarShowing = false;
      if (Get.isSnackbarOpen) {
        Get.closeAllSnackbars();
      }
    }
  }

  void _handleStateChange(NetworkState state) {
    // Ignore all state changes during background or resume grace period
    if (_isBackground || _inResumeGracePeriod) {
      debugPrint('NetworkService: Ignoring _handleStateChange (background=$_isBackground, grace=$_inResumeGracePeriod, state=$state)');
      return;
    }

    if (state == NetworkState.disconnected) {
      _hideWeakSnackbar();
      _showDisconnectedDialog();
    } else if (state == NetworkState.weak) {
      _hideDisconnectedDialog();
      _showWeakSnackbar();
    } else {
      _hideDisconnectedDialog();
      _hideWeakSnackbar();
    }
  }

  void _showDisconnectedDialog() {
    if (_isDialogShowing) return;
    _isDialogShowing = true;

    Get.dialog(
      PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Text('No Internet Connection',
              style: TextStyle(
                  color: Colors.red, fontWeight: FontWeight.bold)),
          content: const Text(
              'No internet connection. Please reconnect to continue.'),
          actions: [
            TextButton(
              onPressed: _handleRetry,
              child: const Text('Retry',
                  style: TextStyle(color: Colors.blue)),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    ).then((_) {
      // Only reset the flag. Do NOT auto-re-show — _handleStateChange handles it.
      _isDialogShowing = false;
    });
  }

  void _hideDisconnectedDialog() {
    if (_isDialogShowing) {
      _isDialogShowing = false;
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
    }
  }

  void _showWeakSnackbar() {
    if (_isSnackbarShowing) return;
    _isSnackbarShowing = true;

    Get.showSnackbar(
      GetSnackBar(
        titleText: const Text('Network issue detected',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        messageText: const Text('Network is slow.',
            style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.wifi_tethering_error, color: Colors.white),
        backgroundColor: Colors.orange.shade800,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(10),
        borderRadius: 8,
        isDismissible: false,
        duration: null,
        mainButton: TextButton(
          onPressed: _handleRetry,
          child: const Text('Retry',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  void _hideWeakSnackbar() {
    if (_isSnackbarShowing) {
      _isSnackbarShowing = false;
      if (Get.isSnackbarOpen) {
        Get.closeAllSnackbars();
      }
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySubscription?.cancel();
    _pollingTimer?.cancel();
    super.onClose();
  }
}
