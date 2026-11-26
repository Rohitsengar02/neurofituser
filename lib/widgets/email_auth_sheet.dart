import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../screens/dashboard_screen.dart';
import '../screens/questionnaire_screen.dart';
import '../services/user_backend_service.dart';

/// Email sign-in / registration form (bottom sheet) used by the login and
/// register screens. Returns the signed-in user, or null if closed.
Future<UserModel?> showEmailAuthSheet(BuildContext context, {required bool register}) {
  return showModalBottomSheet<UserModel>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _EmailAuthSheet(register: register),
  );
}

/// After any sign-in: questionnaire for new users, dashboard for the rest.
void goAfterSignIn(BuildContext context, UserModel user) {
  final next = user.hasCompletedOnboarding ? const DashboardScreen() : const QuestionnaireScreen();
  Navigator.of(context).pushAndRemoveUntil(
    PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (_, __, ___) => next,
      transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
    ),
    (_) => false,
  );
}

class _EmailAuthSheet extends StatefulWidget {
  const _EmailAuthSheet({required this.register});
  final bool register;

  @override
  State<_EmailAuthSheet> createState() => _EmailAuthSheetState();
}

class _EmailAuthSheetState extends State<_EmailAuthSheet> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _pass = TextEditingController();
  late bool _register = widget.register;
  bool _busy = false;
  bool _hide = true;
  String? _error;

  static const _green = Color(0xFF22C55E);
  static const _ink = Color(0xFF141518);

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _pass]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !(_form.currentState?.validate() ?? false)) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _busy = true;
      _error = null;
    });
    final svc = UserBackendService.instance;
    try {
      final user = _register
          ? await svc.registerWithEmailPassword(_name.text.trim(), _email.text.trim(), _pass.text, phone: _phone.text.trim())
          : await svc.signInWithEmailPassword(_email.text.trim(), _pass.text);
      if (!mounted) return;
      if (user == null) {
        setState(() => _error = svc.lastError ?? 'Something went wrong. Try again.');
      } else {
        Navigator.of(context).pop(user);
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  InputDecoration _deco(String label, IconData icon, {Widget? suffix}) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: const Color(0xFF6B7280)),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        labelStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF6B7280), fontSize: 13.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _green, width: 1.4)),
      );

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.plusJakartaSans(fontSize: 14, color: _ink, fontWeight: FontWeight.w600);
    final bottom = MediaQuery.viewInsetsOf(context).bottom + MediaQuery.paddingOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(22, 12, 22, 20 + bottom),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 18),
            Text(_register ? 'Create your account' : 'Sign in with email',
                style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: _ink, letterSpacing: -0.4)),
            const SizedBox(height: 4),
            Text(_register ? 'It takes less than a minute.' : 'Welcome back.',
                style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: const Color(0xFF6B7280))),
            const SizedBox(height: 18),
            if (_register) ...[
              TextFormField(
                controller: _name,
                style: style,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                decoration: _deco('Full name', Icons.person_outline_rounded),
                validator: (v) => (v ?? '').trim().length < 2 ? 'Enter your name' : null,
              ),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: _email,
              style: style,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              decoration: _deco('Email', Icons.mail_outline_rounded),
              validator: (v) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch((v ?? '').trim()) ? null : 'Enter a valid email',
            ),
            if (_register) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                style: style,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.telephoneNumber],
                decoration: _deco('Phone (optional)', Icons.phone_outlined),
                validator: (v) {
                  final d = (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                  return d.isEmpty || (d.length >= 10 && d.length <= 13) ? null : 'Enter a valid phone number';
                },
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: _pass,
              style: style,
              obscureText: _hide,
              textInputAction: TextInputAction.done,
              autofillHints: [_register ? AutofillHints.newPassword : AutofillHints.password],
              onFieldSubmitted: (_) => _submit(),
              decoration: _deco('Password', Icons.lock_outline_rounded,
                  suffix: IconButton(
                    icon: Icon(_hide ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
                    onPressed: () => setState(() => _hide = !_hide),
                  )),
              validator: (v) => (v ?? '').length < (_register ? 8 : 1) ? (_register ? 'Use at least 8 characters' : 'Enter your password') : null,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.redAccent, fontWeight: FontWeight.w600)),
            ],
            const SizedBox(height: 18),
            SizedBox(
              height: 50,
              child: FilledButton(
                onPressed: _busy ? null : _submit,
                style: FilledButton.styleFrom(backgroundColor: _green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))),
                child: _busy
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                    : Text(_register ? 'Create account' : 'Sign in',
                        style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _busy
                  ? null
                  : () => setState(() {
                        _register = !_register;
                        _error = null;
                      }),
              child: Text(_register ? 'Already have an account? Sign in' : 'New here? Create an account',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w700, color: _green)),
            ),
          ]),
        ),
      ),
    );
  }
}
