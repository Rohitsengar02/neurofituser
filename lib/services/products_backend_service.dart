import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'category_backend_service.dart';
import '../constants/api_constants.dart';

// Aliases for backwards compatibility
typedef ProductModel = ProductItem;
typedef ProductVariantModel = ProductVariant;

class ProductVariant {
  String variantId;
  String name;
  double price;
  int stock;
  String sku;
  String imageUrl;
  Uint8List? localBytes;

  ProductVariant({
    this.variantId = '',
    required this.name,
    required this.price,
    required this.stock,
    required this.sku,
    this.imageUrl = '',
    this.localBytes,
  });

  Map<String, dynamic> toJson() => {
    'variantId': variantId,
    'name': name,
    'price': price,
    'stock': stock,
    'sku': sku,
    'imageUrl': imageUrl,
  };

  factory ProductVariant.fromJson(Map<String, dynamic> json) => ProductVariant(
    variantId: json['variantId'] ?? '',
    name: json['name'] ?? '',
    price: (json['price'] as num?)?.toDouble() ?? 0.0,
    stock: (json['stock'] as num?)?.toInt() ?? 0,
    sku: json['sku'] ?? '',
    imageUrl: json['imageUrl'] ?? '',
  );
}

class ProductItem {
  String get category => categoryName;
  set category(String val) => categoryName = val;
  double get salePrice => price;
  set salePrice(double val) => price = val;
  double get basePrice => regularPrice > 0 ? regularPrice : price;
  set basePrice(double val) => regularPrice = val;
  List<String> get images => [mainImageUrl, ...additionalImages].where((s) => s.isNotEmpty).toList();
  int get reviewsCount => reviewCount;
  set reviewsCount(int val) => reviewCount = val;
  String id;
  String title;
  String description;
  String sku;
  String barcode;
  String categoryId;
  String categoryName;
  String subcategoryId;
  String subcategoryName;
  String? discountId;
  String? discountCode;
  double price;
  double regularPrice;
  double costPerItem;
  int stock;
  int lowStockThreshold;
  String brand;
  String vendor;
  List<String> tags;
  String status;
  String mainImageUrl;
  List<String> additionalImages;
  List<ProductVariant> variants;
  bool isFeatured;
  double rating;
  int reviewCount;
  double weightGrams;
  String dimensions;
  DateTime? createdAt;
  DateTime? updatedAt;

  ProductItem({
    required this.id,
    required this.title,
    this.description = '',
    this.sku = 'NF-SKU-000',
    this.barcode = '',
    this.categoryId = '',
    this.categoryName = 'General',
    this.subcategoryId = '',
    this.subcategoryName = '',
    this.discountId,
    this.discountCode,
    required this.price,
    this.regularPrice = 0.0,
    this.costPerItem = 0.0,
    this.stock = 0,
    this.lowStockThreshold = 5,
    this.brand = 'NeuroFit',
    this.vendor = 'Official Store',
    List<String>? tags,
    this.status = 'active',
    this.mainImageUrl = '',
    List<String>? additionalImages,
    List<ProductVariant>? variants,
    this.isFeatured = false,
    this.rating = 5.0,
    this.reviewCount = 0,
    this.weightGrams = 0.0,
    this.dimensions = '',
    this.createdAt,
    this.updatedAt,
  })  : tags = tags ?? [],
        additionalImages = additionalImages ?? [],
        variants = variants ?? [];

  factory ProductItem.fromJson(Map<String, dynamic> json) {
    final rawImages = json['additionalImages'] as List<dynamic>? ?? json['images'] as List<dynamic>? ?? [];
    final rawVariants = json['variants'] as List<dynamic>? ?? [];
    final rawTags = json['tags'] as List<dynamic>? ?? [];

    return ProductItem(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? 'prod_${DateTime.now().millisecondsSinceEpoch}',
      title: json['title']?.toString() ?? json['name']?.toString() ?? 'Untitled Product',
      description: json['description']?.toString() ?? '',
      sku: json['sku']?.toString() ?? 'NF-SKU-000',
      barcode: json['barcode']?.toString() ?? '',
      categoryId: json['categoryId']?.toString() ?? '',
      categoryName: json['categoryName']?.toString() ?? json['category']?.toString() ?? 'General',
      subcategoryId: json['subcategoryId']?.toString() ?? json['subCategoryId']?.toString() ?? '',
      subcategoryName: json['subcategoryName']?.toString() ?? json['subCategoryName']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      regularPrice: (json['regularPrice'] as num?)?.toDouble() ?? 0.0,
      costPerItem: (json['costPerItem'] as num?)?.toDouble() ?? 0.0,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      lowStockThreshold: (json['lowStockThreshold'] as num?)?.toInt() ?? 5,
      brand: json['brand']?.toString() ?? 'NeuroFit',
      vendor: json['vendor']?.toString() ?? 'Official Store',
      tags: rawTags.map((t) => t.toString()).toList(),
      status: json['status']?.toString() ?? 'active',
      mainImageUrl: json['mainImageUrl']?.toString() ?? json['imageUrl']?.toString() ?? json['image']?.toString() ?? '',
      additionalImages: rawImages.map((i) => i.toString()).toList(),
      variants: rawVariants.map((v) => ProductVariant.fromJson(Map<String, dynamic>.from(v as Map))).toList(),
      isFeatured: json['isFeatured'] == true,
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
    );
  }

