import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../backend/live_backend.dart';
import '../backend/sync_store.dart';
import '../services/category_backend_service.dart';
import '../services/user_backend_service.dart';

// Catalogue, cart, wishlist, coupons, addresses and orders for the shop.
// Products and coupons come from the admin panel (NeuroFit API); orders and
// addresses are saved to the user's account. Everything is also kept on the
// phone, so the shop opens instantly and works offline (orders placed
// offline are sent when the phone is back online).

const shopImg = 'assets/images/';

class Product {
  final String id, name, brand, image, cat;
  final int price, old;
  final double rating;
  final int reviews;
  final bool cover; // photo fills the card instead of sitting on white
  final String description;
  final List<String> variants;
  final List<(String, String)> extraSpecs;
  final int? stock;
  final List<String> gallery;
  final DateTime? createdAt;
  const Product(this.name, this.brand, this.image, this.cat, this.price, this.old, this.rating, this.reviews,
      {this.cover = false, this.id = '', this.description = '', this.variants = const [], this.extraSpecs = const [], this.stock, this.gallery = const [], this.createdAt});
  static const placeholder = Product('', '', '', '', 0, 0, 0, 0);

  int get off => old <= price ? 0 : ((old - price) / old * 100).round();

  /// From the API (admin product form).
  factory Product.fromJson(Map<String, dynamic> j) {
    String img(Object? v) => CategoryBackendService.getDisplayableImageUrl((v ?? '').toString());
    final images = [for (final x in (j['additionalImages'] ?? j['images'] ?? const []) as List) img(x)].where((x) => x.isNotEmpty).toList();
    final main = img(j['mainImageUrl'] ?? j['imageUrl'] ?? j['image'] ?? (images.isEmpty ? '' : images.first));
    final price = ((j['price'] as num?) ?? num.tryParse('${j['price']}') ?? 0).round();
    final old = ((j['regularPrice'] ?? j['mrp'] ?? j['originalPrice'] ?? j['comparePrice']) as num?)?.round() ?? price;
    final variants = [
      for (final v in (j['variants'] is List ? j['variants'] as List : const []))
        if (v is Map && (v['name'] ?? '').toString().isNotEmpty) v['name'].toString(),
    ];
    final specs = <(String, String)>[];
    final rawSpecs = j['specs'] ?? j['specifications'];
    if (rawSpecs is Map) {
      rawSpecs.forEach((k, v) => specs.add((k.toString(), v.toString())));
    } else if (rawSpecs is List) {
      for (final x in rawSpecs) {
        if (x is Map) specs.add(((x['label'] ?? x['key'] ?? x['name'] ?? '').toString(), (x['value'] ?? '').toString()));
      }
    }
    return Product(
      (j['title'] ?? j['name'] ?? 'Product').toString(),
      (j['brand'] ?? j['vendor'] ?? 'NeuroFit').toString(),
      main,
      (j['categoryName'] ?? j['category'] ?? 'Accessories').toString(),
      price,
      math.max(old, price),
      ((j['rating'] as num?) ?? 0).toDouble(),
      ((j['reviewCount'] ?? j['reviews']) as num?)?.toInt() ?? 0,
      cover: j['cover'] == true || !main.toLowerCase().contains('.png'),
      id: (j['id'] ?? j['_id'] ?? '').toString(),
      description: (j['description'] ?? '').toString(),
      variants: variants,
      extraSpecs: specs,
      stock: (j['stock'] as num?)?.toInt(),
      gallery: images,
      createdAt: DateTime.tryParse((j['createdAt'] ?? '').toString()),
    );
  }

  /// Small copy kept with cart lines and orders, so they show even before the catalogue loads.
  Map<String, dynamic> toJson() => {
        'id': id, 'title': name, 'brand': brand, 'mainImageUrl': image, 'categoryName': cat, 'price': price, 'regularPrice': old,
        'rating': rating, 'reviewCount': reviews, 'cover': cover, if (variants.isNotEmpty) 'variants': [for (final v in variants) {'name': v}],
      };

