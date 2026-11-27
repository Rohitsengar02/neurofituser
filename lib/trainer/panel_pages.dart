import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../shop/shop_ui.dart';
import '../widgets/apple_kit.dart';
import '../widgets/liquid_glass.dart';
import 'panel_data.dart';
import 'panel_onboarding.dart';
import 'trainer_data.dart';
import 'trainer_panel.dart';
import '../backend/live_room.dart';

// The coach tools behind the dashboard grid: subscriptions, go live (setup
// and broadcast), upload workout, client detail, schedule, messages,
// analytics, diet plans, reviews and the coach profile.

Widget _page(String title, String caption, Widget body, {List<Widget> actions = const [], Widget? bottom}) => ShopPage(
      title: title,
      caption: caption,
      tint: pViolet,
      icons: panelIcons,
      actions: actions,
      bottom: bottom,
      body: body,
    );

ListView _list(List<Widget> c, {double bottom = 40}) => ListView(
      padding: EdgeInsets.fromLTRB(0, 10, 0, bottom),
      physics: const BouncingScrollPhysics(),
      children: [for (var i = 0; i < c.length; i++) Rise(delay: math.min(i, 8) * 45, child: c[i])],
    );

Widget _label(String t) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
      child: Text(t.toUpperCase(), style: akT(11.5, w: FontWeight.w800, c: akFaint, ls: 1.3)),
    );

Widget _chips(List<String> opts, String sel, ValueChanged<String> on, {Color color = akInk}) => Wrap(spacing: 8, runSpacing: 8, children: [
      for (final o in opts)
        AkPress(
          onTap: () => on(o),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: sel == o ? color : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: sel == o ? color : const Color(0xFFE5E7EB)),
            ),
            child: Text(o, style: akT(13, w: FontWeight.w800, c: sel == o ? Colors.white : akInk)),
          ),
        ),
    ]);

Widget _sheetFrame(BuildContext context, String title, List<Widget> children) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + MediaQuery.paddingOf(context).bottom),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(
              child: Container(width: 40, height: 5, decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(3))),
            ),
            const SizedBox(height: 14),
            Text(title, style: akT(22, w: FontWeight.w800)),
            const SizedBox(height: 14),
            ...children,
          ]),
        ),
      ),
    );

Future<T?> _sheet<T>(BuildContext context, Widget Function(BuildContext, StateSetter) b) => showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(builder: b),
    );

// =====================================================================
//  1. SUBSCRIPTIONS
// =====================================================================

class SubscriptionsPage extends StatelessWidget {
  const SubscriptionsPage({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: PanelStore.I,
        builder: (context, _) {
          final s = PanelStore.I;
          final subs = s.plans.fold<int>(0, (a, p) => a + p.subs);
          final mrr = s.plans.fold<int>(0, (a, p) => a + (p.subs * p.price / p.months).round());
          return _page(
            'Subscriptions',
            '$subs subscribers',
            _list([
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  Expanded(child: Kpi('${inr(mrr)}', 'Monthly recurring', Icons.autorenew_rounded, shopGreen, delta: '+12%')),
                  const SizedBox(width: 10),
                  Expanded(child: Kpi('$subs', 'Subscribers', Icons.groups_rounded, pViolet, delta: '+4')),
                ]),
              ),
              const SizedBox(height: 12),
              ShopCard(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                child: Row(children: [
                  const Icon(Icons.how_to_reg_rounded, color: pViolet),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Accepting new clients', style: akT(14.5, w: FontWeight.w800)),
                      Text(s.acceptingClients ? 'Your Subscribe button is on' : 'Clients can join a waitlist', style: akT(12, w: FontWeight.w600, c: akMuted)),
                    ]),
                  ),
                  Switch.adaptive(value: s.acceptingClients, activeTrackColor: pViolet, onChanged: s.setAccepting),
                ]),
              ),
              _label('Your plans'),
              for (final p in s.plans)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _PlanTile(p),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ShopButton('Add a plan', icon: Icons.add_rounded, outline: true, color: pViolet, onTap: () => editPlan(context, null)),
              ),
              _label('Recent subscribers'),
              for (final c in s.clients.take(4))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ShopCard(
                    padding: const EdgeInsets.all(12),
                    onTap: () => panelPush(context, ClientDetailPage(c)),
                    child: Row(children: [
                      ClientAvatar(c, size: 40),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(c.name, style: akT(14, w: FontWeight.w800)),
                          Text('${c.plan} · joined ${dayName(c.since)}', style: akT(11.5, w: FontWeight.w600, c: akMuted)),
                        ]),
                      ),
                      statusPill(c.status),
                    ]),
                  ),
                ),
            ]),
          );
        },
      );
}

class _PlanTile extends StatelessWidget {
  final PPlan p;
  const _PlanTile(this.p);
  @override
  Widget build(BuildContext context) => ShopCard(
        border: Border.all(color: p.active ? pViolet.withValues(alpha: 0.3) : Colors.white, width: 1.4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.name, style: akT(17, w: FontWeight.w800)),
              Text('${p.months} month${p.months > 1 ? 's' : ''} · ${p.subs} subscribers', style: akT(12, w: FontWeight.w600, c: akMuted)),
            ]),
            const Spacer(),
            Text('${inr(p.price)}', style: akN(24)),
          ]),
          const SizedBox(height: 10),
          for (final k in p.perks)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(children: [
                const Icon(Icons.check_circle_rounded, size: 16, color: pViolet),
                const SizedBox(width: 8),
                Expanded(child: Text(k, style: akT(13, w: FontWeight.w600, c: const Color(0xFF374151)))),
              ]),
            ),
          const SizedBox(height: 8),
          Row(children: [
            Switch.adaptive(value: p.active, activeTrackColor: pViolet, onChanged: (_) => PanelStore.I.togglePlan(p)),
            Text(p.active ? 'Visible' : 'Hidden', style: akT(12.5, w: FontWeight.w700, c: akMuted)),
            const Spacer(),
            TextButton.icon(
              onPressed: () => editPlan(context, p),
              icon: const Icon(Icons.edit_rounded, size: 16, color: pViolet),
              label: Text('Edit', style: akT(13, w: FontWeight.w800, c: pViolet)),
            ),
          ]),
        ]),
      );
}

