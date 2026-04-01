import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Result returned from any Mascom transaction call.
class MascomResult {
  final bool success;
  final String message;
  final int responseCode;
  final String referenceId;

  const MascomResult({
    required this.success,
    required this.message,
    required this.responseCode,
    required this.referenceId,
  });
}

class MascomService {
  static const String _baseUrl = 'https://zamagm.escrowagm.com/MainAPI/home/MascomTransactions';

  /// Key used to persist the last-used ReferenceID counter in SharedPreferences.
  static const String _refIdKey = 'mascom_last_reference_id';

  /// Starting counter — first generated ID will be 00030.
  static const int _startingCounter = 29;

  // -------------------------------------------------------------------------
  // ReferenceID helpers
  // -------------------------------------------------------------------------

  /// Returns the next ReferenceID string (zero-padded to 5 digits) and
  /// persists the new counter so it survives app restarts.
  static Future<String> _nextReferenceId() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_refIdKey) ?? _startingCounter;
    final next = current + 1;
    await prefs.setInt(_refIdKey, next);
    // Zero-pad to 5 digits: 30 → "00030"
    return next.toString().padLeft(5, '0');
  }

  /// Peek at the current counter without incrementing (useful for debugging).
  static Future<int> currentCounter() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_refIdKey) ?? _startingCounter;
  }

  // -------------------------------------------------------------------------
  // Core request
  // -------------------------------------------------------------------------

  /// Sends a transaction to the Mascom endpoint.
  ///
  /// [transactionType] must be either `'COLLECTION'` (deposit) or
  /// `'DISBURSEMENT'` (withdrawal).
  static Future<MascomResult> _sendTransaction({
    required String cdsNumber,
    required String mobileNumber,
    required double amount,
    required String transactionType,
  }) async {
    final referenceId = await _nextReferenceId();

    try {
      final response = await http
          .post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'accept': 'application/json',
        },
        body: jsonEncode({
          'Amount': amount.toStringAsFixed(0), // API expects string
          'ReferenceID': referenceId,
          'CDSNumber': cdsNumber,
          'TransactionType': transactionType,
          'MobileNumber': mobileNumber,
        }),
      )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        // Response is a JSON array: [{"responseCode": 0, "responseMessage": "..."}]
        final List<dynamic> data = jsonDecode(response.body);

        if (data.isEmpty) {
          return MascomResult(
            success: false,
            message: 'Empty response from Mascom',
            responseCode: -1,
            referenceId: referenceId,
          );
        }

        final first = data[0] as Map<String, dynamic>;
        final int code = first['responseCode'] ?? -1;
        final String message = first['responseMessage'] ?? 'Unknown response';

        // responseCode 0 = success (adjust if Mascom uses a different code)
        final bool success = code == 0;

        return MascomResult(
          success: success,
          message: message,
          responseCode: code,
          referenceId: referenceId,
        );
      } else {
        return MascomResult(
          success: false,
          message: 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          responseCode: response.statusCode,
          referenceId: referenceId,
        );
      }
    } catch (e) {
      return MascomResult(
        success: false,
        message: 'Network error: ${e.toString()}',
        responseCode: -1,
        referenceId: referenceId,
      );
    }
  }

  // -------------------------------------------------------------------------
  // Public API
  // -------------------------------------------------------------------------

  /// Initiates a **deposit** (COLLECTION) via Mascom.
  static Future<MascomResult> deposit({
    required String cdsNumber,
    required String mobileNumber,
    required double amount,
  }) {
    return _sendTransaction(
      cdsNumber: cdsNumber,
      mobileNumber: mobileNumber,
      amount: amount,
      transactionType: 'COLLECTION',
    );
  }

  /// Initiates a **withdrawal** (DISBURSEMENT) via Mascom.
  static Future<MascomResult> withdraw({
    required String cdsNumber,
    required String mobileNumber,
    required double amount,
  }) {
    return _sendTransaction(
      cdsNumber: cdsNumber,
      mobileNumber: mobileNumber,
      amount: amount,
      transactionType: 'DISBURSEMENT',
    );
  }
}