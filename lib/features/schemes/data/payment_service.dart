import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../../core/session_manager.dart';
import 'package:suvarna_jewellers/core/notification_service.dart';

class PaymentService {
  static Razorpay? _razorpay;

  static const String _createOrderUrl =
      'https://suvarna-jewellers-customer-backend.vercel.app/api/payments/create-order';

  static const String _verifyUrl =
      'https://suvarna-jewellers-customer-backend.vercel.app/api/payments/verify';

  static const String _razorpayKeyId =
      'rzp_test_TlLhkVrMSDh6az';

  static void _showMessage(
    BuildContext context,
    String message, {
    Color? backgroundColor,
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static Map<String, dynamic>? _decodeMap(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}

    return null;
  }

  static String _friendlyBackendMessage(
    Map<String, dynamic>? body,
    int statusCode,
  ) {
    final code = body?['code']?.toString();

    switch (code) {
      case 'MISSED_INSTALLMENT_PENDING':
        final count =
            int.tryParse(body?['missedCount']?.toString() ?? '0') ?? 0;
        if (count > 1) {
          return 'You have $count missed installments. Please clear them at the store before paying online again.';
        }
        return 'A previous installment is missed. Please clear it at the store before paying the next month.';
      case 'INSTALLMENT_NOT_DUE':
        return 'Your next installment is not due yet.';
      case 'SCHEME_COMPLETED':
        return 'This scheme is already completed.';
      case 'NO_INSTALLMENTS_LEFT':
        return 'All installments for this scheme are already paid.';
      case 'INSTALLMENT_DATA_MISSING':
        return 'The installment schedule for this enrollment is missing. Please contact the store.';
      case 'INSTALLMENT_AMOUNT_MISMATCH':
        return 'The stored installment amount does not match the schedule. Please contact the store.';
      default:
        return body?['message']?.toString() ??
            body?['error']?.toString() ??
            'Request failed ($statusCode).';
    }
  }

  static Future<void> startPayment({
    required BuildContext context,
    required String schemeId,
    required double amount,
    VoidCallback? onSuccess,
    String? customerAddress,
    String? nomineeName,
    String? nomineeRelation,
    String? nomineePhone,
    String? nomineeAddress,
  }) async {
    try {
      if (amount <= 0) {
        _showMessage(
          context,
          'Please select a valid installment amount.',
        );
        return;
      }

      final token = await SessionManager.getToken();
      final userId = await SessionManager.getUserId();

      if (token == null || userId == null) {
        _showMessage(
          context,
          'Session missing. Please login again.',
        );
        return;
      }

      print('[PAYMENT] ========================================');
      print('[PAYMENT] Starting payment');
      print('[PAYMENT] Scheme ID       : $schemeId');
      print('[PAYMENT] User ID         : $userId');
      print('[PAYMENT] Requested amount: ₹$amount');
      print('[PAYMENT] ========================================');

      // ========================================================
      // 1. CREATE ORDER
      //
      // This endpoint is the first missed-installment gate.
      // If a previous month is missed, Razorpay is never opened.
      // ========================================================

      final orderResponse = await http.post(
        Uri.parse(_createOrderUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'amount': amount,
          'currency': 'INR',
          'userId': userId,
          'schemeId': schemeId,
          'customerAddress': customerAddress,
          'nomineeName': nomineeName,
          'nomineeRelation': nomineeRelation,
          'nomineePhone': nomineePhone,
          'nomineeAddress': nomineeAddress,
        }),
      );

      print(
        '[PAYMENT] Create order status: ${orderResponse.statusCode}',
      );
      print(
        '[PAYMENT] Create order body: ${orderResponse.body}',
      );

      final orderData = _decodeMap(orderResponse.body);

      if (orderResponse.statusCode != 200) {
        _showMessage(
          context,
          _friendlyBackendMessage(
            orderData,
            orderResponse.statusCode,
          ),
        );
        return;
      }

      if (orderData == null ||
          orderData['orderId'] == null ||
          orderData['amount'] == null) {
        _showMessage(
          context,
          'Invalid payment order response received.',
        );
        return;
      }

      final razorpayAmount = orderData['amount'];

      // The backend decides the amount for existing enrollments.
      // Never use a changed client-side amount after create-order.
      final serverAmount =
          double.tryParse(orderData['amountRupees']?.toString() ?? '') ??
              amount;

      final rateType =
          orderData['rateType']?.toString() ?? 'CASH';

      // ========================================================
      // 2. FRESH RAZORPAY INSTANCE
      // ========================================================

      try {
        _razorpay?.clear();
      } catch (_) {}

      _razorpay = Razorpay();

      // ========================================================
      // 3. SUCCESS LISTENER
      // ========================================================

      _razorpay!.on(
        Razorpay.EVENT_PAYMENT_SUCCESS,
        (PaymentSuccessResponse response) {
          if (response.orderId == null ||
              response.paymentId == null ||
              response.signature == null) {
            _showMessage(
              context,
              'Payment response is incomplete.',
            );
            return;
          }

          print('[PAYMENT SUCCESS]');
          print('[PAYMENT] Order ID   : ${response.orderId}');
          print('[PAYMENT] Payment ID : ${response.paymentId}');
          print('[PAYMENT] Signature  : ${response.signature}');
          print('[PAYMENT] Scheme ID  : $schemeId');
          print('[PAYMENT] User ID    : $userId');
          print('[PAYMENT] Amount     : ₹$serverAmount');

          Future.microtask(
            () => _verifyPayment(
              context: context,
              token: token,
              userId: userId,
              schemeId: schemeId,
              amount: serverAmount,
              razorpayOrderId: response.orderId!,
              razorpayPaymentId: response.paymentId!,
              razorpaySignature: response.signature!,
              onSuccess: onSuccess,
              customerAddress: customerAddress,
              nomineeName: nomineeName,
              nomineeRelation: nomineeRelation,
              nomineePhone: nomineePhone,
              nomineeAddress: nomineeAddress,
            ),
          );
        },
      );

      // ========================================================
      // 4. FAILURE LISTENER
      // ========================================================

      _razorpay!.on(
        Razorpay.EVENT_PAYMENT_ERROR,
        (PaymentFailureResponse response) {
          print(
            '[PAYMENT ERROR] code=${response.code} '
            'message=${response.message}',
          );

          _showMessage(
            context,
            'Payment failed (${response.code}): '
            '${response.message ?? 'Unknown error'}',
          );
        },
      );

      _razorpay!.on(
        Razorpay.EVENT_EXTERNAL_WALLET,
        (ExternalWalletResponse response) {
          print(
            '[PAYMENT] External wallet: ${response.walletName}',
          );
        },
      );

      // ========================================================
      // 5. OPEN RAZORPAY
      // ========================================================

      final options = {
        'key': _razorpayKeyId,
        'amount': razorpayAmount,
        'currency': 'INR',
        'name': 'Suvarna Jewellers',
        'description':
            '${_assetLabel(rateType)} Scheme Installment - ₹$serverAmount',
        'order_id': orderData['orderId'],
        'prefill': {
          'contact': '',
          'email': '',
        },
        'notes': {
          'schemeId': schemeId,
          'customerId': userId,
          'installmentAmount': serverAmount.toString(),
          'rateType': rateType,
        },
        'theme': {
          'color': '#D4AF37',
        },
      };

      print(
        '[PAYMENT] Opening Razorpay for ₹$serverAmount ($rateType)',
      );

      _razorpay!.open(options);
    } catch (e, stackTrace) {
      print('[PAYMENT EXCEPTION] $e');
      print('[PAYMENT STACK] $stackTrace');

      _showMessage(
        context,
        'Payment could not be started. Please try again.',
      );
    }
  }

