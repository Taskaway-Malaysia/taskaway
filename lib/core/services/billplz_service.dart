import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';

class BillplzService {
  static const String _apiKey = 'YOUR_BILLPLZ_API_KEY'; // Replace with your API key
  static const String _collectionId = 'YOUR_COLLECTION_ID'; // Replace with your collection ID

  Future<Map<String, dynamic>> createBill({
    required String name,
    required String email,
    required String description,
    required int amount, // Amount in cents (RM 10.00 = 1000)
    required String callbackUrl,
    required String redirectUrl,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConstants.billplzApiEndpoint}/bills'),
      headers: {
        'Authorization': 'Basic ${base64Encode(utf8.encode(_apiKey + ':'))}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'collection_id': _collectionId,
        'name': name,
        'email': email,
        'amount': amount,
        'description': description,
        'callback_url': callbackUrl,
        'redirect_url': redirectUrl,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create bill: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getBillStatus(String billId) async {
    final response = await http.get(
      Uri.parse('${AppConstants.billplzApiEndpoint}/bills/$billId'),
      headers: {
        'Authorization': 'Basic ${base64Encode(utf8.encode(_apiKey + ':'))}',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get bill status: ${response.body}');
    }
  }

  // Helper method to convert amount from RM to cents
  static int convertToCents(double amountInRM) {
    return (amountInRM * 100).round();
  }

  // Helper method to convert amount from cents to RM
  static double convertToRM(int amountInCents) {
    return amountInCents / 100;
  }
} 