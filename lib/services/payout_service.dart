import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/economy.dart';
import '../models/payout.dart';

/// Talks to Cashark payout backend. Falls back to local queue if API is offline.
class PayoutService extends ChangeNotifier {
  /// Change to your deployed API, e.g. https://api.cashark.app
  static const defaultBaseUrl = String.fromEnvironment(
    'CASHARK_API_URL',
    defaultValue: 'http://127.0.0.1:8787',
  );

  static const _historyKey = 'cashark_cashouts_v1';

  final _uuid = const Uuid();
  String baseUrl = defaultBaseUrl;
  List<CashoutRequest> history = [];
  bool busy = false;
  String? lastError;
  bool apiReachable = false;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyKey);
    if (raw != null && raw.isNotEmpty) {
      final list = jsonDecode(raw) as List<dynamic>;
      history = list.map((e) => CashoutRequest.fromJson(e as Map<String, dynamic>)).toList();
    }
    await ping();
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _historyKey,
      jsonEncode(history.map((e) => e.toJson()).toList()),
    );
  }

  Future<bool> ping() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 3));
      apiReachable = res.statusCode == 200;
    } catch (_) {
      apiReachable = false;
    }
    notifyListeners();
    return apiReachable;
  }

  Future<CashoutRequest> submitCashout({
    required String userEmail,
    required double amountEuro,
    required PayoutMethod method,
    required String destination,
    String? accountName,
  }) async {
    if (amountEuro < EconomyConfig.minCashEuro) {
      throw Exception('MIN_AMOUNT');
    }
    if (destination.trim().isEmpty) {
      throw Exception('DESTINATION');
    }

    busy = true;
    lastError = null;
    notifyListeners();

    final local = CashoutRequest(
      id: _uuid.v4(),
      userEmail: userEmail,
      amountEuro: double.parse(amountEuro.toStringAsFixed(2)),
      method: method,
      destination: destination.trim(),
      accountName: accountName?.trim(),
      status: CashoutStatus.pending,
      createdAt: DateTime.now().toUtc().toIso8601String(),
    );

    try {
      await ping();
      if (apiReachable) {
        final res = await http
            .post(
              Uri.parse('$baseUrl/v1/cashouts'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(local.toJson()),
            )
            .timeout(const Duration(seconds: 20));

        if (res.statusCode >= 200 && res.statusCode < 300) {
          final body = jsonDecode(res.body) as Map<String, dynamic>;
          final saved = CashoutRequest.fromJson(body['cashout'] as Map<String, dynamic>);
          history.insert(0, saved);
          await _persist();
          busy = false;
          notifyListeners();
          return saved;
        }
        lastError = 'API ${res.statusCode}: ${res.body}';
      }

      // Offline / sandbox queue — still records the request for later processing.
      final queued = local.copyWith(
        status: CashoutStatus.pending,
        note: apiReachable ? lastError : 'queued_offline',
      );
      history.insert(0, queued);
      await _persist();
      busy = false;
      notifyListeners();
      return queued;
    } catch (e) {
      lastError = e.toString();
      final queued = local.copyWith(note: 'queued_offline');
      history.insert(0, queued);
      await _persist();
      busy = false;
      notifyListeners();
      return queued;
    }
  }

  Future<void> refreshFromApi(String userEmail) async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/v1/cashouts?email=${Uri.encodeComponent(userEmail)}'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final list = (body['cashouts'] as List<dynamic>)
            .map((e) => CashoutRequest.fromJson(e as Map<String, dynamic>))
            .toList();
        if (list.isNotEmpty) {
          history = list;
          await _persist();
          notifyListeners();
        }
      }
    } catch (_) {
      // keep local history
    }
  }
}
