import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../services/api_service.dart';

class PaymentService {
  late Razorpay _razorpay;
  String? _orderId;
  Function(String paymentId)? _onSuccess;
  Function(String error)? _onFailure;

  PaymentService() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void dispose() {
    _razorpay.clear();
  }

  Future<void> startPayment({
    required double amount,
    required String description,
    required String userPhone,
    required String userEmail,
    required Function(String paymentId) onSuccess,
    required Function(String error) onFailure,
  }) async {
    _onSuccess = onSuccess;
    _onFailure = onFailure;

    try {
      // 1. Get Public Key
      final keyRes = await ApiService.getRazorpayKey();
      if (keyRes.containsKey('error')) {
        onFailure(keyRes['error']);
        return;
      }
      final String razorpayKey = keyRes['key'];

      // 2. Create Order on Backend
      final orderRes = await ApiService.createRazorpayOrder(amount: amount);
      if (orderRes.containsKey('error')) {
        onFailure(orderRes['error']);
        return;
      }

      _orderId = orderRes['id'];

      // 3. Open Razorpay Checkout
      var options = {
        'key': razorpayKey,
        'amount': (amount * 100).toInt(), // in paise
        'name': 'Driver App',
        'order_id': _orderId,
        'description': description,
        'prefill': {'contact': userPhone, 'email': userEmail},
        'external': {
          'wallets': ['paytm']
        }
      };

      _razorpay.open(options);
    } catch (e) {
      onFailure(e.toString());
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    // 4. Verify Payment on Backend
    if (_orderId != null && response.paymentId != null && response.signature != null) {
      final verifyRes = await ApiService.verifyRazorpayPayment(
        orderId: _orderId!,
        paymentId: response.paymentId!,
        signature: response.signature!,
      );

      if (verifyRes['success'] == true) {
        _onSuccess?.call(response.paymentId!);
      } else {
        _onFailure?.call(verifyRes['message'] ?? "Verification failed");
      }
    } else {
      _onFailure?.call("Invalid response from Razorpay");
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _onFailure?.call(response.message ?? "Payment Failed");
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _onFailure?.call("External Wallet Selected: ${response.walletName}");
  }
}
