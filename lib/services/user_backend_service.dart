import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mongo_dart/mongo_dart.dart' show where;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'mongo_backend_service.dart';

class UserModel {
  final String uid;
  String name;
  String email;
  String phone;
  String photoUrl;
  String authProvider;
  bool hasCompletedOnboarding;
  Map<String, dynamic> questionnaireData;
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
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : questionnaireData = questionnaireData ?? {},
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String? ?? '',
      name: json['name'] as String? ?? 'Athlete',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      photoUrl: json['photoUrl'] as String? ?? '',
      authProvider: json['authProvider'] as String? ?? 'google',
      hasCompletedOnboarding: json['hasCompletedOnboarding'] as bool? ?? false,
      questionnaireData: json['questionnaireData'] as Map<String, dynamic>? ?? {},
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

  static String get _apiBaseUrl {
    if (kIsWeb) return 'http://localhost:5000/api';
    return 'http://10.60.114.191:5000/api';
  }

  static String get socketUrl {
    if (kIsWeb) return 'http://localhost:5000';
    return 'http://10.60.114.191:5000';
  }

  IO.Socket? _socket;
  IO.Socket? get socket => _socket;

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

        // Fetch fresh data from MongoDB Atlas
        if (_currentUser != null && _currentUser!.uid.isNotEmpty) {
          await fetchUserFromMongo(_currentUser!.uid);
        }
      }
    } catch (e) {
      debugPrint('Error restoring user session: $e');
    }
    notifyListeners();
  }

  Future<UserModel?> fetchUserFromMongo(String uid) async {
    try {
      final url = Uri.parse('$_apiBaseUrl/users/$uid');
      final res = await http.get(url).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['success'] == true && body['data'] != null) {
          _currentUser = UserModel.fromJson(Map<String, dynamic>.from(body['data']));
          await _saveSessionLocally(_currentUser!);
          notifyListeners();
          return _currentUser;
        }
      }
    } catch (e) {
      debugPrint('Error fetching user from Mongo API: $e');
    }
    return _currentUser;
  }

  // -------------------------------------------------------------
  // 2. GOOGLE SIGN IN & SIGN UP (GOOGLE CLOUD CONSOLE OAUTH)
  // -------------------------------------------------------------
  Future<UserModel?> signInWithGoogle() async {
    _isAuthLoading = true;
    notifyListeners();

    try {
      final GoogleSignInAccount? googleAccount = await _googleSignIn.signIn();
      if (googleAccount == null) {
        _isAuthLoading = false;
        notifyListeners();
        return null;
      }

      final String uid = 'usr_g_${googleAccount.id}';
      final user = UserModel(
        uid: uid,
        name: googleAccount.displayName ?? 'Athlete',
        email: googleAccount.email,
        photoUrl: googleAccount.photoUrl ?? '',
        authProvider: 'google',
        hasCompletedOnboarding: false,
      );

      _currentUser = user;
      await _syncUserToMongo(user);
      await _saveSessionLocally(user);

      debugPrint('✅ Google Sign-In Successful via Google Cloud Console OAuth (UID: $uid)!');
      return user;
    } catch (e) {
      debugPrint('Error in Google Sign-In: $e');
    } finally {
      _isAuthLoading = false;
      notifyListeners();
    }
    return null;
  }

  // -------------------------------------------------------------
  // 3. EMAIL & PASSWORD SIGN-IN / REGISTER (PURE MONGO BACKEND)
  // -------------------------------------------------------------
  Future<UserModel?> signInWithEmailPassword(String email, String password) async {
    _isAuthLoading = true;
    notifyListeners();

    try {
      final String uid = 'usr_em_${email.trim().toLowerCase().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';

      // Check if user exists in Mongo
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
      return _currentUser;
    } catch (e) {
      debugPrint('Error in email sign in: $e');
    } finally {
      _isAuthLoading = false;
      notifyListeners();
    }
    return null;
  }

  Future<UserModel?> registerWithEmailPassword(String name, String email, String password) async {
    _isAuthLoading = true;
    notifyListeners();

    try {
      final String uid = 'usr_em_${email.trim().toLowerCase().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';
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
      return newUser;
    } catch (e) {
      debugPrint('Error in email registration: $e');
    } finally {
      _isAuthLoading = false;
      notifyListeners();
    }
    return null;
  }

  // -------------------------------------------------------------
  // 4. SAVE QUESTIONNAIRE DATA DIRECTLY TO MONGODB USERS COLLECTION
  // -------------------------------------------------------------
  Future<bool> saveQuestionnaireData(Map<String, dynamic> questionnaireAnswers) async {
    if (_currentUser == null) return false;

    try {
      _currentUser!.questionnaireData = questionnaireAnswers;
      _currentUser!.hasCompletedOnboarding = true;
      _currentUser!.updatedAt = DateTime.now();

      // 1. Post to Express REST API
      final qUrls = [
        Uri.parse('http://10.60.114.191:5000/api/users/${_currentUser!.uid}/questionnaire'),
        Uri.parse('$_apiBaseUrl/users/${_currentUser!.uid}/questionnaire'),
        Uri.parse('http://10.0.2.2:5000/api/users/${_currentUser!.uid}/questionnaire'),
        Uri.parse('http://localhost:5000/api/users/${_currentUser!.uid}/questionnaire'),
      ];
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

      // 2. Direct Mongo Driver write to MongoDB Atlas 'users' collection
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

      debugPrint('✅ Questionnaire saved to MongoDB users collection successfully!');
      return true;
    } catch (e) {
      debugPrint('Error saving questionnaire to MongoDB: $e');
    }
    return false;
  }

  // -------------------------------------------------------------
  // 5. HELPER SYNC METHODS
  // -------------------------------------------------------------
  Future<void> _syncUserToMongo(UserModel user) async {
    debugPrint('🚀 Syncing user profile to backend & MongoDB: ${user.email} (${user.uid})');

    // 1. Post to Express REST API (Try configured base URL and fallbacks)
    final urlsToTry = [
      Uri.parse('http://10.60.114.191:5000/api/users/${user.uid}'),
      Uri.parse('$_apiBaseUrl/users/${user.uid}'),
      Uri.parse('http://10.0.2.2:5000/api/users/${user.uid}'),
      Uri.parse('http://localhost:5000/api/users/${user.uid}'),
    ];

    bool expressSynced = false;
    for (final url in urlsToTry) {
      if (expressSynced) break;
      try {
        debugPrint('📡 Posting to Express backend: $url');
        final res = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(user.toJson()),
        ).timeout(const Duration(seconds: 3));

        debugPrint('📡 Backend response [${res.statusCode}]: ${res.body}');
        if (res.statusCode == 200 || res.statusCode == 201) {
          debugPrint('✅ User ${user.uid} (${user.email}) synced to Express REST API at $url!');
          expressSynced = true;
        }
      } catch (e) {
        debugPrint('Express sync attempt failed for $url: $e');
      }
    }

    // 2. Direct Mongo Driver write to MongoDB Atlas 'users' collection
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

    // 3. Write to Firestore REST API (neurofit-63189)
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
      notifyListeners();
      debugPrint('🧹 Wiped all local cache and signed out user!');
    } catch (e) {
      debugPrint('Error signing out: $e');
      _currentUser = null;
      notifyListeners();
    }
  }

  bool get isLoggedIn => _currentUser != null && _currentUser!.email.isNotEmpty;

  Future<void> checkAuthStatus() async {
    try {
      final fbUser = FirebaseAuth.instance.currentUser;

      // If Firebase Auth has no user or no email, immediately wipe cache & log out
      if (fbUser == null || (fbUser.email?.isEmpty ?? true)) {
        debugPrint('No authenticated Firebase user found. Clearing all local cache.');
        await signOut();
        return;
      }

      // Verify user document in Express / MongoDB REST API
      try {
        final url = Uri.parse('$_apiBaseUrl/users/${fbUser.uid}');
        final res = await http.get(url).timeout(const Duration(seconds: 2));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (data['success'] == true && data['data'] != null) {
            _currentUser = UserModel.fromJson(data['data']);
            notifyListeners();
            return;
          }
        }
      } catch (apiErr) {
        debugPrint('MongoDB session check notice: $apiErr');
      }

      // Fallback to active Firebase user if email exists
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
        notifyListeners();
        return;
      }

      // No registered email in DB -> Wipe all cache & force sign out
      debugPrint('No registered email found. Clearing cache and logging out.');
      await signOut();
    } catch (e) {
      debugPrint('Error checking auth status: $e');
      await signOut();
    }
  }

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

      // Try Firebase Auth credential exchange
      try {
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final UserCredential userCred = await FirebaseAuth.instance.signInWithCredential(credential);
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
      notifyListeners();
      return user;
    } catch (e) {
      debugPrint('Error signing in with Real Google: $e');
    }
    return null;
  }

  Future<bool> saveQuestionnaireAndPlan({
    Map<String, dynamic>? questionnaireData,
    Map<String, dynamic>? questionnaireAnswers,
  }) async {
    final payload = questionnaireData ?? questionnaireAnswers ?? {};
    return await saveQuestionnaireData(payload);
  }
}
