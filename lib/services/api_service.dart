import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Use 10.0.2.2 for Android emulator to access localhost of the host machine.
  // Use localhost for iOS simulator or web.
  static const String baseUrl = 'https://skaagpay-backend.vercel.app/api'; 
  
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    return {
      'Content-Type': 'application/json',
      if (userId != null) 'X-User-ID': userId.toString(),
    };
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('user_id');
  }

  // --- Auth ---
  Future<Map<String, dynamic>> login(String phoneNumber, String fullName) async {
    final url = Uri.parse('$baseUrl/auth/login/');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'phone_number': phoneNumber,
        'full_name': fullName,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final userId = data['user']['id'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('user_id', userId);
      return data;
    } else {
      throw Exception('Login failed: ${response.body}');
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
  }

  // --- Wallet ---
  Future<Map<String, dynamic>> getWalletBalance() async {
    // Note: Endpoint from README is /api/wallet/balance/
    // Assuming it requires GET and returns balance info
    final url = Uri.parse('$baseUrl/wallet/balance/');
    final headers = await _getHeaders();
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get balance: ${response.body}');
    }
  }

  Future<List<dynamic>> getTransactions() async {
    final url = Uri.parse('$baseUrl/wallet/transactions/');
    final headers = await _getHeaders();
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      // Assuming response is a list or contains a list
      return jsonDecode(response.body) as List<dynamic>;
    } else {
       // Return empty list on failure or handle proper error parsing depending on API
      return []; 
    }
  }

  Future<void> requestTopUp(String amount, String transactionReference) async {
    final url = Uri.parse('$baseUrl/wallet/topup/');
    final headers = await _getHeaders();

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode({
        'amount': amount,
        'transaction_reference': transactionReference,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Top-up failed: ${response.body}');
    }
  }

  // --- Recharge ---
  Future<Map<String, dynamic>> submitRecharge({
    required String mobileNumber,
    required String operator,
    required double amount,
    required String category,
    bool isScheduled = false,
    String? scheduledAt,
  }) async {
    final url = Uri.parse('$baseUrl/recharge/request/');
    final headers = await _getHeaders();
    
    final Map<String, dynamic> body = {
      'mobile_number': mobileNumber,
      'operator': operator,
      'amount': amount,
      'category': category,
      if (isScheduled) ...{
        'is_scheduled': true,
        'scheduled_at': scheduledAt, // ISO 8601 string
      }
    };

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Recharge failed: ${response.body}');
    }
  }

  Future<void> walletTransfer(String recipientId, double amount, String description) async {
    final url = Uri.parse('$baseUrl/wallet/transactions/transfer/');
    final headers = await _getHeaders();

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode({
        'recipient_id': recipientId,
        'amount': amount,
        'description': description,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Transfer failed: ${response.body}');
    }
  }
  // --- Profile ---
  Future<Map<String, dynamic>> getProfile() async {
    final url = Uri.parse('$baseUrl/auth/profile/');
    final headers = await _getHeaders();
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get profile: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    required String fullName,
    required String address,
    required String fcmToken,
  }) async {
    final url = Uri.parse('$baseUrl/auth/profile/');
    final headers = await _getHeaders();
    final body = {
      'full_name': fullName,
      'address': address,
      'fcm_token': fcmToken,
    };

    final response = await http.patch(
      url,
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update profile: ${response.body}');
    }
  }
}