Future<void> editPlan(BuildContext context, PPlan? p) {
  final name = TextEditingController(text: p?.name ?? 'Starter');
  final perks = TextEditingController(text: (p?.perks ?? ['Custom workout plan', 'Chat support']).join('\n'));
  var price = (p?.price ?? 999).toDouble();
  var months = p?.months ?? 1;
  return _sheet(context, (ctx, set) {
    return _sheetFrame(ctx, p == null ? 'New plan' : 'Edit plan', [
      GlassField(label: 'Plan name', controller: name, icon: Icons.label_rounded, dark: false),
      Text('Length', style: akT(13, w: FontWeight.w700, c: akMuted)),
      const SizedBox(height: 8),
      _chips(const ['1 month', '3 months', '6 months', '12 months'], '$months month${months > 1 ? 's' : ''}', (v) => set(() => months = int.parse(v.split(' ').first)), color: pViolet),
      const SizedBox(height: 16),
      Row(children: [
        Text('Price', style: akT(13, w: FontWeight.w700, c: akMuted)),
        const Spacer(),
        Text('${inr(price.round())}', style: akN(24)),
      ]),
      Slider(value: price, min: 299, max: 39999, divisions: 397, activeColor: pViolet, onChanged: (v) => set(() => price = v)),
      Text('You get ${inr((price * 0.85).round())} after fees', style: akT(12, w: FontWeight.w600, c: shopGreen)),
      const SizedBox(height: 14),
      GlassField(label: 'Perks (one per line)', controller: perks, icon: Icons.checklist_rounded, lines: 3, dark: false),
      Row(children: [
        if (p != null) ...[
          Expanded(
            child: ShopButton('Delete', outline: true, color: shopRed, onTap: () {
              PanelStore.I.removePlan(p);
              Navigator.pop(ctx);
              shopToast(context, 'Plan deleted', icon: Icons.delete_rounded);
            }),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          flex: 2,
          child: ShopButton('Save plan', color: pViolet, onTap: () {
            final ps = perks.text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
            final nm = name.text.trim().isEmpty ? 'Plan' : name.text.trim();
            if (p == null) {
              PanelStore.I.savePlan(PPlan(nm, months, price.round(), 0, true, ps), isNew: true);
            } else {
              p
                ..name = nm
                ..months = months
                ..price = price.round()
                ..perks = ps;
              PanelStore.I.savePlan(p);
            }
            Navigator.pop(ctx);
            shopToast(context, 'Plan saved');
          }),
        ),
      ]),
    ]);
  });
}

// =====================================================================
//  2. GO LIVE
// =====================================================================

class GoLiveSetup extends StatefulWidget {
  final bool inTab;
  const GoLiveSetup({super.key, this.inTab = false});
  @override
  State<GoLiveSetup> createState() => _GoLiveSetupState();
}

class _GoLiveSetupState extends State<GoLiveSetup> {
  final _title = TextEditingController(text: 'Evening HIIT burn');
  String type = 'HIIT';
  String who = 'All clients';
  bool record = true, chat = true, tips = true;
  int? count;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    HapticFeedback.mediumImpact();
    for (var i = 3; i > 0; i--) {
      setState(() => count = i);
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
    }
    setState(() => count = null);
    PanelStore.I.startLive(_title.text.trim().isEmpty ? '$type live' : _title.text.trim());
    await Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (_, _, _) => const BroadcastPage(),
      transitionsBuilder: (_, a, _, c) => FadeTransition(opacity: a, child: c),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PanelStore.I,
      builder: (context, _) {
        final s = PanelStore.I;
        final body = <Widget>[
          // Camera preview.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AspectRatio(
              aspectRatio: 4 / 3.4,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1E1B4B), Color(0xFF4C1D95), Color(0xFF831843)]),
                  boxShadow: [BoxShadow(color: pViolet.withValues(alpha: 0.35), blurRadius: 30, offset: const Offset(0, 14))],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(children: [
                  Center(child: PanelAvatar(photo: s.photo, name: s.name, size: 110)),
                  Positioned(
                    left: 14,
                    top: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(10)),
                      child: Row(children: [
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF34D399), shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text('Camera ready · HD', style: akT(11.5, w: FontWeight.w800, c: Colors.white)),
                      ]),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Column(children: [
                      for (final i in [Icons.cameraswitch_rounded, Icons.mic_rounded, Icons.auto_awesome_rounded])
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), shape: BoxShape.circle),
                          child: Icon(i, color: Colors.white, size: 18),
                        ),
                    ]),
                  ),
                  if (count != null)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black45,
                        alignment: Alignment.center,
                        child: TweenAnimationBuilder<double>(
                          key: ValueKey(count),
                          tween: Tween(begin: 1.8, end: 1),
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOutBack,
                          builder: (_, v, _) => Transform.scale(scale: v, child: Text('$count', style: akN(96, c: Colors.white))),
                        ),
                      ),
                    ),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GlassField(label: 'Class title', controller: _title, icon: Icons.title_rounded, dark: false),
          ),
          _label('Class type'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _chips(const ['HIIT', 'Strength', 'Yoga', 'Mobility', 'Q&A', 'Form check'], type, (v) => setState(() => type = v), color: const Color(0xFFE11D48)),
          ),
          _label('Who can join'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _chips(const ['All clients', 'Yearly only', 'Everyone'], who, (v) => setState(() => who = v)),
          ),
          const SizedBox(height: 14),
          ShopCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Column(children: [
              _toggle(Icons.fiber_smart_record_rounded, 'Save replay to Content', record, (v) => setState(() => record = v)),
              _toggle(Icons.chat_rounded, 'Live chat', chat, (v) => setState(() => chat = v)),
              _toggle(Icons.volunteer_activism_rounded, 'Allow tips', tips, (v) => setState(() => tips = v)),
            ]),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: s.live
                ? ShopButton('Return to your live class', icon: Icons.sensors_rounded, color: const Color(0xFFE11D48), onTap: () => panelPush(context, const BroadcastPage()))
                : ShopButton('Go live now', icon: Icons.sensors_rounded, color: const Color(0xFFE11D48), busy: count != null, onTap: _start),
          ),
          const SizedBox(height: 8),
          Center(child: Text('${s.activeClients} clients will get a notification', style: akT(12, w: FontWeight.w600, c: akMuted))),
        ];
        if (widget.inTab) {
          return PanelTab(caption: s.live ? 'You are live' : 'Stream to your clients', title: 'Go live', children: [const SizedBox(height: 10), ...body]);
        }
        return _page('Go live', 'Stream to your clients', _list(body));
      },
    );
  }

  Widget _toggle(IconData i, String t, bool v, ValueChanged<bool> on) => Row(children: [
        Icon(i, color: akMuted, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(t, style: akT(14, w: FontWeight.w700))),
        Switch.adaptive(value: v, activeTrackColor: const Color(0xFFE11D48), onChanged: on),
      ]);
}

class BroadcastPage extends StatefulWidget {
  const BroadcastPage({super.key});
  @override
  State<BroadcastPage> createState() => _BroadcastPageState();
}

class _BroadcastPageState extends State<BroadcastPage> {
  Timer? _t;
  final room = LiveRoom();
  int peak = 0;
  bool mic = true, cam = true;
  int get viewers => room.viewers;
  int get hearts => room.hearts;
  int get tipsIn => room.tips;
  List<(String, String)> get msgs => room.messages.length > 6 ? room.messages.sublist(room.messages.length - 6) : room.messages;

  @override
  void initState() {
    super.initState();
    room.addListener(_changed);
    // Clock tick for the timer pill.
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    _connect();
  }

  void _changed() {
    if (!mounted) return;
    setState(() => peak = math.max(peak, room.viewers));
    if (room.error != null && !room.connected) shopToast(context, room.error!);
  }

