import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../constants/api_constants.dart';
import '../backend/live_backend.dart';
import '../backend/sync_store.dart';
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

  /// Last sign-in error, in words the user can act on (shown by the auth screens).
  String? lastError;

  /// Google OAuth client ids (public ids, not secrets). Override per build with
  ///   --dart-define=GOOGLE_WEB_CLIENT_ID=xxxx.apps.googleusercontent.com
  ///   --dart-define=GOOGLE_IOS_CLIENT_ID=yyyy.apps.googleusercontent.com (iPhone only)
  static const _webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID',
      defaultValue: '465865494955-7q16j5dqtsnt8rusbdicmsiftjo6mf0j.apps.googleusercontent.com');
  static const _iosClientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const ['email', 'profile'],
    clientId: kIsWeb ? (_webClientId.isEmpty ? null : _webClientId) : (defaultTargetPlatform == TargetPlatform.iOS && _iosClientId.isNotEmpty ? _iosClientId : null),
    serverClientId: kIsWeb || _webClientId.isEmpty ? null : _webClientId,
  );

  static String get _apiBaseUrl => ApiConstants.apiBaseUrl;
  static String get socketUrl => ApiConstants.socketUrl;

  IO.Socket? _socket;
  IO.Socket? get socket => _socket;

  bool get isLoggedIn => _currentUser != null && _currentUser!.uid.isNotEmpty && (ApiConstants.demoMode || AppSession.isSignedIn);

  // -------------------------------------------------------------
  // REAL-TIME SOCKET.IO
  // -------------------------------------------------------------
  void initSocket() {
    if (ApiConstants.demoMode || !AppSession.isSignedIn) return;
    if (_socket != null && _socket!.connected) return;

    try {
      _socket = IO.io(
        socketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .setAuth({'token': AppSession.accessToken ?? ''})
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionDelay(2000)
            .build(),
      );

      _socket!.onConnect((_) {
        if (_currentUser != null && _currentUser!.uid.isNotEmpty) {
          _socket!.emit('join_user_room', _currentUser!.uid);
        }
      });

      // The server says "your profile changed" (from another device or the admin).
      for (final ev in const ['user:self_updated', 'user:questionnaire_saved', 'user:address_updated', 'user:address_self_updated']) {
        _socket!.on(ev, (_) => refreshProfile());
      }

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
    } catch (_) {}
  }

  // -------------------------------------------------------------
  // 1. SESSION
  // -------------------------------------------------------------
  Future<void> initSession() async {
    await _restoreLocal();
    if (isLoggedIn) {
      initSocket();
      unawaited(refreshProfile());
      FcmNotificationService.instance.subscribeUserTopic(_currentUser!.uid);
    }
    notifyListeners();
  }

  Future<void> _restoreLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('user_session_json');
      _currentUser = (saved != null && saved.isNotEmpty) ? UserModel.fromJson(jsonDecode(saved) as Map<String, dynamic>) : null;
    } catch (_) {
      _currentUser = null;
    }
  }

  /// Fresh profile from the server (kept on the device for offline use).
  Future<UserModel?> refreshProfile() async {
    if (ApiConstants.demoMode || !AppSession.isSignedIn) return _currentUser;
    try {
      final j = await Api.get('/auth/me');
      if (j['data'] is Map) {
        _currentUser = UserModel.fromJson(Map<String, dynamic>.from(j['data'] as Map));
        await _saveSessionLocally(_currentUser!);
        notifyListeners();
      }
    } catch (_) {
      // offline: keep the saved profile
    }
    return _currentUser;
  }

  Future<UserModel?> fetchUserFromMongo(String uid) => refreshProfile();

  // -------------------------------------------------------------
  // 2. AUTHENTICATION (GOOGLE & EMAIL)
  // -------------------------------------------------------------
  Future<UserModel?> _signedIn(Map<String, dynamic> j) async {
    await AppSession.save(j);
    final data = j['data'] ?? j['user'];
    _currentUser = UserModel.fromJson(Map<String, dynamic>.from(data as Map));
    await _saveSessionLocally(_currentUser!);
    initSocket();
    SyncStore.I.signedIn();
    FcmNotificationService.instance.subscribeUserTopic(_currentUser!.uid);
    notifyListeners();
    return _currentUser;
  }

  Future<UserModel?> signInWithRealGoogle() async {
    lastError = null;
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // cancelled
      final auth = await googleUser.authentication;
      final idToken = auth.idToken;
      final accessToken = auth.accessToken;
      // Web sign-in often returns only an access token; the server verifies either.
      if ((idToken == null || idToken.isEmpty) && (accessToken == null || accessToken.isEmpty)) {
        lastError = 'Google did not return a sign-in token. Try again.';
        throw ApiError(lastError!);
      }
      final j = await Api.send('POST', '/auth/google', {
        if (idToken != null && idToken.isNotEmpty) 'idToken': idToken,
        if (accessToken != null && accessToken.isNotEmpty) 'accessToken': accessToken,
      });
      return await _signedIn(j);
    } on ApiError catch (e) {
      lastError = e.message;
      try {
        await _googleSignIn.signOut();
      } catch (_) {}
      rethrow;
    } catch (e) {
      lastError = 'Google sign-in failed. Check your connection and try again.';
      debugPrint('Google sign-in error: $e');
      throw ApiError(lastError!);
    }
  }

  Future<UserModel?> signInWithGoogle() => signInWithRealGoogle();

  /// Email sign-in. Throws [ApiError] with a readable message (wrong password, no account...).
  Future<UserModel?> signInWithEmailPassword(String email, String password) async {
    _isAuthLoading = true;
    lastError = null;
    notifyListeners();
    try {
      final j = await Api.send('POST', '/auth/login', {'email': email.trim(), 'password': password});
      return await _signedIn(j);
    } on ApiError catch (e) {
      lastError = e.message;
      rethrow;
    } catch (_) {
      lastError = 'Could not reach NeuroFit. Check your connection and try again.';
      throw ApiError(lastError!);
    } finally {
      _isAuthLoading = false;
      notifyListeners();
    }
  }

  /// Email registration. Throws [ApiError] (email taken, weak password...).
  Future<UserModel?> registerWithEmailPassword(String name, String email, String password, {String phone = ''}) async {
    _isAuthLoading = true;
    lastError = null;
    notifyListeners();
    try {
      final j = await Api.send('POST', '/auth/register', {'name': name.trim(), 'email': email.trim(), 'password': password, 'phone': phone.trim()});
      return await _signedIn(j);
    } on ApiError catch (e) {
      lastError = e.message;
      rethrow;
    } catch (_) {
      lastError = 'Could not reach NeuroFit. Check your connection and try again.';
      throw ApiError(lastError!);
    } finally {
      _isAuthLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      if (!ApiConstants.demoMode) {
        try {
          await _googleSignIn.signOut();
        } catch (_) {}
        await AppSession.clear();
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
    _currentUser = null;
    disconnectSocket();
    notifyListeners();
  }

  /// Splash check: a saved session opens the app straight away (also offline);
  /// the profile refreshes in the background.
  Future<void> checkAuthStatus() async {
    await _restoreLocal();
    if (ApiConstants.demoMode) {
      notifyListeners();
      return;
    }
    if (!AppSession.isSignedIn) {
      _currentUser = null;
      notifyListeners();
      return;
    }
    if (_currentUser == null) {
      await refreshProfile();
    } else {
      unawaited(refreshProfile());
    }
    initSocket();
    notifyListeners();
  }

  // -------------------------------------------------------------
  // 3. QUESTIONNAIRE & PLANS
  // -------------------------------------------------------------
  Future<bool> saveQuestionnaireData(Map<String, dynamic> questionnaireAnswers) async {
    if (_currentUser == null) return false;
    _currentUser!.questionnaireData = questionnaireAnswers;
    _currentUser!.hasCompletedOnboarding = true;
    _currentUser!.updatedAt = DateTime.now();
    await _saveSessionLocally(_currentUser!);
    notifyListeners();
    try {
      // Saved offline too: the outbox sends it when the phone is back online.
      await Api.send('POST', '/users/${_currentUser!.uid}/questionnaire', questionnaireAnswers);
    } catch (e) {
      debugPrint('Questionnaire save notice: $e');
    }
    return true;
  }

  Future<bool> saveQuestionnaireAndPlan({
    Map<String, dynamic>? questionnaireData,
    Map<String, dynamic>? questionnaireAnswers,
  }) async {
    final payload = questionnaireData ?? questionnaireAnswers ?? {};
    return await saveQuestionnaireData(payload);
  }

  /// Saves profile fields (name, phone, photoUrl, gender, age...).
  Future<bool> updateProfile(Map<String, dynamic> fields) async {
    if (_currentUser == null) return false;
    try {
      final j = await Api.send('PATCH', '/users/${_currentUser!.uid}', fields);
      if (j['data'] is Map && j['queued'] != true) {
        _currentUser = UserModel.fromJson(Map<String, dynamic>.from(j['data'] as Map));
        await _saveSessionLocally(_currentUser!);
        notifyListeners();
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  // -------------------------------------------------------------
  // 4. ADDRESSES
  // -------------------------------------------------------------
  List<Map<String, dynamic>> _addrList(Map<String, dynamic> j) {
    final raw = j['addresses'] ?? j['data'];
    return raw is List ? raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : [];
  }

  Future<void> _setAddresses(List<Map<String, dynamic>> list) async {
    if (_currentUser == null) return;
    _currentUser!.addresses = list;
    await _saveSessionLocally(_currentUser!);
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> getUserAddresses(String uid, {bool forceNetwork = false}) async {
    if (uid.isEmpty) return [];
    if (!forceNetwork && _currentUser != null && _currentUser!.uid == uid && _currentUser!.addresses.isNotEmpty) {
      unawaited(_fetchAddresses(uid));
      return _currentUser!.addresses;
    }
    return await _fetchAddresses(uid) ?? (_currentUser?.addresses ?? []);
  }

  Future<List<Map<String, dynamic>>?> _fetchAddresses(String uid) async {
    try {
      final list = _addrList(await Api.get('/users/$uid/addresses'));
      if (_currentUser != null && _currentUser!.uid == uid) await _setAddresses(list);
      return list;
    } catch (_) {
      return null;
    }
  }

  Future<bool> saveUserAddress(String uid, Map<String, dynamic> addressData) async {
    if (uid.isEmpty) return false;
    final addr = Map<String, dynamic>.from(addressData);
    addr['id'] ??= 'addr_${DateTime.now().millisecondsSinceEpoch}';
    // Show it at once; the server copy follows (or is queued offline).
    if (_currentUser != null && _currentUser!.uid == uid) {
      final list = List<Map<String, dynamic>>.from(_currentUser!.addresses)..removeWhere((a) => a['id'] == addr['id']);
      if (addr['isDefault'] == true || list.isEmpty) {
        for (final a in list) {
          a['isDefault'] = false;
        }
        addr['isDefault'] = true;
      }
      list.insert(0, addr);
      await _setAddresses(list);
    }
    try {
      final j = await Api.send('POST', '/users/$uid/addresses', addr);
      if (j['queued'] != true) {
        final list = _addrList(j);
        if (list.isNotEmpty) await _setAddresses(list);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> setDefaultAddress(String uid, String addressId) async {
    if (uid.isEmpty || addressId.isEmpty) return false;
    if (_currentUser != null && _currentUser!.uid == uid) {
      for (final a in _currentUser!.addresses) {
        a['isDefault'] = (a['id'] == addressId);
      }
      await _setAddresses(_currentUser!.addresses);
    }
    try {
      final j = await Api.send('PUT', '/users/$uid/addresses/$addressId/default');
      if (j['queued'] != true) {
        final list = _addrList(j);
        if (list.isNotEmpty) await _setAddresses(list);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteUserAddress(String uid, String addressId) async {
    if (uid.isEmpty || addressId.isEmpty) return false;
    if (_currentUser != null && _currentUser!.uid == uid) {
      final list = List<Map<String, dynamic>>.from(_currentUser!.addresses)..removeWhere((a) => a['id'] == addressId);
      if (list.isNotEmpty && !list.any((a) => a['isDefault'] == true)) list.first['isDefault'] = true;
      await _setAddresses(list);
    }
    try {
      final j = await Api.send('DELETE', '/users/$uid/addresses/$addressId');
      if (j['queued'] != true && (j['addresses'] is List)) await _setAddresses(_addrList(j));
      return true;
    } catch (_) {
      return false;
    }
  }

  // -------------------------------------------------------------
  // 5. LOCAL CACHE
  // -------------------------------------------------------------
  Future<void> _saveSessionLocally(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_session_json', jsonEncode(user.toJson()));
    } catch (e) {
      debugPrint('Error saving local session: $e');
    }
  }

  @visibleForTesting
  static String get apiBase => _apiBaseUrl;
}
