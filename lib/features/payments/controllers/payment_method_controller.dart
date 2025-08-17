import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../auth/controllers/auth_controller.dart';
import '../models/payment_method.dart';
import 'dart:developer' as dev;

// Provider for payment methods stream with error handling
final paymentMethodsStreamProvider = StreamProvider<List<PaymentMethod>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return Stream.value([]);
  }

  try {
    return Supabase.instance.client
        .from('taskaway_payment_methods')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => PaymentMethod.fromJson(json)).toList())
        .handleError((error) {
          print('Error loading payment methods: $error');
          // Return empty list if table doesn't exist
          return <PaymentMethod>[];
        });
  } catch (e) {
    print('Database error: $e');
    // Return mock data for now until table is created
    return Stream.value(_getMockPaymentMethods(user.id));
  }
});

// Mock data for development/testing
List<PaymentMethod> _getMockPaymentMethods(String userId) {
  return [
    PaymentMethod(
      id: 'mock-1',
      userId: userId,
      type: PaymentMethodType.creditCard,
      cardNumber: '**** **** **** 0171',
      cardHolderName: 'Ibrahim R.',
      expiryDate: '03/26',
      isDefault: true,
    ),
  ];
}

// Provider for payment method controller
final paymentMethodControllerProvider = Provider((ref) => PaymentMethodController(ref));

class PaymentMethodController {
  final Ref _ref;
  final _supabase = Supabase.instance.client;

  PaymentMethodController(this._ref);

  Future<PaymentMethod> addCreditCard({
    required String cardHolderName,
    required String cardNumber,
    required String expiryDate,
    required String cvv,
    bool isDefault = false,
  }) async {
    try {
      final user = _ref.read(currentUserProvider);
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Mask the card number for storage (store only last 4 digits)
      final maskedCardNumber = '**** **** **** ${cardNumber.substring(cardNumber.length - 4)}';

      final paymentMethodData = {
        'user_id': user.id,
        'type': PaymentMethodType.creditCard.name,
        'card_holder_name': cardHolderName,
        'card_number': maskedCardNumber,
        'expiry_date': expiryDate,
        'is_default': isDefault,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('taskaway_payment_methods')
          .insert(paymentMethodData)
          .select()
          .single();

      print('Payment method added: ${response.toString()}');
      return PaymentMethod.fromJson(response);
    } catch (e) {
      print('Error adding payment method: $e');
      
      // If table doesn't exist, show helpful message
      if (e.toString().contains('does not exist')) {
        throw Exception('Payment methods table not found. Please create the database table first.');
      }
      
      throw Exception('Failed to add payment method: $e');
    }
  }

  Future<PaymentMethod> addOnlineBanking({
    required String bankName,
    bool isDefault = false,
  }) async {
    try {
      final user = _ref.read(currentUserProvider);
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final paymentMethodData = {
        'user_id': user.id,
        'type': PaymentMethodType.onlineBanking.name,
        'bank_name': bankName,
        'is_default': isDefault,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('taskaway_payment_methods')
          .insert(paymentMethodData)
          .select()
          .single();

      print('Online banking method added: ${response.toString()}');
      return PaymentMethod.fromJson(response);
    } catch (e) {
      print('Error adding online banking method: $e');
      
      if (e.toString().contains('does not exist')) {
        throw Exception('Payment methods table not found. Please create the database table first.');
      }
      
      throw Exception('Failed to add online banking method: $e');
    }
  }

  Future<PaymentMethod> addEWallet({
    required String eWalletProvider,
    bool isDefault = false,
  }) async {
    try {
      final user = _ref.read(currentUserProvider);
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final paymentMethodData = {
        'user_id': user.id,
        'type': PaymentMethodType.eWallet.name,
        'ewallet_provider': eWalletProvider,
        'is_default': isDefault,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('taskaway_payment_methods')
          .insert(paymentMethodData)
          .select()
          .single();

      print('E-wallet method added: ${response.toString()}');
      return PaymentMethod.fromJson(response);
    } catch (e) {
      print('Error adding e-wallet method: $e');
      
      if (e.toString().contains('does not exist')) {
        throw Exception('Payment methods table not found. Please create the database table first.');
      }
      
      throw Exception('Failed to add e-wallet method: $e');
    }
  }

  Future<PaymentMethod> updatePaymentMethod({
    required String id,
    String? cardHolderName,
    String? cardNumber,
    String? expiryDate,
    String? bankName,
    String? eWalletProvider,
    bool? isDefault,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (cardHolderName != null) updateData['card_holder_name'] = cardHolderName;
      if (cardNumber != null) {
        // Mask the card number for storage
        updateData['card_number'] = '**** **** **** ${cardNumber.substring(cardNumber.length - 4)}';
      }
      if (expiryDate != null) updateData['expiry_date'] = expiryDate;
      if (bankName != null) updateData['bank_name'] = bankName;
      if (eWalletProvider != null) updateData['ewallet_provider'] = eWalletProvider;
      if (isDefault != null) updateData['is_default'] = isDefault;

      final response = await _supabase
          .from('taskaway_payment_methods')
          .update(updateData)
          .eq('id', id)
          .select()
          .single();

      print('Payment method updated: ${response.toString()}');
      return PaymentMethod.fromJson(response);
    } catch (e) {
      print('Error updating payment method: $e');
      
      if (e.toString().contains('does not exist')) {
        throw Exception('Payment methods table not found. Please create the database table first.');
      }
      
      throw Exception('Failed to update payment method: $e');
    }
  }

  Future<void> deletePaymentMethod(String id) async {
    try {
      await _supabase
          .from('taskaway_payment_methods')
          .delete()
          .eq('id', id);

      print('Payment method deleted: $id');
    } catch (e) {
      print('Error deleting payment method: $e');
      
      if (e.toString().contains('does not exist')) {
        throw Exception('Payment methods table not found. Please create the database table first.');
      }
      
      throw Exception('Failed to delete payment method: $e');
    }
  }

  Future<void> setAsDefault(String id) async {
    try {
      final user = _ref.read(currentUserProvider);
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // First, unset all other payment methods as default
      await _supabase
          .from('taskaway_payment_methods')
          .update({'is_default': false, 'updated_at': DateTime.now().toIso8601String()})
          .eq('user_id', user.id);

      // Then set the selected one as default
      await _supabase
          .from('taskaway_payment_methods')
          .update({'is_default': true, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', id);

      print('Payment method set as default: $id');
    } catch (e) {
      print('Error setting payment method as default: $e');
      
      if (e.toString().contains('does not exist')) {
        throw Exception('Payment methods table not found. Please create the database table first.');
      }
      
      throw Exception('Failed to set payment method as default: $e');
    }
  }
} 