  /// Waits for the session the panel just created, then streams the camera.
  Future<void> _connect() async {
    final s = PanelStore.I;
    for (var i = 0; i < 30 && s.liveToken == null; i++) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
    }
    final id = s.liveId;
    if (id == null) return;
    await room.host(id, url: s.liveUrl, token: s.liveToken);
  }

  @override
  void dispose() {
    _t?.cancel();
    room.removeListener(_changed);
    room.dispose();
    super.dispose();
  }

  Future<void> _end() async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (c) => _sheetFrame(c, 'End live class?', [
        Text('Your replay will be saved to Content.', style: akT(14, w: FontWeight.w600, c: akMuted)),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: ShopButton('Keep going', outline: true, onTap: () => Navigator.pop(c, false))),
          const SizedBox(width: 10),
          Expanded(child: ShopButton('End class', color: const Color(0xFFE11D48), onTap: () => Navigator.pop(c, true))),
        ]),
      ]),
    );
    if (ok != true || !mounted) return;
    final since = PanelStore.I.liveSince;
    final secs = since == null ? 0 : DateTime.now().difference(since).inSeconds;
    PanelStore.I.endLive(viewers: peak, tips: tipsIn);
    unawaited(room.leave());
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (c) => _sheetFrame(c, 'Great class! 🎉', [
        Row(children: [
          Expanded(child: Kpi('${secs ~/ 60}:${(secs % 60).toString().padLeft(2, '0')}', 'Duration', Icons.timer_rounded, pViolet)),
          const SizedBox(width: 8),
          Expanded(child: Kpi('$peak', 'Peak viewers', Icons.visibility_rounded, akBlue)),
          const SizedBox(width: 8),
          Expanded(child: Kpi('₹$tipsIn', 'Tips', Icons.volunteer_activism_rounded, shopGreen)),
        ]),
        const SizedBox(height: 16),
        ShopButton('Done', onTap: () => Navigator.pop(c)),
      ]),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = PanelStore.I;
    final since = s.liveSince ?? DateTime.now();
    final d = DateTime.now().difference(since);
    final pad = MediaQuery.paddingOf(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF312E81), Color(0xFF581C87), Color(0xFF0B0A1A)]),
            ),
            child: cam
                ? LiveRoomVideo(
                    room: room,
                    placeholder: Center(child: Opacity(opacity: 0.9, child: PanelAvatar(photo: s.photo, name: s.name, size: 170))),
                  )
                : Center(child: Icon(Icons.videocam_off_rounded, color: Colors.white.withValues(alpha: 0.4), size: 64)),
          ),
        ),
        Positioned(
          top: pad.top + 10,
          left: 14,
          right: 14,
          child: Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: const Color(0xFFE11D48), borderRadius: BorderRadius.circular(10)),
              child: Text('LIVE', style: akT(12, w: FontWeight.w900, c: Colors.white, ls: 1)),
            ),
            const SizedBox(width: 8),
            _pill('${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}'),
            const SizedBox(width: 8),
            _pill('👁 $viewers'),
            const Spacer(),
            _pill('💜 $hearts'),
          ]),
        ),
        Positioned(
          top: pad.top + 54,
          left: 16,
          right: 80,
          child: Text(s.liveTitle, style: akT(20, w: FontWeight.w800, c: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        // Chat.
        Positioned(
          left: 14,
          right: 90,
          bottom: pad.bottom + 110,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (final m in msgs)
              TweenAnimationBuilder<double>(
                key: ValueKey(m),
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 380),
                builder: (_, v, c) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, 10 * (1 - v)), child: c)),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.35), borderRadius: BorderRadius.circular(16)),
                  child: Text.rich(TextSpan(children: [
                    TextSpan(text: '${m.$1}  ', style: akT(12.5, w: FontWeight.w800, c: const Color(0xFFF9A8D4))),
                    TextSpan(text: m.$2, style: akT(12.5, w: FontWeight.w600, c: Colors.white)),
                  ])),
                ),
              ),
          ]),
        ),
        Positioned(
          right: 14,
          bottom: pad.bottom + 110,
          child: Column(children: [
            Text('₹$tipsIn', style: akN(16, c: Colors.white)),
            Text('tips', style: akT(11, w: FontWeight.w700, c: Colors.white60)),
          ]),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: pad.bottom + 24,
          child: Row(children: [
            _round(mic ? Icons.mic_rounded : Icons.mic_off_rounded, () {
              setState(() => mic = !mic);
              room.setMic(mic);
            }),
            const SizedBox(width: 10),
            _round(cam ? Icons.videocam_rounded : Icons.videocam_off_rounded, () {
              setState(() => cam = !cam);
              room.setCam(cam);
            }),
            const SizedBox(width: 10),
            _round(Icons.cameraswitch_rounded, () => HapticFeedback.selectionClick()),
            const SizedBox(width: 10),
            Expanded(
              child: AkPress(
                onTap: _end,
                child: Container(
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: const Color(0xFFE11D48), borderRadius: BorderRadius.circular(20)),
                  child: Text('End', style: akT(16, w: FontWeight.w800, c: Colors.white)),
                ),
              ),
            ),
          ]),
        ),
        Positioned(
          top: pad.top + 52,
          right: 14,
          child: _round(Icons.keyboard_arrow_down_rounded, () => Navigator.pop(context)),
        ),
      ]),
    );
  }

  Widget _pill(String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.35), borderRadius: BorderRadius.circular(10)),
        child: Text(t, style: akT(12, w: FontWeight.w800, c: Colors.white)),
      );

  Widget _round(IconData i, VoidCallback on) => LiquidGlass(
        style: LiquidGlassStyle.clear,
        shape: BoxShape.circle,
        shadow: false,
        colors: [Colors.white.withValues(alpha: 0.22), Colors.white.withValues(alpha: 0.08)],
        onTap: on,
        child: SizedBox(width: 52, height: 52, child: Icon(i, color: Colors.white, size: 22)),
      );
}

// =====================================================================
//  3. UPLOAD WORKOUT
// =====================================================================

class UploadWorkoutPage extends StatefulWidget {
  const UploadWorkoutPage({super.key});
  @override
  State<UploadWorkoutPage> createState() => _UploadWorkoutPageState();
}

class _UploadWorkoutPageState extends State<UploadWorkoutPage> {
  final _title = TextEditingController();
  String kind = 'Video';
  String level = 'Beginner';
  double minutes = 30;
  String? cover;
  final ex = <String>[];
  bool sendAll = true;
  double? progress;

