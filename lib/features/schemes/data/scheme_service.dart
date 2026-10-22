import 'dart:convert';

import 'package:http/http.dart' as http;

import 'scheme_model.dart';

class SchemeService {
  // ============================================================
  // API
  // ============================================================

  static const String _schemesUrl =
      'https://suvarnagold-16e5.vercel.app/api/schemes/all';

  // ============================================================
  // OPTIONAL LIGHT CACHE
  // ============================================================

  static List<SchemeModel>? _cachedSchemes;
  static DateTime? _lastFetched;

  static const Duration _cacheDuration =
      Duration(minutes: 5);

  static bool get _isCacheValid {
    if (_cachedSchemes == null ||
        _lastFetched == null) {
      return false;
    }

    return DateTime.now()
            .difference(_lastFetched!) <
        _cacheDuration;
  }

  // ============================================================
  // INVALIDATE CACHE
  // ============================================================

  static void invalidateCache() {
    _cachedSchemes = null;
    _lastFetched = null;
  }

  // ============================================================
  // GET ALL SCHEMES
  // ============================================================

  static Future<List<SchemeModel>> getSchemes({
    bool forceRefresh = false,
  }) async {
    // ----------------------------------------------------------
    // CACHE
    // ----------------------------------------------------------

    if (!forceRefresh &&
        _isCacheValid) {
      print(
        '[SCHEME SERVICE] Returning cached schemes',
      );

      return _cachedSchemes!;
    }

    try {
      print(
        '[SCHEME SERVICE] ========================================',
      );

      print(
        '[SCHEME SERVICE] Fetching schemes...',
      );

      // --------------------------------------------------------
      // API CALL
      // --------------------------------------------------------

      final response =
          await http.get(
        Uri.parse(
          _schemesUrl,
        ),

        headers: {
          'Accept':
              'application/json',

          'Content-Type':
              'application/json',
        },
      );

      print(
        '[SCHEME SERVICE] STATUS CODE: ${response.statusCode}',
      );

      print(
        '[SCHEME SERVICE] RAW BODY: ${response.body}',
      );

      // --------------------------------------------------------
      // HTTP ERROR
      // --------------------------------------------------------

      if (response.statusCode !=
          200) {
        print(
          '[SCHEME SERVICE] API returned status ${response.statusCode}',
        );

        return _cachedSchemes ??
            [];
      }

      // --------------------------------------------------------
      // EMPTY RESPONSE
      // --------------------------------------------------------

      if (response.body
          .trim()
          .isEmpty) {
        print(
          '[SCHEME SERVICE] Empty response body',
        );

        return _cachedSchemes ??
            [];
      }

      // --------------------------------------------------------
      // DECODE JSON
      // --------------------------------------------------------

      final dynamic decoded =
          jsonDecode(
        response.body,
      );

      if (decoded == null) {
        print(
          '[SCHEME SERVICE] Decoded response is null',
        );

        return [];
      }

      // --------------------------------------------------------
      // BACKEND EXPECTED FORMAT
      //
      // {
      //   "schemes": [...]
      // }
      // --------------------------------------------------------

      if (decoded is! Map) {
        print(
          '[SCHEME SERVICE] Response is not a JSON object',
        );

        return [];
      }

      final data =
          Map<String, dynamic>.from(
        decoded,
      );

      final dynamic rawSchemes =
          data['schemes'];

      if (rawSchemes == null) {
        print(
          '[SCHEME SERVICE] "schemes" field missing',
        );

        return [];
      }

      if (rawSchemes is! List) {
        print(
          '[SCHEME SERVICE] "schemes" is not a list',
        );

        return [];
      }

      // ========================================================
      // PARSE SCHEMES
      // ========================================================

      final List<SchemeModel>
          result = [];

      for (final item
          in rawSchemes) {
        try {
          if (item is! Map) {
            print(
              '[SCHEME SERVICE] Skipping invalid scheme item',
            );

            continue;
          }

          final json =
              Map<String, dynamic>.from(
            item,
          );

          final scheme =
              SchemeModel.fromJson(
            json,
          );

          // ----------------------------------------------------
          // REQUIRED DATA VALIDATION
          // ----------------------------------------------------

          if (scheme.id.isEmpty) {
            print(
              '[SCHEME SERVICE] Skipping scheme with empty ID',
            );

            continue;
          }

          if (scheme.name
              .trim()
              .isEmpty) {
            print(
              '[SCHEME SERVICE] Skipping scheme with empty name',
            );

            continue;
          }

          if (scheme.durationMonths <=
              0) {
            print(
              '[SCHEME SERVICE] '
              'Skipping ${scheme.name}: invalid durationMonths=${scheme.durationMonths}',
            );

            continue;
          }

          // ----------------------------------------------------
          // LOG TYPE
          // ----------------------------------------------------

          print(
            '[SCHEME SERVICE] Loaded: '
            '${scheme.name} | '
            'id=${scheme.id} | '
            'rateType=${scheme.rateType} | '
            'duration=${scheme.durationMonths} | '
            'weightBased=${scheme.isWeightBased}',
          );

          result.add(
            scheme,
          );
        } catch (
          e,
          stackTrace,
        ) {
          // ----------------------------------------------------
          // One bad scheme should NOT break all schemes.
          // ----------------------------------------------------

          print(
            '[SCHEME SERVICE] Failed to parse one scheme: $e',
          );

          print(
            '[SCHEME SERVICE] STACK: $stackTrace',
          );
        }
      }

      // ========================================================
      // SORT SCHEMES
      //
      // GOLD_22K
      // GOLD_18K
      // SILVER
      // CASH
      // ========================================================

      int priority(
        SchemeModel scheme,
      ) {
        switch (
            scheme.rateType) {
          case 'GOLD_22K':
            return 0;

          case 'GOLD_18K':
            return 1;

          case 'SILVER':
            return 2;

          case 'CASH':
            return 3;

          default:
            return 4;
        }
      }

      result.sort(
        (
          a,
          b,
        ) {
          final first =
              priority(a);

          final second =
              priority(b);

          if (first != second) {
            return first.compareTo(
              second,
            );
          }

          return a.name
              .toLowerCase()
              .compareTo(
                b.name.toLowerCase(),
              );
        },
      );

      // ========================================================
      // CACHE RESULT
      // ========================================================

      _cachedSchemes =
          result;

      _lastFetched =
          DateTime.now();

      print(
        '[SCHEME SERVICE] Successfully loaded ${result.length} schemes',
      );

      print(
        '[SCHEME SERVICE] ========================================',
      );

      return result;
    } catch (
      e,
      stackTrace,
    ) {
      print(
        '[SCHEME FETCH ERROR] $e',
      );

      print(
        '[SCHEME FETCH STACK] $stackTrace',
      );

      // Keep previously loaded schemes if temporary network
      // failure occurs.
      return _cachedSchemes ??
          [];
    }
  }