  List<String> get options => variants.isNotEmpty ? variants : const ['Standard'];

  String get optionLabel => variants.isEmpty
      ? 'Option'
      : switch (cat) {
          'Protein' => 'Flavour',
          'Apparel' => 'Size',
          'Equipment' => 'Model',
          _ => 'Variant',
        };

  String get blurb => description.isNotEmpty
      ? description
      : switch (cat) {
          'Protein' => 'Protein to support your training, picked by the NeuroFit team.',
          'Equipment' => 'Training equipment for home and gym, picked by the NeuroFit team.',
          'Apparel' => 'Training wear for runs, gym sessions and everyday use.',
          _ => 'Everyday training kit, picked by the NeuroFit team.',
        };

  List<(String, String)> get specs => extraSpecs.isNotEmpty
      ? extraSpecs
      : [
          ('Brand', brand),
          ('Category', cat),
          if (stock != null) ('Availability', stock! > 0 ? 'In stock' : 'Out of stock'),
          ('Rating', reviews > 0 ? '${rating.toStringAsFixed(1)} ($reviews)' : 'New'),
        ];

  @override
  bool operator ==(Object other) => other is Product && (id.isNotEmpty ? other.id == id : other.name == name);
  @override
  int get hashCode => id.isNotEmpty ? id.hashCode : name.hashCode;
}

/// Live catalogue (filled from the API, then kept up to date). Empty until the
/// admin adds products.
final List<Product> shopProducts = [];

/// Wrap-around pick so fixed layouts work with any number of products.
Product shopPick(int i) => shopProducts.isEmpty ? Product.placeholder : shopProducts[i % shopProducts.length];

/// Product picture: a web URL (uploaded to R2 from the admin panel) or a
/// bundled asset path. Network images are cached on the device.
Widget productImage(String src, {BoxFit fit = BoxFit.cover, Alignment alignment = Alignment.center, int? cacheWidth}) {
  if (src.startsWith('http')) {
    return Image.network(src, fit: fit, alignment: alignment, cacheWidth: cacheWidth, gaplessPlayback: true,
        errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFFF1F1F4)));
  }
  if (src.isEmpty) return const ColoredBox(color: Color(0xFFF1F1F4));
  return Image.asset(src, fit: fit, alignment: alignment, cacheWidth: cacheWidth,
      errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFFF1F1F4)));
}

final Map<String, Product> _known = {};
Product productNamed(String n, [Map<String, dynamic>? snapshot]) {
  for (final p in shopProducts) {
    if (p.name == n || p.id == n) return p;
  }
  if (_known[n] != null) return _known[n]!;
  if (snapshot != null) return _known[n] = Product.fromJson(snapshot);
  return Product(n, 'NeuroFit', '', 'Accessories', 0, 0, 0, 0);
}

String rs(int v) {
  final neg = v < 0;
  final s = v.abs().toString();
  String out;
  if (s.length <= 3) {
    out = s;
  } else {
    final last3 = s.substring(s.length - 3);
    var rest = s.substring(0, s.length - 3);
    final parts = <String>[];
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    out = '${parts.join(',')},$last3';
  }
  return '${neg ? '-' : ''}₹$out';
}

// ---------------------------------------------------------------- coupons

class Coupon {
  final String code, title, detail;
  final int minOrder, flat, percent, cap;
  final String? onlyCat;
  final bool freeShip;
  final Color color;
  const Coupon(this.code, this.title, this.detail, this.color,
      {this.minOrder = 0, this.flat = 0, this.percent = 0, this.cap = 0, this.onlyCat, this.freeShip = false});

  int discountOn(List<CartLine> lines) {
    final base = lines
        .where((l) => onlyCat == null || l.product.cat == onlyCat)
        .fold(0, (a, l) => a + l.product.price * l.qty);
    final sub = lines.fold(0, (a, l) => a + l.product.price * l.qty);
    if (sub < minOrder || base == 0) return 0;
    var d = flat + base * percent ~/ 100;
    if (cap > 0) d = math.min(d, cap);
    return d;
  }