  static final _suggest = [for (final d in planDays) for (final e in d.$3) e.name];

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    try {
      final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 900, imageQuality: 78);
      if (x == null) return;
      final b = await x.readAsBytes();
      setState(() => cover = base64Encode(b));
    } catch (_) {
      if (mounted) shopToast(context, 'Could not open your photos', icon: Icons.error_rounded);
    }
  }

  Future<void> _publish() async {
    if (_title.text.trim().length < 3) {
      shopToast(context, 'Give your workout a title', icon: Icons.info_rounded);
      return;
    }
    if (ex.isEmpty) {
      shopToast(context, 'Add at least one exercise', icon: Icons.info_rounded);
      return;
    }
    for (var i = 0; i <= 20; i++) {
      setState(() => progress = i / 20);
      await Future.delayed(const Duration(milliseconds: 60));
      if (!mounted) return;
    }
    PanelStore.I.publish(PWorkout('w${DateTime.now().millisecondsSinceEpoch}', _title.text.trim(), level, kind, minutes.round(), List.of(ex),
        cover, DateTime.now(), true, 0, 0));
    HapticFeedback.mediumImpact();
    Navigator.pop(context);
    shopToast(context, sendAll ? 'Published and sent to ${PanelStore.I.activeClients} clients' : 'Published to your library',
        icon: Icons.cloud_done_rounded);
  }

  @override
  Widget build(BuildContext context) => _page(
        'Upload workout',
        'New content',
        _list([
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AkPress(
              onTap: _pick,
              child: Container(
                height: 190,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  color: Colors.white.withValues(alpha: 0.8),
                  border: Border.all(color: pViolet.withValues(alpha: 0.35), width: 1.6),
                ),
                clipBehavior: Clip.antiAlias,
                child: cover != null
                    ? Stack(fit: StackFit.expand, children: [
                        Image.memory(base64Decode(cover!), fit: BoxFit.cover, gaplessPlayback: true),
                        Positioned(
                          right: 10,
                          bottom: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                            child: Text('Change cover', style: akT(12, w: FontWeight.w800, c: Colors.white)),
                          ),
                        ),
                      ])
                    : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [pViolet, pPink])),
                          child: const Icon(Icons.add_photo_alternate_rounded, color: Colors.white, size: 28),
                        ),
                        const SizedBox(height: 12),
                        Text('Add a cover photo', style: akT(15, w: FontWeight.w800)),
                        Text('JPG or PNG from your gallery', style: akT(12, w: FontWeight.w600, c: akMuted)),
                      ]),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GlassField(label: 'Workout title', hint: 'e.g. 20-min fat burner', controller: _title, icon: Icons.title_rounded, dark: false),
          ),
          _label('Type'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _chips(const ['Video', 'Plan', 'Circuit'], kind, (v) => setState(() => kind = v), color: pViolet),
          ),
          _label('Level'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _chips(const ['Beginner', 'Intermediate', 'Advanced', 'All levels'], level, (v) => setState(() => level = v), color: pViolet),
          ),
          _label('Duration · ${minutes.round()} min'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Slider(value: minutes, min: 5, max: 90, divisions: 17, activeColor: pViolet, onChanged: (v) => setState(() => minutes = v)),
          ),
          _label('Exercises · ${ex.length}'),
          if (ex.isNotEmpty)
            ShopCard(
              padding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
              child: ReorderableListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                onReorderItem: (a, b) => setState(() => ex.insert(b, ex.removeAt(a))),
                children: [
                  for (var i = 0; i < ex.length; i++)
                    Row(key: ValueKey(ex[i]), children: [
                      Text('${i + 1}', style: akN(14, c: pViolet)),
                      const SizedBox(width: 12),
                      Expanded(child: Text(ex[i], style: akT(14, w: FontWeight.w700))),
                      IconButton(onPressed: () => setState(() => ex.removeAt(i)), icon: const Icon(Icons.remove_circle_rounded, color: shopRed, size: 20)),
                      ReorderableDragStartListener(index: i, child: const Padding(padding: EdgeInsets.all(8), child: Icon(Icons.drag_handle_rounded, color: akMuted))),
                    ]),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Wrap(spacing: 8, runSpacing: 8, children: [
              for (final e in _suggest)
                if (!ex.contains(e))
                  AkPress(
                    onTap: () => setState(() => ex.add(e)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
                      child: Text('+ $e', style: akT(12.5, w: FontWeight.w700)),
                    ),
                  ),
            ]),
          ),
          const SizedBox(height: 14),
          ShopCard(
            padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
            child: Row(children: [
              const Icon(Icons.send_rounded, color: pViolet, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text('Send to all ${PanelStore.I.activeClients} clients', style: akT(14, w: FontWeight.w700))),
              Switch.adaptive(value: sendAll, activeTrackColor: pViolet, onChanged: (v) => setState(() => sendAll = v)),
            ]),
          ),
        ], bottom: 120),
        bottom: ShopBottomBar(
          child: progress == null
              ? ShopButton('Publish workout', icon: Icons.cloud_upload_rounded, color: pViolet, onTap: _publish)
              : Column(mainAxisSize: MainAxisSize.min, children: [
                  Row(children: [
                    Text('Uploading…', style: akT(14, w: FontWeight.w800)),
                    const Spacer(),
                    Text('${(progress! * 100).round()}%', style: akN(14, c: pViolet)),
                  ]),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: LinearProgressIndicator(value: progress, minHeight: 10, backgroundColor: const Color(0xFFEDE9FE), color: pViolet),
                  ),
                  const SizedBox(height: 14),
                ]),
        ),
      );
}

// =====================================================================
//  4. CLIENT DETAIL
// =====================================================================

class ClientDetailPage extends StatefulWidget {
  final PClient c;
  const ClientDetailPage(this.c, {super.key});
  @override
  State<ClientDetailPage> createState() => _ClientDetailPageState();
}

class _ClientDetailPageState extends State<ClientDetailPage> {
  late final _note = TextEditingController(text: widget.c.note);
  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _assign(String what, List<String> opts) async {
    final pick = await _sheet<String>(context, (ctx, set) => _sheetFrame(ctx, 'Assign $what', [
          for (final o in opts)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ShopCard(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.all(14),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                onTap: () => Navigator.pop(ctx, o),
                child: Row(children: [
                  Expanded(child: Text(o, style: akT(14.5, w: FontWeight.w700))),
                  const Icon(Icons.chevron_right_rounded, color: akMuted),
                ]),
              ),
            ),
        ]));
    if (pick == null || !mounted) return;
    PanelStore.I.sendTo(widget.c, 'I’ve assigned you "$pick". Check your plan 💪');
    shopToast(context, '"$pick" assigned to ${widget.c.name.split(' ').first}');
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: PanelStore.I,
        builder: (context, _) {
          final c = widget.c;
          final s = PanelStore.I;
          final diff = c.nowKg - c.startKg;
          return _page(
            c.name,
            '${c.plan} plan · since ${dayName(c.since)}',
            _list([
              ShopCard(
                child: Row(children: [
                  ClientAvatar(c, size: 70),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      statusPill(c.status),
                      const SizedBox(height: 6),
                      Text('Goal: ${c.goal}', style: akT(15, w: FontWeight.w800)),
                      Text(c.daysLeft >= 0 ? 'Plan renews in ${c.daysLeft} days' : 'Plan ended', style: akT(12.5, w: FontWeight.w600, c: akMuted)),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  Expanded(child: Kpi('${diff >= 0 ? '+' : ''}${diff.toStringAsFixed(1)} kg', 'Weight change', Icons.monitor_weight_rounded, diff <= 0 ? shopGreen : akBlue)),
                  const SizedBox(width: 10),
                  Expanded(child: Kpi('${c.workouts}', 'Workouts', Icons.fitness_center_rounded, pViolet)),
                  const SizedBox(width: 10),
                  Expanded(child: Kpi('${c.streak}d', 'Streak', Icons.local_fire_department_rounded, shopOrange)),
                ]),
              ),
              _label('Weight trend'),
              ShopCard(
                child: SizedBox(
                  height: 110,
                  child: AkSeen(
                    builder: (_, t) => CustomPaint(
                      painter: _Line([for (var i = 0; i < 8; i++) c.startKg + (c.nowKg - c.startKg) * (i / 7) + math.sin(i * 1.7) * 0.4], pViolet, t),
                      size: Size.infinite,
                    ),
                  ),
                ),
              ),
              _label('Actions'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.05,
                  children: [
                    _act(Icons.chat_bubble_rounded, 'Message', pPink, () => panelPush(context, PanelChatPage(c))),
                    _act(Icons.fitness_center_rounded, 'Assign workout', pViolet, () => _assign('workout', s.workouts.map((w) => w.title).toList())),
                    _act(Icons.restaurant_rounded, 'Assign diet', shopOrange, () => _assign('diet', s.diets.map((d) => d.name).toList())),
                    _act(Icons.videocam_rounded, 'Book a call', akBlue, () {
                      final now = DateTime.now();
                      s.addSession(PSession('s${now.millisecondsSinceEpoch}', 'Check-in call', '1:1 call', DateTime(now.year, now.month, now.day + 1, 18), 20, c.name));
                      shopToast(context, 'Call booked for tomorrow, 6:00 PM');
                    }),
                    _act(Icons.autorenew_rounded, 'Renew', shopGreen, () {
                      s.renew(c);
                      shopToast(context, '${c.name.split(' ').first} renewed their ${c.plan} plan');
                    }),
                    _act(c.status == 'paused' ? Icons.play_arrow_rounded : Icons.pause_rounded, c.status == 'paused' ? 'Resume' : 'Pause', akMuted, () {
                      s.setClientStatus(c, c.status == 'paused' ? 'active' : 'paused');
                    }),
                  ],
                ),
              ),
              _label('Private coach notes'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GlassField(
                  label: 'Injuries, preferences, reminders…',
                  controller: _note,
                  icon: Icons.sticky_note_2_rounded,
                  lines: 3,
                  dark: false,
                  onChanged: (v) => s.setClientNote(c, v),
                ),
              ),
            ]),
          );
        },
      );

  Widget _act(IconData i, String t, Color c, VoidCallback on) => AkPress(
        onTap: on,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.92), borderRadius: BorderRadius.circular(20)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: c.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(i, color: c, size: 20),
            ),
            const SizedBox(height: 8),
            Text(t, textAlign: TextAlign.center, style: akT(11.5, w: FontWeight.w800), maxLines: 2),
          ]),
        ),
      );
}