  // ============================================================
  // GOLD SCHEMES
  //
  // Includes both:
  //
  // GOLD_22K
  // GOLD_18K
  // ============================================================

  static Future<List<SchemeModel>>
      getGoldSchemes({
    bool forceRefresh = false,
  }) async {
    final schemes =
        await getSchemes(
      forceRefresh:
          forceRefresh,
    );

    return schemes
        .where(
          (scheme) =>
              scheme.isGold,
        )
        .toList();
  }

  // ============================================================
  // 22K GOLD SCHEMES
  // ============================================================

  static Future<List<SchemeModel>>
      get22KGoldSchemes({
    bool forceRefresh = false,
  }) async {
    final schemes =
        await getSchemes(
      forceRefresh:
          forceRefresh,
    );

    return schemes
        .where(
          (scheme) =>
              scheme.rateType ==
              'GOLD_22K',
        )
        .toList();
  }

  // ============================================================
  // 18K GOLD SCHEMES
  // ============================================================

  static Future<List<SchemeModel>>
      get18KGoldSchemes({
    bool forceRefresh = false,
  }) async {
    final schemes =
        await getSchemes(
      forceRefresh:
          forceRefresh,
    );

    return schemes
        .where(
          (scheme) =>
              scheme.rateType ==
              'GOLD_18K',
        )
        .toList();
  }

  // ============================================================
  // SILVER SCHEMES
  // ============================================================

  static Future<List<SchemeModel>>
      getSilverSchemes({
    bool forceRefresh = false,
  }) async {
    final schemes =
        await getSchemes(
      forceRefresh:
          forceRefresh,
    );

    return schemes
        .where(
          (scheme) =>
              scheme.isSilver,
        )
        .toList();
  }

  // ============================================================
  // CASH SCHEMES
  // ============================================================

  static Future<List<SchemeModel>>
      getCashSchemes({
    bool forceRefresh = false,
  }) async {
    final schemes =
        await getSchemes(
      forceRefresh:
          forceRefresh,
    );

    return schemes
        .where(
          (scheme) =>
              scheme.isCash,
        )
        .toList();
  }
}