  // Aliases and Compatibility Getters / Setters
  String get productId => id;
  set productId(String val) => id = val;

  String get subCategoryId => subcategoryId;
  set subCategoryId(String val) => subcategoryId = val;

  String get subCategoryName => subcategoryName;
  set subCategoryName(String val) => subcategoryName = val;

  int get totalStock => stock;
  set totalStock(int val) => stock = val;

  int get lowStockAlert => lowStockThreshold;
  set lowStockAlert(dynamic val) {
    if (val is int) lowStockThreshold = val;
    if (val is bool) lowStockThreshold = val ? 5 : 0;
  }

  String get stockStatus {
    if (stock <= 0) return 'Out of Stock';
    if (stock <= lowStockThreshold) return 'Low Stock';
    return 'In Stock';
  }
  set stockStatus(String val) {}

  List<String> get galleryImages => additionalImages;
  set galleryImages(List<String> val) => additionalImages = val;

  double get profitMargin {
    if (price <= 0) return 0;
    return ((price - costPerItem) / price) * 100;
  }

  bool get isLowStock => stock <= lowStockThreshold && stock > 0;
  bool get isOutOfStock => stock <= 0;
}

class ProductsBackendService extends ChangeNotifier {
  Future<void> fetchProducts({bool silent = false}) => fetchProductsFromFirestore(silent: silent);
  static final ProductsBackendService _instance = ProductsBackendService._internal();
  factory ProductsBackendService() => _instance;
  static ProductsBackendService get instance => _instance;

  ProductsBackendService._internal() {
    fetchProductsFromFirestore();
    startRealtimeSync();
    _initSocket();
  }

  IO.Socket? _socket;
  void _initSocket() {
    try {
      final socketUri = ApiConstants.socketUrl;
      _socket = IO.io(
        socketUri,
        IO.OptionBuilder().setTransports(['websocket', 'polling']).disableAutoConnect().build(),
      );

      _socket?.connect();

      _socket?.on('product_created', (_) => fetchProductsFromFirestore(silent: true));
      _socket?.on('product_updated', (_) => fetchProductsFromFirestore(silent: true));
      _socket?.on('product_deleted', (_) => fetchProductsFromFirestore(silent: true));
      _socket?.on('products_updated', (_) => fetchProductsFromFirestore(silent: true));
      _socket?.on('media_uploaded', (_) => fetchProductsFromFirestore(silent: true));
    } catch (_) {}
  }

