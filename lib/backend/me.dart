import '../services/user_backend_service.dart';

/// The signed-in user's name for greetings ("Fuel your day, Asha").
class Me {
  static String get name {
    final n = UserBackendService.instance.currentUser?.name.trim() ?? '';
    return n.isEmpty ? 'Athlete' : n;
  }

  static String get first => name.split(RegExp(r'\s+')).first;
  static String get email => UserBackendService.instance.currentUser?.email ?? '';
  static String get uid => UserBackendService.instance.currentUser?.uid ?? '';
  static String get photo => UserBackendService.instance.currentUser?.photoUrl ?? '';
}
