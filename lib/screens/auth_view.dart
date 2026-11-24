import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/user_backend_service.dart';
import '../widgets/onboarding/onboarding_kit.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';
import 'privacy_policy_screen.dart';
import 'questionnaire_screen.dart';
import 'register_screen.dart';
import 'terms_of_service_screen.dart';

/// Shared sign-in / sign-up view used by [LoginScreen] and [RegisterScreen].
///
/// Phone: an orbiting 3D-object hero on top, the headline and an auth card.
/// Desktop (>= 900px): the hero on the left and the auth card on the right.
class AuthView extends StatefulWidget {
  const AuthView({super.key, required this.isLogin});
  final bool isLogin;

  @override
  State<AuthView> createState() => _AuthViewState();
}

const _orbitAssets = <String>[
  'assets/images/neon_green_dumbbell_1787819274202.jpg',
  'assets/images/neon_orange_kettlebell_1787819340750.jpg',
  'assets/images/neon_green_shoe_1787819288631.jpg',
  'assets/images/neon_orange_heartrate_1787819363247.jpg',
  'assets/images/neon_green_waterbottle_1787819315145.jpg',
  'assets/images/neon_orange_proteinshaker_1787819387813.jpg',
];

class _AuthViewState extends State<AuthView> {
  bool _showEmail = false;
  bool _busy = false;
  bool _obscure = true;
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool get _isLogin => widget.isLogin;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------
  Future<void> _social(String provider) async {
    if (_busy) return;
    HapticFeedback.mediumImpact();
    setState(() => _busy = true);
    UserModel? user;
    try {
      user = await UserBackendService.instance.signInWithRealGoogle();
    } catch (e) {
      debugPrint('$provider sign-in error: $e');
      _toast('$provider sign-in failed. Please try again.', error: true);
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (user != null) _enter(user);
  }

  Future<void> _submitEmail() async {
    if (_busy || !(_formKey.currentState?.validate() ?? false)) return;
    HapticFeedback.mediumImpact();
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    final svc = UserBackendService.instance;
    UserModel? user;
    try {
      user = _isLogin
          ? await svc.signInWithEmailPassword(_email.text.trim(), _password.text)
          : await svc.registerWithEmailPassword(_name.text.trim(), _email.text.trim(), _password.text);
    } catch (e) {
      debugPrint('Email auth error: $e');
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (user == null) {
      _toast('Something went wrong. Please try again.', error: true);
      return;
    }
    _enter(user);
  }

  void _enter(UserModel user) {
    _toast('Welcome, ${user.name}!');
    final next = user.hasCompletedOnboarding ? const DashboardScreen() : const QuestionnaireScreen();
    Navigator.of(context).pushReplacement(_fade(next));
  }

  void _switchMode() {
    HapticFeedback.selectionClick();
    Navigator.of(context)
        .pushReplacement(_fade(_isLogin ? const RegisterScreen() : const LoginScreen()));
  }

  PageRouteBuilder<void> _fade(Widget page) => PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (context, a, b) => page,
        transitionsBuilder: (context, a, b, child) => FadeTransition(opacity: a, child: child),
      );

  void _toast(String text, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: OnbColors.ink,
        duration: const Duration(milliseconds: 1600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Row(
          children: [
            Icon(error ? Icons.error_rounded : Icons.check_circle_rounded,
                color: error ? const Color(0xFFF87171) : const Color(0xFF4ADE80), size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: onbFont(size: 13.5, weight: FontWeight.w700, color: Colors.white))),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Layout
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OnbColors.base,
      resizeToAvoidBottomInset: true,
      body: AuroraBackground(
        colors: const [Color(0xFF22C55E), OnbColors.lime, Color(0xFF22D3EE)],
        child: SafeArea(
          child: LayoutBuilder(builder: (context, box) {
            return box.maxWidth >= 900 ? _wide(box) : _phone(box);
          }),
        ),
      ),
    );
  }

  Widget _phone(BoxConstraints box) {
    final heroH = (box.maxHeight * 0.36).clamp(220.0, 340.0);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: box.maxWidth < 380 ? 16 : 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              _topBar(),
              SizedBox(height: heroH, child: const _OrbitHero()),
              const SizedBox(height: 6),
              _headline(phone: true),
              const SizedBox(height: 20),
              Reveal(delay: const Duration(milliseconds: 320), child: _card()),
              const SizedBox(height: 18),
              _legal(),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _wide(BoxConstraints box) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 20, 40, 20),
      child: Column(
        children: [
          _topBar(),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 6,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _OrbitHero(large: box.maxHeight > 700)),
                      _headline(phone: false),
                      SizedBox(height: box.maxHeight * 0.06),
                    ],
                  ),
                ),
                const SizedBox(width: 48),
                Expanded(
                  flex: 5,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Reveal(delay: const Duration(milliseconds: 250), child: _card(showTitle: true)),
                            const SizedBox(height: 18),
                            _legal(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _topBar() {
    final canPop = Navigator.of(context).canPop();
    return Row(
      children: [
        if (canPop) ...[
          RoundIconButton(icon: Icons.arrow_back_ios_new_rounded, onTap: () => Navigator.of(context).pop(), size: 42),
          const SizedBox(width: 12),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: Image.asset('assets/images/app_logo.png', width: 36, height: 36, fit: BoxFit.cover),
        ),
        const SizedBox(width: 10),
        Text('NeuroFit', style: onbFont(size: 18, weight: FontWeight.w800, spacing: -0.3)),
        const Spacer(),
        _TextLink(label: _isLogin ? 'Create account' : 'Sign in', onTap: _switchMode),
      ],
    );
  }

  Widget _headline({required bool phone}) {
    final size = phone ? 32.0 : 50.0;
    final style = onbFont(size: size, weight: FontWeight.w800, height: 1.08, spacing: phone ? -1 : -1.8);
    final lead = _isLogin ? 'Welcome back,' : 'Train smarter.';
    final accent = _isLogin ? "let's keep moving." : 'Live stronger.';
    final sub = _isLogin
        ? 'Pick up your streak, your plan and your progress right where you left them.'
        : 'Workouts, nutrition and mindfulness in one place, built around you.';
    return Column(
      crossAxisAlignment: phone ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Reveal(delay: const Duration(milliseconds: 120), child: Text(lead, style: style, textAlign: TextAlign.center)),
        Reveal(
          delay: const Duration(milliseconds: 200),
          child: GradientText(accent, style: style, colors: const [Color(0xFF16A34A), Color(0xFF65A30D), Color(0xFF0891B2)]),
        ),
        const SizedBox(height: 10),
        Reveal(
          delay: const Duration(milliseconds: 260),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Text(sub,
                textAlign: phone ? TextAlign.center : TextAlign.start,
                style: onbFont(size: phone ? 14.5 : 17, color: OnbColors.body, height: 1.5)),
          ),
        ),
        if (!phone) ...[
          const SizedBox(height: 22),
          Reveal(
            delay: const Duration(milliseconds: 340),
            child: const Wrap(spacing: 10, runSpacing: 10, children: [
              _StatPill(icon: Icons.fitness_center_rounded, text: '1,300+ exercises'),
              _StatPill(icon: Icons.restaurant_rounded, text: 'Smart meal plans'),
              _StatPill(icon: Icons.self_improvement_rounded, text: 'Mind & sleep'),
            ]),
          ),
        ],
      ],
    );
  }

