import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../constants/api_constants.dart';

class DiscountItem {
  final String discountId;
  final String id;
  String title;
  String code;
  String type; // 'percentage' or 'fixed'
  double value; // e.g. 10.0 (10%) or 500.0 (₹500)
  double minOrderValue;
  int usedCount;
  int maxUses;
  String status;
  bool isActive;

  DiscountItem({
    required this.discountId,
    String? id,
    required this.title,
    required this.code,
    required this.type,
    required this.value,
    this.minOrderValue = 0.0,
    this.usedCount = 0,
    this.maxUses = 1000,
    this.status = 'Active',
    this.isActive = true,
  }) : id = id ?? discountId;

  factory DiscountItem.fromJson(Map<String, dynamic> json) {
    return DiscountItem(
      discountId: json['discountId'] ?? json['id'] ?? json['_id'] ?? '',
      title: json['title'] ?? '',
      code: json['code'] ?? '',
      type: json['type'] ?? 'percentage',
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      minOrderValue: (json['minOrderValue'] as num?)?.toDouble() ?? 0.0,
      maxUses: (json['maxUses'] as num?)?.toInt() ?? 1000,
      usedCount: (json['usedCount'] as num?)?.toInt() ?? 0,
      status: json['status'] ?? 'Active',
      isActive: (json['status'] ?? 'Active') == 'Active' || json['isActive'] == true,
    );
  }

  double calculateDiscount(double subtotal) {
    if (subtotal < minOrderValue) return 0.0;
    if (type == 'percentage') {
      return (subtotal * (value / 100.0)).clamp(0.0, subtotal);
    } else {
      return value.clamp(0.0, subtotal);
    }
  }
}

class DiscountsBackendService extends ChangeNotifier {
  static final DiscountsBackendService _instance = DiscountsBackendService._internal();
  factory DiscountsBackendService() => _instance;
  static DiscountsBackendService get instance => _instance;

  DiscountsBackendService._internal() {
    fetchDiscounts();
    _initSocket();
  }

  final List<DiscountItem> _discounts = [];
  List<DiscountItem> get discounts => List.unmodifiable(_discounts);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  IO.Socket? _socket;

  void _initSocket() {
    if (ApiConstants.demoMode) return;
    try {
      final socketUri = ApiConstants.socketUrl;
      _socket = IO.io(
        socketUri,
        IO.OptionBuilder().setTransports(['websocket', 'polling']).disableAutoConnect().build(),
      );

      _socket?.connect();

      _socket?.on('discount_created', (_) => fetchDiscounts(silent: true));
      _socket?.on('discount_updated', (_) => fetchDiscounts(silent: true));
      _socket?.on('discount_deleted', (_) => fetchDiscounts(silent: true));
      _socket?.on('discounts_updated', (_) => fetchDiscounts(silent: true));
    } catch (_) {}
  }

  Future<void> fetchDiscounts({bool silent = false}) async {
    if (!silent) _isLoading = true;
    if (!silent) notifyListeners();

    final candidateUrls = ApiConstants.candidateBaseUrls.map((b) => '$b/api/discounts').toList();

    for (final url in candidateUrls) {
      try {
        final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 6));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final items = (data['data'] ?? data) as List<dynamic>? ?? [];
          _discounts.clear();
          for (var item in items) {
            final disc = DiscountItem.fromJson(item);
            if (disc.isActive) _discounts.add(disc);
          }
          _isLoading = false;
          notifyListeners();
          debugPrint('✅ [DISCOUNTS LOADED IN USER APP] ${_discounts.length} live coupons');
          return;
        }
      } catch (_) {}
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> validateCoupon(String code, double orderValue) async {
    final candidateUrls = ApiConstants.candidateBaseUrls.map((b) => '$b/api/discounts/validate').toList();

    for (final url in candidateUrls) {
      try {
        final res = await http.post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'code': code, 'orderValue': orderValue}),
        ).timeout(const Duration(seconds: 3));

        if (res.statusCode == 200) {
          final body = jsonDecode(res.body);
          if (body['success'] == true && body['data'] != null) {
            return body['data'] as Map<String, dynamic>;
          }
        } else {
          final body = jsonDecode(res.body);
          return {'error': body['message'] ?? 'Invalid coupon code'};
        }
      } catch (_) {}
    }

    // Local fallback check
    final match = _discounts.where((d) => d.code.toUpperCase().trim() == code.toUpperCase().trim() && d.isActive).firstOrNull;
    if (match != null) {
      if (orderValue < match.minOrderValue) {
        return {'error': 'Minimum order value for ${match.code} is ₹${match.minOrderValue.toInt()}'};
      }
      return {
        'code': match.code,
        'title': match.title,
        'type': match.type,
        'value': match.value,
        'calculatedDiscount': match.calculateDiscount(orderValue),
      };
    }

    return {'error': 'Invalid or expired coupon code'};
  }
}
