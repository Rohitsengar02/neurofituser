import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../shop/shop_ui.dart';
import '../widgets/apple_kit.dart';
import '../widgets/liquid_glass.dart';
import 'panel_data.dart';
import 'trainer_data.dart';
import '../backend/me.dart';

// Become-a-coach onboarding: a dark aurora with floating fitness objects and
// liquid glass cards. Seven steps (welcome, profile, specialties,
// experience, pricing, bio and review, done). Finishing registers the coach
// and switches the app into the trainer panel.

const pViolet = Color(0xFF8B5CF6);
const pPink = Color(0xFFEC4899);
const pBlue = Color(0xFF38BDF8);
const pNight = Color(0xFF0B0A1A);

const panelIcons = [
  Icons.fitness_center_rounded,
  Icons.sports_gymnastics_rounded,
  Icons.timer_rounded,
  Icons.favorite_rounded,
  Icons.bolt_rounded,
  Icons.self_improvement_rounded,
  Icons.directions_run_rounded,
  Icons.sports_martial_arts_rounded,
];

/// Opens the trainer panel: straight in when already registered, otherwise
/// the onboarding.
void openTrainerPanel(BuildContext context) {
  final s = PanelStore.I;
  if (s.registered) {
    s.enterPanel();
    Navigator.of(context).popUntil((r) => r.isFirst);
    return;
  }
  Navigator.of(context).push(PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 520),
    reverseTransitionDuration: const Duration(milliseconds: 360),
    pageBuilder: (_, _, _) => const PanelOnboarding(),
    transitionsBuilder: (_, a, _, child) {
      final c = CurvedAnimation(parent: a, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: c,
        child: ScaleTransition(scale: Tween(begin: 1.06, end: 1.0).animate(c), child: child),
      );
    },
  ));
}

/// Dark glass surface for the onboarding and panel hero cards.
class DarkGlass extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final bool selected;
  final Color accent;
  const DarkGlass({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 26,
    this.onTap,
    this.selected = false,
    this.accent = pViolet,
  });

  @override
  Widget build(BuildContext context) => LiquidGlass(
        style: LiquidGlassStyle.clear,
        borderRadius: BorderRadius.circular(radius),
        shadow: false,
        onTap: onTap,
        colors: selected
            ? [accent.withValues(alpha: 0.55), accent.withValues(alpha: 0.28)]
            : [Colors.white.withValues(alpha: 0.14), Colors.white.withValues(alpha: 0.05)],
        padding: padding,
        child: child,
      );
}

TextStyle _w(double s, {FontWeight w = FontWeight.w700, double a = 1, double? h, double? ls}) =>
    akT(s, w: w, c: Colors.white.withValues(alpha: a), h: h, ls: ls);

class PanelOnboarding extends StatefulWidget {
  const PanelOnboarding({super.key});
  @override
  State<PanelOnboarding> createState() => _PanelOnboardingState();
}

class _PanelOnboardingState extends State<PanelOnboarding> {
  final _pc = PageController();
  int step = 0;
  static const steps = 7;

  final _name = TextEditingController(text: Me.name);
  final _headline = TextEditingController();
  final _city = TextEditingController();
  final _bio = TextEditingController();
  final _cert = TextEditingController();
  String? photo;
  final spec = <String>{'Strength', 'Fat loss'};
  String mode = 'Online';
  double years = 3;
  final certs = <String>[];
  final prices = [1499.0, 3899.0, 12999.0];
  final on = [true, true, true];
  bool agree = false;
  bool busy = false;

  @override
  void dispose() {
    for (final c in [_name, _headline, _city, _bio, _cert]) {
      c.dispose();
    }
    _pc.dispose();
    super.dispose();
  }

  String? get _block => switch (step) {
        1 => _name.text.trim().length < 2
            ? 'Add your name'
            : _headline.text.trim().isEmpty
                ? 'Add a short headline'
                : null,
        2 => spec.isEmpty ? 'Pick at least one specialty' : null,
        4 => !on.contains(true) ? 'Turn on at least one plan' : null,
        5 => _bio.text.trim().length < 20
            ? 'Write a bio of at least 20 characters'
            : !agree
                ? 'Accept the coach terms to continue'
                : null,
        _ => null,
      };

