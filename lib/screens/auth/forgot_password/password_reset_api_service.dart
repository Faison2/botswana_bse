import 'dart:convert';
import 'package:http/http.dart' as http;

class PasswordResetService {
  static const String baseUrl = 'http://192.168.3.201/MainAPI/Authentication';

  // Send OTP to email
  static Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/RequestPasswordReset'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'Email': email,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['responseCode'] == 200) {
        return {
          'success': true,
          'message': data['responseMessage'],
        };
      } else {
        return {
          'success': false,
          'message': data['responseMessage'] ?? 'Failed to send OTP',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Verify OTP and reset password
  static Future<Map<String, dynamic>> verifyOtpAndResetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/VerifyOTPAndResetPassword'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'Email': email,
          'OTP': otp,
          'NewPassword': newPassword,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['responseCode'] == 200) {
        return {
          'success': true,
          'message': data['responseMessage'],
        };
      } else {
        return {
          'success': false,
          'message': data['responseMessage'] ?? 'Failed to reset password',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }
}