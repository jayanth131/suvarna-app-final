import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/session_manager.dart';
import '../models/enrolled_scheme.dart';

class EnrolledSchemeService {
  static List<EnrolledScheme>? _cachedSchemes;
  static DateTime? _lastFetched;

  static const _cacheDuration = Duration(minutes: 5);

  static bool get _isCacheValid {
    if (_cachedSchemes == null || _lastFetched == null) {
      return false;
    }

    return DateTime.now().difference(_lastFetched!) < _cacheDuration;
  }

  static void invalidateCache() {
    _cachedSchemes = null;
    _lastFetched = null;
  }

  static double _toDouble(dynamic value) {
    return double.tryParse(value?.toString() ?? '0') ?? 0.0;
  }

  static int _toInt(dynamic value) {
    return int.tryParse(value?.toString() ?? '0') ?? 0;
  }

  static bool _toBool(dynamic value) {
    return value == true || value?.toString().toLowerCase() == 'true';
  }

  static String _formatDate(dynamic value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    if (parsed == null) return '';

    return '${parsed.day.toString().padLeft(2, '0')}-'
        '${parsed.month.toString().padLeft(2, '0')}-'
        '${parsed.year}';
  }

  static Future<List<EnrolledScheme>> getUserSchemes({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _isCacheValid) {
      return _cachedSchemes!;
    }

    try {
      final token = await SessionManager.getToken();

      if (token == null) {
        print('[ENROLLED SCHEMES] Token missing');
        return [];
      }

      final response = await http.get(
        Uri.parse(
          'https://suvarna-jewellers-customer-backend.vercel.app/api/schemes/my',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('[ENROLLED SCHEMES] STATUS: ${response.statusCode}');
      print('[ENROLLED SCHEMES] BODY: ${response.body}');

      if (response.statusCode != 200) {
        return _cachedSchemes ?? [];
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map) {
        print('[ENROLLED SCHEMES] Invalid response format');
        return _cachedSchemes ?? [];
      }

      final data = Map<String, dynamic>.from(decoded);
      final rawSchemes = data['schemes'];

      if (rawSchemes is! List) {
        print('[ENROLLED SCHEMES] schemes is not a list');
        return [];
      }

      final result = <EnrolledScheme>[];

      for (final rawEnrollment in rawSchemes) {
        try {
          if (rawEnrollment is! Map) continue;

          final e = Map<String, dynamic>.from(rawEnrollment);

          final rawScheme = e['Scheme'] ?? e['scheme'] ?? {};
          final scheme = rawScheme is Map
              ? Map<String, dynamic>.from(rawScheme)
              : <String, dynamic>{};

          final rawHistory =
              e['PaymentHistory'] ?? e['paymentHistory'] ?? <dynamic>[];
          final history = rawHistory is List ? rawHistory : <dynamic>[];

          final rawNext = e['nextInstallment'];
          final nextInstallment = rawNext is Map
              ? Map<String, dynamic>.from(rawNext)
              : <String, dynamic>{};

          final installmentAmount = _toDouble(e['installmentAmount']);
          final durationMonths = _toInt(scheme['durationMonths']);
          final installmentsPaid = _toInt(e['installmentsPaid']);
          final totalPaid = _toDouble(e['totalPaid']);
          final remainingAmount = _toDouble(e['remainingAmount']);
          final accumulatedGrams = _toDouble(e['accumulatedGrams']);

          final rawRateType = scheme['rateType']?.toString().toUpperCase();
          final legacyWeightBased = _toBool(scheme['isWeightBased']);

          final rateType = (rawRateType == null || rawRateType.isEmpty)
              ? (legacyWeightBased ? 'GOLD_22K' : 'CASH')
              : rawRateType;

          final isWeightBased = rateType != 'CASH';

          double lastPaymentGrams = 0.0;
          String lastPaymentDate = '';

          if (history.isNotEmpty && history.first is Map) {
            final first = Map<String, dynamic>.from(history.first as Map);
            lastPaymentGrams = _toDouble(first['gramsAdded']);
            lastPaymentDate = _formatDate(first['paidAt']);
          }

          // The backend is now the source of truth for installment dates.
          if (lastPaymentDate.isEmpty) {
            lastPaymentDate = _formatDate(e['lastPaymentDate']);
          }

          final nextDueDate = _formatDate(
            e['nextDueDate'] ?? nextInstallment['dueDate'],
          );

          final totalAmount = installmentAmount * durationMonths;

          final hasMissedInstallments =
              _toBool(e['hasMissedInstallments']);
          final missedInstallmentCount =
              _toInt(e['missedInstallmentCount']);
          final isCompleted =
              _toBool(e['isCompleted']) ||
              (durationMonths > 0 && installmentsPaid >= durationMonths);

          final canPayOnline = _toBool(e['canPayOnline']);
          final isPaidThisMonth = _toBool(e['isPaidThisMonth']);
          final isNextInstallmentDue = _toBool(e['isNextInstallmentDue']);
          final scheduleMissing = _toBool(e['scheduleMissing']);

          final nextInstallmentNumber =
              nextInstallment['installmentNumber'] == null
              ? null
              : _toInt(nextInstallment['installmentNumber']);

          result.add(
            EnrolledScheme(
              id: e['id']?.toString() ?? '',
              schemeId: e['schemeId']?.toString() ?? '',
              name: scheme['name']?.toString() ?? 'Unnamed Scheme',
              totalAmount: totalAmount,
              amountPaid: totalPaid,
              amountBalance: remainingAmount,
              monthsPaid: installmentsPaid,
              totalMonths: durationMonths,
              lastPaymentDate: lastPaymentDate,
              nextDueDate: isCompleted ? 'Completed' : nextDueDate,
              isWeightBased: isWeightBased,
              rateType: rateType,
              accumulatedGrams: accumulatedGrams,
              installmentAmount: installmentAmount,
              lastPaymentGrams: lastPaymentGrams,
              hasMissedInstallments: hasMissedInstallments,
              missedInstallmentCount: missedInstallmentCount,
              canPayOnline: canPayOnline,
              isCompleted: isCompleted,
              isPaidThisMonth: isPaidThisMonth,
              isNextInstallmentDue: isNextInstallmentDue,
              scheduleMissing: scheduleMissing,
              nextInstallmentNumber: nextInstallmentNumber,
              nextInstallmentStatus:
                  nextInstallment['status']?.toString() ?? '',
            ),
          );
        } catch (e, stackTrace) {
          print('[ENROLLED SCHEMES] Failed to parse one enrollment: $e');
          print(stackTrace);
        }
      }

      _cachedSchemes = result;
      _lastFetched = DateTime.now();

      print('[ENROLLED SCHEMES] Returning ${result.length} scheme(s)');
      return result;
    } catch (e, stackTrace) {
      print('[ENROLLED SCHEMES ERROR] $e');
      print('[ENROLLED SCHEMES STACK] $stackTrace');

      return _cachedSchemes ?? [];
    }
  }
}