class _Line extends CustomPainter {
  final List<double> v;
  final Color c;
  final double t;
  _Line(this.v, this.c, this.t);
  @override
  void paint(Canvas canvas, Size size) {
    if (v.length < 2) return;
    final mn = v.reduce(math.min) - 0.5, mx = v.reduce(math.max) + 0.5;
    Offset p(int i) => Offset(size.width * i / (v.length - 1), size.height - (v[i] - mn) / (mx - mn) * size.height);
    final path = Path()..moveTo(p(0).dx, p(0).dy);
    for (var i = 1; i < v.length; i++) {
      final a = p(i - 1), b = p(i);
      path.cubicTo((a.dx + b.dx) / 2, a.dy, (a.dx + b.dx) / 2, b.dy, b.dx, b.dy);
    }
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, -10, size.width * t.clamp(0, 1), size.height + 20));
    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [c.withValues(alpha: 0.25), c.withValues(alpha: 0)]).createShader(Offset.zero & size),
    );
    canvas.drawPath(path, Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round);
    canvas.restore();
    if (t >= 1) canvas.drawCircle(p(v.length - 1), 5, Paint()..color = c);
  }

  @override
  bool shouldRepaint(_Line o) => o.t != t || o.v != v;
}

// =====================================================================
//  5. SCHEDULE
// =====================================================================

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});
  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  int day = 0;

  Future<void> _add(DateTime base) async {
    final title = TextEditingController(text: 'Strength live');
    var kind = 'Live class';
    var hour = 18;
    var mins = 45.0;
    var client = PanelStore.I.clients.first.name;
    await _sheet(context, (ctx, set) => _sheetFrame(ctx, 'New session', [
          GlassField(label: 'Title', controller: title, icon: Icons.title_rounded, dark: false),
          _chips(const ['Live class', '1:1 call', 'Check-in'], kind, (v) => set(() => kind = v), color: pViolet),
          const SizedBox(height: 14),
          Text('Time', style: akT(13, w: FontWeight.w700, c: akMuted)),
          const SizedBox(height: 8),
          SizedBox(
            height: 42,
            child: ListView(scrollDirection: Axis.horizontal, children: [
              for (final h in [6, 7, 8, 9, 12, 17, 18, 19, 20, 21])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: AkPress(
                    onTap: () => set(() => hour = h),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: hour == h ? pViolet : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(hhmm(DateTime(2000, 1, 1, h)), style: akT(13, w: FontWeight.w800, c: hour == h ? Colors.white : akInk)),
                    ),
                  ),
                ),
            ]),
          ),
          const SizedBox(height: 14),
          Text('Length · ${mins.round()} min', style: akT(13, w: FontWeight.w700, c: akMuted)),
          Slider(value: mins, min: 15, max: 90, divisions: 5, activeColor: pViolet, onChanged: (v) => set(() => mins = v)),
          if (kind != 'Live class') ...[
            Text('Client', style: akT(13, w: FontWeight.w700, c: akMuted)),
            const SizedBox(height: 8),
            _chips([for (final c in PanelStore.I.clients.take(5)) c.name], client, (v) => set(() => client = v), color: pViolet),
            const SizedBox(height: 14),
          ],
          ShopButton('Add to schedule', color: pViolet, onTap: () {
            PanelStore.I.addSession(PSession('s${DateTime.now().millisecondsSinceEpoch}', title.text.trim().isEmpty ? kind : title.text.trim(), kind,
                DateTime(base.year, base.month, base.day, hour), mins.round(), kind == 'Live class' ? null : client));
            Navigator.pop(ctx);
            shopToast(context, 'Session added · clients notified');
          }),
        ]));
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: PanelStore.I,
        builder: (context, _) {
          final now = DateTime.now();
          final days = [for (var i = 0; i < 14; i++) DateTime(now.year, now.month, now.day + i)];
          final sel = days[day];
          final list = PanelStore.I.sessions.where((s) => s.at.year == sel.year && s.at.month == sel.month && s.at.day == sel.day).toList()
            ..sort((a, b) => a.at.compareTo(b.at));
          const wd = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
          return _page(
            'Schedule',
            '${PanelStore.I.upcoming.length} upcoming',
            _list([
              SizedBox(
                height: 84,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: days.length,
                  itemBuilder: (_, i) {
                    final d = days[i];
                    final on = i == day;
                    final has = PanelStore.I.sessions.any((s) => s.at.year == d.year && s.at.month == d.month && s.at.day == d.day);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: AkPress(
                        onTap: () => setState(() => day = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          width: 56,
                          decoration: BoxDecoration(
                            gradient: on ? const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [pViolet, pPink]) : null,
                            color: on ? null : Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text(wd[d.weekday - 1], style: akT(12, w: FontWeight.w700, c: on ? Colors.white70 : akMuted)),
                            const SizedBox(height: 4),
                            Text('${d.day}', style: akN(20, c: on ? Colors.white : akInk)),
                            const SizedBox(height: 4),
                            Container(width: 5, height: 5, decoration: BoxDecoration(shape: BoxShape.circle, color: has ? (on ? Colors.white : pPink) : Colors.transparent)),
                          ]),
                        ),
                      ),
                    );
                  },
                ),
              ),
              _label(day == 0 ? 'Today' : day == 1 ? 'Tomorrow' : dayName(sel)),
              if (list.isEmpty)
                ShopCard(
                  child: Column(children: [
                    const Icon(Icons.event_available_rounded, color: akMuted, size: 36),
                    const SizedBox(height: 8),
                    Text('Nothing planned', style: akT(15, w: FontWeight.w800)),
                    Text('Add a live class or a client call.', style: akT(12.5, w: FontWeight.w600, c: akMuted)),
                  ]),
                ),
              for (final s in list)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ShopCard(
                    padding: const EdgeInsets.all(14),
                    child: IntrinsicHeight(
                      child: Row(children: [
                        SizedBox(
                          width: 62,
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(hhmm(s.at), style: akN(14)),
                            const SizedBox(height: 2),
                            Text('${s.minutes} min', style: akT(11, w: FontWeight.w600, c: akMuted)),
                          ]),
                        ),
                        Container(
                          width: 4,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: s.kind == 'Live class' ? const Color(0xFFE11D48) : s.kind == '1:1 call' ? akBlue : shopGreen,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(s.title, style: akT(14.5, w: FontWeight.w800)),
                            Text(s.client == null ? s.kind : '${s.kind} · ${s.client}', style: akT(12, w: FontWeight.w600, c: akMuted)),
                          ]),
                        ),
                        IconButton(
                          onPressed: () {
                            PanelStore.I.cancelSession(s);
                            shopToast(context, 'Session cancelled', icon: Icons.event_busy_rounded);
                          },
                          icon: const Icon(Icons.close_rounded, color: akMuted, size: 20),
                        ),
                      ]),
                    ),
                  ),
                ),
            ], bottom: 120),
            bottom: ShopBottomBar(child: ShopButton('Add session', icon: Icons.add_rounded, color: pViolet, onTap: () => _add(sel))),
          );
        },
      );
}

