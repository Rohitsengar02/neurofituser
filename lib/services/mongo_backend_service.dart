import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mongo_dart/mongo_dart.dart';

class MongoBackendService extends ChangeNotifier {
  static final MongoBackendService _instance = MongoBackendService._internal();
  factory MongoBackendService() => _instance;
  static MongoBackendService get instance => _instance;
  MongoBackendService._internal();

  static const String mongoUri =
      'mongodb+srv://rohitsengar02_db_user:HtQBKwZ4zHyDnSKS@neurofitapp.pfpotec.mongodb.net/neurofit?retryWrites=true&w=majority';

  Db? _db;
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  bool _isConnecting = false;
  bool get isConnecting => _isConnecting;

  // -------------------------------------------------------------
  // 1. INITIALIZE & CONNECT TO MONGODB ATLAS
  // -------------------------------------------------------------
  Future<Db?> connect() async {
    if (_db != null && _db!.isConnected) {
      return _db;
    }

    if (_isConnecting) {
      while (_isConnecting) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _db;
    }

    _isConnecting = true;
    notifyListeners();

    try {
      debugPrint('Connecting to MongoDB Atlas at $mongoUri...');
      _db = await Db.create(mongoUri);
      await _db!.open();
      _isConnected = true;
      debugPrint('✅ Successfully connected to MongoDB Atlas (Database: neurofit)!');
    } catch (e) {
      debugPrint('❌ Error connecting to MongoDB Atlas: $e');
      _isConnected = false;
    } finally {
      _isConnecting = false;
      notifyListeners();
    }

    return _db;
  }

  Future<DbCollection?> getCollection(String collectionName) async {
    final db = await connect();
    if (db == null || !db.isConnected) return null;
    return db.collection(collectionName);
  }

  // -------------------------------------------------------------
  // 2. USER ADDRESS MANAGEMENT (MongoDB 'addresses' collection)
  // -------------------------------------------------------------
  Future<Map<String, dynamic>?> fetchUserAddress(String uid) async {
    if (uid.isEmpty) return null;
    try {
      final col = await getCollection('addresses');
      if (col == null) return null;

      final doc = await col.findOne(where.eq('uid', uid));
      if (doc != null) {
        return {
          'fullName': doc['fullName'] ?? '',
          'phoneNumber': doc['phoneNumber'] ?? '',
          'streetAddress': doc['streetAddress'] ?? '',
          'city': doc['city'] ?? '',
          'state': doc['state'] ?? '',
          'pincode': doc['pincode'] ?? '',
        };
      }
    } catch (e) {
      debugPrint('Error fetching address from MongoDB: $e');
    }
    return null;
  }

  Future<bool> saveUserAddress(String uid, Map<String, dynamic> address) async {
    if (uid.isEmpty) return false;
    try {
      final col = await getCollection('addresses');
      if (col == null) return false;

      final doc = {
        'uid': uid,
        'fullName': address['fullName'] ?? '',
        'phoneNumber': address['phoneNumber'] ?? '',
        'streetAddress': address['streetAddress'] ?? '',
        'city': address['city'] ?? '',
        'state': address['state'] ?? '',
        'pincode': address['pincode'] ?? '',
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      };

      await col.update(
        where.eq('uid', uid),
        doc,
        upsert: true,
      );

      debugPrint('✅ Address saved to MongoDB for user $uid!');
      return true;
    } catch (e) {
      debugPrint('Error saving address to MongoDB: $e');
    }
    return false;
  }

  // -------------------------------------------------------------
  // 3. ORDERS MANAGEMENT (MongoDB 'orders' collection)
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
      final col = await getCollection('orders');
      if (col == null) return false;

      final orderDoc = {
        'orderId': orderId,
        'uid': uid,
        'userEmail': userEmail,
        'userName': shippingAddress['fullName'] ?? '',
        'shippingAddress': shippingAddress,
        'items': items,
        'subtotal': subtotal,
        'shippingFee': 0.0,
        'tax': 0.0,
        'totalAmount': totalAmount,
        'paymentMethod': paymentMethod,
        'paymentStatus': paymentStatus,
        'orderStatus': 'Placed',
        'createdAt': DateTime.now().toUtc().toIso8601String(),
      };