  void _go(int to) {
    FocusScope.of(context).unfocus();
    setState(() => step = to);
    _pc.animateToPage(to, duration: const Duration(milliseconds: 560), curve: Curves.easeOutCubic);
  }

  Future<void> _next() async {
    final b = _block;
    if (b != null) {
      HapticFeedback.heavyImpact();
      shopToast(context, b, icon: Icons.info_rounded);
      return;
    }
    HapticFeedback.mediumImpact();
    if (step == 5) {
      setState(() => busy = true);
      await Future.delayed(const Duration(milliseconds: 1100));
      if (!mounted) return;
      setState(() => busy = false);
    }
    if (step == steps - 1) {
      _finish();
      return;
    }
    _go(step + 1);
  }

  void _finish() {
    const names = ['Monthly', 'Quarterly', 'Yearly'];
    const months = [1, 3, 12];
    const perks = [
      ['Custom workout plan', 'Weekly check-in', 'Chat support'],
      ['Everything in Monthly', 'Diet plan', '2 video calls a month'],
      ['Everything in Quarterly', 'Priority replies', 'Live classes free'],
    ];
    final seeded = {for (final p in PanelStore.I.plans) p.name: p.subs};
    PanelStore.I.register(
      name: _name.text.trim(),
      headline: _headline.text.trim(),
      bio: _bio.text.trim(),
      city: _city.text.trim(),
      mode: mode,
      years: years.round(),
      specialties: spec.toList(),
      certs: certs,
      photo: photo,
      plans: [
        for (var i = 0; i < 3; i++)
          if (on[i]) PPlan(names[i], months[i], (prices[i] / 50).round() * 50, seeded[names[i]] ?? 0, true, perks[i]),
      ],
    );
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  Future<void> _pickPhoto() async {
    try {
      final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 600, imageQuality: 80);
      if (x == null) return;
      final b = await x.readAsBytes();
      setState(() => photo = base64Encode(b));
    } catch (_) {
      if (mounted) shopToast(context, 'Could not open your photos', icon: Icons.error_rounded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    return Scaffold(
      backgroundColor: pNight,
      resizeToAvoidBottomInset: true,
      body: Stack(children: [
        const Positioned.fill(
          child: ShopBackdrop(tint: pViolet, tint2: pPink, icons: panelIcons, base: pNight, bubble: Color(0x14FFFFFF)),
        ),
        // Aurora ribbons.
        const Positioned.fill(child: IgnorePointer(child: _Aurora())),
        Column(children: [
          SizedBox(height: pad.top + 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(children: [
              _GlassBtn(
                icon: step == 0 ? Icons.close_rounded : Icons.arrow_back_ios_new_rounded,
                onTap: () => step == 0 || step == steps - 1 ? Navigator.pop(context) : _go(step - 1),
              ),
              const SizedBox(width: 14),
              Expanded(child: _Progress(step: step, total: steps)),
              const SizedBox(width: 14),
              SizedBox(
                width: 44,
                child: Text('${step + 1}/$steps', textAlign: TextAlign.right, style: _w(13, a: 0.7)),
              ),
            ]),
          ),
          Expanded(
            child: PageView(
              controller: _pc,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _welcome(),
                _profile(),
                _specialties(),
                _experience(),
                _pricing(),
                _review(),
                _done(),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 16 + pad.bottom),
            child: _CTA(
              label: switch (step) {
                0 => 'Get started',
                5 => 'Create my coach profile',
                6 => 'Open trainer panel',
                _ => 'Continue',
              },
              busy: busy,
              onTap: _next,
            ),
          ),
        ]),
      ]),
    );
  }

  // ---------------- steps ----------------

  Widget _scroll(List<Widget> c) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        physics: const BouncingScrollPhysics(),
        children: [for (var i = 0; i < c.length; i++) Rise(delay: 60 * i, child: c[i])],
      );

  Widget _title(String cap, String a, String b, String sub) => Padding(
        padding: const EdgeInsets.only(bottom: 22),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(cap, style: _w(11.5, w: FontWeight.w800, a: 0.55, ls: 1.5)),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(children: [
              TextSpan(text: '$a '),
              WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: ShaderMask(
                  shaderCallback: (r) => const LinearGradient(colors: [Color(0xFFC4B5FD), pPink, Color(0xFFFDBA74)]).createShader(r),
                  child: Text(b, style: _w(34, w: FontWeight.w800, ls: -1.3, h: 1.08)),
                ),
              ),
            ]),
            style: _w(34, w: FontWeight.w800, ls: -1.3, h: 1.08),
          ),
          const SizedBox(height: 10),
          Text(sub, style: _w(15, w: FontWeight.w500, a: 0.68, h: 1.4)),
        ]),
      );

  Widget _welcome() => _scroll([
        const Center(child: _Orb()),
        const SizedBox(height: 18),
        _title('NEUROFIT FOR COACHES', 'Coach on', 'NeuroFit',
            'Sell plans, go live and manage every client from one beautiful panel.'),
        for (final (i, t, s, c) in const [
          (Icons.workspace_premium_rounded, 'Sell subscriptions', 'Monthly, quarterly and yearly plans', Color(0xFFFBBF24)),
          (Icons.sensors_rounded, 'Go live', 'Stream classes to all your clients', pPink),
          (Icons.groups_rounded, 'Manage clients', 'Progress, chat, check-ins and diets', pBlue),
          (Icons.account_balance_wallet_rounded, 'Get paid weekly', 'Payouts straight to your bank', Color(0xFF34D399)),
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: DarkGlass(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(colors: [c, c.withValues(alpha: 0.6)]),
                    boxShadow: [BoxShadow(color: c.withValues(alpha: 0.4), blurRadius: 14)],
                  ),
                  child: Icon(i, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(t, style: _w(15.5, w: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(s, style: _w(12.5, w: FontWeight.w500, a: 0.6)),
                  ]),
                ),
              ]),
            ),
          ),
        const SizedBox(height: 6),
        Row(children: [
          for (final (v, l) in const [('12K+', 'coaches'), ('4.8★', 'avg rating'), ('₹48K', 'avg monthly')])
            Expanded(
              child: Column(children: [
                Text(v, style: akN(22, c: Colors.white)),
                const SizedBox(height: 4),
                Text(l, style: _w(11.5, w: FontWeight.w600, a: 0.55)),
              ]),
            ),
        ]),
      ]);

  Widget _profile() => _scroll([
        _title('STEP 1 · PROFILE', 'Introduce', 'yourself', 'This is what clients see first.'),
        Center(
          child: AkPress(
            onTap: _pickPhoto,
            child: Stack(clipBehavior: Clip.none, children: [
              Container(
                width: 112,
                height: 112,
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(colors: [pViolet, pPink, Color(0xFFFDBA74), pBlue, pViolet]),
                ),
                child: ClipOval(
                  child: photo != null
                      ? Image.memory(base64Decode(photo!), fit: BoxFit.cover)
                      : Container(
                          color: const Color(0xFF1E1B3A),
                          child: Center(child: Text(_initials(_name.text), style: akN(34, c: Colors.white))),
                        ),
                ),
              ),
              Positioned(
                right: -2,
                bottom: 4,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10)],
                  ),
                  child: const Icon(Icons.photo_camera_rounded, size: 18, color: pViolet),
                ),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 8),
        Center(child: Text(photo == null ? 'Add a profile photo' : 'Tap to change photo', style: _w(12.5, a: 0.6))),
        const SizedBox(height: 22),
        GlassField(label: 'Full name', controller: _name, icon: Icons.person_rounded, onChanged: (_) => setState(() {})),
        GlassField(label: 'Headline', controller: _headline, icon: Icons.short_text_rounded, hint: 'e.g. Yoga and mobility coach'),
        GlassField(label: 'City', controller: _city, icon: Icons.location_on_rounded),
      ]);

  Widget _specialties() => _scroll([
        _title('STEP 2 · EXPERTISE', 'What do you', 'coach?', 'Pick up to 5. We use these to match you with clients.'),
        Wrap(spacing: 10, runSpacing: 10, children: [
          for (final s in specialtyOptions)
            _Chip(
              label: s,
              on: spec.contains(s),
              onTap: () => setState(() {
                if (spec.contains(s)) {
                  spec.remove(s);
                } else if (spec.length < 5) {
                  spec.add(s);
                } else {
                  shopToast(context, 'You can pick up to 5', icon: Icons.info_rounded);
                }
              }),
            ),
        ]),
        const SizedBox(height: 28),
        Text('HOW DO YOU TRAIN?', style: _w(11.5, w: FontWeight.w800, a: 0.55, ls: 1.3)),
        const SizedBox(height: 12),
        Row(children: [
          for (final (m, i) in const [
            ('Online', Icons.videocam_rounded),
            ('In person', Icons.place_rounded),
            ('Both', Icons.all_inclusive_rounded),
          ])
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: DarkGlass(
                  selected: mode == m,
                  onTap: () => setState(() => mode = m),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(children: [
                    Icon(i, color: Colors.white, size: 24),
                    const SizedBox(height: 6),
                    Text(m, style: _w(13, w: FontWeight.w800)),
                  ]),
                ),
              ),
            ),
        ]),
      ]);

  Widget _experience() => _scroll([
        _title('STEP 3 · EXPERIENCE', 'Your', 'credentials', 'Verified coaches get a badge and rank higher.'),
        DarkGlass(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('Years coaching', style: _w(14, w: FontWeight.w700, a: 0.75)),
              const Spacer(),
              Text(years >= 15 ? '15+' : '${years.round()}', style: akN(30, c: Colors.white)),
              Text(' yrs', style: _w(13, a: 0.6)),
            ]),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 6,
                activeTrackColor: pPink,
                inactiveTrackColor: Colors.white24,
                thumbColor: Colors.white,
                overlayColor: pPink.withValues(alpha: 0.2),
              ),
              child: Slider(value: years, min: 0, max: 15, divisions: 15, onChanged: (v) => setState(() => years = v)),
            ),
          ]),
        ),
        const SizedBox(height: 22),
        Text('CERTIFICATIONS', style: _w(11.5, w: FontWeight.w800, a: 0.55, ls: 1.3)),
        const SizedBox(height: 12),
        for (final c in certs)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: DarkGlass(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
              child: Row(children: [
                const Icon(Icons.verified_rounded, color: Color(0xFF34D399), size: 22),
                const SizedBox(width: 12),
                Expanded(child: Text(c, style: _w(14, w: FontWeight.w700))),
                IconButton(
                  onPressed: () => setState(() => certs.remove(c)),
                  icon: Icon(Icons.close_rounded, color: Colors.white.withValues(alpha: 0.6), size: 20),
                ),
              ]),
            ),
          ),
        GlassField(
          label: 'Add a certification',
          controller: _cert,
          icon: Icons.add_rounded,
          onSubmitted: (_) => _addCert(),
          trailing: TextButton(onPressed: _addCert, child: Text('Add', style: _w(14, w: FontWeight.w800))),
        ),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final s in const ['NASM CPT', 'ACSM EP-C', 'RYT 200 Yoga', 'ISSA Nutrition', 'K11 Fitness', 'CrossFit L1'])
            if (!certs.contains(s)) _Chip(label: '+ $s', on: false, small: true, onTap: () => setState(() => certs.add(s))),
        ]),
      ]);

  void _addCert() {
    final t = _cert.text.trim();
    if (t.isEmpty) return;
    setState(() {
      certs.add(t);
      _cert.clear();
    });
  }

  Widget _pricing() {
    const names = ['Monthly', 'Quarterly', 'Yearly'];
    const ranges = [(499.0, 4999.0), (1499.0, 12999.0), (4999.0, 39999.0)];
    final est = on[0] ? prices[0] * 10 : (on[1] ? prices[1] / 3 * 10 : prices[2] / 12 * 10);
    return _scroll([
      _title('STEP 4 · PRICING', 'Set your', 'plans', 'You keep 85%. Change prices any time from the panel.'),
      for (var i = 0; i < 3; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DarkGlass(
            selected: on[i],
            accent: [pViolet, pPink, const Color(0xFFF59E0B)][i],
            padding: const EdgeInsets.fromLTRB(16, 14, 10, 6),
            child: Column(children: [
              Row(children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(names[i], style: _w(16, w: FontWeight.w800)),
                  Text(i == 0 ? 'Billed every month' : i == 1 ? 'Billed every 3 months' : 'Billed once a year',
                      style: _w(12, w: FontWeight.w500, a: 0.6)),
                ]),
                const Spacer(),
                Text('${inr((prices[i] / 50).round() * 50)}', style: akN(24, c: Colors.white)),
                const SizedBox(width: 6),
                Switch.adaptive(
                  value: on[i],
                  activeTrackColor: Colors.white.withValues(alpha: 0.45),
                  onChanged: (v) => setState(() => on[i] = v),
                ),
              ]),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: on[i] ? 1 : 0.35,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    activeTrackColor: Colors.white,
                    inactiveTrackColor: Colors.white24,
                    thumbColor: Colors.white,
                  ),
                  child: Slider(
                    value: prices[i],
                    min: ranges[i].$1,
                    max: ranges[i].$2,
                    onChanged: on[i] ? (v) => setState(() => prices[i] = v) : null,
                  ),
                ),
              ),
            ]),
          ),
        ),
      DarkGlass(
        child: Row(children: [
          const Icon(Icons.trending_up_rounded, color: Color(0xFF34D399), size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(children: [
                const TextSpan(text: 'With 10 clients you could earn about '),
                TextSpan(text: '${inr((est * 0.85).round())}', style: _w(14, w: FontWeight.w800)),
                const TextSpan(text: ' a month.'),
              ]),
              style: _w(13.5, w: FontWeight.w500, a: 0.8, h: 1.4),
            ),
          ),
        ]),
      ),
    ]);
  }

  Widget _review() => _scroll([
        _title('STEP 5 · ABOUT YOU', 'Tell your', 'story', 'A warm, specific bio converts 3× better.'),
        GlassField(label: 'Bio', controller: _bio, icon: Icons.edit_note_rounded, lines: 4, onChanged: (_) => setState(() {})),
        const SizedBox(height: 6),
        Text('PREVIEW', style: _w(11.5, w: FontWeight.w800, a: 0.55, ls: 1.3)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: pViolet.withValues(alpha: 0.35), blurRadius: 30, offset: const Offset(0, 12))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              PanelAvatar(photo: photo, name: _name.text, size: 52),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Flexible(child: Text(_name.text, style: akT(16, w: FontWeight.w800), overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 4),
                    const Icon(Icons.verified_rounded, color: akBlue, size: 16),
                  ]),
                  Text('${_headline.text} · ${_city.text}', style: akT(12, w: FontWeight.w600, c: akMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                ]),
              ),
            ]),
            const SizedBox(height: 10),
            Text(_bio.text, style: akT(13, w: FontWeight.w500, c: const Color(0xFF374151), h: 1.4), maxLines: 3, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 10),
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final s in spec)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: pViolet.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: Text(s, style: akT(11.5, w: FontWeight.w700, c: pViolet)),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(10)),
                child: Text('${years.round()} yrs · $mode', style: akT(11.5, w: FontWeight.w700, c: akMuted)),
              ),
            ]),
            const Divider(height: 22),
            Row(children: [
              Text('From ', style: akT(12.5, w: FontWeight.w600, c: akMuted)),
              Text('${inr((prices[on.indexOf(true) < 0 ? 0 : on.indexOf(true)] / 50).round() * 50)}', style: akN(18)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: akInk, borderRadius: BorderRadius.circular(12)),
                child: Text('Subscribe', style: akT(12.5, w: FontWeight.w800, c: Colors.white)),
              ),
            ]),
          ]),
        ),
        const SizedBox(height: 18),
        GestureDetector(
          onTap: () => setState(() => agree = !agree),
          behavior: HitTestBehavior.opaque,
          child: Row(children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: agree ? pPink : Colors.transparent,
                border: Border.all(color: agree ? pPink : Colors.white54, width: 1.6),
              ),
              child: agree ? const Icon(Icons.check_rounded, size: 16, color: Colors.white) : null,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text('I agree to the NeuroFit coach terms and community guidelines.', style: _w(13, w: FontWeight.w500, a: 0.75, h: 1.35))),
          ]),
        ),
      ]);

  Widget _done() => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: step == 6 ? 0 : 1, end: 1),
              duration: const Duration(milliseconds: 1000),
              curve: akSpring,
              builder: (_, v, _) => Transform.scale(
                scale: 0.4 + 0.6 * v,
                child: Container(
                  width: 132,
                  height: 132,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [pViolet, pPink]),
                    boxShadow: [BoxShadow(color: pPink.withValues(alpha: 0.5 * v.clamp(0, 1)), blurRadius: 50, spreadRadius: 6)],
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 70),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text("You're a NeuroFit coach", textAlign: TextAlign.center, style: _w(28, w: FontWeight.w800, ls: -0.9)),
            const SizedBox(height: 10),
            Text('Your profile is live. Next: share your link, plan your first live class and welcome your clients.',
                textAlign: TextAlign.center, style: _w(15, w: FontWeight.w500, a: 0.68, h: 1.45)),
            const SizedBox(height: 24),
            DarkGlass(
              child: Column(children: [
                for (final (i, t) in const [
                  (Icons.link_rounded, 'Share your coach link'),
                  (Icons.sensors_rounded, 'Schedule your first live class'),
                  (Icons.upload_rounded, 'Upload a starter workout'),
                ])
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Row(children: [
                      Icon(i, color: Colors.white, size: 20),
                      const SizedBox(width: 12),
                      Expanded(child: Text(t, style: _w(14, w: FontWeight.w700))),
                      Icon(Icons.chevron_right_rounded, color: Colors.white.withValues(alpha: 0.5)),
                    ]),
                  ),
              ]),
            ),
          ]),
        ),
      );
}

