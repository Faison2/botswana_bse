import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../contants/constants.dart';

/// Outcome of an ABSA / Cybersource card charge.
///
/// The API answer is final — there is no prompt and no polling loop. The only
/// case that needs a follow-up is a timeout, where [timedOut] is set and the
/// charge must NOT be resent (every call is a new charge). Use
/// [AbsaService.checkStatus] with the reference instead.
class AbsaResult {
  final bool success;
  final String message;
  final int responseCode;
  final String reference;
  final bool timedOut;

  const AbsaResult({
    required this.success,
    required this.message,
    required this.responseCode,
    this.reference = '',
    this.timedOut = false,
  });

  /// Friendly, user-facing title for the response code.
  String get title {
    if (success) return 'Deposit Successful';
    switch (responseCode) {
      case 402:
        return 'Card Declined';
      case 300:
        return 'Invalid Request';
      case 401:
        return 'Session Expired';
      case 403:
        return 'Broker Not Linked';
      default:
        return 'Deposit Failed';
    }
  }
}

class AbsaService {
  static const String _depositPath = 'Home/DepositWithAbsa';
  static const String _statusPath = 'Home/GetTransactionStatus';

  /// Charges a bank card through ABSA and credits the balance on approval.
  ///
  /// [amount] is sent with two decimals, the card number is stripped of the
  /// spaces the input formatter adds, and the expiry year is sent in full
  /// (4 digits) as the endpoint expects.
  static Future<AbsaResult> deposit({
    required String brokerCode,
    required double amount,
    required String cardNumber,
    required String expiryMonth,
    required String expiryYear,
    required String cvv,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl$_depositPath'),
            headers: {
              'Content-Type': 'application/json',
              'accept': 'application/json',
              if (token.isNotEmpty) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'BrokerCode': brokerCode,
              'Amount': amount.toStringAsFixed(2),
              'CardNumber': cardNumber.replaceAll(RegExp(r'\s+'), ''),
              'ExpiryMonth': expiryMonth.padLeft(2, '0'),
              'ExpiryYear': expiryYear,
              'Cvv': cvv,
            }),
          )
          .timeout(const Duration(seconds: 90));

      final body = response.body.trim();
      final decoded = body.isEmpty ? null : jsonDecode(body);
      final Map<String, dynamic> data = decoded is List
          ? (decoded.isEmpty ? {} : Map<String, dynamic>.from(decoded.first))
          : (decoded is Map ? Map<String, dynamic>.from(decoded) : {});

      // The unauthorized shape is { message, status } rather than responseCode.
      if (response.statusCode == 401 || data['status'] == 401) {
        return AbsaResult(
          success: false,
          responseCode: 401,
          message: data['message']?.toString() ??
              'Unauthorized access. Please log in again.',
        );
      }

      if (response.statusCode != 200) {
        return AbsaResult(
          success: false,
          responseCode: response.statusCode,
          message: 'Server error ${response.statusCode}. Please try again.',
        );
      }

      final int code =
          int.tryParse(data['responseCode']?.toString() ?? '') ?? -1;

      return AbsaResult(
        success: code == 0,
        responseCode: code,
        reference: data['reference']?.toString() ?? '',
        message: data['responseMessage']?.toString() ??
            (code == 0 ? 'Deposit successful' : 'Deposit failed'),
      );
    } on FormatException {
      return const AbsaResult(
        success: false,
        responseCode: -1,
        message: 'Unexpected response from the payment service.',
      );
    } catch (e) {
      final text = e.toString();
      final bool isTimeout =
          text.contains('TimeoutException') || text.contains('timed out');
      return AbsaResult(
        success: false,
        responseCode: -1,
        timedOut: isTimeout,
        message: isTimeout
            ? 'The payment service did not respond in time. Your card may '
                'still have been charged — do not retry, check the status first.'
            : 'Network error. Please check your connection and try again.',
      );
    }
  }

  /// Looks up a charge by the reference returned from [deposit].
  /// Used after a timeout, where resending would charge the card twice.
  static Future<AbsaResult> checkStatus(String reference) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl$_statusPath?reference=$reference'),
            headers: {
              'accept': 'application/json',
              if (token.isNotEmpty) 'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 30));

      final body = response.body.trim();
      final decoded = body.isEmpty ? null : jsonDecode(body);
      final Map<String, dynamic> data = decoded is List
          ? (decoded.isEmpty ? {} : Map<String, dynamic>.from(decoded.first))
          : (decoded is Map ? Map<String, dynamic>.from(decoded) : {});

      final int code =
          int.tryParse(data['responseCode']?.toString() ?? '') ?? -1;

      return AbsaResult(
        success: code == 0,
        responseCode: code,
        reference: reference,
        message: data['responseMessage']?.toString() ??
            data['status']?.toString() ??
            'Status unavailable',
      );
    } catch (_) {
      return AbsaResult(
        success: false,
        responseCode: -1,
        reference: reference,
        message: 'Could not reach the payment service. Please try again.',
      );
    }
  }
}

/// Card helpers shared by the ABSA screen.
class AbsaCard {
  /// Luhn checksum — catches typos before the card is ever charged.
  static bool isValidNumber(String digits) {
    if (digits.length < 13 || digits.length > 19) return false;
    int sum = 0;
    bool alternate = false;
    for (int i = digits.length - 1; i >= 0; i--) {
      int n = int.parse(digits[i]);
      if (alternate) {
        n *= 2;
        if (n > 9) n -= 9;
      }
      sum += n;
      alternate = !alternate;
    }
    return sum % 10 == 0;
  }

  /// 'VISA' | 'MASTERCARD' | 'AMEX' | '' for the badge on the card face.
  static String brand(String digits) {
    if (digits.startsWith('4')) return 'VISA';
    if (RegExp(r'^5[1-5]').hasMatch(digits) ||
        RegExp(r'^2[2-7]').hasMatch(digits)) {
      return 'MASTERCARD';
    }
    if (RegExp(r'^3[47]').hasMatch(digits)) return 'AMEX';
    return '';
  }

  static int cvvLength(String digits) => brand(digits) == 'AMEX' ? 4 : 3;

  /// True when MM/YYYY is a real month that has not already passed.
  static bool isValidExpiry(String month, String year) {
    final m = int.tryParse(month);
    final y = int.tryParse(year);
    if (m == null || y == null || m < 1 || m > 12 || year.length != 4) {
      return false;
    }
    final now = DateTime.now();
    // Cards stay valid through the last day of the expiry month.
    final expiry = DateTime(y, m + 1, 1);
    return expiry.isAfter(DateTime(now.year, now.month, 1));
  }
}
