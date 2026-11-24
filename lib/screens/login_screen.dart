import 'package:flutter/material.dart';

import 'auth_view.dart';

/// Sign-in screen. The layout and animations live in [AuthView].
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) => const AuthView(isLogin: true);
}
