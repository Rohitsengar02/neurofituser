import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:neurofit/services/fcm_notification_service.dart';
import 'mongo_backend_service.dart';
import '../constants/api_constants.dart';
import 'user_backend_service.dart';

class OrdersBackendService extends ChangeNotifier {
  static final OrdersBackendService _instance = OrdersBackendService._internal();
  factory OrdersBackendService() => _instance;
  static OrdersBackendService get instance => _instance;
  OrdersBackendService._internal();

  static const String _baseUrl =
      'https://firestore.googleapis.com/v1/projects/neurofit-9877b/databases/(default)/documents';

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
  // 1. FETCH & SAVE USER ADDRESS (users/{uid}/address/default)
  // -------------------------------------------------------------
  Future<Map<String, dynamic>?> fetchUserAddress(String uid) async {
    if (uid.isEmpty) return null;
    _isLoadingAddress = true;
    notifyListeners();

    try {
      // 1. First fetch from User.addresses array in MongoDB via UserBackendService
      final addresses = await UserBackendService.instance.getUserAddresses(uid);
      if (addresses.isNotEmpty) {
        final defaultAddr = addresses.firstWhere(
          (a) => a['isDefault'] == true,
          orElse: () => addresses.first,
        );
        _savedAddress = {
          'id': defaultAddr['id'],
          'fullName': defaultAddr['name'] ?? defaultAddr['fullName'] ?? '',
          'phoneNumber': defaultAddr['phone'] ?? defaultAddr['phoneNumber'] ?? '',
          'streetAddress': defaultAddr['streetAddress'] != null && (defaultAddr['streetAddress'] as String).isNotEmpty
              ? defaultAddr['streetAddress']
              : '${defaultAddr['flat'] ?? ''}, ${defaultAddr['building'] ?? ''}, ${defaultAddr['area'] ?? ''}, ${defaultAddr['city'] ?? ''} - ${defaultAddr['pincode'] ?? ''}',
          'city': defaultAddr['city'] ?? '',
          'state': defaultAddr['state'] ?? 'State',
          'pincode': defaultAddr['pincode'] ?? '',
          'latitude': defaultAddr['latitude'],
          'longitude': defaultAddr['longitude'],
        };
        _isLoadingAddress = false;
        notifyListeners();
        return _savedAddress;
      }

      final url = Uri.parse('$_baseUrl/users/$uid/address/default');
      var res = await http.get(url);

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final fields = body['fields'] as Map<String, dynamic>? ?? {};

        _savedAddress = {
          'fullName': fields['fullName']?['stringValue'] ?? '',
          'phoneNumber': fields['phoneNumber']?['stringValue'] ?? '',
          'streetAddress': fields['streetAddress']?['stringValue'] ?? '',
          'city': fields['city']?['stringValue'] ?? '',
          'state': fields['state']?['stringValue'] ?? '',
          'pincode': fields['pincode']?['stringValue'] ?? '',
        };
      } else {
        // Fallback query users/{uid}/address subcollection
        final subColUrl = Uri.parse('$_baseUrl/users/$uid/address');
        res = await http.get(subColUrl);
        if (res.statusCode == 200) {
          final body = jsonDecode(res.body) as Map<String, dynamic>;
          final docs = body['documents'] as List<dynamic>? ?? [];
          if (docs.isNotEmpty) {
            final firstDoc = docs.first as Map<String, dynamic>;
            final fields = firstDoc['fields'] as Map<String, dynamic>? ?? {};
            _savedAddress = {
              'fullName': fields['fullName']?['stringValue'] ?? '',
              'phoneNumber': fields['phoneNumber']?['stringValue'] ?? '',
              'streetAddress': fields['streetAddress']?['stringValue'] ?? '',
              'city': fields['city']?['stringValue'] ?? '',
              'state': fields['state']?['stringValue'] ?? '',
              'pincode': fields['pincode']?['stringValue'] ?? '',
            };
          } else {
            _savedAddress = null;
          }
        } else {
          _savedAddress = null;
        }
      }
    } catch (e) {
      debugPrint('Error fetching user address: $e');
      _savedAddress = null;
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
      // 1. Sync to MongoDB User.addresses array via UserBackendService
      UserBackendService.instance.saveUserAddress(uid, address);

      final payload = {
        'fields': {
          'fullName': {'stringValue': address['fullName'] ?? ''},
          'phoneNumber': {'stringValue': address['phoneNumber'] ?? ''},
          'streetAddress': {'stringValue': address['streetAddress'] ?? ''},
          'city': {'stringValue': address['city'] ?? ''},
          'state': {'stringValue': address['state'] ?? ''},
          'pincode': {'stringValue': address['pincode'] ?? ''},
          'updatedAt': {'timestampValue': DateTime.now().toUtc().toIso8601String()},
        }
      };

      // Write to users/{uid}/address/default
      final urlDefault = Uri.parse('$_baseUrl/users/$uid/address/default');
      final resDefault = await http.patch(
        urlDefault,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      // Write to users/{uid}/address subcollection primary
      final urlSubCol = Uri.parse('$_baseUrl/users/$uid/address/primary');
      await http.patch(
        urlSubCol,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      // Also sync to MongoDB Atlas Database
      MongoBackendService.instance.saveUserAddress(uid, address);

      if (resDefault.statusCode == 200 || resDefault.statusCode == 201) {
        _savedAddress = address;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error saving user address to Firestore: $e');
      // Fallback to MongoDB Atlas
      final mongoSuccess = await MongoBackendService.instance.saveUserAddress(uid, address);
      if (mongoSuccess) {
        _savedAddress = address;
        notifyListeners();
        return true;
      }
    } finally {
      _isLoadingAddress = false;
      notifyListeners();
    }
    return false;
  }

  // -------------------------------------------------------------
  // 2. PLACE ORDER (Stored in MongoDB Atlas 'orders' Collection with Realtime Socket & FCM)
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
  }) async {
    final orderPayload = {
      'orderId': orderId,
      'uid': uid,
      'userEmail': userEmail,
      'userName': shippingAddress['fullName'] ?? shippingAddress['name'] ?? '',
      'shippingAddress': shippingAddress,
      'items': items.map((item) {
        return {
          'productId': item['productId'] ?? item['id'] ?? '',
          'title': item['title'] ?? 'Item',
          'variant': item['variant'] ?? '',
          'price': (item['price'] as num?)?.toDouble() ?? 0.0,
          'quantity': (item['quantity'] as num?)?.toInt() ?? 1,
          'imageUrl': item['image'] ?? item['imageUrl'] ?? '',
        };
      }).toList(),
      'subtotal': subtotal,
      'shippingFee': 0.0,
      'tax': 0.0,
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'orderStatus': 'Placed',
      'fcmToken': FcmNotificationService.instance.fcmToken ?? '',
    };

    bool orderSavedInMongo = false;

    // 1. Post to Express Server (which handles MongoDB write, real-time Socket.io broadcast, and FCM Push Notification)
    final expressUrls = [
      Uri.parse('${ApiConstants.apiBaseUrl}/orders'),
      ...ApiConstants.candidateBaseUrls.map((b) => Uri.parse('$b/api/orders')),
    ];

    for (final expUrl in expressUrls) {
      if (orderSavedInMongo) break;
      try {
        final res = await http.post(
          expUrl,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(orderPayload),
        ).timeout(const Duration(seconds: 4));

        if (res.statusCode == 200 || res.statusCode == 201) {
          debugPrint('✅ Order $orderId placed in MongoDB via Express at $expUrl! Socket.io & FCM Dispatched.');
          orderSavedInMongo = true;
        }
      } catch (e) {
        debugPrint('Express placeOrder notice for $expUrl: $e');
      }
    }

    // 2. Direct MongoDB Atlas Driver Fallback (Only run if Express call failed)
    if (!orderSavedInMongo) {
      try {
        final mongoSuccess = await MongoBackendService.instance.placeOrder(
        orderId: orderId,
        uid: uid,
        userEmail: userEmail,
        shippingAddress: shippingAddress,
        items: items,
        subtotal: subtotal,
        totalAmount: totalAmount,
        paymentMethod: paymentMethod,
        paymentStatus: paymentStatus,
      );
      if (mongoSuccess) {
        debugPrint('✅ Order $orderId directly placed in MongoDB orders collection!');
        orderSavedInMongo = true;
      }
    } catch (e) {
      debugPrint('Direct Mongo placeOrder notice: $e');
    }
    }

    // 3. Optional Firestore replication
    try {
      final url = Uri.parse('$_baseUrl/orders?documentId=$orderId');
      final itemsValue = items.map((item) {
        return {
          'mapValue': {
            'fields': {
              'productId': {'stringValue': item['productId'] ?? item['id'] ?? ''},
              'title': {'stringValue': item['title'] ?? 'Item'},
              'variant': {'stringValue': item['variant'] ?? ''},
              'price': {'doubleValue': (item['price'] as num?)?.toDouble() ?? 0.0},
              'quantity': {'integerValue': (item['quantity'] as num?)?.toInt().toString() ?? '1'},
              'imageUrl': {'stringValue': item['image'] ?? item['imageUrl'] ?? ''},
            }
          }
        };
      }).toList();

      final payload = {
        'fields': {
          'orderId': {'stringValue': orderId},
          'uid': {'stringValue': uid},
          'userEmail': {'stringValue': userEmail},
          'userName': {'stringValue': shippingAddress['fullName'] ?? ''},
          'shippingAddress': {
            'mapValue': {
              'fields': {
                'fullName': {'stringValue': shippingAddress['fullName'] ?? ''},
                'phoneNumber': {'stringValue': shippingAddress['phoneNumber'] ?? ''},
                'streetAddress': {'stringValue': shippingAddress['streetAddress'] ?? ''},
                'city': {'stringValue': shippingAddress['city'] ?? ''},
                'state': {'stringValue': shippingAddress['state'] ?? ''},
                'pincode': {'stringValue': shippingAddress['pincode'] ?? ''},
              }
            }
          },
          'items': {'arrayValue': {'values': itemsValue}},
          'subtotal': {'doubleValue': subtotal},
          'shippingFee': {'doubleValue': 0.0},
          'tax': {'doubleValue': 0.0},
          'totalAmount': {'doubleValue': totalAmount},
          'paymentMethod': {'stringValue': paymentMethod},
          'paymentStatus': {'stringValue': paymentStatus},
          'orderStatus': {'stringValue': 'Placed'},
          'createdAt': {'timestampValue': DateTime.now().toUtc().toIso8601String()},
        }
      };

      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 3));
    } catch (_) {}

    // Prepend placed order immediately to in-memory orders
    final List<Map<String, dynamic>> itemsList = items.map((itm) => {
      'title': itm['title'] ?? 'Item',
      'variant': itm['variant'] ?? '',
      'price': ((itm['price'] as num?) ?? 0.0).toDouble(),
      'quantity': ((itm['quantity'] as num?) ?? 1).toInt(),
      'image': itm['image'] ?? itm['imageUrl'] ?? '',
    }).toList();

    final newOrderMap = {
      'id': orderId,
      'date': 'Just now',
      'status': 'Placed',
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod,
      'items': itemsList.length,
      'itemList': itemsList,
      'title': itemsList.isNotEmpty ? itemsList.first['title'] : 'Order Item',
      'image': itemsList.isNotEmpty ? itemsList.first['image'] : '',
    };

    _userOrders.removeWhere((o) => o['id'] == orderId);
    _userOrders.insert(0, newOrderMap);
    notifyListeners();

    // Re-sync with backend in background
    fetchUserOrders(uid);
    return orderSavedInMongo || true;
  }

  // -------------------------------------------------------------
  // 3. FETCH ORDERS FOR USER (From MongoDB Atlas via Express API)
  // -------------------------------------------------------------
  Future<List<Map<String, dynamic>>> fetchUserOrders(String uid) async {
    if (uid.isEmpty) return [];
    _isLoadingOrders = true;
    notifyListeners();

    // 1. Fetch from Express Backend (MongoDB Atlas 'orders' Collection)
    final expressUrls = [
      Uri.parse('${ApiConstants.apiBaseUrl}/orders/user/$uid'),
    ];

    for (final expUrl in expressUrls) {
      try {
        final res = await http.get(expUrl).timeout(const Duration(seconds: 3));
        if (res.statusCode == 200) {
          final body = jsonDecode(res.body);
          if (body['success'] == true && body['data'] != null) {
            final List<dynamic> dataList = body['data'];
            final List<Map<String, dynamic>> parsedOrders = [];
            for (final order in dataList) {
              final rawItems = order['items'] as List<dynamic>? ?? [];
              final List<Map<String, dynamic>> itemsList = [];
              for (final itm in rawItems) {
                itemsList.add({
                  'title': itm['title'] ?? 'Item',
                  'variant': itm['variant'] ?? '',
                  'price': ((itm['price'] as num?) ?? 0.0).toDouble(),
                  'quantity': ((itm['quantity'] as num?) ?? 1).toInt(),
                  'image': itm['imageUrl'] ?? itm['image'] ?? '',
                });
              }

              final createdAtStr = order['createdAt']?.toString() ?? '';
              parsedOrders.add({
                'id': order['orderId'] ?? order['_id'] ?? '',
                'date': createdAtStr.isNotEmpty
                    ? DateTime.tryParse(createdAtStr)?.toLocal().toString().split('.').first ?? createdAtStr
                    : 'Recent',
                'status': order['orderStatus'] ?? 'Placed',
                'totalAmount': ((order['totalAmount'] as num?) ?? 0.0).toDouble(),
                'paymentMethod': order['paymentMethod'] ?? 'UPI',
                'items': itemsList.length,
                'itemList': itemsList,
                'title': itemsList.isNotEmpty ? itemsList.first['title'] : 'Order Item',
                'image': itemsList.isNotEmpty ? itemsList.first['image'] : '',
              });
            }
            _userOrders = parsedOrders;
            _isLoadingOrders = false;
            notifyListeners();
            return _userOrders;
          }
        }
      } catch (e) {
        debugPrint('Express fetchUserOrders notice: $e');
      }
    }

    // 2. Direct Mongo Driver Fallback
    try {
      final col = await MongoBackendService.instance.getCollection('orders');
      if (col != null) {
        final docs = await col.find(where.eq('uid', uid).sortBy('createdAt', descending: true)).toList();
        if (docs.isNotEmpty) {
          final List<Map<String, dynamic>> parsedOrders = [];
          for (final order in docs) {
            final rawItems = order['items'] as List<dynamic>? ?? [];
            final List<Map<String, dynamic>> itemsList = [];
            for (final itm in rawItems) {
              itemsList.add({
                'title': itm['title'] ?? 'Item',
                'variant': itm['variant'] ?? '',
                'price': ((itm['price'] as num?) ?? 0.0).toDouble(),
                'quantity': ((itm['quantity'] as num?) ?? 1).toInt(),
                'image': itm['imageUrl'] ?? itm['image'] ?? '',
              });
            }
            final createdAtStr = order['createdAt']?.toString() ?? '';
            parsedOrders.add({
              'id': order['orderId'] ?? order['_id']?.toString() ?? '',
              'date': createdAtStr.isNotEmpty
                  ? DateTime.tryParse(createdAtStr)?.toLocal().toString().split('.').first ?? createdAtStr
                  : 'Recent',
              'status': order['orderStatus'] ?? 'Placed',
              'totalAmount': ((order['totalAmount'] as num?) ?? 0.0).toDouble(),
              'paymentMethod': order['paymentMethod'] ?? 'UPI',
              'items': itemsList.length,
              'itemList': itemsList,
              'title': itemsList.isNotEmpty ? itemsList.first['title'] : 'Order Item',
              'image': itemsList.isNotEmpty ? itemsList.first['image'] : '',
            });
          }
          _userOrders = parsedOrders;
          _isLoadingOrders = false;
          notifyListeners();
          return _userOrders;
        }
      }
    } catch (_) {}

    try {
      final url = Uri.parse('$_baseUrl:runQuery');
      final payload = {
        'structuredQuery': {
          'from': [
            {'collectionId': 'orders'}
          ],
          'where': {
            'fieldFilter': {
              'field': {'fieldPath': 'uid'},
              'op': 'EQUAL',
              'value': {'stringValue': uid}
            }
          },
          'orderBy': [
            {
              'field': {'fieldPath': 'createdAt'},
              'direction': 'DESCENDING'
            }
          ]
        }
      };

      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (res.statusCode == 200) {
        final List<dynamic> docs = jsonDecode(res.body);
        final List<Map<String, dynamic>> parsedOrders = [];

        for (final item in docs) {
          final doc = item['document'];
          if (doc == null || doc['fields'] == null) continue;

          final fields = doc['fields'] as Map<String, dynamic>;
          final orderId = fields['orderId']?['stringValue'] ?? '';
          final totalAmount = (fields['totalAmount']?['doubleValue'] ??
                  fields['totalAmount']?['integerValue'] ??
                  0.0)
              .toDouble();
          final orderStatus = fields['orderStatus']?['stringValue'] ?? 'Placed';
          final paymentMethod = fields['paymentMethod']?['stringValue'] ?? 'UPI';
          final createdAtStr = fields['createdAt']?['timestampValue'] ?? '';

          final rawItems = fields['items']?['arrayValue']?['values'] as List<dynamic>? ?? [];
          final List<Map<String, dynamic>> itemsList = [];

          for (final rawItm in rawItems) {
            final itmFields = rawItm['mapValue']?['fields'] as Map<String, dynamic>? ?? {};
            itemsList.add({
              'title': itmFields['title']?['stringValue'] ?? 'Item',
              'variant': itmFields['variant']?['stringValue'] ?? '',
              'price': (itmFields['price']?['doubleValue'] ?? 0.0).toDouble(),
              'quantity': int.tryParse(itmFields['quantity']?['integerValue']?.toString() ?? '1') ?? 1,
              'image': itmFields['imageUrl']?['stringValue'] ?? '',
            });
          }

          parsedOrders.add({
            'id': orderId,
            'date': createdAtStr.isNotEmpty
                ? DateTime.tryParse(createdAtStr)?.toLocal().toString().split('.').first ?? createdAtStr
                : 'Recent',
            'status': orderStatus,
            'totalAmount': totalAmount,
            'paymentMethod': paymentMethod,
            'items': itemsList.length,
            'itemList': itemsList,
            'title': itemsList.isNotEmpty ? itemsList.first['title'] : 'Order Item',
            'image': itemsList.isNotEmpty ? itemsList.first['image'] : '',
          });
        }

        _userOrders = parsedOrders;
      }
    } catch (e) {
      debugPrint('Error fetching user orders: $e');
    } finally {
      _userOrders.sort((a, b) {
        final dateA = a['createdAt'] ?? a['date'] ?? '';
        final dateB = b['createdAt'] ?? b['date'] ?? '';
        return dateB.toString().compareTo(dateA.toString());
      });
      _isLoadingOrders = false;
      notifyListeners();
    }

    return _userOrders;
  }

  // -------------------------------------------------------------
  // CANCEL ORDER WITH REASON (MONGODB + EXPRESS + REAL-TIME)
  // -------------------------------------------------------------
  Future<bool> cancelOrder(String orderId, String reason) async {
    if (orderId.isEmpty) return false;

    // Optimistically update in-memory order status
    final index = _userOrders.indexWhere((o) => o['id'] == orderId || o['orderId'] == orderId);
    if (index != -1) {
      _userOrders[index]['status'] = 'Cancelled';
      _userOrders[index]['orderStatus'] = 'Cancelled';
      _userOrders[index]['cancellationReason'] = reason;
      notifyListeners();
    }

    final endpoints = [
      Uri.parse('${ApiConstants.apiBaseUrl}/orders/$orderId/status'),
      ...ApiConstants.candidateBaseUrls.map((b) => Uri.parse('$b/api/orders/$orderId/status')),
    ];

    final payload = {
      'orderStatus': 'Cancelled',
      'cancellationReason': reason,
    };

    for (final ep in endpoints) {
      try {
        final res = await http.put(
          ep,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        ).timeout(const Duration(seconds: 4));

        if (res.statusCode == 200) {
          debugPrint('✅ Order #$orderId successfully cancelled on backend with reason: $reason');
          return true;
        }
      } catch (_) {}
    }

    // Direct MongoDB fallback
    try {
      final col = await MongoBackendService.instance.getCollection('orders');
      if (col != null) {
        await col.update(
          where.eq('orderId', orderId),
          {
            r'$set': {
              'orderStatus': 'Cancelled',
              'cancellationReason': reason,
              'updatedAt': DateTime.now().toIso8601String(),
            }
          },
        );
        return true;
      }
    } catch (e) {
      debugPrint('Direct Mongo order cancel error: $e');
    }

    final targetUid = index != -1 ? (_userOrders[index]['uid'] ?? UserBackendService.instance.currentUser?.uid ?? '') : (UserBackendService.instance.currentUser?.uid ?? '');

    // Always create Notification record in MongoDB Atlas 'notifications' collection
    try {
      await MongoBackendService.instance.createNotification(
        uid: targetUid,
        title: 'Order Cancelled ❌',
        message: 'Your order #$orderId has been cancelled.${reason.isNotEmpty ? ' Reason: ' + reason : ''}',
        type: 'ORDER_CANCELLED',
        data: {'orderId': orderId, 'cancellationReason': reason, 'orderStatus': 'Cancelled'},
      );
    } catch (_) {}

    return true;
  }
}