  static String _assetLabel(String rateType) {
    switch (rateType) {
      case 'GOLD_22K':
        return '22K Gold';
      case 'GOLD_18K':
        return '18K Gold';
      case 'SILVER':
        return 'Silver';
      case 'CASH':
      default:
        return 'Savings';
    }
  }

  static Future<void> _verifyPayment({
    required BuildContext context,
    required String token,
    required String userId,
    required String schemeId,
    required double amount,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    VoidCallback? onSuccess,
    String? customerAddress,
    String? nomineeName,
    String? nomineeRelation,
    String? nomineePhone,
    String? nomineeAddress,
  }) async {
    try {
      print('[VERIFY] ========================================');
      print('[VERIFY] Starting verification');
      print('[VERIFY] User ID         : $userId');
      print('[VERIFY] Scheme ID       : $schemeId');
      print('[VERIFY] Amount          : ₹$amount');
      print('[VERIFY] Order ID        : $razorpayOrderId');
      print('[VERIFY] Payment ID      : $razorpayPaymentId');
      print('[VERIFY] ========================================');

      final requestBody = {
        'razorpay_order_id': razorpayOrderId,
        'razorpay_payment_id': razorpayPaymentId,
        'razorpay_signature': razorpaySignature,
        'schemeId': schemeId,
        'userId': userId,
        'amount': amount,
        'customerAddress': customerAddress,
        'nomineeName': nomineeName,
        'nomineeRelation': nomineeRelation,
        'nomineePhone': nomineePhone,
        'nomineeAddress': nomineeAddress,
      };

      final response = await http.post(
        Uri.parse(_verifyUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      print('[VERIFY] Status: ${response.statusCode}');
      print('[VERIFY] Body: ${response.body}');

      final body = _decodeMap(response.body);

      if (!context.mounted) return;

      if (response.statusCode == 200 &&
          body?['status'] == 'Success') {
        final summary = body?['summary'];
        final rateType =
            summary is Map ? summary['rateType']?.toString() : null;
        final gramsAdded =
            summary is Map
                ? double.tryParse(
                    summary['gramsAdded']?.toString() ?? '0',
                  )
                : 0.0;

        String successMessage =
            'Payment of ₹$amount successful ✅';

        if (rateType != null &&
            rateType != 'CASH' &&
            (gramsAdded ?? 0) > 0) {
          successMessage +=
              '\n${(gramsAdded ?? 0).toStringAsFixed(4)} g locked.';
        }

        _showMessage(
          context,
          successMessage,
        );

        await NotificationService.showLocalNotification(
          title: 'Payment Successful ✅',
          body:
              'Your scheme installment of ₹$amount has been received.',
          id: 1,
        );

        onSuccess?.call();
        return;
      }

      final message =
          _friendlyBackendMessage(body, response.statusCode);

      print('[VERIFY ERROR] $message');

      // At this stage Razorpay has already reported success.
      // Do not tell the customer to pay again.
      _showMessage(
        context,
        'Payment was received, but confirmation could not be completed: '
        '$message. Please do not pay again and contact the store.',
      );
    } catch (e, stackTrace) {
      print('[VERIFY EXCEPTION] $e');
      print('[VERIFY STACK] $stackTrace');

      _showMessage(
        context,
        'Payment was received, but confirmation could not be completed. '
        'Please do not pay again and contact the store.',
      );
    }
  }

  static void dispose() {
    try {
      _razorpay?.clear();
      _razorpay = null;
    } catch (e) {
      print('[PAYMENT] Error disposing Razorpay: $e');
    }
  }
}
