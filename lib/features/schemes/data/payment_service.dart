import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter/material.dart';
import '../../../core/session_manager.dart';
import 'package:suvarna_jewellers/core/notification_service.dart';

class PaymentService {
  // FIX 1 ▸ Not a final static — recreated fresh on every payment
  //          to avoid stale native channel on iOS
  static Razorpay? _razorpay;

  static void startPayment({
    required BuildContext context,
    required String schemeId,
    required int amount,
    VoidCallback? onSuccess,
  }) async {
    try {
      final token = await SessionManager.getToken();
      final userId = await SessionManager.getUserId();

      if (token == null || userId == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Session missing. Login again."),
            ),
          );
        }
        return;
      }

      // FIX 2 ▸ Added Authorization header (was missing in original)
      final orderResponse = await http.post(
        Uri.parse(
          "https://suvarna-jewellers-customer-backend.vercel.app/api/payments/create-order",
        ),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "amount": amount,
          "currency": "INR",
          "userId": userId,
          "schemeId": schemeId,
        }),
      );

      if (orderResponse.statusCode != 200) {
        throw Exception("Order creation failed: ${orderResponse.body}");
      }

      final orderData = jsonDecode(orderResponse.body);

      // FIX 3 ▸ Clear OLD instance first, then create FRESH one
      //          Old code called clear() on the same instance then
      //          immediately attached listeners — iOS native channel
      //          was torn down causing "no connection" crash
      try {
        _razorpay?.clear();
      } catch (e) {
        print("[PAYMENT] Error clearing old instance: $e");
      }
      _razorpay = Razorpay();

      // Attach listeners on fresh instance — no clear() after this
      _razorpay!.on(
        Razorpay.EVENT_PAYMENT_SUCCESS,
        (PaymentSuccessResponse response) {
          if (response.orderId == null ||
              response.paymentId == null ||
              response.signature == null) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Payment response incomplete"),
                ),
              );
            }
            return;
          }

          print("ORDER ID: ${response.orderId}");
          print("PAYMENT ID: ${response.paymentId}");
          print("SIGNATURE: ${response.signature}");
          print("SCHEME ID SENT: $schemeId");
          print("USER ID SENT: $userId");

          // FIX 4 ▸ Use Future.microtask instead of async/await inside
          //          listener — await inside iOS callback blocks the
          //          native thread and causes a crash/drop
          Future.microtask(() => _verifyPayment(
                context: context,
                token: token,
                userId: userId,
                schemeId: schemeId,
                razorpayOrderId: response.orderId!,
                razorpayPaymentId: response.paymentId!,
                razorpaySignature: response.signature!,
                onSuccess: onSuccess,
              ));
        },
      );

      _razorpay!.on(
        Razorpay.EVENT_PAYMENT_ERROR,
        (PaymentFailureResponse response) {
          print("[PAYMENT ERROR] code=${response.code} msg=${response.message}");
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Payment failed (${response.code}): ${response.message ?? 'Unknown error'}",
                ),
              ),
            );
          }
        },
      );

      _razorpay!.on(
        Razorpay.EVENT_EXTERNAL_WALLET,
        (ExternalWalletResponse response) {
          print("[PAYMENT] External wallet: ${response.walletName}");
        },
      );

      final options = {
        'key': 'rzp_test_SQBmMDbmpm3m0D',
        'amount': orderData["amount"],
          'currency': 'INR',
        'name': 'Suvarna Jewellers',
        'description': 'Scheme Payment',
        'order_id': orderData["orderId"],
        'prefill': {
          'contact': '',
          'email': '',
        },
      };

      _razorpay!.open(options);
    } catch (e) {
      print("[PAYMENT EXCEPTION] $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Payment start failed: $e"),
          ),
        );
      }
    }
  }

  static Future<void> _verifyPayment({
    required BuildContext context,
    required String token,
    required String userId,
    required String schemeId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    VoidCallback? onSuccess,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(
          "https://suvarna-jewellers-customer-backend.vercel.app/api/payments/verify",
        ),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "razorpay_order_id": razorpayOrderId,
          "razorpay_payment_id": razorpayPaymentId,
          "razorpay_signature": razorpaySignature,
          "schemeId": schemeId,
          "userId": userId,
        }),
      );

      if (!context.mounted) return;

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body["status"] == "Success") {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Payment successful ✅"),
          ),
        );

        await NotificationService.showLocalNotification(
          title: "Payment Successful ✅",
          body: "Your scheme payment has been received. Thank you!",
          id: 1,
        );

        if (onSuccess != null) {
          onSuccess();
        }
      } else {
        print("VERIFY STATUS: ${response.statusCode}");
        print("VERIFY BODY: ${response.body}");

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Verify failed: ${response.body}"),
            ),
          );
        }
      }
    } catch (e) {
      print("[VERIFY EXCEPTION] $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Verification error: $e"),
          ),
        );
      }
    }
  }

  static void dispose() {
    try {
      _razorpay?.clear();
      _razorpay = null;
    } catch (e) {
      print("[PAYMENT] Error disposing: $e");
    }
  }
}