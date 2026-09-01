import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'mongo_backend_service.dart';

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
  // 2. PLACE ORDER (Root Collection 'orders')
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
          'items': {
            'arrayValue': {'values': itemsValue}
          },
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

      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        debugPrint('Order $orderId placed successfully in root collection orders!');
        await fetchUserOrders(uid);
        return true;
      } else {
        debugPrint('Error placing order: ${res.statusCode} ${res.body}');
      }
    } catch (e) {
      debugPrint('Error in placeOrder: $e');
    }
    return false;
  }

  // -------------------------------------------------------------
  // 3. FETCH ORDERS FOR USER (Root Collection 'orders')
  // -------------------------------------------------------------
  Future<List<Map<String, dynamic>>> fetchUserOrders(String uid) async {
    if (uid.isEmpty) return [];
    _isLoadingOrders = true;
    notifyListeners();

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
      debugPrint('Error fetching user orders from root collection orders: $e');
    } finally {
      _isLoadingOrders = false;
      notifyListeners();
    }

    return _userOrders;
  }
}