      await col.insert(orderDoc);
      debugPrint('✅ Order $orderId successfully inserted into MongoDB orders collection!');

      // Create Notification Record in MongoDB Atlas 'notifications' collection
      await createNotification(
        uid: uid,
        title: 'Order Placed Successfully! 🎉',
        message: 'Your order #$orderId for ₹${totalAmount.toStringAsFixed(0)} has been placed.',
        type: 'ORDER_PLACED',
        data: {'orderId': orderId, 'totalAmount': totalAmount, 'orderStatus': 'Placed'},
      );
      return true;
    } catch (e) {
      debugPrint('Error placing order in MongoDB: $e');
    }
    return false;
  }

  // -------------------------------------------------------------
  // 3.5 CREATE NOTIFICATION DOCUMENT IN MONGODB ATLAS
  // -------------------------------------------------------------
  Future<void> createNotification({
    required String uid,
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      final col = await getCollection('notifications');
      if (col == null) return;

      final notifDoc = {
        'notificationId': 'notif_${DateTime.now().millisecondsSinceEpoch}',
        'uid': uid,
        'title': title,
        'message': message,
        'type': type,
        'data': data ?? {},
        'isRead': false,
        'fcmMessageId': '',
        'fcmStatus': 'pending',
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      };

      await col.insert(notifDoc);
      debugPrint('🔔 Notification inserted into MongoDB notifications collection: ${notifDoc['notificationId']}');
    } catch (e) {
      debugPrint('Error inserting notification in MongoDB: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchUserOrders(String uid) async {
    if (uid.isEmpty) return [];
    try {
      final col = await getCollection('orders');
      if (col == null) return [];

      final docs = await col.find(where.eq('uid', uid).sortBy('createdAt', descending: true)).toList();
      return docs.map((doc) {
        final rawItems = doc['items'] as List<dynamic>? ?? [];
        final itemsList = rawItems.map((itm) {
          final itemMap = Map<String, dynamic>.from(itm as Map);
          return {
            'title': itemMap['title'] ?? 'Item',
            'variant': itemMap['variant'] ?? '',
            'price': (itemMap['price'] as num?)?.toDouble() ?? 0.0,
            'quantity': (itemMap['quantity'] as num?)?.toInt() ?? 1,
            'image': itemMap['image'] ?? itemMap['imageUrl'] ?? '',
          };
        }).toList();

        return {
          'id': doc['orderId'] ?? 'NF-ORD',
          'date': doc['createdAt'] != null
              ? DateTime.tryParse(doc['createdAt'].toString())?.toLocal().toString().split('.').first ?? doc['createdAt'].toString()
              : 'Recent',
          'status': doc['orderStatus'] ?? 'Placed',
          'totalAmount': (doc['totalAmount'] as num?)?.toDouble() ?? 0.0,
          'paymentMethod': doc['paymentMethod'] ?? 'UPI',
          'items': itemsList.length,
          'itemList': itemsList,
          'title': itemsList.isNotEmpty ? itemsList.first['title'] : 'Order Item',
          'image': itemsList.isNotEmpty ? itemsList.first['image'] : '',
        };
      }).toList();
    } catch (e) {
      debugPrint('Error fetching orders from MongoDB: $e');
    }
    return [];
  }

  // -------------------------------------------------------------
  // 4. GENERIC PRODUCTS, CATEGORIES, BANNERS FETCH FROM MONGODB
  // -------------------------------------------------------------
  Future<List<Map<String, dynamic>>> fetchCollectionDocs(String collectionName) async {
    try {
      final col = await getCollection(collectionName);
      if (col == null) return [];
      return await col.find().toList();
    } catch (e) {
      debugPrint('Error fetching $collectionName from MongoDB: $e');
    }
    return [];
  }
}