// =====================================================================
//  6. MESSAGES
// =====================================================================

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: PanelStore.I,
        builder: (context, _) {
          final list = List.of(PanelStore.I.clients)..sort((a, b) => b.chat.last.at.compareTo(a.chat.last.at));
          return _page(
            'Messages',
            PanelStore.I.unread == 0 ? 'All caught up' : '${PanelStore.I.unread} unread',
            _list([
              ShopCard(
                padding: const EdgeInsets.all(14),
                onTap: () => _broadcast(context),
                color: const Color(0xFFF5F3FF),
                border: Border.all(color: const Color(0xFFDDD6FE)),
                child: Row(children: [
                  const Icon(Icons.campaign_rounded, color: pViolet),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Broadcast to all clients', style: akT(14.5, w: FontWeight.w800, c: pViolet))),
                  const Icon(Icons.chevron_right_rounded, color: pViolet),
                ]),
              ),
              const SizedBox(height: 12),
              for (final c in list)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ShopCard(
                    padding: const EdgeInsets.all(12),
                    onTap: () => panelPush(context, PanelChatPage(c)),
                    child: Row(children: [
                      ClientAvatar(c, size: 48),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Expanded(child: Text(c.name, style: akT(14.5, w: FontWeight.w800))),
                            Text(ago(c.chat.last.at), style: akT(11, w: FontWeight.w600, c: akMuted)),
                          ]),
                          const SizedBox(height: 2),
                          Row(children: [
                            Expanded(
                              child: Text('${c.chat.last.me ? 'You: ' : ''}${c.chat.last.text}',
                                  style: akT(12.5, w: c.unread > 0 ? FontWeight.w800 : FontWeight.w600, c: c.unread > 0 ? akInk : akMuted),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ),
                            if (c.unread > 0) CountBadge(c.unread, color: pPink),
                          ]),
                        ]),
                      ),
                    ]),
                  ),
                ),
            ]),
          );
        },
      );

  void _broadcast(BuildContext context) {
    final t = TextEditingController(text: 'Live HIIT tonight at 6:30 PM. Bring water and a towel! 🔥');
    _sheet(context, (ctx, set) => _sheetFrame(ctx, 'Broadcast', [
          GlassField(label: 'Message', controller: t, icon: Icons.campaign_rounded, lines: 3, dark: false),
          ShopButton('Send to ${PanelStore.I.activeClients} clients', icon: Icons.send_rounded, color: pViolet, onTap: () {
            for (final c in PanelStore.I.clients.where((c) => c.status != 'paused')) {
              PanelStore.I.sendTo(c, t.text.trim());
            }
            Navigator.pop(ctx);
            shopToast(context, 'Broadcast sent', icon: Icons.send_rounded);
          }),
        ]));
  }
}

class PanelChatPage extends StatefulWidget {
  final PClient c;
  const PanelChatPage(this.c, {super.key});
  @override
  State<PanelChatPage> createState() => _PanelChatPageState();
}

class _PanelChatPageState extends State<PanelChatPage> {
  final _t = TextEditingController();
  final _sc = ScrollController();
  bool typing = false;
  static const _replies = ['Got it coach 👍', 'Thanks! Will do.', 'Perfect, see you then', 'Done ✅', 'Makes sense, thank you!'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => PanelStore.I.readChat(widget.c));
  }

  @override
  void dispose() {
    _t.dispose();
    _sc.dispose();
    super.dispose();
  }

  void _send([String? q]) {
    final text = (q ?? _t.text).trim();
    if (text.isEmpty) return;
    _t.clear();
    PanelStore.I.sendTo(widget.c, text);
    setState(() => typing = true);
    _bottom();
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      widget.c.chat.add(ChatMsg(false, _replies[widget.c.chat.length % _replies.length], DateTime.now()));
      setState(() => typing = false);
      _bottom();
    });
  }

  void _bottom() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_sc.hasClients) _sc.animateTo(_sc.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      });

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    return _page(
      c.name.split(' ').first,
      '${c.plan} client · ${c.goal}',
      Column(children: [
        Expanded(
          child: ListView(
            controller: _sc,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            children: [
              for (final m in c.chat)
                Align(
                  alignment: m.me ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 280),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: m.me ? const LinearGradient(colors: [pViolet, pPink]) : null,
                      color: m.me ? null : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: Radius.circular(m.me ? 20 : 6),
                        bottomRight: Radius.circular(m.me ? 6 : 20),
                      ),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text(m.text, style: akT(14, w: FontWeight.w600, c: m.me ? Colors.white : akInk, h: 1.35)),
                      const SizedBox(height: 3),
                      Text(hhmm(m.at), style: akT(10, w: FontWeight.w600, c: m.me ? Colors.white70 : akMuted)),
                    ]),
                  ),
                ),
              if (typing)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
                    child: Text('typing…', style: akT(13, w: FontWeight.w600, c: akMuted)),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              for (final q in const ['Great work today! 💪', 'Send me your weigh-in', 'New plan is up', 'How is your sleep?'])
                Padding(
                  padding: const EdgeInsets.only(right: 8, bottom: 6),
                  child: AkPress(
                    onTap: () => _send(q),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE5E7EB))),
                      child: Text(q, style: akT(12.5, w: FontWeight.w700)),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(12, 8, 12, 10 + MediaQuery.paddingOf(context).bottom),
          color: Colors.white.withValues(alpha: 0.95),
          child: Row(children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(22)),
                child: TextField(
                  controller: _t,
                  onSubmitted: (_) => _send(),
                  style: akT(14.5, w: FontWeight.w600),
                  decoration: InputDecoration(border: InputBorder.none, hintText: 'Message ${c.name.split(' ').first}', hintStyle: akT(14, w: FontWeight.w500, c: akMuted)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            AkPress(
              onTap: _send,
              child: Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [pViolet, pPink])),
                child: const Icon(Icons.arrow_upward_rounded, color: Colors.white),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

// =====================================================================
//  8. ANALYTICS
// =====================================================================

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final s = PanelStore.I;
    const growth = <double>[6, 8, 9, 13, 15, 19, 24, 27, 31, 34];
    final top = List.of(s.workouts)..sort((a, b) => b.views.compareTo(a.views));
    return _page(
      'Analytics',
      'Last 90 days',
      _list([
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.45,
            children: [
              Kpi('2,840', 'Profile views', Icons.visibility_rounded, pViolet, delta: '+22%'),
              Kpi('8.4%', 'View → subscribe', Icons.trending_up_rounded, shopGreen, delta: '+1.2'),
              Kpi('92%', 'Retention', Icons.autorenew_rounded, akBlue, delta: '+3%'),
              Kpi('4.2', 'Workouts / client / wk', Icons.fitness_center_rounded, shopOrange, delta: '-0.3'),
            ],
          ),
        ),
        _label('Subscriber growth'),
        ShopCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('34', style: akN(30)),
              const SizedBox(width: 8),
              Text('subscribers · +28 in 90 days', style: akT(12.5, w: FontWeight.w700, c: shopGreen)),
            ]),
            const SizedBox(height: 12),
            SizedBox(
              height: 130,
              child: AkSeen(builder: (_, t) => CustomPaint(painter: _Line(growth, pViolet, t), size: Size.infinite)),
            ),
          ]),
        ),
        _label('Where clients find you'),
        ShopCard(
          child: Column(children: [
            for (final (n, v, c) in const [
              ('Trainers tab', 0.46, pViolet),
              ('Community posts', 0.27, pPink),
              ('Live classes', 0.18, Color(0xFFE11D48)),
              ('Shared link', 0.09, akBlue),
            ])
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(children: [
                  SizedBox(width: 120, child: Text(n, style: akT(13, w: FontWeight.w700))),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: AkSeen(builder: (_, t) => LinearProgressIndicator(value: v * t, minHeight: 10, backgroundColor: const Color(0xFFF3F4F6), color: c)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(width: 36, child: Text('${(v * 100).round()}%', textAlign: TextAlign.right, style: akN(13))),
                ]),
              ),
          ]),
        ),
        _label('Top content'),
        for (final w in top.take(3))
          Padding(padding: const EdgeInsets.only(bottom: 10), child: WorkoutRow(w)),
      ]),
    );
  }
}