  Timer? _syncTimer;
  void startRealtimeSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      fetchProductsFromFirestore(silent: true);
    });
  }

  static const String projectId = "neurofit-63189";
  static const String apiKey = "AIzaSyDcGovQH3Sd_0kdNeSISK6eNCdtjA_g9vg";
  static const String firestoreBase = "https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents";

  List<ProductItem> _products = [];
  List<ProductItem> get products => List.unmodifiable(_products);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> fetchProductsFromFirestore({bool silent = false}) async {
    if (!silent) _isLoading = true;
    if (!silent) notifyListeners();

    final candidateUrls = ApiConstants.candidateBaseUrls.map((b) => Uri.parse('$b/api/products')).toList();

    for (final url in candidateUrls) {
      try {
        final res = await http.get(url).timeout(const Duration(seconds: 6));
        if (res.statusCode == 200) {
          final body = jsonDecode(res.body);
          final rawData = (body['data'] ?? body) as List<dynamic>? ?? [];
          if (rawData.isNotEmpty) {
            final List<ProductItem> fetched = rawData.map((item) {
              return ProductItem.fromJson(Map<String, dynamic>.from(item as Map));
            }).toList();

            _products = fetched;
            debugPrint('✅ [PRODUCTS LOADED FROM MONGODB ATLAS] ${_products.length} live products');
            _isLoading = false;
            notifyListeners();
            return;
          }
        }
      } catch (_) {}
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addProduct(ProductItem product, {Uint8List? rawImageBytes, String? imageFileName}) async {
    _isLoading = true;
    notifyListeners();

    try {
      String mainUrl = product.mainImageUrl;
      if (rawImageBytes != null && imageFileName != null) {
        final uploadedUrl = await CategoryBackendService().uploadRawImageToR2(
          imageBytes: rawImageBytes,
          fileName: imageFileName,
        );
        if (uploadedUrl != null) {
          mainUrl = uploadedUrl;
        }
      }

      final fields = {
        'title': {'stringValue': product.title},
        'description': {'stringValue': product.description},
        'sku': {'stringValue': product.sku},
        'barcode': {'stringValue': product.barcode},
        'categoryId': {'stringValue': product.categoryId},
        'categoryName': {'stringValue': product.categoryName},
        'subcategoryId': {'stringValue': product.subcategoryId},
        'subcategoryName': {'stringValue': product.subcategoryName},
        'discountId': {'stringValue': product.discountId ?? ''},
        'discountCode': {'stringValue': product.discountCode ?? ''},
        'price': {'doubleValue': product.price},
        'regularPrice': {'doubleValue': product.regularPrice},
        'costPerItem': {'doubleValue': product.costPerItem},
        'stock': {'integerValue': product.stock.toString()},
        'lowStockThreshold': {'integerValue': product.lowStockThreshold.toString()},
        'brand': {'stringValue': product.brand},
        'vendor': {'stringValue': product.vendor},
        'tags': {'arrayValue': {'values': product.tags.map((t) => {'stringValue': t}).toList()}},
        'status': {'stringValue': product.status},
        'mainImageUrl': {'stringValue': mainUrl},
        'additionalImages': {'arrayValue': {'values': product.additionalImages.map((img) => {'stringValue': img}).toList()}},
        'variants': {
          'arrayValue': {
            'values': product.variants.map((v) => {
                  'mapValue': {
                    'fields': {
                      'variantId': {'stringValue': v.variantId},
                      'name': {'stringValue': v.name},
                      'price': {'doubleValue': v.price},
                      'stock': {'integerValue': v.stock.toString()},
                      'sku': {'stringValue': v.sku},
                      'imageUrl': {'stringValue': v.imageUrl},
                    }
                  }
                }).toList()
          }
        },
        'isFeatured': {'booleanValue': product.isFeatured},
        'rating': {'doubleValue': product.rating},
        'reviewCount': {'integerValue': product.reviewCount.toString()},
        'weightGrams': {'doubleValue': product.weightGrams},
        'dimensions': {'stringValue': product.dimensions},
      };

      final Uri uri = Uri.parse('$firestoreBase/products/${product.id}?key=$apiKey');
      final res = await http.patch(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'fields': fields}),
      );

      if (res.statusCode == 200) {
        await fetchProductsFromFirestore();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error adding product: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Support createProduct with flexible parameters (named or single ProductItem)
  Future<bool> createProduct({
    ProductItem? product,
    String? title,
    String? brand,
    String? description,
    String? categoryId,
    String? categoryName,
    String? subCategoryId,
    String? subCategoryName,
    String? discountId,
    String? discountCode,
    double? price,
    double? regularPrice,
    int? totalStock,
    dynamic lowStockAlert,
    dynamic stockStatus,
    String? sku,
    String? mainImageFileName,
    Uint8List? mainImageBytes,
    List<dynamic>? galleryRawList,
    List<ProductVariant>? variants,
  }) async {
    if (product != null) {
      return addProduct(product);
    }

    final newId = 'prod_${DateTime.now().millisecondsSinceEpoch}';
    final p = ProductItem(
      id: newId,
      title: title ?? 'New Product',
      brand: brand ?? 'NeuroFit',
      description: description ?? '',
      categoryId: categoryId ?? '',
      categoryName: categoryName ?? 'General',
      subcategoryId: subCategoryId ?? '',
      subcategoryName: subCategoryName ?? '',
      discountId: discountId ?? '',
      discountCode: discountCode ?? '',
      price: price ?? 0.0,
      regularPrice: regularPrice ?? 0.0,
      stock: totalStock ?? 0,
      lowStockThreshold: (lowStockAlert is int) ? lowStockAlert : 5,
      sku: sku ?? 'NF-SKU-000',
      variants: variants ?? [],
    );

    return addProduct(p, rawImageBytes: mainImageBytes, imageFileName: mainImageFileName);
  }

  Future<bool> updateProduct(ProductItem product, {Uint8List? rawImageBytes, String? imageFileName}) {
    return addProduct(product, rawImageBytes: rawImageBytes, imageFileName: imageFileName);
  }

  Future<bool> deleteProduct(String productId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final Uri uri = Uri.parse('$firestoreBase/products/$productId?key=$apiKey');
      final res = await http.delete(uri);
      if (res.statusCode == 200) {
        _products.removeWhere((p) => p.id == productId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
