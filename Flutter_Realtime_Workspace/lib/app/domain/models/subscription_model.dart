class SubscriptionSeats {
  final int purchased;
  final int used;

  const SubscriptionSeats({this.purchased = 10, this.used = 1});

  factory SubscriptionSeats.fromJson(Map<String, dynamic> json) =>
      SubscriptionSeats(
        purchased: json['purchased'] ?? 10,
        used: json['used'] ?? 1,
      );

  Map<String, dynamic> toJson() => {'purchased': purchased, 'used': used};
}

class SubscriptionModel {
  final String id;
  final String tenantId; // unique per org
  final String? orgId;
  // plan: free | starter | professional | enterprise
  final String plan;
  // status: active | past_due | cancelled | trialing
  final String status;
  // billingCycle: monthly | annual
  final String billingCycle;
  final DateTime? currentPeriodStart;
  final DateTime? currentPeriodEnd;
  final DateTime? cancelledAt;
  final DateTime? trialEndsAt;
  final SubscriptionSeats seats;
  final String? externalId; // Stripe subscription ID
  final String? paymentMethodId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SubscriptionModel({
    required this.id,
    required this.tenantId,
    this.orgId,
    this.plan = 'free',
    this.status = 'active',
    this.billingCycle = 'monthly',
    this.currentPeriodStart,
    this.currentPeriodEnd,
    this.cancelledAt,
    this.trialEndsAt,
    this.seats = const SubscriptionSeats(),
    this.externalId,
    this.paymentMethodId,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isActive => status == 'active' || status == 'trialing';
  bool get isPaid =>
      plan == 'starter' || plan == 'professional' || plan == 'enterprise';

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) =>
      SubscriptionModel(
        id: json['_id'] ?? json['id'] ?? '',
        tenantId: json['tenantId'] ?? '',
        orgId: json['orgId'] is Map ? json['orgId']['_id'] : json['orgId'],
        plan: json['plan'] ?? 'free',
        status: json['status'] ?? 'active',
        billingCycle: json['billingCycle'] ?? 'monthly',
        currentPeriodStart: json['currentPeriodStart'] != null
            ? DateTime.tryParse(json['currentPeriodStart'])
            : null,
        currentPeriodEnd: json['currentPeriodEnd'] != null
            ? DateTime.tryParse(json['currentPeriodEnd'])
            : null,
        cancelledAt: json['cancelledAt'] != null
            ? DateTime.tryParse(json['cancelledAt'])
            : null,
        trialEndsAt: json['trialEndsAt'] != null
            ? DateTime.tryParse(json['trialEndsAt'])
            : null,
        seats: json['seats'] != null
            ? SubscriptionSeats.fromJson(json['seats'])
            : const SubscriptionSeats(),
        externalId: json['externalId'],
        paymentMethodId: json['paymentMethodId'],
        createdAt:
            DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
        updatedAt:
            DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        '_id': id,
        'tenantId': tenantId,
        'orgId': orgId,
        'plan': plan,
        'status': status,
        'billingCycle': billingCycle,
        'currentPeriodStart': currentPeriodStart?.toIso8601String(),
        'currentPeriodEnd': currentPeriodEnd?.toIso8601String(),
        'cancelledAt': cancelledAt?.toIso8601String(),
        'trialEndsAt': trialEndsAt?.toIso8601String(),
        'seats': seats.toJson(),
        'externalId': externalId,
        'paymentMethodId': paymentMethodId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}

class InvoiceLineItem {
  final String description;
  final int quantity;
  final double unitPrice;
  final double total;

  const InvoiceLineItem({
    required this.description,
    this.quantity = 1,
    required this.unitPrice,
    required this.total,
  });

  factory InvoiceLineItem.fromJson(Map<String, dynamic> json) =>
      InvoiceLineItem(
        description: json['description'] ?? '',
        quantity: json['quantity'] ?? 1,
        unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
        total: (json['total'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'description': description,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'total': total,
      };
}

class InvoiceModel {
  final String id;
  final String tenantId;
  final String? orgId;
  final String? invoiceNumber;
  final double amount;
  final String currency;
  // status: draft | pending | paid | failed | refunded
  final String status;
  final String? description;
  final List<InvoiceLineItem> lineItems;
  final DateTime? paidAt;
  final DateTime? dueDate;
  final String? externalId; // Stripe invoice ID
  final String? pdfUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const InvoiceModel({
    required this.id,
    required this.tenantId,
    this.orgId,
    this.invoiceNumber,
    this.amount = 0,
    this.currency = 'USD',
    this.status = 'pending',
    this.description,
    this.lineItems = const [],
    this.paidAt,
    this.dueDate,
    this.externalId,
    this.pdfUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) => InvoiceModel(
        id: json['_id'] ?? json['id'] ?? '',
        tenantId: json['tenantId'] ?? '',
        orgId: json['orgId'] is Map ? json['orgId']['_id'] : json['orgId'],
        invoiceNumber: json['invoiceNumber'],
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        currency: json['currency'] ?? 'USD',
        status: json['status'] ?? 'pending',
        description: json['description'],
        lineItems: (json['lineItems'] as List? ?? [])
            .map((l) => InvoiceLineItem.fromJson(l as Map<String, dynamic>))
            .toList(),
        paidAt:
            json['paidAt'] != null ? DateTime.tryParse(json['paidAt']) : null,
        dueDate: json['dueDate'] != null
            ? DateTime.tryParse(json['dueDate'])
            : null,
        externalId: json['externalId'],
        pdfUrl: json['pdfUrl'],
        createdAt:
            DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
        updatedAt:
            DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        '_id': id,
        'tenantId': tenantId,
        'orgId': orgId,
        'invoiceNumber': invoiceNumber,
        'amount': amount,
        'currency': currency,
        'status': status,
        'description': description,
        'lineItems': lineItems.map((l) => l.toJson()).toList(),
        'paidAt': paidAt?.toIso8601String(),
        'dueDate': dueDate?.toIso8601String(),
        'externalId': externalId,
        'pdfUrl': pdfUrl,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}
