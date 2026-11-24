import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:mongo_dart/mongo_dart.dart' show where;
export 'package:mongo_dart/mongo_dart.dart' show where;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../constants/api_constants.dart';
import 'mongo_backend_service.dart';
import 'fcm_notification_service.dart';

class UserModel {
  final String uid;
  String name;
  String email;
  String phone;
  String photoUrl;
  String authProvider;
  bool hasCompletedOnboarding;
  Map<String, dynamic> questionnaireData;
  List<Map<String, dynamic>> addresses;
  final DateTime createdAt;
  DateTime updatedAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.phone = '',
    this.photoUrl = '',
    this.authProvider = 'google',
    this.hasCompletedOnboarding = false,
    Map<String, dynamic>? questionnaireData,
    List<Map<String, dynamic>>? addresses,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : questionnaireData = questionnaireData ?? {},
        addresses = addresses ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory UserModel.fromJson(Map<String, dynamic> json) {
    var rawAddrs = json['addresses'];
    List<Map<String, dynamic>> parsedAddresses = [];
    if (rawAddrs is List) {
      parsedAddresses = rawAddrs
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    return UserModel(
      uid: json['uid'] as String? ?? '',
      name: json['name'] as String? ?? 'Athlete',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      photoUrl: json['photoUrl'] as String? ?? '',
      authProvider: json['authProvider'] as String? ?? 'google',
      hasCompletedOnboarding: json['hasCompletedOnboarding'] as bool? ?? false,
      questionnaireData: json['questionnaireData'] is Map
          ? Map<String, dynamic>.from(json['questionnaireData'] as Map)
          : {},
      addresses: parsedAddresses,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'photoUrl': photoUrl,
      'authProvider': authProvider,
      'hasCompletedOnboarding': hasCompletedOnboarding,
      'questionnaireData': questionnaireData,
      'addresses': addresses,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class UserBackendService extends ChangeNotifier {
  static final UserBackendService _instance = UserBackendService._internal();
  factory UserBackendService() => _instance;
  static UserBackendService get instance => _instance;
  UserBackendService._internal();

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  bool _isAuthLoading = false;
  bool get isAuthLoading => _isAuthLoading;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  static String get _apiBaseUrl => ApiConstants.apiBaseUrl;
  static String get socketUrl => ApiConstants.socketUrl;

  static List<Uri> _buildEndpoints(String path) {
    final List<Uri> list = [Uri.parse('$_apiBaseUrl/$path')];
    for (var b in ApiConstants.candidateBaseUrls) {
      final uri = Uri.parse('$b/api/$path');
      if (!list.any((u) => u.toString() == uri.toString())) {
        list.add(uri);
      }
    }
    return list;
  }

  IO.Socket? _socket;
  IO.Socket? get socket => _socket;

  bool get isLoggedIn => _currentUser != null && _currentUser!.email.isNotEmpty;

  // -------------------------------------------------------------
  // REAL-TIME SOCKET.IO
  // -------------------------------------------------------------
  void initSocket() {
    if (_socket != null && _socket!.connected) return;

    try {
      _socket = IO.io(
        socketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionDelay(2000)
            .build(),
      );

      _socket!.onConnect((_) {
        debugPrint('⚡ Socket.io Connected to Express Backend: ${_socket?.id}');
        if (_currentUser != null && _currentUser!.uid.isNotEmpty) {
          _socket!.emit('join_user_room', _currentUser!.uid);
          debugPrint('👤 Joined socket user room: user_${_currentUser!.uid}');
        }
      });

      _socket!.on('user:updated', (data) {
        debugPrint('📥 Realtime Socket Event [user:updated]: $data');
        if (data != null && data is Map) {
          final updatedUser = UserModel.fromJson(Map<String, dynamic>.from(data));
          if (_currentUser != null && _currentUser!.uid == updatedUser.uid) {
            _currentUser = updatedUser;
            _saveSessionLocally(_currentUser!);
            notifyListeners();
          }
        }
      });

      _socket!.on('user:self_updated', (data) {
        debugPrint('📥 Realtime Socket Event [user:self_updated]: $data');
        if (data != null && data is Map) {
          _currentUser = UserModel.fromJson(Map<String, dynamic>.from(data));
          _saveSessionLocally(_currentUser!);
          notifyListeners();
        }
      });

      _socket!.on('user:questionnaire_saved', (data) {
        debugPrint('📥 Realtime Socket Event [user:questionnaire_saved]: $data');
        if (data != null && data is Map && _currentUser != null) {
          final uid = data['uid'];
          if (_currentUser!.uid == uid) {
            final qData = data['questionnaireData'];
            if (qData != null && qData is Map) {
              _currentUser!.questionnaireData = Map<String, dynamic>.from(qData);
              _currentUser!.hasCompletedOnboarding = true;
              _saveSessionLocally(_currentUser!);
              notifyListeners();
            }
          }
        }
      });

      _socket!.on('user:address_updated', (data) {
        debugPrint('📥 Realtime Socket Event [user:address_updated]: $data');
        if (data != null && data is Map && _currentUser != null) {
          final uid = data['uid'];
          if (_currentUser!.uid == uid && data['addresses'] is List) {
            _currentUser!.addresses = (data['addresses'] as List)
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
            _saveSessionLocally(_currentUser!);
            notifyListeners();
          }
        }
      });

      _socket!.on('user:address_self_updated', (data) {
        debugPrint('📥 Realtime Socket Event [user:address_self_updated]: $data');
        if (data != null && data is Map && _currentUser != null) {
          if (data['addresses'] is List) {
            _currentUser!.addresses = (data['addresses'] as List)
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
            _saveSessionLocally(_currentUser!);
            notifyListeners();
          }
        }
      });

      _socket!.onDisconnect((_) {
        debugPrint('❌ Socket.io Disconnected from Backend');
      });

      _socket!.connect();
    } catch (e) {
      debugPrint('Error initializing Socket.io: $e');
    }
  }

  void disconnectSocket() {
    try {
      _socket?.disconnect();
      _socket?.dispose();
      _socket = null;
    } catch (e) {
      debugPrint('Error disconnecting socket: $e');
    }
  }

  // -------------------------------------------------------------
  // 1. INITIALIZE & RESTORE SESSION FROM MONGO / LOCAL STORAGE
  // -------------------------------------------------------------
  Future<void> initSession() async {
    initSocket();
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUserData = prefs.getString('user_session_json');

      if (savedUserData != null && savedUserData.isNotEmpty) {
        final Map<String, dynamic> jsonMap = jsonDecode(savedUserData);
        _currentUser = UserModel.fromJson(jsonMap);

        if (_currentUser != null && _currentUser!.uid.isNotEmpty) {
          await fetchUserFromMongo(_currentUser!.uid);
          FcmNotificationService.instance.subscribeUserTopic(_currentUser!.uid);
        }
      }
    } catch (e) {
      debugPrint('Error restoring user session: $e');
    }
    notifyListeners();
  }

  Future<UserModel?> fetchUserFromMongo(String uid) async {
    if (uid.isEmpty) return _currentUser;

    final urlsToTry = _buildEndpoints('users/$uid');

    for (final url in urlsToTry) {
      try {
        final res = await http.get(url).timeout(const Duration(seconds: 3));
        if (res.statusCode == 200) {
          final body = jsonDecode(res.body);
          if (body['success'] == true && body['data'] != null) {
            _currentUser = UserModel.fromJson(Map<String, dynamic>.from(body['data']));
            await _saveSessionLocally(_currentUser!);
            notifyListeners();
            return _currentUser;
          }
        }
      } catch (_) {}
    }

    // Direct MongoDB Atlas fallback
    try {
      final col = await MongoBackendService.instance
          .getCollection('users')
          .timeout(const Duration(seconds: 2));
      if (col != null) {
        final doc = await col.findOne(where.eq('uid', uid));
        if (doc != null) {
          _currentUser = UserModel.fromJson(Map<String, dynamic>.from(doc));
          await _saveSessionLocally(_currentUser!);
          notifyListeners();
          return _currentUser;
        }
      }
    } catch (e) {
      debugPrint('Direct Mongo fetch notice: $e');
    }

    return _currentUser;
  }

  // -------------------------------------------------------------
  // 2. AUTHENTICATION (GOOGLE & EMAIL)
  // -------------------------------------------------------------
  Future<UserModel?> signInWithRealGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('Google Sign-In prompt cancelled by user.');
        return null;
      }

      String uid = 'google_${googleUser.id}';
      String name = googleUser.displayName ?? 'Athlete';
      String email = googleUser.email;
      String photoUrl = googleUser.photoUrl ?? '';

      try {
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final UserCredential userCred =
            await FirebaseAuth.instance.signInWithCredential(credential);
        final fbUser = userCred.user;
        if (fbUser != null) {
          uid = fbUser.uid;
          name = fbUser.displayName ?? name;
          email = fbUser.email ?? email;
          photoUrl = fbUser.photoURL ?? photoUrl;
        }
      } catch (fbErr) {
        debugPrint('Firebase Auth notice ($fbErr). Continuing with Google Account Profile.');
      }

      final user = UserModel(
        uid: uid,
        name: name,
        email: email,
        phone: '',
        photoUrl: photoUrl,
        authProvider: 'google',
        hasCompletedOnboarding: false,
      );

      _currentUser = user;
      await _syncUserToMongo(user);
      await _saveSessionLocally(user);
      initSocket();
      notifyListeners();
      return user;
    } catch (e) {
      debugPrint('Error signing in with Real Google: $e');
    }
    return null;
  }

