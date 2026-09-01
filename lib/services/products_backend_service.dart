import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'category_backend_service.dart';

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
  }

  Timer? _syncTimer;
  void startRealtimeSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      fetchProductsFromFirestore(silent: true);
    });
  }

  static const String projectId = "neurofit-52fe0";
  static const String apiKey = "AIzaSyDcGovQH3Sd_0kdNeSISK6eNCdtjA_g9vg";
  static const String firestoreBase = "https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents";

  List<ProductItem> _products = [];
  List<ProductItem> get products => List.unmodifiable(_products);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> fetchProductsFromFirestore({bool silent = false}) async {
    if (!silent) _isLoading = true;
    if (!silent) notifyListeners();
    _isLoading = true;
    notifyListeners();

    try {
      final Uri uri = Uri.parse('$firestoreBase/products?key=$apiKey&pageSize=100');
      final res = await http.get(uri).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final documents = data['documents'] as List<dynamic>? ?? [];

        final List<ProductItem> fetched = [];
        for (var doc in documents) {
          final fields = doc['fields'] as Map<String, dynamic>? ?? {};
          final name = doc['name'] as String? ?? '';
          final id = name.split('/').last;

          final variantsList = (fields['variants']?['arrayValue']?['values'] as List<dynamic>?)
                  ?.map((v) {
                    final vf = v['mapValue']?['fields'] as Map<String, dynamic>? ?? {};
                    return ProductVariant(
                      variantId: vf['variantId']?['stringValue'] ?? '',
                      name: vf['name']?['stringValue'] ?? '',
                      price: (vf['price']?['doubleValue'] as num?)?.toDouble() ?? 0.0,
                      stock: int.tryParse(vf['stock']?['integerValue']?.toString() ?? '0') ?? 0,
                      sku: vf['sku']?['stringValue'] ?? '',
                      imageUrl: vf['imageUrl']?['stringValue'] ?? '',
                    );
                  }).toList() ??
              [];

          final tagsList = (fields['tags']?['arrayValue']?['values'] as List<dynamic>?)
                  ?.map((t) => t['stringValue']?.toString() ?? '')
                  .where((t) => t.isNotEmpty)
                  .toList() ??
              [];

          final addImagesList = (fields['additionalImages']?['arrayValue']?['values'] as List<dynamic>?)
                  ?.map((img) => img['stringValue']?.toString() ?? '')
                  .where((img) => img.isNotEmpty)
                  .toList() ??
              [];

          fetched.add(ProductItem(
            id: id,
            title: fields['title']?['stringValue'] ?? 'Untitled Product',
            description: fields['description']?['stringValue'] ?? '',
            sku: fields['sku']?['stringValue'] ?? 'NF-SKU-000',
            barcode: fields['barcode']?['stringValue'] ?? '',
            categoryId: fields['categoryId']?['stringValue'] ?? '',
            categoryName: fields['categoryName']?['stringValue'] ?? 'General',
            subcategoryId: fields['subcategoryId']?['stringValue'] ?? '',
            subcategoryName: fields['subcategoryName']?['stringValue'] ?? '',
            discountId: fields['discountId']?['stringValue'] ?? '',
            discountCode: fields['discountCode']?['stringValue'] ?? '',
            price: double.tryParse(fields['price']?['doubleValue']?.toString() ?? fields['price']?['integerValue']?.toString() ?? '0') ?? 0.0,
            regularPrice: double.tryParse(fields['regularPrice']?['doubleValue']?.toString() ?? fields['regularPrice']?['integerValue']?.toString() ?? '0') ?? 0.0,
            costPerItem: double.tryParse(fields['costPerItem']?['doubleValue']?.toString() ?? fields['costPerItem']?['integerValue']?.toString() ?? '0') ?? 0.0,
            stock: int.tryParse(fields['stock']?['integerValue']?.toString() ?? '0') ?? 0,
            lowStockThreshold: int.tryParse(fields['lowStockThreshold']?['integerValue']?.toString() ?? '5') ?? 5,
            brand: fields['brand']?['stringValue'] ?? 'NeuroFit',
            vendor: fields['vendor']?['stringValue'] ?? 'Official Store',
            tags: tagsList,
            status: fields['status']?['stringValue'] ?? 'active',
            mainImageUrl: fields['mainImageUrl']?['stringValue'] ?? '',
            additionalImages: addImagesList,
            variants: variantsList,
            isFeatured: fields['isFeatured']?['booleanValue'] ?? false,
            rating: (fields['rating']?['doubleValue'] as num?)?.toDouble() ?? 5.0,
            reviewCount: int.tryParse(fields['reviewCount']?['integerValue']?.toString() ?? '0') ?? 0,
            weightGrams: (fields['weightGrams']?['doubleValue'] as num?)?.toDouble() ?? 0.0,
            dimensions: fields['dimensions']?['stringValue'] ?? '',
          ));
        }

        _products = fetched;
        debugPrint('✅ [PRODUCTS LOADED FROM FIRESTORE] ${_products.length} live database products');
      }
    } catch (e) {
      debugPrint('❌ Error loading products: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