String _initials(String n) {
  final p = n.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
  if (p.isEmpty) return '?';
  return (p.first[0] + (p.length > 1 ? p.last[0] : '')).toUpperCase();
}

/// Coach photo from onboarding, or initials on a gradient.
class PanelAvatar extends StatelessWidget {
  final String? photo;
  final String name;
  final double size;
  const PanelAvatar({super.key, this.photo, required this.name, this.size = 44});
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(colors: [pViolet, pPink]),
        ),
        clipBehavior: Clip.antiAlias,
        child: photo == null || photo!.isEmpty
            ? Center(child: Text(_initials(name), style: akN(size * 0.36, c: Colors.white)))
            : photo!.startsWith('http')
                ? Image.network(photo!, fit: BoxFit.cover, gaplessPlayback: true,
                    errorBuilder: (_, _, _) => Center(child: Text(_initials(name), style: akN(size * 0.36, c: Colors.white))))
                : Image.memory(base64Decode(photo!), fit: BoxFit.cover, gaplessPlayback: true),
      );
}

class GlassField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final String? hint;
  final int lines;
  final ValueChanged<String>? onChanged, onSubmitted;
  final Widget? trailing;
  final bool dark;
  final TextInputType? keyboard;
  const GlassField({
    super.key,
    required this.label,
    required this.controller,
    required this.icon,
    this.hint,
    this.lines = 1,
    this.onChanged,
    this.onSubmitted,
    this.trailing,
    this.dark = true,
    this.keyboard,
  });

  @override
  Widget build(BuildContext context) {
    final fg = dark ? Colors.white : akInk;
    final field = Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      child: Row(crossAxisAlignment: lines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center, children: [
        Padding(
          padding: EdgeInsets.only(top: lines > 1 ? 18 : 0),
          child: Icon(icon, color: fg.withValues(alpha: 0.6), size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: controller,
            maxLines: lines,
            minLines: lines,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            keyboardType: keyboard,
            cursorColor: dark ? pPink : pViolet,
            style: akT(15, w: FontWeight.w600, c: fg, h: 1.35),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              labelText: label,
              hintText: hint,
              hintStyle: akT(14, w: FontWeight.w500, c: fg.withValues(alpha: 0.35)),
              labelStyle: akT(13, w: FontWeight.w600, c: fg.withValues(alpha: 0.55)),
              floatingLabelStyle: akT(13, w: FontWeight.w700, c: dark ? const Color(0xFFF9A8D4) : pViolet),
            ),
          ),
        ),
        ?trailing,
      ]),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: dark
          ? DarkGlass(padding: EdgeInsets.zero, radius: 20, child: field)
          : Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: field,
            ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool on;
  final bool small;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.on, required this.onTap, this.small = false});
  @override
  Widget build(BuildContext context) => AkPress(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(horizontal: small ? 12 : 16, vertical: small ? 8 : 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: on ? const LinearGradient(colors: [pViolet, pPink]) : null,
            color: on ? null : Colors.white.withValues(alpha: small ? 0.06 : 0.1),
            border: Border.all(color: Colors.white.withValues(alpha: on ? 0.4 : 0.16)),
            boxShadow: on ? [BoxShadow(color: pPink.withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 6))] : null,
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (on) ...[const Icon(Icons.check_rounded, size: 16, color: Colors.white), const SizedBox(width: 5)],
            Text(label, style: _w(small ? 12.5 : 14, w: FontWeight.w700, a: on ? 1 : 0.85)),
          ]),
        ),
      );
}