  Widget _card({bool showTitle = false}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(color: const Color(0xFF16A34A).withValues(alpha: 0.10), blurRadius: 50, offset: const Offset(0, 22)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showTitle) ...[
            Text(_isLogin ? 'Sign in' : 'Create your account', style: onbFont(size: 22, weight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(_isLogin ? 'Good to see you again.' : 'It takes less than a minute.',
                style: onbFont(size: 14, color: OnbColors.body)),
            const SizedBox(height: 18),
          ],
          _SocialButton(
            label: 'Continue with Google',
            icon: const SizedBox(width: 22, height: 22, child: CustomPaint(painter: _GoogleG())),
            dark: false,
            onTap: _busy ? null : () => _social('Google'),
          ),
          const SizedBox(height: 12),
          _SocialButton(
            label: 'Continue with Apple',
            icon: const Icon(Icons.apple, color: Colors.white, size: 24),
            dark: true,
            onTap: _busy ? null : () => _social('Apple'),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(child: Divider(color: OnbColors.line)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('or', style: onbFont(size: 13, color: OnbColors.muted, weight: FontWeight.w600)),
              ),
              const Expanded(child: Divider(color: OnbColors.line)),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedSize(
            duration: const Duration(milliseconds: 380),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _showEmail ? _emailForm() : _emailButton(),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text.rich(
              TextSpan(
                text: _isLogin ? 'New to NeuroFit? ' : 'Already have an account? ',
                style: onbFont(size: 13.5, color: OnbColors.body),
                children: [
                  TextSpan(
                    text: _isLogin ? 'Create account' : 'Sign in',
                    style: onbFont(size: 13.5, weight: FontWeight.w800, color: OnbColors.green),
                    recognizer: TapGestureRecognizer()..onTap = _switchMode,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emailButton() {
    return _SocialButton(
      key: const ValueKey('email-btn'),
      label: 'Continue with email',
      icon: const Icon(Icons.mail_rounded, color: OnbColors.green, size: 22),
      dark: false,
      outlined: true,
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _showEmail = true);
      },
    );
  }

  Widget _emailForm() {
    return Form(
      key: _formKey,
      child: Column(
        key: const ValueKey('email-form'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!_isLogin) ...[
            _Field(
              controller: _name,
              hint: 'Full name',
              icon: Icons.person_rounded,
              action: TextInputAction.next,
              validator: (v) => (v ?? '').trim().isEmpty ? 'Please enter your name' : null,
            ),
            const SizedBox(height: 12),
          ],
          _Field(
            controller: _email,
            hint: 'Email address',
            icon: Icons.alternate_email_rounded,
            keyboard: TextInputType.emailAddress,
            action: TextInputAction.next,
            validator: (v) {
              final s = (v ?? '').trim();
              return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s) ? null : 'Enter a valid email';
            },
          ),
          const SizedBox(height: 12),
          _Field(
            controller: _password,
            hint: 'Password',
            icon: Icons.lock_rounded,
            obscure: _obscure,
            action: TextInputAction.done,
            onSubmitted: (_) => _submitEmail(),
            suffix: IconButton(
              tooltip: _obscure ? 'Show password' : 'Hide password',
              icon: Icon(_obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                  color: OnbColors.muted, size: 20),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
            validator: (v) => (v ?? '').length < 6 ? 'At least 6 characters' : null,
          ),
          if (_isLogin)
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _TextLink(
                  label: 'Forgot password?',
                  small: true,
                  onTap: () => _toast('Password reset is not available in the demo.'),
                ),
              ),
            ),
          const SizedBox(height: 16),
          GlowButton(
            label: _isLogin ? 'Sign in' : 'Create account',
            color: OnbColors.green,
            loading: _busy,
            height: 54,
            onTap: _submitEmail,
          ),
        ],
      ),
    );
  }

  Widget _legal() {
    final link = onbFont(size: 12, weight: FontWeight.w700, color: OnbColors.ink);
    return Text.rich(
      TextSpan(
        text: 'By continuing you agree to our ',
        style: onbFont(size: 12, color: OnbColors.muted, height: 1.5),
        children: [
          TextSpan(
            text: 'Terms of Service',
            style: link,
            recognizer: TapGestureRecognizer()
              ..onTap = () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TermsOfServiceScreen())),
          ),
          const TextSpan(text: ' and '),
          TextSpan(
            text: 'Privacy Policy',
            style: link,
            recognizer: TapGestureRecognizer()
              ..onTap = () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
          ),
          const TextSpan(text: '.'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

// =============================================================================
// Hero: a glowing logo core with 3D objects orbiting in a tilted ellipse.
// =============================================================================
class _OrbitHero extends StatefulWidget {
  const _OrbitHero({this.large = false});
  final bool large;

  @override
  State<_OrbitHero> createState() => _OrbitHeroState();
}

class _OrbitHeroState extends State<_OrbitHero> with TickerProviderStateMixin {
  late final AnimationController _orbit =
      AnimationController(vsync: this, duration: const Duration(seconds: 26))..repeat();
  late final AnimationController _intro =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..forward();

  @override
  void dispose() {
    _orbit.dispose();
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth;
      final h = box.maxHeight;
      final core = math.min(w, h) * 0.34;
      final rx = math.min(w * 0.42, h * 0.95);
      final ry = h * 0.30;
      final tileBase = math.min(w, h) * 0.2;
      return RepaintBoundary(
        child: AnimatedBuilder(
          animation: Listenable.merge([_orbit, _intro]),
          builder: (context, _) {
            final intro = Curves.easeOutBack.transform(_intro.value.clamp(0.0, 1.0));
            final center = Offset(w / 2, h / 2);
            final items = <(double, Widget)>[];
            for (var i = 0; i < _orbitAssets.length; i++) {
              final a = _orbit.value * 2 * math.pi + i * 2 * math.pi / _orbitAssets.length;
              final depth = (math.sin(a) + 1) / 2; // 0 = back, 1 = front
              final size = tileBase * (0.62 + 0.5 * depth) * intro;
              final pos = center + Offset(math.cos(a) * rx * intro, math.sin(a) * ry * intro);
              items.add((
                depth,
                Positioned(
                  left: pos.dx - size / 2,
                  top: pos.dy - size / 2,
                  child: Opacity(
                    opacity: (0.55 + 0.45 * depth).clamp(0.0, 1.0),
                    child: Transform.rotate(
                      angle: math.sin(a * 2) * 0.12,
                      child: Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(size * 0.28),
                          image: DecorationImage(image: AssetImage(_orbitAssets[i]), fit: BoxFit.cover),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08 + 0.12 * depth),
                              blurRadius: size * 0.35,
                              offset: Offset(0, size * 0.14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ));
            }
            items.sort((x, y) => x.$1.compareTo(y.$1));
            final back = items.where((e) => e.$1 < 0.5).map((e) => e.$2);
            final front = items.where((e) => e.$1 >= 0.5).map((e) => e.$2);
            final pulse = 1 + 0.04 * math.sin(_orbit.value * 2 * math.pi * 6);

            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: _OrbitPainter(rx * intro, ry * intro, _orbit.value)),
                ),
                ...back,
                Positioned(
                  left: center.dx - core / 2,
                  top: center.dy - core / 2,
                  child: Transform.scale(
                    scale: intro * pulse,
                    child: Container(
                      width: core,
                      height: core,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(colors: [Color(0xFF22C55E), Color(0xFF14532D)]),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF22C55E).withValues(alpha: 0.45), blurRadius: core * 0.5),
                        ],
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      padding: EdgeInsets.all(core * 0.16),
                      child: ClipOval(child: Image.asset('assets/images/app_logo.png', fit: BoxFit.cover)),
                    ),
                  ),
                ),
                ...front,
                if (w > 300) ...[
                  Positioned(
                    left: w * 0.02,
                    top: h * 0.06,
                    child: Opacity(
                      opacity: _intro.value,
                      child: _Bob(phase: 0, child: const _StatPill(icon: Icons.local_fire_department_rounded, text: '520 kcal', color: Color(0xFFEA580C))),
                    ),
                  ),
                  Positioned(
                    right: w * 0.02,
                    bottom: h * 0.06,
                    child: Opacity(
                      opacity: _intro.value,
                      child: _Bob(phase: 2, child: const _StatPill(icon: Icons.favorite_rounded, text: '128 bpm', color: Color(0xFFE11D48))),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      );
    });
  }
}

class _OrbitPainter extends CustomPainter {
  _OrbitPainter(this.rx, this.ry, this.t);
  final double rx;
  final double ry;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final rect = Rect.fromCenter(center: c, width: rx * 2, height: ry * 2);
    // Dashed orbit
    final p = Paint()
      ..color = const Color(0xFF16A34A).withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    const dashes = 60;
    for (var i = 0; i < dashes; i++) {
      final start = (i / dashes) * 2 * math.pi + t * 2 * math.pi * 0.25;
      canvas.drawArc(rect, start, math.pi / dashes, false, p);
    }
    // Inner glow rings
    for (var i = 1; i <= 3; i++) {
      canvas.drawOval(
        Rect.fromCenter(center: c, width: rx * 2 * (0.35 + i * 0.12), height: ry * 2 * (0.35 + i * 0.12)),
        Paint()
          ..color = const Color(0xFF84CC16).withValues(alpha: 0.05 * (4 - i))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(_OrbitPainter old) => old.t != t || old.rx != rx || old.ry != ry;
}

class _Bob extends StatefulWidget {
  const _Bob({required this.child, this.phase = 0});
  final Widget child;
  final double phase;

  @override
  State<_Bob> createState() => _BobState();
}

class _BobState extends State<_Bob> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 3200))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, math.sin(_c.value * 2 * math.pi + widget.phase) * 6),
        child: child,
      ),
    );
  }
}

// =============================================================================
// Small pieces
// =============================================================================
class _StatPill extends StatelessWidget {
  const _StatPill({required this.icon, required this.text, this.color = OnbColors.green});
  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 8),
          Text(text, style: onbFont(size: 13, weight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _SocialButton extends StatefulWidget {
  const _SocialButton({
    super.key,
    required this.label,
    required this.icon,
    required this.dark,
    required this.onTap,
    this.outlined = false,
  });

  final String label;
  final Widget icon;
  final bool dark;
  final bool outlined;
  final VoidCallback? onTap;

  @override
  State<_SocialButton> createState() => _SocialButtonState();
}

class _SocialButtonState extends State<_SocialButton> {
  bool _hover = false;
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final dark = widget.dark;
    final bg = dark ? OnbColors.ink : Colors.white;
    return Semantics(
      button: true,
      label: widget.label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _down = true),
          onTapCancel: () => setState(() => _down = false),
          onTapUp: (_) => setState(() => _down = false),
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _down ? 0.97 : 1,
            duration: const Duration(milliseconds: 120),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              height: 54,
              transform: Matrix4.translationValues(0, _hover ? -2 : 0, 0),
              decoration: BoxDecoration(
                color: widget.outlined ? OnbColors.green.withValues(alpha: _hover ? 0.10 : 0.06) : bg,
                borderRadius: BorderRadius.circular(27),
                border: Border.all(
                  color: widget.outlined
                      ? OnbColors.green.withValues(alpha: 0.45)
                      : (dark ? OnbColors.ink : OnbColors.line),
                  width: 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: _hover ? 0.12 : 0.05),
                    blurRadius: _hover ? 20 : 10,
                    offset: Offset(0, _hover ? 10 : 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  widget.icon,
                  const SizedBox(width: 12),
                  Text(
                    widget.label,
                    style: onbFont(
                      size: 15,
                      weight: FontWeight.w700,
                      color: dark ? Colors.white : (widget.outlined ? OnbColors.green : OnbColors.ink),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hint,
    required this.icon,
    this.validator,
    this.keyboard,
    this.obscure = false,
    this.suffix,
    this.action,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final String? Function(String?)? validator;
  final TextInputType? keyboard;
  final bool obscure;
  final Widget? suffix;
  final TextInputAction? action;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color c, [double w = 1.3]) =>
        OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: c, width: w));
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboard,
      obscureText: obscure,
      textInputAction: action,
      onFieldSubmitted: onSubmitted,
      style: onbFont(size: 15, weight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: onbFont(size: 15, color: OnbColors.muted),
        prefixIcon: Icon(icon, color: OnbColors.muted, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: border(OnbColors.line),
        focusedBorder: border(OnbColors.green, 2),
        errorBorder: border(const Color(0xFFF87171)),
        focusedErrorBorder: border(const Color(0xFFEF4444), 2),
        errorStyle: onbFont(size: 12, color: const Color(0xFFDC2626), weight: FontWeight.w600),
      ),
    );
  }
}

class _TextLink extends StatelessWidget {
  const _TextLink({required this.label, required this.onTap, this.small = false});
  final String label;
  final VoidCallback onTap;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: OnbColors.green,
        padding: EdgeInsets.symmetric(horizontal: small ? 4 : 14, vertical: small ? 4 : 10),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: const StadiumBorder(),
        backgroundColor: small ? null : Colors.white.withValues(alpha: 0.7),
      ),
      child: Text(label, style: onbFont(size: small ? 13 : 13.5, weight: FontWeight.w800, color: OnbColors.green)),
    );
  }
}

/// Four-colour "G" mark.
class _GoogleG extends CustomPainter {
  const _GoogleG();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final c = size.center(Offset.zero);
    final stroke = s * 0.2;
    final r = s / 2 - stroke / 2;
    final rect = Rect.fromCircle(center: c, radius: r);
    Paint p(int color) => Paint()
      ..color = Color(color)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawArc(rect, -0.25 * math.pi, -0.55 * math.pi, false, p(0xFFEA4335)); // red, top
    canvas.drawArc(rect, -0.8 * math.pi, -0.45 * math.pi, false, p(0xFFFBBC05)); // yellow, left
    canvas.drawArc(rect, 0.75 * math.pi, -0.6 * math.pi, false, p(0xFF34A853)); // green, bottom
    canvas.drawArc(rect, 0.15 * math.pi, -0.15 * math.pi, false, p(0xFF4285F4)); // blue, right
    canvas.drawRect(
      Rect.fromLTWH(c.dx, c.dy - stroke / 2, r + stroke / 2, stroke),
      Paint()..color = const Color(0xFF4285F4),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