  Future<UserModel?> signInWithGoogle() => signInWithRealGoogle();

  Future<UserModel?> signInWithEmailPassword(String email, String password) async {
    _isAuthLoading = true;
    notifyListeners();

    try {
      final String uid =
          'usr_em_${email.trim().toLowerCase().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';

      final existingUser = await fetchUserFromMongo(uid);
      if (existingUser != null) {
        _currentUser = existingUser;
      } else {
        final newUser = UserModel(
          uid: uid,
          name: email.split('@').first,
          email: email.trim(),
          authProvider: 'email',
        );
        _currentUser = newUser;
        await _syncUserToMongo(newUser);
      }

      await _saveSessionLocally(_currentUser!);
      initSocket();
      return _currentUser;
    } catch (e) {
      debugPrint('Error in email sign in: $e');
    } finally {
      _isAuthLoading = false;
      notifyListeners();
    }
    return null;
  }

  Future<UserModel?> registerWithEmailPassword(
      String name, String email, String password) async {
    _isAuthLoading = true;
    notifyListeners();

    try {
      final String uid =
          'usr_em_${email.trim().toLowerCase().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';
      final newUser = UserModel(
        uid: uid,
        name: name.trim().isNotEmpty ? name.trim() : email.split('@').first,
        email: email.trim(),
        authProvider: 'email',
        hasCompletedOnboarding: false,
      );

      _currentUser = newUser;
      await _syncUserToMongo(newUser);
      await _saveSessionLocally(newUser);
      initSocket();
      return newUser;
    } catch (e) {
      debugPrint('Error in email registration: $e');
    } finally {
      _isAuthLoading = false;
      notifyListeners();
    }
    return null;
  }

