import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Catalogue, cart, wishlist, coupons, addresses and orders for the shop.
// Everything is kept on the phone (SharedPreferences) so the whole flow
// works without the backend: add to cart, check out, and track the order.

const shopImg = 'assets/images/';

class Product {
  final String name, brand, image, cat;
  final int price, old;
  final double rating;
  final int reviews;
  final bool cover; // photo fills the card instead of sitting on white
  const Product(this.name, this.brand, this.image, this.cat, this.price, this.old, this.rating, this.reviews, {this.cover = false});
  int get off => old <= price ? 0 : ((old - price) / old * 100).round();

  List<String> get options => switch (cat) {
        'Protein' => ['Chocolate', 'Vanilla', 'Strawberry'],
        'Apparel' => ['UK 7', 'UK 8', 'UK 9', 'UK 10'],
        'Equipment' => ['Standard', 'Pro'],
        _ => ['Black', 'Green', 'Orange'],
      };

  String get optionLabel => switch (cat) {
        'Protein' => 'Flavour',
        'Apparel' => 'Size',
        'Equipment' => 'Model',
        _ => 'Colour',
      };

  String get blurb => switch (cat) {
        'Protein' =>
          '24 g of fast-absorbing protein per scoop with 5.5 g BCAAs. Mixes smooth in water or milk, with no added sugar and third-party lab testing on every batch.',
        'Equipment' =>
          'Built from powder-coated steel for daily home training. Knurled grips, a stable base and a 2-year warranty.',
        'Apparel' => 'Light knit upper, a soft foam midsole and a grippy rubber outsole for runs, gym sessions and everyday wear.',
        'Wearables' => 'Tracks heart rate, sleep, steps and workouts, and syncs with NeuroFit. Up to 7 days of battery on one charge.',
        'Yoga' => 'A 6 mm non-slip mat with alignment lines. Sweat-resistant and easy to wipe clean, with a carry strap.',
        _ => 'Everyday training kit made to last, picked by the NeuroFit team.',
      };

  List<(String, String)> get specs => switch (cat) {
        'Protein' => [('Protein / scoop', '24 g'), ('Servings', '30'), ('Sugar', '1 g'), ('Type', 'Whey isolate blend')],
        'Equipment' => [('Material', 'Steel'), ('Warranty', '2 years'), ('Assembly', 'Not needed'), ('Use', 'Home and gym')],
        'Apparel' => [('Upper', 'Knit'), ('Sole', 'Rubber'), ('Weight', '240 g'), ('Fit', 'True to size')],
        'Wearables' => [('Battery', 'Up to 7 days'), ('Water', '5 ATM'), ('Sensors', 'HR, SpO2, GPS'), ('Display', '1.4" AMOLED')],
        _ => [('Material', 'Premium'), ('Warranty', '1 year'), ('Care', 'Wipe clean'), ('In the box', '1 item')],
      };
}

const shopProducts = [
  Product('Gold Standard Whey + Creatine', 'Optimum Nutrition', '${shopImg}product_1.png', 'Protein', 6499, 8299, 4.8, 12840),
  Product('Performance Whey 2 kg', 'Optimum Nutrition', '${shopImg}product_2.png', 'Protein', 4299, 5199, 4.6, 6420),
  Product('NutriFit Premium Whey', 'NutriFit', '${shopImg}nutrifit_whey_protein.jpg', 'Protein', 2899, 3999, 4.7, 2210),
  Product('Air Bike Pro', 'NeuroFit Gear', '${shopImg}product_3.png', 'Equipment', 24999, 32999, 4.5, 640),
  Product('Home Gym Station', 'NeuroFit Gear', '${shopImg}product_5.png', 'Equipment', 38999, 49999, 4.4, 312),
  Product('Hex Dumbbell 10 kg', 'NeuroFit Gear', '${shopImg}neon_green_dumbbell_1787819274202.jpg', 'Equipment', 1899, 2499, 4.7, 3110, cover: true),
  Product('Cloud Run Shoes', 'Stride', '${shopImg}neon_green_shoe_1787819288631.jpg', 'Apparel', 5499, 7999, 4.6, 1980, cover: true),
  Product('Pulse Smartwatch', 'NeuroFit', '${shopImg}neon_green_smartwatch_1787819302325.jpg', 'Wearables', 8999, 12999, 4.5, 2740, cover: true),
  Product('Steel Bottle 1 L', 'NeuroFit', '${shopImg}neon_green_waterbottle_1787819315145.jpg', 'Accessories', 699, 999, 4.8, 5320, cover: true),
  Product('Grip Yoga Mat', 'Zen Flow', '${shopImg}neon_green_yogamat_1787819327380.jpg', 'Yoga', 1299, 1899, 4.7, 2860, cover: true),
  Product('Duffle Gym Bag', 'NeuroFit', '${shopImg}neon_orange_gymbag_1787819375587.jpg', 'Accessories', 1799, 2599, 4.6, 1420, cover: true),
  Product('Heart Rate Strap', 'Pulse', '${shopImg}neon_orange_heartrate_1787819363247.jpg', 'Wearables', 3299, 4499, 4.4, 880, cover: true),
  Product('Cast Kettlebell 12 kg', 'NeuroFit Gear', '${shopImg}neon_orange_kettlebell_1787819340750.jpg', 'Equipment', 2199, 2999, 4.8, 1760, cover: true),
  Product('Leakproof Shaker', 'NeuroFit', '${shopImg}neon_orange_proteinshaker_1787819387813.jpg', 'Accessories', 399, 599, 4.6, 6210, cover: true),
  Product('Speed Rope', 'NeuroFit', '${shopImg}neon_orange_skippingrope_1787819351491.jpg', 'Accessories', 549, 799, 4.5, 2390, cover: true),
];