  String? whyNot(List<CartLine> lines) {
    final sub = lines.fold(0, (a, l) => a + l.product.price * l.qty);
    if (sub < minOrder) return 'Add ${rs(minOrder - sub)} more to use this';
    if (onlyCat != null && !lines.any((l) => l.product.cat == onlyCat)) return 'Only for $onlyCat items';
    return null;
  }
}

/// Live coupons from the admin panel (Discounts).
final List<Coupon> coupons = [];

const _couponColors = [Color(0xFFF97316), Color(0xFF8B5CF6), Color(0xFF16A34A), Color(0xFF3B82F6), Color(0xFF14B8A6), Color(0xFFEF4444)];

Coupon couponFromJson(Map<String, dynamic> j, int i) {
  final type = (j['type'] ?? j['discountType'] ?? 'percentage').toString().toLowerCase();
  final value = ((j['value'] ?? j['amount']) as num?) ?? 0;
  final min = ((j['minOrderValue'] ?? j['minOrder']) as num?)?.round() ?? 0;
  final cap = ((j['maxDiscount'] ?? j['maxDiscountAmount']) as num?)?.round() ?? 0;
  final freeShip = type.contains('ship');
  final percent = type.startsWith('perc') ? value.round() : 0;
  final flat = !freeShip && percent == 0 ? value.round() : 0;
  final code = (j['code'] ?? '').toString().toUpperCase();
  final title = (j['title'] ?? '').toString().isNotEmpty
      ? j['title'].toString()
      : freeShip ? 'Free delivery' : percent > 0 ? '$percent% off' : 'Flat ${rs(flat)} off';
  final detail = (j['description'] ?? '').toString().isNotEmpty
      ? j['description'].toString()
      : [if (cap > 0) 'Up to ${rs(cap)} off', if (min > 0) 'On orders above ${rs(min)}'].join(' · ');
  final cat = (j['categoryName'] ?? j['category'] ?? '').toString();
  return Coupon(code, title, detail.isEmpty ? 'Use code $code at checkout' : detail, _couponColors[i % _couponColors.length],
      minOrder: min, flat: flat, percent: percent, cap: cap, onlyCat: cat.isEmpty ? null : cat, freeShip: freeShip);
}

// ---------------------------------------------------------------- cart

class CartLine {
  final Product product;
  final String option;
  int qty;
  CartLine(this.product, this.option, this.qty);
  Map<String, dynamic> toJson() => {'p': product.id.isNotEmpty ? product.id : product.name, 'o': option, 'q': qty, 's': product.toJson()};
  static CartLine fromJson(Map<String, dynamic> j) =>
      CartLine(productNamed(j['p'].toString(), j['s'] is Map ? Map<String, dynamic>.from(j['s'] as Map) : null), (j['o'] ?? 'Standard').toString(), (j['q'] as num?)?.toInt() ?? 1);
}

class Address {
  final String id, label, name, phone, line1, line2, city, state, pin;
  const Address(this.id, this.label, this.name, this.phone, this.line1, this.line2, this.city, this.state, this.pin);
  String get short => '$line1, $line2';
  String get full => '$line1, $line2, $city, $state $pin';
  Map<String, dynamic> toJson() =>
      {'id': id, 'l': label, 'n': name, 'ph': phone, 'a1': line1, 'a2': line2, 'c': city, 's': state, 'pin': pin};
  static Address fromJson(Map<String, dynamic> j) =>
      Address(j['id'], j['l'], j['n'], j['ph'], j['a1'], j['a2'], j['c'], j['s'], j['pin']);

