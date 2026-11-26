import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:neurofit/services/fcm_notification_service.dart';

import '../backend/live_backend.dart';
import 'user_backend_service.dart';

/// Orders and the default delivery address, from the NeuroFit API.
/// Works offline: reads come from the device cache, and an order placed
/// offline is queued and sent (once) when the phone is back online.
class OrdersBackendService extends ChangeNotifier {
  static final OrdersBackendService _instance = OrdersBackendService._internal();
  factory OrdersBackendService() => _instance;
  static OrdersBackendService get instance => _instance;
  OrdersBackendService._internal();

  List<Map<String, dynamic>> _userOrders = [];
  List<Map<String, dynamic>> get userOrders => _userOrders;

  Map<String, dynamic>? _savedAddress;
  Map<String, dynamic>? get savedAddress => _savedAddress;
  set savedAddress(Map<String, dynamic>? addr) {
    _savedAddress = addr;
    notifyListeners();
  }

  bool _isLoadingAddress = false;
  bool get isLoadingAddress => _isLoadingAddress;

  bool _isLoadingOrders = false;
  bool get isLoadingOrders => _isLoadingOrders;

  // -------------------------------------------------------------
  // 1. DEFAULT ADDRESS
  // -------------------------------------------------------------
  Future<Map<String, dynamic>?> fetchUserAddress(String uid) async {
    if (uid.isEmpty) return null;
    _isLoadingAddress = true;
    notifyListeners();
    try {
      final addresses = await UserBackendService.instance.getUserAddresses(uid);
      if (addresses.isNotEmpty) {
        final a = addresses.firstWhere((a) => a['isDefault'] == true, orElse: () => addresses.first);
        final street = (a['streetAddress'] ?? '').toString();
        _savedAddress = {
          'id': a['id'],
          'fullName': a['name'] ?? a['fullName'] ?? '',
          'phoneNumber': a['phone'] ?? a['phoneNumber'] ?? '',
          'streetAddress': street.isNotEmpty
              ? street
              : [a['flat'], a['building'], a['area'], a['city']].where((x) => (x ?? '').toString().isNotEmpty).join(', ') +
                  ((a['pincode'] ?? '').toString().isNotEmpty ? ' - ${a['pincode']}' : ''),
          'city': a['city'] ?? '',
          'state': a['state'] ?? '',
          'pincode': a['pincode'] ?? '',
          'latitude': a['latitude'],
          'longitude': a['longitude'],
        };
      } else {
        _savedAddress = null;
      }
    } catch (e) {
      debugPrint('Error fetching user address: $e');
    } finally {
      _isLoadingAddress = false;
      notifyListeners();
    }
    return _savedAddress;
  }

  Future<bool> saveUserAddress(String uid, Map<String, dynamic> address) async {
    if (uid.isEmpty) return false;
    _isLoadingAddress = true;
    notifyListeners();
    try {
      final ok = await UserBackendService.instance.saveUserAddress(uid, {
        ...address,
        'name': address['fullName'] ?? address['name'] ?? '',
        'phone': address['phoneNumber'] ?? address['phone'] ?? '',
        'isDefault': true,
      });
      if (ok) _savedAddress = address;
      return ok;
    } finally {
      _isLoadingAddress = false;
      notifyListeners();
    }
  }

