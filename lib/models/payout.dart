/// Real-money payout methods used by rewards / casino-style apps.
enum PayoutMethod {
  paypal,
  skrill,
  revolut,
  wise,
  bankSepa,
  usdtTrc20,
}

extension PayoutMethodX on PayoutMethod {
  String get id => name;

  String get title => switch (this) {
        PayoutMethod.paypal => 'PayPal',
        PayoutMethod.skrill => 'Skrill',
        PayoutMethod.revolut => 'Revolut',
        PayoutMethod.wise => 'Wise',
        PayoutMethod.bankSepa => 'Bank SEPA',
        PayoutMethod.usdtTrc20 => 'USDT (TRC20)',
      };

  String get emoji => switch (this) {
        PayoutMethod.paypal => '💙',
        PayoutMethod.skrill => '🖤',
        PayoutMethod.revolut => '💳',
        PayoutMethod.wise => '🌍',
        PayoutMethod.bankSepa => '🏦',
        PayoutMethod.usdtTrc20 => '🪙',
      };

  String get fieldHint => switch (this) {
        PayoutMethod.paypal => 'PayPal email',
        PayoutMethod.skrill => 'Skrill email',
        PayoutMethod.revolut => 'Revolut email or phone (+351...)',
        PayoutMethod.wise => 'Wise email',
        PayoutMethod.bankSepa => 'IBAN (PT50...)',
        PayoutMethod.usdtTrc20 => 'USDT TRC20 wallet address',
      };

  String get fieldKey => switch (this) {
        PayoutMethod.paypal => 'email',
        PayoutMethod.skrill => 'email',
        PayoutMethod.revolut => 'account',
        PayoutMethod.wise => 'email',
        PayoutMethod.bankSepa => 'iban',
        PayoutMethod.usdtTrc20 => 'wallet',
      };

  /// Methods we can auto-pay via PayPal Payouts API when configured.
  bool get supportsAutoPayPalBridge =>
      this == PayoutMethod.paypal;

  static PayoutMethod? fromId(String id) {
    for (final m in PayoutMethod.values) {
      if (m.id == id) return m;
    }
    return null;
  }
}

enum CashoutStatus { pending, processing, paid, rejected, failed }

class CashoutRequest {
  final String id;
  final String userEmail;
  final double amountEuro;
  final PayoutMethod method;
  final String destination;
  final String? accountName;
  final CashoutStatus status;
  final String createdAt;
  final String? providerRef;
  final String? note;

  const CashoutRequest({
    required this.id,
    required this.userEmail,
    required this.amountEuro,
    required this.method,
    required this.destination,
    this.accountName,
    required this.status,
    required this.createdAt,
    this.providerRef,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userEmail': userEmail,
        'amountEuro': amountEuro,
        'method': method.id,
        'destination': destination,
        'accountName': accountName,
        'status': status.name,
        'createdAt': createdAt,
        'providerRef': providerRef,
        'note': note,
      };

  factory CashoutRequest.fromJson(Map<String, dynamic> j) => CashoutRequest(
        id: j['id'] as String,
        userEmail: j['userEmail'] as String? ?? '',
        amountEuro: (j['amountEuro'] as num).toDouble(),
        method: PayoutMethodX.fromId(j['method'] as String) ?? PayoutMethod.paypal,
        destination: j['destination'] as String? ?? '',
        accountName: j['accountName'] as String?,
        status: CashoutStatus.values.firstWhere(
          (e) => e.name == (j['status'] as String? ?? 'pending'),
          orElse: () => CashoutStatus.pending,
        ),
        createdAt: j['createdAt'] as String? ?? '',
        providerRef: j['providerRef'] as String?,
        note: j['note'] as String?,
      );

  CashoutRequest copyWith({
    CashoutStatus? status,
    String? providerRef,
    String? note,
  }) =>
      CashoutRequest(
        id: id,
        userEmail: userEmail,
        amountEuro: amountEuro,
        method: method,
        destination: destination,
        accountName: accountName,
        status: status ?? this.status,
        createdAt: createdAt,
        providerRef: providerRef ?? this.providerRef,
        note: note ?? this.note,
      );
}