  /// Shape saved on the user's account (shared with the profile's address screen).
  Map<String, dynamic> toServer({bool isDefault = false}) => {
        'id': id, 'label': label, 'type': label, 'name': name, 'fullName': name, 'phone': phone, 'phoneNumber': phone,
        'line1': line1, 'line2': line2, 'flat': line1, 'area': line2, 'streetAddress': '$line1, $line2',
        'city': city, 'state': state, 'pincode': pin, 'isDefault': isDefault,
      };

  static Address fromServer(Map<String, dynamic> a) {
    String v(List<String> keys) {
      for (final k in keys) {
        final x = (a[k] ?? '').toString();
        if (x.isNotEmpty) return x;
      }
      return '';
    }

    final street = v(['streetAddress']);
    return Address(
      v(['id', '_id']).isEmpty ? 'addr_${a.hashCode}' : v(['id', '_id']),
      v(['label', 'type', 'tag']).isEmpty ? 'Home' : v(['label', 'type', 'tag']),
      v(['name', 'fullName']),
      v(['phone', 'phoneNumber']),
      v(['line1', 'flat', 'houseNo']).isNotEmpty ? v(['line1', 'flat', 'houseNo']) : street,
      v(['line2', 'area', 'building', 'landmark']),
      v(['city']),
      v(['state']),
      v(['pincode', 'pin', 'zip']),
    );
  }
}

enum Speed { standard, express }

class Bill {
  final int mrp, subtotal, savings, coupon, delivery, handling;
  const Bill(this.mrp, this.subtotal, this.savings, this.coupon, this.delivery, this.handling);
  int get total => math.max(0, subtotal - coupon + delivery + handling);
  int get saved => savings + coupon;
}

const orderSteps = ['Order placed', 'Packed', 'Shipped', 'Out for delivery', 'Delivered'];

class Order {
  final String id;
  final DateTime at;
  final List<CartLine> lines;
  final Address address;
  final String payment;
  final Speed speed;
  final Bill bill;
  final String? coupon;
  bool cancelled;
  String status;
  Order(this.id, this.at, this.lines, this.address, this.payment, this.speed, this.bill, this.coupon, {this.cancelled = false, this.status = 'Placed'});

  int get items => lines.fold(0, (a, l) => a + l.qty);

  /// Tracking step from the status the admin sets on the order.
  int get step {
    final s = status.toLowerCase();
    if (cancelled || s.contains('cancel') || s.contains('return')) return -1;
    if (s.contains('deliver') && !s.contains('out for')) return 4;
    if (s.contains('out for')) return 3;
    if (s.contains('ship')) return 2;
    if (s.contains('pack') || s.contains('process') || s.contains('confirm')) return 1;
    return 0;
  }

  bool get active => !cancelled && step < 4;
  bool get canCancel => !cancelled && step < 2;
  DateTime get eta => at.add(Duration(days: speed == Speed.express ? 1 : 3));
  DateTime stepTime(int i) {
    final scale = speed == Speed.express ? 1 : 2;
    return at.add(Duration(minutes: [0, 2, 20 * scale, 8 * 60 * scale, 24 * 60 * scale][i]));
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'at': at.millisecondsSinceEpoch,
        'lines': lines.map((l) => l.toJson()).toList(),
        'addr': address.toJson(),
        'pay': payment,
        'speed': speed.index,
        'bill': [bill.mrp, bill.subtotal, bill.savings, bill.coupon, bill.delivery, bill.handling],
        'coupon': coupon,
        'x': cancelled,
        'st': status,
      };

  static Order fromJson(Map<String, dynamic> j) {
    final b = List<int>.from(j['bill']);
    return Order(
      j['id'],
      DateTime.fromMillisecondsSinceEpoch(j['at']),
      [for (final l in j['lines']) CartLine.fromJson(Map<String, dynamic>.from(l))],
      Address.fromJson(Map<String, dynamic>.from(j['addr'])),
      j['pay'],
      Speed.values[j['speed']],
      Bill(b[0], b[1], b[2], b[3], b[4], b[5]),
      j['coupon'],
      cancelled: j['x'] ?? false,
      status: (j['st'] ?? 'Placed').toString(),
    );
  }