Product productNamed(String n) => shopProducts.firstWhere((p) => p.name == n, orElse: () => shopProducts.first);

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

const coupons = [
  Coupon('FIT10', '10% off everything', 'Up to ₹500 off on any order', Color(0xFFF97316), percent: 10, cap: 500),
  Coupon('NEURO200', 'Flat ₹200 off', 'On orders above ₹1,499', Color(0xFF8B5CF6), flat: 200, minOrder: 1499),
  Coupon('PROTEIN15', '15% off protein', 'Up to ₹750 off whey and supplements', Color(0xFF16A34A), percent: 15, cap: 750, onlyCat: 'Protein'),
  Coupon('FIRST300', '₹300 off your first order', 'On orders above ₹1,999', Color(0xFF3B82F6), flat: 300, minOrder: 1999),
  Coupon('FREESHIP', 'Free express delivery', 'Express delivery at no cost', Color(0xFF14B8A6), freeShip: true),
];

// ---------------------------------------------------------------- cart

class CartLine {
  final Product product;
  final String option;
  int qty;
  CartLine(this.product, this.option, this.qty);
  Map<String, dynamic> toJson() => {'p': product.name, 'o': option, 'q': qty};
  static CartLine fromJson(Map<String, dynamic> j) => CartLine(productNamed(j['p']), j['o'], j['q']);
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
  Order(this.id, this.at, this.lines, this.address, this.payment, this.speed, this.bill, this.coupon, {this.cancelled = false});

  int get items => lines.fold(0, (a, l) => a + l.qty);

  /// Orders move along on the clock so tracking works without a backend.
  int get step {
    if (cancelled) return -1;
    final m = DateTime.now().difference(at).inMinutes;
    final scale = speed == Speed.express ? 1 : 2;
    if (m >= 24 * 60 * scale) return 4;
    if (m >= 8 * 60 * scale) return 3;
    if (m >= 20 * scale) return 2;
    if (m >= 2) return 1;
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
    );
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
  static const _key = 'shop_store_v1';

  final List<CartLine> cart = [];
  final List<Address> addresses = [];
  final List<Order> orders = [];
  String? addressId;
  String? couponCode;
  Speed speed = Speed.standard;

  /// Cheap listenables for badges.
  final cartCount = ValueNotifier<int>(0);
  final saved = ValueNotifier<Set<String>>({});

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

  void selectAddress(String id) {
    addressId = id;
    _changed();
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
  }

  void deleteAddress(Address a) {
    addresses.removeWhere((x) => x.id == a.id);
    if (addressId == a.id) addressId = addresses.isEmpty ? null : addresses.first.id;
    _changed();
  }

  Order placeOrder(String payment) {
    final b = bill;
    final o = Order(
      'NF${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
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
    return o;
  }

  void cancel(Order o) {
    o.cancelled = true;
    _changed();
  }

  void reorder(Order o) {
    for (final l in o.lines) {
      add(l.product, option: l.option, qty: l.qty);
    }
  }

  // ------------------------------------------------------------ persist

  void _changed() {
    if (coupon != null && coupon!.whyNot(cart) != null) couponCode = null;
    cartCount.value = count;
    notifyListeners();
    _save();
  }

  Future<void> _load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_key);
      if (raw == null) {
        _seed();
        return;
      }
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
      addressId = j['addrId'];
      couponCode = j['coupon'];
      _changed();
    } catch (_) {
      _seed();
    }
  }

  /// First run: two items in the cart, one saved address and one past
  /// order, so every screen has something to show.
  void _seed() {
    cart
      ..clear()
      ..addAll([CartLine(shopProducts[0], 'Chocolate', 1), CartLine(shopProducts[8], 'Black', 1)]);
    const home = Address('a1', 'Home', 'Rohit', '98765 43210', 'B-42, Green Park', 'Near Metro Gate 2', 'New Delhi', 'Delhi', '110016');
    addresses
      ..clear()
      ..add(home);
    addressId = home.id;
    saved.value = {shopProducts[9].name, shopProducts[7].name};
    orders
      ..clear()
      ..add(Order(
        'NF20418873',
        DateTime.now().subtract(const Duration(days: 9)),
        [CartLine(shopProducts[13], 'Black', 2), CartLine(shopProducts[14], 'Orange', 1)],
        home,
        'UPI · Google Pay',
        Speed.standard,
        const Bill(1997, 1347, 650, 0, 0, 9),
        null,
      ));
    _changed();
  }

  Future<void> _save() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(
        _key,
        jsonEncode({
          'cart': cart.map((l) => l.toJson()).toList(),
          'addr': addresses.map((a) => a.toJson()).toList(),
          'orders': orders.map((o) => o.toJson()).toList(),
          'saved': saved.value.toList(),
          'addrId': addressId,
          'coupon': couponCode,
        }),
      );
    } catch (_) {}
  }
}
