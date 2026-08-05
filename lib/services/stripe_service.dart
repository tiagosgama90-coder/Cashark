import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../models/economy.dart';
import 'payout_service.dart';

/// Stripe Checkout — YOU receive money when users buy shop items.
class StripeService extends ChangeNotifier {
  String get baseUrl => PayoutService.defaultBaseUrl;

  bool configured = false;
  bool busy = false;
  String? lastError;

  Future<void> refreshHealth() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/health')).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        configured = body['stripeConfigured'] == true;
      } else {
        configured = false;
      }
    } catch (_) {
      configured = false;
    }
    notifyListeners();
  }

  /// Opens Stripe Checkout in the browser. Returns sessionId for later claim.
  Future<String?> startCheckout({
    required String userEmail,
    required ShopItem item,
  }) async {
    busy = true;
    lastError = null;
    notifyListeners();
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/v1/checkout'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'userEmail': userEmail,
              'itemId': item.id,
              'itemTitle': item.titleKey,
              'amountEuro': item.priceEuro,
              // Deep-link friendly placeholders — replace PUBLIC_APP_URL in backend .env
              'successUrl':
                  'https://cashark.app/stripe-success?session_id={CHECKOUT_SESSION_ID}&email=${Uri.encodeComponent(userEmail)}',
              'cancelUrl': 'https://cashark.app/stripe-cancel',
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final url = body['url'] as String?;
        final sessionId = body['sessionId'] as String?;
        if (url != null) {
          final uri = Uri.parse(url);
          final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (!ok) lastError = 'Could not open Stripe Checkout';
        }
        busy = false;
        notifyListeners();
        return sessionId;
      }
      lastError = 'Stripe ${res.statusCode}: ${res.body}';
      busy = false;
      notifyListeners();
      return null;
    } catch (e) {
      lastError = e.toString();
      busy = false;
      notifyListeners();
      return null;
    }
  }

  /// After payment, claim the item once (idempotent).
  Future<String?> claimSession({
    required String sessionId,
    required String userEmail,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/v1/checkout/claim'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'sessionId': sessionId, 'userEmail': userEmail}),
          )
          .timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final grant = body['grant'] as Map<String, dynamic>?;
        return grant?['itemId'] as String?;
      }
      lastError = 'Claim ${res.statusCode}: ${res.body}';
      return null;
    } catch (e) {
      lastError = e.toString();
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> pendingPurchases(String email) async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/v1/purchases/pending?email=${Uri.encodeComponent(email)}'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        return (body['purchases'] as List<dynamic>).cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return [];
  }
}