  /// Body for POST /api/orders (the admin panel reads the same fields).
  Map<String, dynamic> toServer() => {
        'orderId': id,
        'customerName': address.name,
        'userName': address.name,
        'shippingAddress': address.toServer(),
        'items': [
          for (final l in lines)
            {
              'productId': l.product.id, 'title': l.product.name, 'name': l.product.name, 'variant': l.option, 'price': l.product.price,
              'quantity': l.qty, 'imageUrl': l.product.image, 'image': l.product.image, 'brand': l.product.brand, 'categoryName': l.product.cat,
            },
        ],
        'subtotal': bill.subtotal,
        'discount': bill.coupon,
        'shippingFee': bill.delivery,
        'handlingFee': bill.handling,
        'totalAmount': bill.total,
        'paymentMethod': payment,
        'paymentStatus': payment.toLowerCase().contains('cash') || payment.toLowerCase() == 'cod' ? 'Pending' : 'Paid',
        'orderStatus': 'Placed',
        'deliverySpeed': speed.name,
        if (coupon != null) 'couponCode': coupon,
        'app': toJson(),
      };

  static Order? fromServer(Map<String, dynamic> j) {
    try {
      if (j['app'] is Map) {
        final o = fromJson(Map<String, dynamic>.from(j['app'] as Map));
        o.status = (j['orderStatus'] ?? o.status).toString();
        o.cancelled = o.status.toLowerCase().contains('cancel');
        return o;
      }
      // Orders created elsewhere (older app versions, admin): rebuild from the plain fields.
      final items = j['items'] is List ? j['items'] as List : const [];
      final lines = [
        for (final it in items)
          if (it is Map)
            CartLine(
              productNamed((it['productId'] ?? it['title'] ?? it['name'] ?? '').toString(), {
                'id': it['productId'], 'title': it['title'] ?? it['name'], 'mainImageUrl': it['imageUrl'] ?? it['image'], 'price': it['price'], 'brand': it['brand'],
              }),
              (it['variant'] ?? 'Standard').toString(),
              ((it['quantity'] as num?) ?? 1).toInt(),
            ),
      ];
      final total = ((j['totalAmount'] as num?) ?? 0).round();
      final sub = ((j['subtotal'] as num?) ?? total).round();
      final status = (j['orderStatus'] ?? 'Placed').toString();
      return Order(
        (j['orderId'] ?? j['id']).toString(),
        DateTime.tryParse((j['createdAt'] ?? '').toString())?.toLocal() ?? DateTime.now(),
        lines,
        Address.fromServer(j['shippingAddress'] is Map ? Map<String, dynamic>.from(j['shippingAddress'] as Map) : const {}),
        (j['paymentMethod'] ?? 'UPI').toString(),
        j['deliverySpeed'] == 'express' ? Speed.express : Speed.standard,
        Bill(sub, sub, 0, ((j['discount'] as num?) ?? 0).round(), ((j['shippingFee'] as num?) ?? 0).round(), ((j['handlingFee'] as num?) ?? 0).round()),
        j['couponCode']?.toString(),
        cancelled: status.toLowerCase().contains('cancel'),
        status: status,
      );
    } catch (_) {
      return null;
    }
  }
}

String shortDate(DateTime d) {
  const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  const w = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return '${w[d.weekday - 1]}, ${d.day} ${m[d.month - 1]}';
}

String clock(DateTime t) {
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  return '$h:${t.minute.toString().padLeft(2, '0')} ${t.hour < 12 ? 'AM' : 'PM'}';
}

// ---------------------------------------------------------------- store

class ShopStore extends ChangeNotifier {
  ShopStore._() {
    _load();
  }
  static final ShopStore I = ShopStore._();
  static const _key = 'shop_store_v2';

  final List<CartLine> cart = [];
  final List<Address> addresses = [];
  final List<Order> orders = [];
  String? addressId;
  String? couponCode;
  Speed speed = Speed.standard;