// =====================================================================
//  9. DIET PLANS
// =====================================================================

class DietPlansPage extends StatelessWidget {
  const DietPlansPage({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: PanelStore.I,
        builder: (context, _) {
          final s = PanelStore.I;
          return _page(
            'Diet plans',
            '${s.diets.length} templates',
            _list([
              for (final d in s.diets)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ShopCard(
                    onTap: () => panelPush(context, DietBuilderPage(d)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(color: shopOrange.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
                          child: const Icon(Icons.restaurant_menu_rounded, color: shopOrange),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(d.name, style: akT(15.5, w: FontWeight.w800)),
                            Text('${d.goal} · ${d.kcal} kcal · ${d.protein} g protein', style: akT(12, w: FontWeight.w600, c: akMuted)),
                          ]),
                        ),
                      ]),
                      const SizedBox(height: 10),
                      for (final m in d.meals.take(4))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Row(children: [
                            Container(width: 5, height: 5, decoration: const BoxDecoration(color: shopOrange, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Expanded(child: Text(m, style: akT(12.5, w: FontWeight.w600, c: const Color(0xFF374151)))),
                          ]),
                        ),
                      const SizedBox(height: 10),
                      Row(children: [
                        Text('Assigned to ${d.assigned} clients', style: akT(12, w: FontWeight.w700, c: akMuted)),
                        const Spacer(),
                        AkPress(
                          onTap: () {
                            PanelStore.I.assignDiet(d, 1);
                            shopToast(context, '${d.name} sent to a client');
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(color: akInk, borderRadius: BorderRadius.circular(12)),
                            child: Text('Assign', style: akT(12, w: FontWeight.w800, c: Colors.white)),
                          ),
                        ),
                      ]),
                    ]),
                  ),
                ),
            ], bottom: 120),
            bottom: ShopBottomBar(
              child: ShopButton('Create diet plan', icon: Icons.add_rounded, color: shopOrange, onTap: () => panelPush(context, const DietBuilderPage(null))),
            ),
          );
        },
      );
}

class DietBuilderPage extends StatefulWidget {
  final PDiet? d;
  const DietBuilderPage(this.d, {super.key});
  @override
  State<DietBuilderPage> createState() => _DietBuilderPageState();
}

class _DietBuilderPageState extends State<DietBuilderPage> {
  late final _name = TextEditingController(text: widget.d?.name ?? 'My new plan');
  final _meal = TextEditingController();
  late String goal = widget.d?.goal ?? 'Fat loss';
  late double kcal = (widget.d?.kcal ?? 1900).toDouble();
  late double protein = (widget.d?.protein ?? 130).toDouble();
  late final meals = List.of(widget.d?.meals ?? ['Breakfast: oats, whey, banana', 'Lunch: dal, rice, salad']);

  @override
  void dispose() {
    _name.dispose();
    _meal.dispose();
    super.dispose();
  }

  void _addMeal() {
    final t = _meal.text.trim();
    if (t.isEmpty) return;
    setState(() {
      meals.add(t);
      _meal.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final carbs = ((kcal - protein * 4 - kcal * 0.28) / 4).round();
    final fat = (kcal * 0.28 / 9).round();
    return _page(
      widget.d == null ? 'New diet plan' : 'Edit diet plan',
      'Diet builder',
      _list([
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GlassField(label: 'Plan name', controller: _name, icon: Icons.label_rounded, dark: false),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _chips(const ['Fat loss', 'Muscle gain', 'Maintenance', 'Vegan'], goal, (v) => setState(() => goal = v), color: shopOrange),
        ),
        const SizedBox(height: 14),
        ShopCard(
          child: Column(children: [
            Row(children: [
              Text('Calories', style: akT(14, w: FontWeight.w800)),
              const Spacer(),
              Text('${kcal.round()} kcal', style: akN(18)),
            ]),
            Slider(value: kcal, min: 1200, max: 3600, divisions: 48, activeColor: shopOrange, onChanged: (v) => setState(() => kcal = v)),
            Row(children: [
              Text('Protein', style: akT(14, w: FontWeight.w800)),
              const Spacer(),
              Text('${protein.round()} g', style: akN(18)),
            ]),
            Slider(value: protein, min: 50, max: 250, divisions: 40, activeColor: const Color(0xFFE11D48), onChanged: (v) => setState(() => protein = v)),
            const SizedBox(height: 4),
            Row(children: [
              _macro('Protein', '${protein.round()} g', const Color(0xFFE11D48)),
              _macro('Carbs', '${math.max(0, carbs)} g', shopAmber),
              _macro('Fat', '$fat g', akBlue),
            ]),
          ]),
        ),
        _label('Meals'),
        for (var i = 0; i < meals.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ShopCard(
              padding: const EdgeInsets.fromLTRB(14, 6, 4, 6),
              child: Row(children: [
                Text('${i + 1}', style: akN(14, c: shopOrange)),
                const SizedBox(width: 12),
                Expanded(child: Text(meals[i], style: akT(13.5, w: FontWeight.w700))),
                IconButton(onPressed: () => setState(() => meals.removeAt(i)), icon: const Icon(Icons.close_rounded, size: 18, color: akMuted)),
              ]),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GlassField(
            label: 'Add a meal',
            controller: _meal,
            icon: Icons.add_rounded,
            dark: false,
            onSubmitted: (_) => _addMeal(),
            trailing: TextButton(onPressed: _addMeal, child: Text('Add', style: akT(14, w: FontWeight.w800, c: shopOrange))),
          ),
        ),
      ], bottom: 120),
      bottom: ShopBottomBar(
        child: ShopButton('Save diet plan', color: shopOrange, onTap: () {
          final d = widget.d;
          if (d == null) {
            PanelStore.I.saveDiet(PDiet(_name.text.trim(), goal, kcal.round(), protein.round(), meals, 0), isNew: true);
          } else {
            d
              ..name = _name.text.trim()
              ..goal = goal
              ..kcal = kcal.round()
              ..protein = protein.round()
              ..meals = meals;
            PanelStore.I.saveDiet(d);
          }
          Navigator.pop(context);
          shopToast(context, 'Diet plan saved');
        }),
      ),
    );
  }

  Widget _macro(String l, String v, Color c) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
          child: Column(children: [
            Text(v, style: akN(16, c: c)),
            const SizedBox(height: 2),
            Text(l, style: akT(11, w: FontWeight.w700, c: akMuted)),
          ]),
        ),
      );
}