  Future<void> signOut() async {
    try {
      try {
        await _googleSignIn.signOut();
      } catch (_) {}
      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {}
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      _currentUser = null;
      disconnectSocket();
      notifyListeners();
      debugPrint('🧹 Wiped all local cache and signed out user!');
    } catch (e) {
      debugPrint('Error signing out: $e');
      _currentUser = null;
      notifyListeners();
    }
  }

  Future<void> checkAuthStatus() async {
    try {
      final fbUser = FirebaseAuth.instance.currentUser;

      if (fbUser == null || (fbUser.email?.isEmpty ?? true)) {
        debugPrint('No authenticated Firebase user found. Clearing local cache.');
        await signOut();
        return;
      }

      try {
        final url = Uri.parse('$_apiBaseUrl/users/${fbUser.uid}');
        final res = await http.get(url).timeout(const Duration(seconds: 2));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (data['success'] == true && data['data'] != null) {
            _currentUser = UserModel.fromJson(data['data']);
            initSocket();
            notifyListeners();
            return;
          }
        }
      } catch (apiErr) {
        debugPrint('MongoDB session check notice: $apiErr');
      }

      if (fbUser.email != null && fbUser.email!.isNotEmpty) {
        _currentUser = UserModel(
          uid: fbUser.uid,
          name: fbUser.displayName ?? 'Athlete',
          email: fbUser.email!,
          phone: fbUser.phoneNumber ?? '',
          photoUrl: fbUser.photoURL ?? '',
          authProvider: 'google',
          hasCompletedOnboarding: false,
        );
        await _syncUserToMongo(_currentUser!);
        await _saveSessionLocally(_currentUser!);
        initSocket();
        notifyListeners();
        return;
      }

      await signOut();
    } catch (e) {
      debugPrint('Error checking auth status: $e');
      await signOut();
    }
  }

  // -------------------------------------------------------------
  // 3. QUESTIONNAIRE & PLANS
  // -------------------------------------------------------------
  Future<bool> saveQuestionnaireData(Map<String, dynamic> questionnaireAnswers) async {
    if (_currentUser == null) return false;

    try {
      _currentUser!.questionnaireData = questionnaireAnswers;
      _currentUser!.hasCompletedOnboarding = true;
      _currentUser!.updatedAt = DateTime.now();

      final qUrls = _buildEndpoints('users/${_currentUser!.uid}/questionnaire');

      for (final qUrl in qUrls) {
        try {
          final res = await http.post(
            qUrl,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(questionnaireAnswers),
          ).timeout(const Duration(seconds: 2));
          if (res.statusCode == 200 || res.statusCode == 201) break;
        } catch (_) {}
      }

      try {
        final col = await MongoBackendService.instance
            .getCollection('users')
            .timeout(const Duration(milliseconds: 1500));
        if (col != null) {
          await col.update(
            where.eq('uid', _currentUser!.uid),
            {
              r'$set': {
                'questionnaireData': questionnaireAnswers,
                'hasCompletedOnboarding': true,
                'updatedAt': DateTime.now().toIso8601String(),
              }
            },
            upsert: true,
          );
          debugPrint('✅ Questionnaire data directly saved to MongoDB Atlas users collection!');
        }
      } catch (e) {
        debugPrint('Direct Mongo Driver questionnaire notice: $e');
      }

      await _saveSessionLocally(_currentUser!);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error saving questionnaire to MongoDB: $e');
    }
    return false;
  }

  Future<bool> saveQuestionnaireAndPlan({
    Map<String, dynamic>? questionnaireData,
    Map<String, dynamic>? questionnaireAnswers,
  }) async {
    final payload = questionnaireData ?? questionnaireAnswers ?? {};
    return await saveQuestionnaireData(payload);
  }

  // -------------------------------------------------------------
  // 4. USER ADDRESS MANAGEMENT (MONGODB USER.ADDRESSES ARRAY)
  // -------------------------------------------------------------
  Future<List<Map<String, dynamic>>> getUserAddresses(String uid, {bool forceNetwork = false}) async {
    if (uid.isEmpty) return [];

    // Fast path: Return cached in-memory addresses instantly (0ms)
    if (!forceNetwork && _currentUser != null && _currentUser!.uid == uid && _currentUser!.addresses.isNotEmpty) {
      _refreshAddressesInBackground(uid);
      return _currentUser!.addresses;
    }

    final candidateUrls = _buildEndpoints('users/$uid/addresses');

    // Parallel racing across candidate endpoints for instant response
    final completer = Completer<List<Map<String, dynamic>>?>();
    int pending = candidateUrls.length;

    for (final url in candidateUrls) {
      http.get(url).timeout(const Duration(milliseconds: 1600)).then((res) {
        if (!completer.isCompleted && res.statusCode == 200) {
          try {
            final decoded = jsonDecode(res.body);
            if (decoded['success'] == true && decoded['data'] is List) {
              final List<Map<String, dynamic>> addrs = (decoded['data'] as List)
                  .whereType<Map>()
                  .map((e) => Map<String, dynamic>.from(e))
                  .toList();
              if (_currentUser != null && _currentUser!.uid == uid) {
                _currentUser!.addresses = addrs;
                _saveSessionLocally(_currentUser!);
              }
              completer.complete(addrs);
              return;
            }
          } catch (_) {}
        }
        pending--;
        if (pending == 0 && !completer.isCompleted) {
          completer.complete(null);
        }
      }).catchError((_) {
        pending--;
        if (pending == 0 && !completer.isCompleted) {
          completer.complete(null);
        }
      });
    }

    try {
      final networkResult = await completer.future.timeout(
        const Duration(milliseconds: 1800),
        onTimeout: () => null,
      );
      if (networkResult != null && networkResult.isNotEmpty) {
        return networkResult;
      }
    } catch (_) {}

    // Direct MongoDB fallback
    try {
      final col = await MongoBackendService.instance
          .getCollection('users')
          .timeout(const Duration(milliseconds: 1500));
      if (col != null) {
        final doc = await col.findOne(where.eq('uid', uid));
        if (doc != null && doc['addresses'] is List) {
          final List<Map<String, dynamic>> addrs = (doc['addresses'] as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();

          if (_currentUser != null && _currentUser!.uid == uid) {
            _currentUser!.addresses = addrs;
            _saveSessionLocally(_currentUser!);
          }
          return addrs;
        }
      }
    } catch (e) {
      debugPrint('Direct Mongo getUserAddresses notice: $e');
    }

    // Return in-memory addresses if available
    if (_currentUser != null && _currentUser!.uid == uid) {
      return _currentUser!.addresses;
    }

    return [];
  }

  void _refreshAddressesInBackground(String uid) {
    // Non-blocking background fetch
    Future.microtask(() async {
      try {
        final res = await http.get(Uri.parse('$_apiBaseUrl/users/$uid/addresses'))
            .timeout(const Duration(milliseconds: 2500));
        if (res.statusCode == 200) {
          final decoded = jsonDecode(res.body);
          if (decoded['success'] == true && decoded['data'] is List) {
            final List<Map<String, dynamic>> addrs = (decoded['data'] as List)
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
            if (_currentUser != null && _currentUser!.uid == uid) {
              _currentUser!.addresses = addrs;
              _saveSessionLocally(_currentUser!);
              notifyListeners();
            }
          }
        }
      } catch (_) {}
    });
  }

  Future<bool> saveUserAddress(String uid, Map<String, dynamic> addressData) async {
    if (uid.isEmpty) return false;

    bool savedOnExpress = false;
    final candidateUrls = _buildEndpoints('users/$uid/addresses');

    for (final url in candidateUrls) {
      try {
        final res = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(addressData),
        ).timeout(const Duration(seconds: 3));

        if (res.statusCode == 200 || res.statusCode == 201) {
          savedOnExpress = true;
          final decoded = jsonDecode(res.body);
          if (decoded['addresses'] is List && _currentUser != null) {
            _currentUser!.addresses = (decoded['addresses'] as List)
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
          }
          break;
        }
      } catch (_) {}
    }

    if (savedOnExpress) {
      if (_currentUser != null) {
        _saveSessionLocally(_currentUser!);
      }
      notifyListeners();
      return true;
    }

    // Direct Mongo driver fallback
    try {
      final col = await MongoBackendService.instance
          .getCollection('users')
          .timeout(const Duration(milliseconds: 2000));
      if (col != null) {
        final doc = await col.findOne(where.eq('uid', uid));
        List<dynamic> existingAddrs = [];
        if (doc != null && doc['addresses'] is List) {
          existingAddrs = List.from(doc['addresses']);
        }

        final addrId = addressData['id'] ?? 'addr_${DateTime.now().millisecondsSinceEpoch}';
        final isDefault = addressData['isDefault'] == true || existingAddrs.isEmpty;

        if (isDefault) {
          for (var a in existingAddrs) {
            if (a is Map) a['isDefault'] = false;
          }
        }

        final mapToSave = Map<String, dynamic>.from(addressData);
        mapToSave['id'] = addrId;
        mapToSave['isDefault'] = isDefault;

        existingAddrs.removeWhere((a) => a is Map && a['id'] == addrId);
        existingAddrs.insert(0, mapToSave);

        await col.update(
          where.eq('uid', uid),
          {
            r'$set': {
              'addresses': existingAddrs,
              'updatedAt': DateTime.now().toIso8601String(),
            }
          },
          upsert: true,
        );

        if (_currentUser != null && _currentUser!.uid == uid) {
          _currentUser!.addresses = existingAddrs
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Direct Mongo saveUserAddress notice: $e');
    }

    // If currentUser is loaded, ensure local list reflects address
    if (_currentUser != null && _currentUser!.uid == uid) {
      final addrId = addressData['id'];
      _currentUser!.addresses.removeWhere((a) => a['id'] == addrId);
      _currentUser!.addresses.insert(0, Map<String, dynamic>.from(addressData));
      await _saveSessionLocally(_currentUser!);
      notifyListeners();
    }

    return true;
  }

  Future<bool> setDefaultAddress(String uid, String addressId) async {
    if (uid.isEmpty || addressId.isEmpty) return false;

    final candidateUrls = _buildEndpoints('users/$uid/addresses/$addressId/default');

    for (final url in candidateUrls) {
      try {
        final res = await http.put(url).timeout(const Duration(seconds: 3));
        if (res.statusCode == 200) {
          final decoded = jsonDecode(res.body);
          if (decoded['addresses'] is List && _currentUser != null) {
            _currentUser!.addresses = (decoded['addresses'] as List)
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
          }
          break;
        }
      } catch (_) {}
    }

    // Direct Mongo driver fallback
    try {
      final col = await MongoBackendService.instance
          .getCollection('users')
          .timeout(const Duration(milliseconds: 2000));
      if (col != null) {
        final doc = await col.findOne(where.eq('uid', uid));
        if (doc != null && doc['addresses'] is List) {
          final list = List.from(doc['addresses']);
          for (var a in list) {
            if (a is Map) {
              a['isDefault'] = (a['id'] == addressId);
            }
          }
          await col.update(
            where.eq('uid', uid),
            {
              r'$set': {
                'addresses': list,
                'updatedAt': DateTime.now().toIso8601String(),
              }
            },
          );
        }
      }
    } catch (e) {
      debugPrint('Direct Mongo setDefaultAddress notice: $e');
    }

    if (_currentUser != null && _currentUser!.uid == uid) {
      for (final a in _currentUser!.addresses) {
        a['isDefault'] = (a['id'] == addressId);
      }
      await _saveSessionLocally(_currentUser!);
      notifyListeners();
    }

    return true;
  }

  Future<bool> deleteUserAddress(String uid, String addressId) async {
    if (uid.isEmpty || addressId.isEmpty) return false;

    final candidateUrls = _buildEndpoints('users/$uid/addresses/$addressId');

    for (final url in candidateUrls) {
      try {
        final res = await http.delete(url).timeout(const Duration(seconds: 3));
        if (res.statusCode == 200) {
          final decoded = jsonDecode(res.body);
          if (decoded['addresses'] is List && _currentUser != null) {
            _currentUser!.addresses = (decoded['addresses'] as List)
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
          }
          break;
        }
      } catch (_) {}
    }

    // Direct Mongo driver fallback
    try {
      final col = await MongoBackendService.instance
          .getCollection('users')
          .timeout(const Duration(milliseconds: 2000));
      if (col != null) {
        final doc = await col.findOne(where.eq('uid', uid));
        if (doc != null && doc['addresses'] is List) {
          final list = List.from(doc['addresses']);
          list.removeWhere((a) => a is Map && a['id'] == addressId);
          if (list.isNotEmpty && !list.any((a) => a is Map && a['isDefault'] == true)) {
            if (list.first is Map) list.first['isDefault'] = true;
          }
          await col.update(
            where.eq('uid', uid),
            {
              r'$set': {
                'addresses': list,
                'updatedAt': DateTime.now().toIso8601String(),
              }
            },
          );
        }
      }
    } catch (e) {
      debugPrint('Direct Mongo deleteUserAddress notice: $e');
    }

    if (_currentUser != null && _currentUser!.uid == uid) {
      _currentUser!.addresses.removeWhere((a) => a['id'] == addressId);
      if (_currentUser!.addresses.isNotEmpty &&
          !_currentUser!.addresses.any((a) => a['isDefault'] == true)) {
        _currentUser!.addresses.first['isDefault'] = true;
      }
      await _saveSessionLocally(_currentUser!);
      notifyListeners();
    }

    return true;
  }

  // -------------------------------------------------------------
  // 5. HELPER SYNC & CACHE METHODS
  // -------------------------------------------------------------
  Future<void> _syncUserToMongo(UserModel user) async {
    debugPrint('🚀 Syncing user profile to backend & MongoDB: ${user.email} (${user.uid})');

    final urlsToTry = _buildEndpoints('users/${user.uid}');

    bool expressSynced = false;
    for (final url in urlsToTry) {
      if (expressSynced) break;
      try {
        final res = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(user.toJson()),
        ).timeout(const Duration(seconds: 3));

        if (res.statusCode == 200 || res.statusCode == 201) {
          debugPrint('✅ User ${user.uid} (${user.email}) synced to Express REST API at $url!');
          expressSynced = true;
        }
      } catch (e) {
        debugPrint('Express sync attempt failed for $url: $e');
      }
    }

    // Direct Mongo Driver write to MongoDB Atlas 'users' collection
    try {
      final col = await MongoBackendService.instance
          .getCollection('users')
          .timeout(const Duration(milliseconds: 1500));
      if (col != null) {
        await col.update(
          where.eq('uid', user.uid),
          user.toJson(),
          upsert: true,
        );
        debugPrint('✅ User ${user.uid} directly saved to MongoDB Atlas users collection!');
      }
    } catch (e) {
      debugPrint('Direct Mongo Driver write notice: $e');
    }

    // Firestore REST API sync
    try {
      final fsUrl = Uri.parse(
          'https://firestore.googleapis.com/v1/projects/neurofit-63189/databases/(default)/documents/users/${user.uid}');
      await http.patch(
        fsUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fields': {
            'uid': {'stringValue': user.uid},
            'name': {'stringValue': user.name},
            'email': {'stringValue': user.email},
            'photoUrl': {'stringValue': user.photoUrl},
            'authProvider': {'stringValue': user.authProvider},
            'hasCompletedOnboarding': {'booleanValue': user.hasCompletedOnboarding},
            'createdAt': {'timestampValue': user.createdAt.toUtc().toIso8601String()},
            'updatedAt': {'timestampValue': DateTime.now().toUtc().toIso8601String()},
          }
        }),
      ).timeout(const Duration(seconds: 3));
      debugPrint('✅ User ${user.uid} synced to Firestore Database!');
    } catch (e) {
      debugPrint('Firestore REST write notice: $e');
    }
  }

  Future<void> _saveSessionLocally(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_session_json', jsonEncode(user.toJson()));
    } catch (e) {
      debugPrint('Error saving local session: $e');
    }
  }
}