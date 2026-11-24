import 'package:flutter/material.dart';

import 'auth_view.dart';

/// Sign-up screen. The layout and animations live in [AuthView].
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) => const AuthView(isLogin: false);
}
