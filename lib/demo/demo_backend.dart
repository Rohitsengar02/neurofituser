import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// UI-only demo mode.
///
/// Every call the app makes to its own backend (`/api/...`), Firestore REST
/// or the Cloudflare API is answered here, in memory, with demo data.
/// Nothing leaves the device. All other traffic (images, map tiles, fonts)
/// goes to the real network as usual.
class DemoBackendClient extends http.BaseClient {
  DemoBackendClient(this._inner);

  final http.Client _inner;

  // One shared store, so data added in one request (an order, a meal)
  // shows up in the next one.
  static final _DemoStore _store = _DemoStore();

  // http.get() and friends close their client after each call; the real
  // client underneath is shared, so it must stay open.
  @override
  void close() {}

  static bool _isBackendRequest(Uri url) {
    if (url.path.startsWith('/api/')) return true;
    const blockedHosts = {
      'firestore.googleapis.com',
      'api.cloudflare.com',
    };
    return blockedHosts.contains(url.host);
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (!_isBackendRequest(request.url)) {
      return _inner.send(request);
    }

    String body = '';
    if (request is http.Request) body = request.body;

    final result = _store.handle(request.method, request.url, body);
    final bytes = utf8.encode(jsonEncode(result.body));
    // A tiny delay so loading states still feel natural.
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return http.StreamedResponse(
      Stream.value(bytes),
      result.status,
      contentLength: bytes.length,
      request: request,
      headers: const {'content-type': 'application/json; charset=utf-8'},
    );
  }
}

class _Result {
  const _Result(this.status, this.body);
  final int status;
  final Object body;
}

const _notFound = _Result(404, {'success': false, 'message': 'Not available in demo mode'});
_Result _ok(Map<String, Object?> body) => _Result(200, {'success': true, ...body});

const String _gifBase = 'https://raw.githubusercontent.com/Rohitsengar02/exercies-data/main';
String _unsplash(String id, {int w = 800}) =>
    'https://images.unsplash.com/photo-$id?w=$w&auto=format&fit=crop&q=80';

String _todayKey([int daysAgo = 0]) =>
    DateTime.now().subtract(Duration(days: daysAgo)).toString().substring(0, 10);

class _DemoStore {
  _DemoStore() {
    _orders.addAll(_seedOrders());
  }

  final List<Map<String, dynamic>> _orders = [];
  final Map<String, List<Map<String, dynamic>>> _addresses = {};
  final Map<String, Map<String, dynamic>> _nutrition = {};

  _Result handle(String method, Uri url, String rawBody) {
    if (!url.path.startsWith('/api/')) return _notFound;
    final parts = url.path.substring(5).split('/').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return _notFound;
    Map<String, dynamic> body = {};
    if (rawBody.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawBody);
        if (decoded is Map) body = Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }

    final head = parts.first;
    switch (head) {
      // ---------------- Marketplace ----------------
      case 'products':
        return method == 'GET' ? _ok({'data': _products}) : _ok({'data': body});
      case 'categories':
        return method == 'GET' ? _ok({'data': _categories}) : _ok({'data': body});
      case 'subcategories':
        return method == 'GET' ? _ok({'data': _subcategories}) : _ok({'data': body});
      case 'banners':
        return method == 'GET' ? _ok({'data': _banners}) : _ok({'data': body});
      case 'layout':
        return method == 'GET' ? _ok({'data': _layoutSections}) : _ok({'data': body});
      case 'discounts':
        if (parts.length > 1 && parts[1] == 'validate') return _validateCoupon(body);
        return _ok({'data': _discounts});

      // ---------------- Workouts ----------------
      case 'workouts':
        return _ok({'data': _workouts});
      case 'exercise-categories':
        return _ok({'data': _exerciseCategories});
      case 'workout-categories':
      case 'workout-banners':
      case 'workout-layout':
      case 'workout-sections':
        // The app has good built-in defaults for these, so it uses those.
        return _notFound;
      case 'user-workouts':
        // Progress is kept on the device by the app itself.
        return _notFound;

      // ---------------- Orders ----------------
      case 'orders':
        return _handleOrders(method, parts, body);

      // ---------------- Users & addresses ----------------
      case 'users':
        return _handleUsers(method, parts, body);

      // ---------------- Nutrition ----------------
      case 'user-nutrition':
        return _handleNutrition(method, parts, url, body);
      case 'recipes':
        return _ok({'recipes': _recipes});
      case 'foods':
        return _ok({'data': _searchFoods(url.queryParameters['query'] ?? '')});

      // ---------------- Misc ----------------
      case 'notifications':
        return _ok({});
      default:
        return _notFound;
    }
  }

  // ---------------------------------------------------------------------------
  // Orders
  // ---------------------------------------------------------------------------
  _Result _handleOrders(String method, List<String> parts, Map<String, dynamic> body) {
    if (method == 'GET' && parts.length >= 3 && parts[1] == 'user') {
      final uid = parts[2];
      final mine = _orders.where((o) => o['uid'] == uid || o['uid'] == 'demo').toList()
        ..sort((a, b) => (b['createdAt'] as String).compareTo(a['createdAt'] as String));
      return _ok({'data': mine});
    }
    if (method == 'POST' && parts.length == 1) {
      final order = Map<String, dynamic>.from(body)
        ..['createdAt'] = DateTime.now().toIso8601String();
      _orders.add(order);
      return _Result(201, {'success': true, 'data': order});
    }
    if (parts.length >= 3 && parts[2] == 'status') {
      final id = parts[1];
      for (final o in _orders) {
        if (o['orderId'] == id) {
          o['orderStatus'] = body['orderStatus'] ?? o['orderStatus'];
        }
      }
      return _ok({});
    }
    return _ok({'data': _orders});
  }

  // ---------------------------------------------------------------------------
  // Users & addresses
  // ---------------------------------------------------------------------------
  _Result _handleUsers(String method, List<String> parts, Map<String, dynamic> body) {
    if (parts.length < 2) return _notFound;
    final uid = parts[1];
    final list = _addresses.putIfAbsent(uid, () => [_demoAddress()]);

    if (parts.length == 2) {
      // GET /users/:uid → let the app use the profile saved on the device.
      if (method == 'GET') return _notFound;
      return _ok({'data': body});
    }

    final sub = parts[2];
    if (sub == 'questionnaire') return _ok({});

    if (sub == 'addresses' || sub == 'address') {
      if (method == 'GET') return _ok({'data': list, 'addresses': list});
      if (method == 'POST' || method == 'PUT' || method == 'PATCH') {
        if (parts.length >= 5 && (parts[4] == 'default' || parts[4] == 'primary')) {
          for (final a in list) {
            a['isDefault'] = a['id'] == parts[3];
          }
          return _ok({'data': list, 'addresses': list});
        }
        final addr = Map<String, dynamic>.from(body);
        addr['id'] ??= 'addr_${DateTime.now().millisecondsSinceEpoch}';
        if (addr['isDefault'] == true || list.isEmpty) {
          for (final a in list) {
            a['isDefault'] = false;
          }
          addr['isDefault'] = true;
        }
        list.removeWhere((a) => a['id'] == addr['id']);
        list.insert(0, addr);
        return _ok({'data': list, 'addresses': list});
      }
      if (method == 'DELETE' && parts.length >= 4) {
        list.removeWhere((a) => a['id'] == parts[3]);
        return _ok({'data': list, 'addresses': list});
      }
    }
    return _ok({});
  }

  Map<String, dynamic> _demoAddress() => {
        'id': 'addr_demo_home',
        'label': 'Home',
        'fullName': 'Demo Athlete',
        'name': 'Demo Athlete',
        'phoneNumber': '9876543210',
        'phone': '9876543210',
        'streetAddress': '221 Fitness Street, Sector 21',
        'addressLine1': '221 Fitness Street, Sector 21',
        'city': 'New Delhi',
        'state': 'Delhi',
        'pincode': '110001',
        'isDefault': true,
      };

  // ---------------------------------------------------------------------------
  // Nutrition
  // ---------------------------------------------------------------------------
  _Result _handleNutrition(
      String method, List<String> parts, Uri url, Map<String, dynamic> body) {
    final action = parts.length > 1 ? parts[1] : '';
    switch (action) {
      case 'today':
        final date = url.queryParameters['date'] ?? _todayKey();
        final uid = url.queryParameters['uid'] ?? 'demo';
        return _ok({'nutrition': _dayFor(uid, date)});
      case 'history':
        final history = <String, dynamic>{};
        for (var i = 1; i <= 14; i++) {
          if (i % 4 == 3) continue; // a few rest days with nothing logged
          history[_todayKey(i)] = {
            'hasLogged': true,
            'consumedCalories': 1700 + (i * 97) % 600,
          };
        }
        return _ok({'history': history});
      case 'log-meal':
        final uid = (body['uid'] ?? 'demo').toString();
        final date = (body['date'] ?? _todayKey()).toString();
        final day = _dayFor(uid, date);
        final qty = (body['quantity'] as num?)?.toDouble() ?? 1.0;
        final meal = {
          'mealId': 'meal_${DateTime.now().millisecondsSinceEpoch}',
          'mealType': body['mealType'] ?? 'snack',
          'foodName': body['foodName'] ?? 'Meal',
          'source': body['source'] ?? 'Demo',
          'category': body['category'] ?? 'General',
          'calories': (((body['calories'] as num?) ?? 0) * qty).round(),
          'protein': ((body['protein'] as num?) ?? 0) * qty,
          'carbs': ((body['carbs'] as num?) ?? 0) * qty,
          'fat': ((body['fat'] as num?) ?? 0) * qty,
          'fiber': ((body['fiber'] as num?) ?? 0) * qty,
          'servingSize': body['servingSize'] ?? '1 serving',
          'quantity': qty,
          'time': _nowTime(),
          'iconType': body['iconType'] ?? 'restaurant',
        };
        (day['meals'] as List).add(meal);
        _recalc(day);
        return _ok({'nutrition': day});
      case 'meal':
        if (parts.length >= 4) {
          final day = _dayFor(parts[2], url.queryParameters['date'] ?? _todayKey());
          (day['meals'] as List).removeWhere((m) => (m as Map)['mealId'] == parts[3]);
          _recalc(day);
          return _ok({'nutrition': day});
        }
        return _ok({});
      case 'water':
        final uid = (body['uid'] ?? 'demo').toString();
        final day = _dayFor(uid, (body['date'] ?? _todayKey()).toString());
        final glasses = (body['glasses'] as num?)?.toInt();
        if (glasses != null) {
          day['waterGlasses'] = glasses;
          day['waterMilliliters'] = glasses * 250;
        }
        return _ok({'nutrition': day});
      default:
        return _notFound;
    }
  }

  Map<String, dynamic> _dayFor(String uid, String date) {
    return _nutrition.putIfAbsent('$uid|$date', () {
      final isToday = date == _todayKey();
      final meals = <Map<String, dynamic>>[
        _seedMeal('breakfast', 'Oats with banana & peanut butter', 420, 15, 62, 13, '8:15 AM'),
        _seedMeal('lunch', 'Grilled chicken rice bowl', 610, 46, 70, 14, '1:30 PM'),
        if (!isToday) _seedMeal('snack', 'Greek yogurt with berries', 180, 17, 20, 3, '5:00 PM'),
        if (!isToday) _seedMeal('dinner', 'Paneer tikka with salad', 520, 32, 18, 34, '8:45 PM'),
      ];
      final day = <String, dynamic>{
        'uid': uid,
        'date': date,
        'targetCalories': 2400,
        'targetProtein': 140,
        'targetCarbs': 260,
        'targetFat': 70,
        'waterGlasses': isToday ? 5 : 8,
        'waterTargetGlasses': 10,
        'waterMilliliters': isToday ? 1250 : 2000,
        'meals': meals,
      };
      _recalc(day);
      return day;
    });
  }

  Map<String, dynamic> _seedMeal(String type, String name, int kcal, double p, double c,
          double f, String time) =>
      {
        'mealId': 'seed_${type}_${name.hashCode}',
        'mealType': type,
        'foodName': name,
        'source': 'Demo',
        'category': 'Meals',
        'calories': kcal,
        'protein': p,
        'carbs': c,
        'fat': f,
        'fiber': 4.0,
        'servingSize': '1 bowl',
        'quantity': 1.0,
        'time': time,
        'iconType': 'restaurant',
      };

  void _recalc(Map<String, dynamic> day) {
    num kcal = 0, p = 0, c = 0, f = 0, fi = 0;
    for (final m in (day['meals'] as List)) {
      final meal = m as Map;
      kcal += (meal['calories'] as num?) ?? 0;
      p += (meal['protein'] as num?) ?? 0;
      c += (meal['carbs'] as num?) ?? 0;
      f += (meal['fat'] as num?) ?? 0;
      fi += (meal['fiber'] as num?) ?? 0;
    }
    day['consumedCalories'] = kcal.round();
    day['consumedProtein'] = p.toDouble();
    day['consumedCarbs'] = c.toDouble();
    day['consumedFat'] = f.toDouble();
    day['consumedFiber'] = fi.toDouble();
  }

  String _nowTime() {
    final now = DateTime.now();
    final h = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final m = now.minute.toString().padLeft(2, '0');
    return '$h:$m ${now.hour < 12 ? 'AM' : 'PM'}';
  }

  List<Map<String, dynamic>> _searchFoods(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty || q == 'healthy') return _foods;
    final hits = _foods
        .where((f) =>
            (f['name'] as String).toLowerCase().contains(q) ||
            (f['category'] as String).toLowerCase().contains(q))
        .toList();
    return hits.isEmpty ? _foods : hits;
  }

  // ---------------------------------------------------------------------------
  // Coupons
  // ---------------------------------------------------------------------------
  _Result _validateCoupon(Map<String, dynamic> body) {
    final code = (body['code'] ?? '').toString().trim().toUpperCase();
    final orderValue = (body['orderValue'] as num?)?.toDouble() ?? 0;
    final match = _discounts.where((d) => d['code'] == code).toList();
    if (match.isEmpty) {
      return const _Result(400, {'success': false, 'message': 'Invalid coupon code'});
    }
    final d = match.first;
    final min = (d['minOrderValue'] as num).toDouble();
    if (orderValue < min) {
      return _Result(400, {
        'success': false,
        'message': 'Minimum order value for $code is ₹${min.toInt()}',
      });
    }
    final value = (d['value'] as num).toDouble();
    final discount = d['type'] == 'percentage' ? orderValue * value / 100 : value;
    return _ok({
      'data': {
        'code': code,
        'type': d['type'],
        'value': value,
        'discountAmount': discount,
        'finalAmount': orderValue - discount,
        'title': d['title'],
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Seed data
  // ---------------------------------------------------------------------------
  List<Map<String, dynamic>> _seedOrders() {
    Map<String, dynamic> item(String id, String title, double price, int qty, String img) => {
          'productId': id,
          'title': title,
          'variant': '',
          'price': price,
          'quantity': qty,
          'imageUrl': img,
        };
    return [
      {
        'orderId': 'NF10482',
        'uid': 'demo',
        'orderStatus': 'Delivered',
        'paymentMethod': 'UPI',
        'paymentStatus': 'Paid',
        'totalAmount': 3498.0,
        'subtotal': 3498.0,
        'createdAt': DateTime.now().subtract(const Duration(days: 9)).toIso8601String(),
        'shippingAddress': _demoAddress(),
        'items': [
          item('p_whey', 'Whey Protein Isolate 1kg', 2999, 1, _products[0]['mainImageUrl'] as String),
          item('p_shaker', 'Neurofit Steel Shaker', 499, 1, _products[3]['mainImageUrl'] as String),
        ],
      },
      {
        'orderId': 'NF10517',
        'uid': 'demo',
        'orderStatus': 'Shipped',
        'paymentMethod': 'Card',
        'paymentStatus': 'Paid',
        'totalAmount': 1799.0,
        'subtotal': 1799.0,
        'createdAt': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
        'shippingAddress': _demoAddress(),
        'items': [
          item('p_bands', 'Resistance Bands Set', 1799, 1, _products[5]['mainImageUrl'] as String),
        ],
      },
    ];
  }
}

// -----------------------------------------------------------------------------
// Static demo catalogue
// -----------------------------------------------------------------------------
final List<Map<String, dynamic>> _categories = [
  {'id': 'cat_supplements', 'name': 'Supplements', 'slug': 'supplements', 'imageUrl': _unsplash('1593095948071-474c5cc2989d', w: 400), 'sortOrder': 1, 'isActive': true, 'productCount': 4},
  {'id': 'cat_equipment', 'name': 'Equipment', 'slug': 'equipment', 'imageUrl': _unsplash('1534438327276-14e5300c3a48', w: 400), 'sortOrder': 2, 'isActive': true, 'productCount': 4},
  {'id': 'cat_apparel', 'name': 'Apparel', 'slug': 'apparel', 'imageUrl': _unsplash('1542291026-7eec264c27ff', w: 400), 'sortOrder': 3, 'isActive': true, 'productCount': 3},
  {'id': 'cat_snacks', 'name': 'Healthy Snacks', 'slug': 'healthy-snacks', 'imageUrl': _unsplash('1490645935967-10de6ba17061', w: 400), 'sortOrder': 4, 'isActive': true, 'productCount': 2},
];

final List<Map<String, dynamic>> _subcategories = [
  {'id': 'sub_protein', 'name': 'Protein', 'parentCategoryId': 'cat_supplements', 'parentCategoryName': 'Supplements', 'imageUrl': _unsplash('1593095948071-474c5cc2989d', w: 300), 'sortOrder': 1, 'isActive': true},
  {'id': 'sub_vitamins', 'name': 'Vitamins', 'parentCategoryId': 'cat_supplements', 'parentCategoryName': 'Supplements', 'imageUrl': _unsplash('1584308666744-24d5c474f2ae', w: 300), 'sortOrder': 2, 'isActive': true},
  {'id': 'sub_weights', 'name': 'Weights', 'parentCategoryId': 'cat_equipment', 'parentCategoryName': 'Equipment', 'imageUrl': _unsplash('1534438327276-14e5300c3a48', w: 300), 'sortOrder': 1, 'isActive': true},
  {'id': 'sub_bands', 'name': 'Bands & Mats', 'parentCategoryId': 'cat_equipment', 'parentCategoryName': 'Equipment', 'imageUrl': _unsplash('1518611012118-696072aa579a', w: 300), 'sortOrder': 2, 'isActive': true},
  {'id': 'sub_shoes', 'name': 'Shoes', 'parentCategoryId': 'cat_apparel', 'parentCategoryName': 'Apparel', 'imageUrl': _unsplash('1542291026-7eec264c27ff', w: 300), 'sortOrder': 1, 'isActive': true},
  {'id': 'sub_bars', 'name': 'Protein Bars', 'parentCategoryId': 'cat_snacks', 'parentCategoryName': 'Healthy Snacks', 'imageUrl': _unsplash('1490645935967-10de6ba17061', w: 300), 'sortOrder': 1, 'isActive': true},
];

Map<String, dynamic> _product(String id, String title, String cat, String catName, String sub,
        String subName, double price, double regular, String img,
        {bool featured = false, double rating = 4.6, int reviews = 120, String desc = ''}) =>
    {
      'id': id,
      'title': title,
      'description': desc.isNotEmpty
          ? desc
          : '$title from the Neurofit store. Demo product for previewing the shop screens.',
      'sku': 'NF-${id.toUpperCase()}',
      'categoryId': cat,
      'categoryName': catName,
      'subcategoryId': sub,
      'subcategoryName': subName,
      'price': price,
      'regularPrice': regular,
      'stock': 40,
      'brand': 'Neurofit',
      'vendor': 'Neurofit Official',
      'tags': [catName.toLowerCase(), subName.toLowerCase()],
      'status': 'active',
      'mainImageUrl': img,
      'additionalImages': [img],
      'variants': [],
      'isFeatured': featured,
      'rating': rating,
      'reviewCount': reviews,
    };

final List<Map<String, dynamic>> _products = [
  _product('p_whey', 'Whey Protein Isolate 1kg', 'cat_supplements', 'Supplements', 'sub_protein', 'Protein', 2999, 3799, _unsplash('1593095948071-474c5cc2989d'), featured: true, rating: 4.8, reviews: 842, desc: '27g protein per scoop, low sugar, chocolate flavour. Mixes smoothly with water or milk.'),
  _product('p_creatine', 'Creatine Monohydrate 250g', 'cat_supplements', 'Supplements', 'sub_protein', 'Protein', 899, 1199, _unsplash('1579722821273-0f6c7d44362f'), featured: true, rating: 4.7, reviews: 516),
  _product('p_multi', 'Daily Multivitamin (60 tabs)', 'cat_supplements', 'Supplements', 'sub_vitamins', 'Vitamins', 549, 699, _unsplash('1584308666744-24d5c474f2ae'), rating: 4.5, reviews: 210),
  _product('p_shaker', 'Neurofit Steel Shaker', 'cat_supplements', 'Supplements', 'sub_protein', 'Protein', 499, 699, _unsplash('1517838277536-f5f99be501cd'), rating: 4.4, reviews: 98),
  _product('p_dumbbell', 'Adjustable Dumbbells 2×10kg', 'cat_equipment', 'Equipment', 'sub_weights', 'Weights', 4499, 5999, _unsplash('1534438327276-14e5300c3a48'), featured: true, rating: 4.7, reviews: 301),
  _product('p_bands', 'Resistance Bands Set', 'cat_equipment', 'Equipment', 'sub_bands', 'Bands & Mats', 1799, 2299, _unsplash('1518611012118-696072aa579a'), featured: true, rating: 4.6, reviews: 455),
  _product('p_mat', 'Yoga Mat 6mm', 'cat_equipment', 'Equipment', 'sub_bands', 'Bands & Mats', 1299, 1599, _unsplash('1506126613408-eca07ce68773'), rating: 4.5, reviews: 187),
  _product('p_kettle', 'Cast Iron Kettlebell 12kg', 'cat_equipment', 'Equipment', 'sub_weights', 'Weights', 2199, 2699, _unsplash('1517836357463-d25dfeac3438'), rating: 4.6, reviews: 143),
  _product('p_shoes', 'Neurofit Runner Shoes', 'cat_apparel', 'Apparel', 'sub_shoes', 'Shoes', 3499, 4999, _unsplash('1542291026-7eec264c27ff'), featured: true, rating: 4.7, reviews: 389),
  _product('p_tee', 'DryFit Training Tee', 'cat_apparel', 'Apparel', 'sub_shoes', 'Shoes', 799, 1199, _unsplash('1581009146145-b5ef050c2e1e'), rating: 4.3, reviews: 76),
  _product('p_bar', 'Protein Bar Box (12)', 'cat_snacks', 'Healthy Snacks', 'sub_bars', 'Protein Bars', 1199, 1440, _unsplash('1490645935967-10de6ba17061'), rating: 4.4, reviews: 164),
  _product('p_granola', 'High-Protein Granola 500g', 'cat_snacks', 'Healthy Snacks', 'sub_bars', 'Protein Bars', 449, 599, _unsplash('1512621776951-a57141f2eefd'), rating: 4.5, reviews: 92),
];

final List<Map<String, dynamic>> _banners = [
  {'id': 'ban_1', 'title': 'Protein Week', 'subtitle': 'Up to 25% off whey and creatine', 'badge': 'LIMITED', 'buttonText': 'Shop Protein', 'imageUrl': _unsplash('1593095948071-474c5cc2989d', w: 1200), 'targetType': 'category', 'targetId': 'cat_supplements', 'targetName': 'Supplements', 'discountCode': 'PROTEIN25', 'sortOrder': 1, 'isActive': true},
  {'id': 'ban_2', 'title': 'Build Your Home Gym', 'subtitle': 'Dumbbells, kettlebells and bands', 'badge': 'NEW', 'buttonText': 'Explore', 'imageUrl': _unsplash('1534438327276-14e5300c3a48', w: 1200), 'targetType': 'category', 'targetId': 'cat_equipment', 'targetName': 'Equipment', 'discountCode': '', 'sortOrder': 2, 'isActive': true},
  {'id': 'ban_3', 'title': 'Run Further', 'subtitle': 'New Neurofit Runner shoes', 'badge': 'FEATURED', 'buttonText': 'View', 'imageUrl': _unsplash('1542291026-7eec264c27ff', w: 1200), 'targetType': 'product', 'targetId': 'p_shoes', 'targetName': 'Neurofit Runner Shoes', 'discountCode': '', 'sortOrder': 3, 'isActive': true},
];

final List<Map<String, dynamic>> _layoutSections = [
  {'id': 'sec_banners', 'title': 'Top Deals', 'type': 'banners', 'layoutMode': 'hero_carousel', 'filterSource': 'all', 'sortOrder': 1, 'isActive': true, 'showTitle': false},
  {'id': 'sec_categories', 'title': 'Shop by Category', 'type': 'categories', 'layoutMode': 'carousel', 'filterSource': 'all', 'sortOrder': 2, 'isActive': true},
  {'id': 'sec_featured', 'title': 'Featured Picks', 'subtitle': 'Most loved by the community', 'type': 'products', 'layoutMode': 'carousel', 'filterSource': 'featured', 'itemLimit': 8, 'sortOrder': 3, 'isActive': true},
  {'id': 'sec_supplements', 'title': 'Supplements', 'type': 'products', 'layoutMode': 'carousel', 'filterSource': 'category', 'filterId': 'cat_supplements', 'filterName': 'Supplements', 'itemLimit': 8, 'sortOrder': 4, 'isActive': true},
  {'id': 'sec_all', 'title': 'All Products', 'type': 'products', 'layoutMode': 'grid', 'filterSource': 'all', 'itemLimit': 12, 'sortOrder': 5, 'isActive': true},
];

final List<Map<String, dynamic>> _discounts = [
  {'id': 'disc_1', 'code': 'PROTEIN25', 'title': '25% off supplements', 'type': 'percentage', 'value': 25, 'minOrderValue': 999, 'maxUses': 1000, 'usedCount': 120, 'isActive': true},
  {'id': 'disc_2', 'code': 'WELCOME200', 'title': '₹200 off your first order', 'type': 'fixed', 'value': 200, 'minOrderValue': 1499, 'maxUses': 1000, 'usedCount': 48, 'isActive': true},
];

Map<String, dynamic> _ex(String id, String name, String muscle, String gif, String tip,
        {int sets = 3, int reps = 12, int seconds = 0, int rest = 45}) =>
    {
      'exerciseId': id,
      'title': name,
      'muscleGroup': muscle,
      'mediaUrl': '$_gifBase/videos/$gif',
      'mediaType': 'gif',
      'sets': sets,
      'reps': reps,
      'durationSeconds': seconds,
      'restSeconds': rest,
      'instructions': tip,
    };

final _benchPress = _ex('0025', 'Barbell Bench Press', 'Chest', '0025-EIeI8Vf.gif', 'Keep your feet planted and lower the bar to mid-chest.', reps: 10);
final _pushUp = _ex('0662', 'Push-up', 'Chest', '0662-I4hDWkc.gif', 'Body in a straight line, elbows at about 45 degrees.', reps: 15);
final _inclinePress = _ex('0314', 'Dumbbell Incline Press', 'Chest', '0314-ns0SIbU.gif', 'Bench at 45 degrees, press up and slightly in.', reps: 10);
final _pullUp = _ex('0652', 'Pull-up', 'Back', '0652-lBDjFxJ.gif', 'Pull your chest to the bar, control the way down.', reps: 8);
final _row = _ex('0027', 'Barbell Bent-over Row', 'Back', '0027-eZyBC3j.gif', 'Hinge at the hips and pull the bar to your belly.', reps: 10);
final _pulldown = _ex('2330', 'Lat Pulldown', 'Back', '2330-LEprlgG.gif', 'Pull the bar to your upper chest, squeeze your back.', reps: 12);
final _squat = _ex('0043', 'Barbell Squat', 'Legs', '0043-qXTaZnJ.gif', 'Chest up, knees track over toes, go to parallel.', reps: 8, rest: 90);
final _deadlift = _ex('0032', 'Barbell Deadlift', 'Legs', '0032-ila4NZS.gif', 'Keep the bar close and your back flat.', reps: 6, rest: 90);
final _lunge = _ex('0336', 'Dumbbell Lunge', 'Legs', '0336-RRWFUcw.gif', 'Step forward and lower until both knees are at 90 degrees.', reps: 12);
final _legPress = _ex('2287', 'Leg Press', 'Legs', '2287-V07qpXy.gif', 'Press through your heels, do not lock your knees.', reps: 12);
final _lateralRaise = _ex('0334', 'Dumbbell Lateral Raise', 'Shoulders', '0334-DsgkuIt.gif', 'Lift to shoulder height with a slight bend in the elbows.', reps: 15);
final _curl = _ex('0294', 'Dumbbell Biceps Curl', 'Arms', '0294-NbVPDMW.gif', 'Keep your elbows by your sides.', reps: 12);
final _dip = _ex('0814', 'Triceps Dip', 'Arms', '0814-X6C6i5Y.gif', 'Lower until your elbows reach 90 degrees.', reps: 12);
final _bicycle = _ex('0972', 'Bicycle Crunch', 'Core', '0972-tZkGYZ9.gif', 'Bring the opposite elbow to knee, slow and controlled.', reps: 20);
final _sidePlank = _ex('3544', 'Side Plank', 'Core', '3544-5VXmnV5.gif', 'Hips up, body in a straight line.', reps: 1, seconds: 30);
final _russianTwist = _ex('0687', 'Russian Twist', 'Core', '0687-XVDdcoj.gif', 'Lean back slightly and rotate from your torso.', reps: 20);
final _climber = _ex('0630', 'Mountain Climber', 'Cardio', '0630-RJgzwny.gif', 'Drive your knees fast, keep hips level.', reps: 1, seconds: 40, rest: 20);
final _burpee = _ex('1160', 'Burpee', 'Cardio', '1160-dK9394r.gif', 'Chest to floor, then jump with arms overhead.', reps: 12, rest: 30);
final _jumpSquat = _ex('0514', 'Jump Squat', 'Legs', '0514-LIlE5Tn.gif', 'Land softly and go straight into the next rep.', reps: 15, rest: 30);
final _highKnee = _ex('3636', 'High Knees', 'Cardio', '3636-ealLwvX.gif', 'Knees to hip height, stay on the balls of your feet.', reps: 1, seconds: 40, rest: 20);
final _goblet = _ex('1760', 'Goblet Squat', 'Legs', '1760-yn8yg1r.gif', 'Hold the dumbbell at your chest, sit between your heels.', reps: 12);
final _swing = _ex('0549', 'Kettlebell Swing', 'Full Body', '0549-UHJlbu3.gif', 'Snap your hips forward, arms stay relaxed.', reps: 15);

Map<String, dynamic> _day(int n, String title, String focus, List<Map<String, dynamic>> ex,
        {int minutes = 45, int kcal = 350, bool rest = false}) =>
    {
      'dayNumber': n,
      'weekNumber': ((n - 1) ~/ 7) + 1,
      'title': title,
      'focus': focus,
      'durationMinutes': minutes,
      'caloriesBurn': kcal,
      'isRestDay': rest,
      'exercises': ex,
    };

Map<String, dynamic> _workout(String id, String title, String subtitle, String cat, String catName,
        String level, String coach, String img, List<Map<String, dynamic>> days,
        {int minutes = 45, int kcal = 380, bool featured = true, double rating = 4.8}) {
  final firstDayExercises = (days.first['exercises'] as List);
  return {
    'id': id,
    'title': title,
    'subtitle': subtitle,
    'description':
        '$title is a $level program by $coach. Follow the days in order and track every set in the app.',
    'category': catName,
    'workoutCategoryId': cat,
    'durationMinutes': minutes,
    'caloriesBurn': kcal,
    'level': level,
    'coach': coach,
    'imageUrl': img,
    'mediaType': 'image',
    'exercisesCount': firstDayExercises.length,
    'rating': rating,
    'completionRate': 91.0,
    'tags': [catName, level],
    'exercises': firstDayExercises,
    'days': days,
    'isFeatured': featured,
    'isActive': true,
  };
}

final List<Map<String, dynamic>> _workouts = [
  _workout('w_strength', '4-Week Strength Builder', 'Push, pull and legs split', 'wcat_strength', 'Strength', 'Intermediate', 'Coach Vikram', _unsplash('1534438327276-14e5300c3a48'), [
    _day(1, 'Push Day', 'Chest, shoulders & triceps', [_benchPress, _inclinePress, _lateralRaise, _dip]),
    _day(2, 'Pull Day', 'Back & biceps', [_pullUp, _row, _pulldown, _curl]),
    _day(3, 'Leg Day', 'Quads, glutes & hamstrings', [_squat, _deadlift, _lunge, _legPress], minutes: 55, kcal: 450),
    _day(4, 'Rest & Recover', 'Light walk and stretching', [], minutes: 20, kcal: 90, rest: true),
    _day(5, 'Upper Body', 'Full upper body', [_pushUp, _row, _lateralRaise, _curl, _dip]),
  ], minutes: 50, kcal: 420),
  _workout('w_hiit', 'Fat Burn HIIT', '20-minute intervals, no equipment', 'wcat_hiit', 'HIIT & Circuit', 'Beginner', 'Coach Aisha', _unsplash('1571019613454-1cb2f99b2d8b'), [
    _day(1, 'Full Body Blast', 'Cardio intervals', [_burpee, _jumpSquat, _climber, _highKnee], minutes: 20, kcal: 280),
    _day(2, 'Lower Body Burn', 'Legs & cardio', [_jumpSquat, _lunge, _highKnee, _goblet], minutes: 22, kcal: 300),
    _day(3, 'Core Cardio', 'Abs & conditioning', [_climber, _bicycle, _russianTwist, _burpee], minutes: 20, kcal: 260),
  ], minutes: 20, kcal: 280),
  _workout('w_core', 'Core Crusher', 'Stronger abs in 15 minutes', 'wcat_core', 'Core & Abs', 'Beginner', 'Coach Meera', _unsplash('1518611012118-696072aa579a'), [
    _day(1, 'Abs Basics', 'Upper & lower abs', [_bicycle, _russianTwist, _sidePlank], minutes: 15, kcal: 140),
    _day(2, 'Obliques', 'Side core', [_sidePlank, _russianTwist, _climber], minutes: 15, kcal: 150),
  ], minutes: 15, kcal: 140),
  _workout('w_yoga', 'Morning Mobility Flow', 'Gentle stretching to start the day', 'wcat_yoga', 'Yoga & Flow', 'Beginner', 'Coach Meera', _unsplash('1506126613408-eca07ce68773'), [
    _day(1, 'Wake Up Flow', 'Hips, spine & shoulders', [_sidePlank, _lunge, _goblet], minutes: 25, kcal: 120),
  ], minutes: 25, kcal: 120, rating: 4.9),
  _workout('w_cardio', 'Cardio Endurance', 'Build your stamina', 'wcat_cardio', 'Cardio Blast', 'Intermediate', 'Coach Arjun', _unsplash('1517838277536-f5f99be501cd'), [
    _day(1, 'Intervals', 'Heart-rate zones 3 to 4', [_highKnee, _burpee, _climber, _jumpSquat], minutes: 30, kcal: 360),
    _day(2, 'Kettlebell Conditioning', 'Power & cardio', [_swing, _goblet, _climber], minutes: 30, kcal: 380),
  ], minutes: 30, kcal: 360),
  _workout('w_home', 'Home Dumbbell Plan', 'Full body with one pair of dumbbells', 'wcat_strength', 'Strength', 'Beginner', 'Coach Vikram', _unsplash('1581009146145-b5ef050c2e1e'), [
    _day(1, 'Full Body A', 'Strength basics', [_goblet, _inclinePress, _lunge, _curl]),
    _day(2, 'Full Body B', 'Strength basics', [_swing, _pushUp, _lateralRaise, _dip]),
  ], minutes: 40, kcal: 330, featured: false),
];

final List<Map<String, dynamic>> _exerciseCategories = [
  for (final c in const [
    ['ec_chest', 'Chest', '0025-EIeI8Vf'],
    ['ec_back', 'Back', '0652-lBDjFxJ'],
    ['ec_legs', 'Legs', '0043-qXTaZnJ'],
    ['ec_shoulders', 'Shoulders', '0334-DsgkuIt'],
    ['ec_arms', 'Arms', '0294-NbVPDMW'],
    ['ec_core', 'Core', '0972-tZkGYZ9'],
  ])
    {
      'id': c[0],
      'name': c[1],
      'slug': c[1].toLowerCase(),
      'imageUrl': '$_gifBase/images/${c[2]}.jpg',
      'mediaType': 'image',
      'isActive': true,
    },
];

final List<Map<String, dynamic>> _recipes = [
  {'title': 'Masala Oats Bowl', 'calories': 380, 'protein': 14, 'carbs': 58, 'fat': 9, 'time': '15 min', 'imageUrl': _unsplash('1490645935967-10de6ba17061', w: 600)},
  {'title': 'Grilled Chicken Salad', 'calories': 450, 'protein': 42, 'carbs': 18, 'fat': 22, 'time': '20 min', 'imageUrl': _unsplash('1512621776951-a57141f2eefd', w: 600)},
  {'title': 'Paneer Power Bowl', 'calories': 520, 'protein': 32, 'carbs': 40, 'fat': 24, 'time': '25 min', 'imageUrl': _unsplash('1546069901-ba9599a7e63c', w: 600)},
  {'title': 'Berry Protein Smoothie', 'calories': 290, 'protein': 28, 'carbs': 34, 'fat': 5, 'time': '5 min', 'imageUrl': _unsplash('1553530666-ba11a7da3888', w: 600)},
];

Map<String, dynamic> _food(String name, String category, int kcal, double p, double c, double f,
        String serving) =>
    {
      'name': name,
      'title': name,
      'category': category,
      'source': 'USDA',
      'calories': kcal,
      'protein': p,
      'carbs': c,
      'fat': f,
      'fiber': 2.0,
      'servingSize': serving,
    };

final List<Map<String, dynamic>> _foods = [
  _food('Boiled Egg', 'Protein', 78, 6.3, 0.6, 5.3, '1 large egg'),
  _food('Chicken Breast (grilled)', 'Protein', 165, 31, 0, 3.6, '100 g'),
  _food('Paneer', 'Protein', 265, 18, 1.2, 21, '100 g'),
  _food('Greek Yogurt', 'Dairy', 97, 9, 3.6, 5, '100 g'),
  _food('Milk (toned)', 'Dairy', 58, 3.1, 4.7, 3, '100 ml'),
  _food('Brown Rice (cooked)', 'Grains', 123, 2.7, 25.6, 1, '100 g'),
  _food('Roti (whole wheat)', 'Grains', 120, 3.1, 18, 3.7, '1 roti'),
  _food('Oats', 'Grains', 389, 16.9, 66, 6.9, '100 g'),
  _food('Dal (cooked)', 'Protein', 116, 9, 20, 0.4, '1 bowl'),
  _food('Banana', 'Fruits', 89, 1.1, 22.8, 0.3, '1 medium'),
  _food('Apple', 'Fruits', 52, 0.3, 13.8, 0.2, '1 medium'),
  _food('Almonds', 'Snacks', 579, 21, 22, 50, '100 g'),
  _food('Peanut Butter', 'Snacks', 588, 25, 20, 50, '100 g'),
  _food('Mixed Salad', 'Vegetables', 35, 2, 6, 0.3, '1 bowl'),
  _food('Whey Protein Shake', 'Supplements', 120, 24, 3, 1.5, '1 scoop'),
];