  /// True once the catalogue has been read (from the API or the offline copy).
  bool catalogReady = false;

  /// Bumped when products or coupons change (shop sections listen to this, not the cart).
  final catalog = ValueNotifier<int>(0);

  /// Cheap listenables for badges.
  final cartCount = ValueNotifier<int>(0);
  final saved = ValueNotifier<Set<String>>({});

  /// Product names the user opened, newest first (for "Recently viewed").
  final List<String> viewed = [];

  int get count => cart.fold(0, (a, l) => a + l.qty);
  Coupon? get coupon => couponCode == null ? null : coupons.where((c) => c.code == couponCode).firstOrNull;
  Address? get address =>
      addresses.where((a) => a.id == addressId).firstOrNull ?? (addresses.isEmpty ? null : addresses.first);

  static const freeOver = 999;

  Bill get bill {
    final mrp = cart.fold(0, (a, l) => a + l.product.old * l.qty);
    final sub = cart.fold(0, (a, l) => a + l.product.price * l.qty);
    final c = coupon;
    final cd = c == null ? 0 : c.discountOn(cart);
    var delivery = sub == 0 ? 0 : (sub >= freeOver ? 0 : 49);
    if (speed == Speed.express) delivery += 99;
    if (c?.freeShip == true) delivery = 0;
    return Bill(mrp, sub, mrp - sub, cd, delivery, sub == 0 ? 0 : 9);
  }

  // ------------------------------------------------------------ catalogue picks

