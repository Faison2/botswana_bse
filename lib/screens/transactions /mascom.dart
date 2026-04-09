import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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
  static const String _refIdKey = 'mascom_last_reference_id';
  static const int _startingCounter = 29;

  static Future<String> _nextReferenceId() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_refIdKey) ?? _startingCounter;
    final next = current + 1;
    await prefs.setInt(_refIdKey, next);
    // Zero-pad to 5 digits: 30 → "00030"
    return next.toString().padLeft(5, '0');
  }

  static Future<int> currentCounter() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_refIdKey) ?? _startingCounter;
  }

  static Future<MascomResult> _sendTransaction({
    required String cdsNumber,
    required String mobileNumber,
    required double amount,
    required String transactionType,
    required String brokerCode, // ← added
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
          'Amount': amount.toStringAsFixed(0),
          'ReferenceID': referenceId,
          'CDSNumber': cdsNumber,
          'TransactionType': transactionType,
          'MobileNumber': mobileNumber,
          'BrokerCode': brokerCode,
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

  static Future<MascomResult> deposit({
    required String cdsNumber,
    required String mobileNumber,
    required double amount,
    required String brokerCode, // ← added
  }) {
    return _sendTransaction(
      cdsNumber: cdsNumber,
      mobileNumber: mobileNumber,
      amount: amount,
      transactionType: 'COLLECTION',
      brokerCode: brokerCode, // ← passed through
    );
  }

  static Future<MascomResult> withdraw({
    required String cdsNumber,
    required String mobileNumber,
    required double amount,
    required String brokerCode, // ← added
  }) {
    return _sendTransaction(
      cdsNumber: cdsNumber,
      mobileNumber: mobileNumber,
      amount: amount,
      transactionType: 'DISBURSEMENT',
      brokerCode: brokerCode, // ← passed through
    );
  }
}