  // -------------------------------------------------------------
  // 2. PLACE ORDER
  // -------------------------------------------------------------
  Future<bool> placeOrder({
    required String orderId,
    required String uid,
    required String userEmail,
    required Map<String, dynamic> shippingAddress,
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double totalAmount,
    required String paymentMethod,
    String paymentStatus = 'Paid',
    String? couponCode,
  }) async {
    final lines = [
      for (final item in items)
        {
          'productId': item['productId'] ?? item['id'] ?? '',
          'title': item['title'] ?? item['name'] ?? 'Item',
          'name': item['title'] ?? item['name'] ?? 'Item',
          'variant': item['variant'] ?? '',
          'price': (item['price'] as num?)?.toDouble() ?? 0.0,
          'quantity': (item['quantity'] as num?)?.toInt() ?? 1,
          'imageUrl': item['image'] ?? item['imageUrl'] ?? '',
          'image': item['image'] ?? item['imageUrl'] ?? '',
          if (item['brand'] != null) 'brand': item['brand'],
          if (item['category'] != null) 'categoryName': item['category'],
        },
    ];
    final payload = {
      'orderId': orderId,
      'userEmail': userEmail,
      'customerName': shippingAddress['fullName'] ?? shippingAddress['name'] ?? '',
      'userName': shippingAddress['fullName'] ?? shippingAddress['name'] ?? '',
      'shippingAddress': shippingAddress,
      'items': lines,
      'subtotal': subtotal,
      'shippingFee': 0.0,
      'tax': 0.0,
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'orderStatus': 'Placed',
      if (couponCode != null && couponCode.isNotEmpty) 'couponCode': couponCode,
      'fcmToken': FcmNotificationService.instance.fcmToken ?? '',
    };

    // Show it straight away; the server copy follows (queued if offline).
    final local = {
      'id': orderId,
      'date': 'Just now',
      'status': 'Placed',
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod,
      'items': lines.length,
      'itemList': [for (final l in lines) {'title': l['title'], 'variant': l['variant'], 'price': l['price'], 'quantity': l['quantity'], 'image': l['image']}],
      'title': lines.isNotEmpty ? lines.first['title'] : 'Order Item',
      'image': lines.isNotEmpty ? lines.first['image'] : '',
    };
    _userOrders.removeWhere((o) => o['id'] == orderId);
    _userOrders.insert(0, local);
    notifyListeners();

    try {
      final j = await Api.send('POST', '/orders', payload);
      if (j['queued'] != true) unawaited(fetchUserOrders(uid));
      return true;
    } catch (e) {
      debugPrint('placeOrder error: $e');
      _userOrders.removeWhere((o) => o['id'] == orderId);
      notifyListeners();
      return false;
    }
  }

  // -------------------------------------------------------------
  // 3. ORDERS FOR THE SIGNED-IN USER
  // -------------------------------------------------------------
  static Map<String, dynamic> _row(Map<String, dynamic> order) {
    final rawItems = order['items'] is List ? order['items'] as List : const [];
    final items = [
      for (final itm in rawItems)
        if (itm is Map)
          {
            'title': itm['title'] ?? itm['name'] ?? 'Item',
            'variant': itm['variant'] ?? '',
            'price': ((itm['price'] as num?) ?? 0.0).toDouble(),
            'quantity': ((itm['quantity'] as num?) ?? 1).toInt(),
            'image': itm['imageUrl'] ?? itm['image'] ?? '',
          },
    ];
    final created = order['createdAt']?.toString() ?? '';
    return {
      'id': order['orderId'] ?? order['id'] ?? '',
      'createdAt': created,
      'date': created.isNotEmpty ? DateTime.tryParse(created)?.toLocal().toString().split('.').first ?? created : 'Recent',
      'status': order['orderStatus'] ?? 'Placed',
      'totalAmount': ((order['totalAmount'] as num?) ?? 0.0).toDouble(),
      'paymentMethod': order['paymentMethod'] ?? 'UPI',
      'items': items.length,
      'itemList': items,
      'title': items.isNotEmpty ? items.first['title'] : 'Order Item',
      'image': items.isNotEmpty ? items.first['image'] : '',
      if (order['cancellationReason'] != null) 'cancellationReason': order['cancellationReason'],
      if (order['trackingNumber'] != null) 'trackingNumber': order['trackingNumber'],
    };
  }

  Future<List<Map<String, dynamic>>> fetchUserOrders(String uid) async {
    if (uid.isEmpty) return [];
    _isLoadingOrders = true;
    notifyListeners();
    try {
      final j = await Api.get('/orders/mine');
      _userOrders = [for (final o in Api.list(j)) _row(o)];
    } catch (e) {
      debugPrint('fetchUserOrders notice: $e');
    } finally {
      _isLoadingOrders = false;
      notifyListeners();
    }
    return _userOrders;
  }

  // -------------------------------------------------------------
  // 4. CANCEL ORDER
  // -------------------------------------------------------------
  Future<bool> cancelOrder(String orderId, String reason) async {
    if (orderId.isEmpty) return false;
    final index = _userOrders.indexWhere((o) => o['id'] == orderId || o['orderId'] == orderId);
    if (index != -1) {
      _userOrders[index]['status'] = 'Cancelled';
      _userOrders[index]['orderStatus'] = 'Cancelled';
      _userOrders[index]['cancellationReason'] = reason;
      notifyListeners();
    }
    try {
      await Api.send('PUT', '/orders/$orderId/status', {'orderStatus': 'Cancelled', 'cancellationReason': reason});
      return true;
    } catch (e) {
      debugPrint('cancelOrder error: $e');
      return false;
    }
  }
}