  List<Product> get bestSellers => [...shopProducts]..sort((a, b) => b.reviews.compareTo(a.reviews));
  List<Product> get newArrivals => [...shopProducts]..sort((a, b) => (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000)));
  List<Product> get deals => [...shopProducts.where((p) => p.off > 0)]..sort((a, b) => b.off.compareTo(a.off));
  List<Product> inCat(String c) => shopProducts.where((p) => p.cat.toLowerCase().contains(c.toLowerCase())).toList();
  List<Product> get recentlyViewed => [for (final n in viewed) ...shopProducts.where((p) => p.name == n)];

  void markViewed(Product p) {
    viewed
      ..remove(p.name)
      ..insert(0, p.name);
    if (viewed.length > 12) viewed.removeLast();
    _save();
    if (p.id.isNotEmpty) {
      Api.send('POST', '/track', {'event': 'product_view', 'id': p.id}).catchError((_) => <String, dynamic>{});
    }
  }

  /// Best coupon price for a single product, for the "get it for" hint.
  (Coupon, int)? bestDealFor(Product p) {
    (Coupon, int)? best;
    for (final c in coupons) {
      final d = c.discountOn([CartLine(p, '', 1)]);
      if (d > 0 && (best == null || d > best.$2)) best = (c, d);
    }
    return best;
  }

  void add(Product p, {String? option, int qty = 1}) {
    final o = option ?? p.options.first;
    final ex = cart.where((l) => l.product.name == p.name && l.option == o).firstOrNull;
    if (ex != null) {
      ex.qty += qty;
    } else {
      cart.insert(0, CartLine(p, o, qty));
    }
    _changed();
  }

  void setQty(CartLine l, int q) {
    if (q <= 0) {
      cart.remove(l);
    } else {
      l.qty = q;
    }
    _changed();
  }

  CartLine? _removed;
  int _removedAt = 0;
  void remove(CartLine l) {
    _removed = l;
    _removedAt = cart.indexOf(l);
    cart.remove(l);
    _changed();
  }

  void undoRemove() {
    if (_removed == null) return;
    cart.insert(_removedAt.clamp(0, cart.length), _removed!);
    _removed = null;
    _changed();
  }

  void saveForLater(CartLine l) {
    cart.remove(l);
    saved.value = {...saved.value, l.product.name};
    _changed();
  }

  bool isSaved(Product p) => saved.value.contains(p.name);

  void toggleSave(Product p) {
    final s = saved.value;
    saved.value = s.contains(p.name) ? ({...s}..remove(p.name)) : {...s, p.name};
    _changed();
  }

  void moveToCart(Product p) {
    saved.value = {...saved.value}..remove(p.name);
    add(p);
  }

  String? applyCoupon(String code) {
    final c = coupons.where((x) => x.code == code.trim().toUpperCase()).firstOrNull;
    if (c == null) return 'That code is not valid';
    final why = c.whyNot(cart);
    if (why != null) return why;
    couponCode = c.code;
    _changed();
    return null;
  }

  void removeCoupon() {
    couponCode = null;
    _changed();
  }

  void setSpeed(Speed s) {
    speed = s;
    _changed();
  }

  String? get _uid => UserBackendService.instance.currentUser?.uid;

  void selectAddress(String id) {
    addressId = id;
    _changed();
    final uid = _uid;
    if (uid != null) unawaited(UserBackendService.instance.setDefaultAddress(uid, id));
  }

  void saveAddress(Address a) {
    final i = addresses.indexWhere((x) => x.id == a.id);
    if (i >= 0) {
      addresses[i] = a;
    } else {
      addresses.insert(0, a);
    }
    addressId = a.id;
    _changed();
    final uid = _uid;
    if (uid != null) unawaited(UserBackendService.instance.saveUserAddress(uid, a.toServer(isDefault: true)));
  }

  void deleteAddress(Address a) {
    addresses.removeWhere((x) => x.id == a.id);
    if (addressId == a.id) addressId = addresses.isEmpty ? null : addresses.first.id;
    _changed();
    final uid = _uid;
    if (uid != null) unawaited(UserBackendService.instance.deleteUserAddress(uid, a.id));
  }

  /// Places the order: shown at once, sent to the server (queued if offline).
  Order placeOrder(String payment) {
    final b = bill;
    final o = Order(
      'NF${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}${math.Random().nextInt(90) + 10}',
      DateTime.now(),
      [for (final l in cart) CartLine(l.product, l.option, l.qty)],
      address!,
      payment,
      speed,
      b,
      couponCode,
    );
    orders.insert(0, o);
    cart.clear();
    couponCode = null;
    speed = Speed.standard;
    _changed();
    Api.send('POST', '/orders', o.toServer()).catchError((_) => <String, dynamic>{});
    return o;
  }

  void cancel(Order o) {
    o.cancelled = true;
    o.status = 'Cancelled';
    _changed();
    Api.send('PUT', '/orders/${o.id}/status', {'orderStatus': 'Cancelled', 'cancellationReason': 'Cancelled in app'}).catchError((_) => <String, dynamic>{});
  }

  void reorder(Order o) {
    for (final l in o.lines) {
      add(l.product, option: l.option, qty: l.qty);
    }
  }

  // ------------------------------------------------------------ server

  bool _listening = false;

  /// Reads products, coupons, addresses and orders. Fast: the API caches,
  /// and offline the last copy on the phone is used.
  Future<void> refresh() async {
    if (!_listening) {
      _listening = true;
      for (final ev in const ['products_updated', 'product_updated', 'discounts_updated', 'discount_updated']) {
        SyncStore.I.on(ev, () => unawaited(refresh()));
      }
      for (final ev in const ['order:user_updated', 'order:user_created']) {
        SyncStore.I.on(ev, () => unawaited(_refreshOrders()));
      }
      UserBackendService.instance.addListener(_syncAddresses);
    }
    await Future.wait([_refreshCatalog(), _refreshCoupons(), _refreshOrders()]);
    _syncAddresses();
  }

  Future<void> _refreshCatalog() async {
    try {
      final j = await Api.get('/products?activeOnly=true&limit=500');
      final list = [for (final x in Api.list(j)) Product.fromJson(x)];
      shopProducts
        ..clear()
        ..addAll(list);
      catalogReady = true;
      // Cart lines point at the fresh product (new price, image).
      for (var i = 0; i < cart.length; i++) {
        final fresh = shopProducts.where((p) => p == cart[i].product).firstOrNull;
        if (fresh != null) cart[i] = CartLine(fresh, cart[i].option, cart[i].qty);
      }
      catalog.value++;
      _changed(save: false);
    } catch (_) {}
  }

  Future<void> _refreshCoupons() async {
    try {
      final j = await Api.get('/discounts?activeOnly=true');
      final list = Api.list(j);
      coupons
        ..clear()
        ..addAll([for (var i = 0; i < list.length; i++) if ((list[i]['code'] ?? '').toString().isNotEmpty) couponFromJson(list[i], i)]);
      catalog.value++;
      _changed(save: false);
    } catch (_) {}
  }

  Future<void> _refreshOrders() async {
    if (_uid == null) return;
    try {
      final j = await Api.get('/orders/mine');
      final server = [for (final x in Api.list(j)) Order.fromServer(x)].whereType<Order>().toList();
      final ids = server.map((o) => o.id).toSet();
      // Keep orders placed offline that the server hasn't seen yet.
      final pending = orders.where((o) => !ids.contains(o.id) && DateTime.now().difference(o.at).inDays < 2);
      orders
        ..clear()
        ..addAll([...pending, ...server]);
      _changed();
    } catch (_) {}
  }

  void _syncAddresses() {
    final u = UserBackendService.instance.currentUser;
    if (u == null) return;
    final list = [for (final a in u.addresses) Address.fromServer(a)];
    if (list.isEmpty && addresses.isEmpty) return;
    addresses
      ..clear()
      ..addAll(list);
    final def = u.addresses.where((a) => a['isDefault'] == true).firstOrNull;
    if (def != null) addressId = (def['id'] ?? addressId)?.toString();
    if (addressId != null && !addresses.any((a) => a.id == addressId)) addressId = addresses.isEmpty ? null : addresses.first.id;
    _changed();
  }

  // ------------------------------------------------------------ persist

  void _changed({bool save = true}) {
    if (coupon != null && coupon!.whyNot(cart) != null) couponCode = null;
    cartCount.value = count;
    notifyListeners();
    if (save) _save();
  }

  Future<void> _load() async {
    try {
      final p = await SharedPreferences.getInstance();
      p.remove('shop_store_v1'); // old demo data
      final raw = p.getString(_key);
      if (raw != null) {
        final j = jsonDecode(raw) as Map<String, dynamic>;
        cart
          ..clear()
          ..addAll([for (final l in j['cart'] ?? []) CartLine.fromJson(Map<String, dynamic>.from(l))]);
        addresses
          ..clear()
          ..addAll([for (final a in j['addr'] ?? []) Address.fromJson(Map<String, dynamic>.from(a))]);
        orders
          ..clear()
          ..addAll([for (final o in j['orders'] ?? []) Order.fromJson(Map<String, dynamic>.from(o))]);
        saved.value = Set<String>.from(j['saved'] ?? []);
        viewed
          ..clear()
          ..addAll(List<String>.from(j['viewed'] ?? const []));
        addressId = j['addrId'];
        couponCode = j['coupon'];
        _changed(save: false);
      }
    } catch (_) {}
    unawaited(refresh());
  }

  Timer? _saveTimer;
  void _save() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 400), () async {
      final body = {
        'cart': cart.map((l) => l.toJson()).toList(),
        'addr': addresses.map((a) => a.toJson()).toList(),
        'orders': orders.take(50).map((o) => o.toJson()).toList(),
        'saved': saved.value.toList(),
        'viewed': viewed,
        'addrId': addressId,
        'coupon': couponCode,
      };
      try {
        final p = await SharedPreferences.getInstance();
        await p.setString(_key, jsonEncode(body));
      } catch (_) {}
      // Cart and wishlist follow the user to other devices.
      unawaited(SyncStore.I.put('shop', 'bag', {'cart': body['cart'], 'saved': body['saved']}));
    });
  }
}