class _GlassBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GlassBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => LiquidGlass(
        style: LiquidGlassStyle.clear,
        shape: BoxShape.circle,
        shadow: false,
        colors: [Colors.white.withValues(alpha: 0.18), Colors.white.withValues(alpha: 0.06)],
        onTap: onTap,
        child: SizedBox(width: 44, height: 44, child: Icon(icon, color: Colors.white, size: 19)),
      );
}

class _Progress extends StatelessWidget {
  final int step, total;
  const _Progress({required this.step, required this.total});
  @override
  Widget build(BuildContext context) => Row(children: [
        for (var i = 0; i < total; i++)
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeOutCubic,
              height: 5,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                gradient: i <= step ? const LinearGradient(colors: [pViolet, pPink]) : null,
                color: i <= step ? null : Colors.white.withValues(alpha: 0.16),
              ),
            ),
          ),
      ]);
}

class _CTA extends StatelessWidget {
  final String label;
  final bool busy;
  final VoidCallback onTap;
  const _CTA({required this.label, required this.busy, required this.onTap});
  @override
  Widget build(BuildContext context) => AkPress(
        onTap: busy ? null : onTap,
        child: Container(
          height: 58,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: Colors.white,
            boxShadow: [BoxShadow(color: pViolet.withValues(alpha: 0.45), blurRadius: 30, offset: const Offset(0, 10))],
          ),
          child: busy
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.6, color: pViolet))
              : AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(label, key: ValueKey(label), style: akT(16.5, w: FontWeight.w800, c: pNight)),
                ),
        ),
      );
}