// =====================================================================
//  10. REVIEWS
// =====================================================================

class ReviewsPage extends StatelessWidget {
  const ReviewsPage({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: PanelStore.I,
        builder: (context, _) {
          final s = PanelStore.I;
          final dist = [for (var st = 5; st >= 1; st--) s.reviews.where((r) => r.stars == st).length];
          return _page(
            'Reviews',
            '${s.reviews.length} reviews',
            _list([
              ShopCard(
                child: Row(children: [
                  Column(children: [
                    Text(s.rating.toStringAsFixed(1), style: akN(46)),
                    Row(children: [for (var i = 0; i < 5; i++) Icon(Icons.star_rounded, size: 16, color: i < s.rating.round() ? shopAmber : const Color(0xFFE5E7EB))]),
                    const SizedBox(height: 4),
                    Text('${s.reviews.length + 124} ratings', style: akT(11.5, w: FontWeight.w600, c: akMuted)),
                  ]),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(children: [
                      for (var i = 0; i < 5; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(children: [
                            Text('${5 - i}', style: akT(11.5, w: FontWeight.w700, c: akMuted)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: s.reviews.isEmpty ? 0 : dist[i] / s.reviews.length,
                                  minHeight: 7,
                                  backgroundColor: const Color(0xFFF3F4F6),
                                  color: shopAmber,
                                ),
                              ),
                            ),
                          ]),
                        ),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 12),
              for (final r in s.reviews)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ShopCard(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        ClipOval(child: SizedBox(width: 38, height: 38, child: Image.network(r.photo, fit: BoxFit.cover, errorBuilder: (_, _, _) => Container(color: const Color(0xFFEDE9FE))))),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(r.name, style: akT(14, w: FontWeight.w800)),
                            Row(children: [
                              for (var i = 0; i < 5; i++) Icon(Icons.star_rounded, size: 13, color: i < r.stars ? shopAmber : const Color(0xFFE5E7EB)),
                              const SizedBox(width: 6),
                              Text(ago(r.at), style: akT(11, w: FontWeight.w600, c: akMuted)),
                            ]),
                          ]),
                        ),
                      ]),
                      const SizedBox(height: 10),
                      Text(r.text, style: akT(13.5, w: FontWeight.w600, c: const Color(0xFF374151), h: 1.4)),
                      const SizedBox(height: 10),
                      if (r.reply != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: const Color(0xFFF5F3FF), borderRadius: BorderRadius.circular(14)),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Your reply', style: akT(11.5, w: FontWeight.w800, c: pViolet)),
                            const SizedBox(height: 3),
                            Text(r.reply!, style: akT(13, w: FontWeight.w600, c: const Color(0xFF374151))),
                          ]),
                        )
                      else
                        GestureDetector(
                          onTap: () => _reply(context, r),
                          child: Text('Reply publicly', style: akT(13, w: FontWeight.w800, c: pViolet)),
                        ),
                    ]),
                  ),
                ),
            ]),
          );
        },
      );

  void _reply(BuildContext context, PReview r) {
    final t = TextEditingController(text: 'Thank you ${r.name.split(' ').first}! So proud of your progress 💜');
    _sheet(context, (ctx, set) => _sheetFrame(ctx, 'Reply to ${r.name.split(' ').first}', [
          GlassField(label: 'Your reply', controller: t, icon: Icons.reply_rounded, lines: 3, dark: false),
          ShopButton('Post reply', color: pViolet, onTap: () {
            PanelStore.I.reply(r, t.text.trim());
            Navigator.pop(ctx);
            shopToast(context, 'Reply posted');
          }),
        ]));
  }
}

// =====================================================================
//  PROFILE
// =====================================================================

class PanelProfilePage extends StatefulWidget {
  const PanelProfilePage({super.key});
  @override
  State<PanelProfilePage> createState() => _PanelProfilePageState();
}

class _PanelProfilePageState extends State<PanelProfilePage> {
  final s = PanelStore.I;
  late final _name = TextEditingController(text: s.name);
  late final _head = TextEditingController(text: s.headline);
  late final _city = TextEditingController(text: s.city);
  late final _bio = TextEditingController(text: s.bio);

  @override
  void dispose() {
    for (final c in [_name, _head, _city, _bio]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _photo() async {
    try {
      final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 600, imageQuality: 80);
      if (x == null) return;
      s.updateProfile(photo: base64Encode(await x.readAsBytes()));
      setState(() {});
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) => _page(
        'Coach profile',
        'Settings',
        _list([
          Center(
            child: AkPress(
              onTap: _photo,
              child: Column(children: [
                PanelAvatar(photo: s.photo, name: s.name, size: 96),
                const SizedBox(height: 8),
                Text('Change photo', style: akT(13, w: FontWeight.w800, c: pViolet)),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(children: [
              GlassField(label: 'Name', controller: _name, icon: Icons.person_rounded, dark: false),
              GlassField(label: 'Headline', controller: _head, icon: Icons.short_text_rounded, dark: false),
              GlassField(label: 'City', controller: _city, icon: Icons.location_on_rounded, dark: false),
              GlassField(label: 'Bio', controller: _bio, icon: Icons.edit_note_rounded, lines: 4, dark: false),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(spacing: 8, runSpacing: 8, children: [
              for (final t in [...s.specialties, '${s.years} yrs', s.mode, ...s.certs])
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(color: pViolet.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Text(t, style: akT(12, w: FontWeight.w800, c: pViolet)),
                ),
            ]),
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ShopButton('Save profile', color: pViolet, onTap: () {
              s.updateProfile(name: _name.text.trim(), headline: _head.text.trim(), city: _city.text.trim(), bio: _bio.text.trim());
              Navigator.pop(context);
              shopToast(context, 'Profile updated');
            }),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ShopButton('Go to NeuroFit home', icon: Icons.home_rounded, outline: true, onTap: () {
              Navigator.pop(context);
              s.exitPanel();
            }),
          ),
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.pop(context);
                s.leaveCoaching();
              },
              child: Text('Stop coaching on NeuroFit', style: akT(13, w: FontWeight.w700, c: shopRed)),
            ),
          ),
        ]),
      );
}