/// Glowing glass orb with orbiting fitness glyphs (welcome hero).
class _Orb extends StatefulWidget {
  const _Orb();
  @override
  State<_Orb> createState() => _OrbState();
}

class _OrbState extends State<_Orb> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: SizedBox(
          width: 220,
          height: 190,
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, _) {
              final t = _c.value * 2 * math.pi;
              return Stack(alignment: Alignment.center, children: [
                Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      center: Alignment(-0.35, -0.4),
                      colors: [Color(0xFFF5D0FE), pViolet, Color(0xFF3B0764)],
                      stops: [0, 0.55, 1],
                    ),
                    boxShadow: [
                      BoxShadow(color: pViolet.withValues(alpha: 0.6), blurRadius: 60, spreadRadius: 4),
                      BoxShadow(color: pPink.withValues(alpha: 0.35), blurRadius: 90, spreadRadius: 10),
                    ],
                  ),
                  child: const Icon(Icons.sports_rounded, color: Colors.white, size: 58),
                ),
                for (var i = 0; i < 4; i++)
                  Transform.translate(
                    offset: Offset(math.cos(t + i * math.pi / 2) * 98, math.sin(t + i * math.pi / 2) * 34),
                    child: Transform.scale(
                      scale: 0.8 + 0.25 * math.sin(t + i * math.pi / 2),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.14),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        child: Icon(panelIcons[i * 2], color: Colors.white, size: 19),
                      ),
                    ),
                  ),
              ]);
            },
          ),
        ),
      );
}

/// Two slow aurora ribbons across the top of the onboarding.
class _Aurora extends StatefulWidget {
  const _Aurora();
  @override
  State<_Aurora> createState() => _AuroraState();
}

class _AuroraState extends State<_Aurora> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat(reverse: true);
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, _) {
            final v = Curves.easeInOut.transform(_c.value);
            return Stack(children: [
              Positioned(
                top: -140 + 30 * v,
                left: -100 + 60 * v,
                child: _blob(340, pViolet.withValues(alpha: 0.45)),
              ),
              Positioned(
                top: 120 - 20 * v,
                right: -140 + 40 * v,
                child: _blob(300, pPink.withValues(alpha: 0.28)),
              ),
              Positioned(
                bottom: -120,
                left: 40 - 40 * v,
                child: _blob(320, pBlue.withValues(alpha: 0.18)),
              ),
            ]);
          },
        ),
      );

  Widget _blob(double s, Color c) => Container(
        width: s,
        height: s,
        decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [c, c.withValues(alpha: 0)])),
      );
}
