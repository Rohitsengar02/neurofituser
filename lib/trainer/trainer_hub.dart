import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../shop/shop_ui.dart';
import '../widgets/apple_kit.dart';
import '../widgets/net_img.dart';
import 'trainer_data.dart';
import 'trainers_page.dart';
import '../backend/me.dart';
import '../backend/live_backend.dart';
import '../backend/live_room.dart';

// Everything a subscriber gets from their trainer: the coaching home plus
// seven feature pages (live training, workout plan, diet, chat, check-ins,
// booking and notifications).

class TrainerHubPage extends StatefulWidget {
  final bool welcome;
  const TrainerHubPage({super.key, this.welcome = false});
  @override
  State<TrainerHubPage> createState() => _TrainerHubPageState();
}

class _TrainerHubPageState extends State<TrainerHubPage> {
  @override
  void initState() {
    super.initState();
    if (widget.welcome) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) shopToast(context, 'Subscription active. Say hi to your coach!', icon: Icons.celebration_rounded);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: TrainerStore.I,
      builder: (context, _) {
        final s = TrainerStore.I;
        final t = s.trainer;
        if (!s.active || t == null) {
          return ShopPage(
            title: 'My coaching',
            tint: tViolet,
            body: EmptyState(
              icon: Icons.sports_rounded,
              title: 'No coach yet',
              body: 'Pick a trainer and subscribe to unlock live sessions, plans and chat.',
              action: 'Find a trainer',
              color: tViolet,
              onAction: () => Navigator.of(context).maybePop(),
            ),
          );
        }
        final day = planDays[s.planIndex];
        final done = day.$3.where((e) => s.isDone(e.name)).length;
        final left = s.until!.difference(DateTime.now()).inDays;
        final feats = [
          (Icons.live_tv_rounded, 'Live training', s.liveNow ? 'Live now' : 'Next ${hhmm(s.nextLive)}', const Color(0xFFEF4444), () => shopPush(context, LiveSessionPage(trainer: t, title: 'Full body burn'))),
          (Icons.fitness_center_rounded, 'Workout plan', '$done/${day.$3.length} today', const Color(0xFF16A34A), () => shopPush(context, const WorkoutPlanPage())),
          (Icons.restaurant_menu_rounded, 'Diet plan', '1,950 kcal', const Color(0xFFF97316), () => shopPush(context, const DietPlanPage())),
          (Icons.chat_bubble_rounded, 'Chat', s.chat.isEmpty ? 'Say hi' : ago(s.chat.last.at), const Color(0xFF3B82F6), () => shopPush(context, const CoachChatPage())),
          (Icons.monitor_weight_rounded, 'Check-ins', s.checkins.isEmpty ? 'Due now' : '${s.checkins.first.weight} kg', const Color(0xFF8B5CF6), () => shopPush(context, const CheckInPage())),
          (Icons.event_available_rounded, 'Book a call', s.bookings.isEmpty ? 'Pick a slot' : dayName(s.bookings.first.at), const Color(0xFF14B8A6), () => shopPush(context, const BookCallPage())),
          (Icons.notifications_active_rounded, 'Notifications', s.unread == 0 ? 'All caught up' : '${s.unread} new', const Color(0xFFEC4899), () => shopPush(context, const CoachNotesPage())),
        ];
        return ShopPage(
          title: 'My coaching',
          caption: '${s.planName} plan · $left days left',
          tint: tViolet,
          actions: [
            GlassIcon(Icons.notifications_none_rounded,
                badge: s.unread == 0 ? null : CountBadge(s.unread, color: tPink), onTap: () => shopPush(context, const CoachNotesPage())),
          ],
          body: ListView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(0, 12, 0, 40 + MediaQuery.paddingOf(context).bottom),
            children: [
              Rise(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  height: 200,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(30)),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(fit: StackFit.expand, children: [
                    NetImg(t.img, alignment: Alignment.topCenter),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [Color(0xEE2E1065), Color(0x332E1065)]),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          if (s.liveNow) const LiveDot() else const LiveDot(label: 'TONIGHT'),
                          const Spacer(),
                          RatingPill(t.rating, dark: true),
                        ]),
                        const Spacer(),
                        Text('YOUR COACH', style: akT(11, w: FontWeight.w800, c: Colors.white60, ls: 1.3)),
                        Text(t.name, style: akT(24, w: FontWeight.w800, c: Colors.white, ls: -0.6)),
                        const SizedBox(height: 10),
                        Row(children: [
                          _pill(context, s.liveNow ? 'Join live' : 'Live at ${hhmm(s.nextLive)}', Icons.videocam_rounded,
                              () => shopPush(context, LiveSessionPage(trainer: t, title: 'Full body burn'))),
                          const SizedBox(width: 8),
                          _pill(context, 'Message', Icons.chat_bubble_rounded, () => shopPush(context, const CoachChatPage()), light: true),
                        ]),
                      ]),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 14),
              Rise(
                delay: 60,
                child: ShopCard(
                  onTap: () => shopPush(context, const WorkoutPlanPage()),
                  child: Row(children: [
                    SizedBox(
                      width: 64,
                      height: 64,
                      child: Stack(alignment: Alignment.center, children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(end: done / day.$3.length),
                          duration: const Duration(milliseconds: 900),
                          curve: akSpring,
                          builder: (_, v, _) => CircularProgressIndicator(
                            value: v.clamp(0.0, 1.0),
                            strokeWidth: 7,
                            strokeCap: StrokeCap.round,
                            backgroundColor: const Color(0xFFEDE9FE),
                            color: tViolet,
                          ),
                        ),
                        Text('$done/${day.$3.length}', style: akN(15)),
                      ]),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text("TODAY'S WORKOUT", style: akT(10.5, w: FontWeight.w800, c: akFaint, ls: 1.1)),
                        Text(day.$1, style: akT(18, w: FontWeight.w800)),
                        Text(day.$2, style: akT(12.5, w: FontWeight.w600, c: akMuted)),
                      ]),
                    ),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(color: tViolet, shape: BoxShape.circle),
                      child: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                    ),
                  ]),
                ),
              ),
              const AkHead('Your coaching'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.35,
                  children: [
                    for (var i = 0; i < feats.length; i++)
                      Rise(
                        delay: i * 50,
                        child: AkPress(
                          onTap: feats[i].$5,
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.94),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [BoxShadow(color: feats[i].$4.withValues(alpha: 0.12), blurRadius: 16, offset: const Offset(0, 8))],
                            ),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(13),
                                  gradient: LinearGradient(colors: [feats[i].$4.withValues(alpha: 0.7), feats[i].$4]),
                                ),
                                child: Icon(feats[i].$1, color: Colors.white, size: 20),
                              ),
                              const Spacer(),
                              Text(feats[i].$2, style: akT(14.5, w: FontWeight.w800)),
                              Text(feats[i].$3, maxLines: 1, overflow: TextOverflow.ellipsis, style: akT(12, w: FontWeight.w600, c: feats[i].$4)),
                            ]),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const AkHead('This week'),
              ShopCard(child: _WeekStreak(s)),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ShopButton('Manage subscription', outline: true, color: akMuted, onTap: () => _manage(context, t)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _pill(BuildContext context, String l, IconData i, VoidCallback f, {bool light = false}) => AkPress(
        onTap: f,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(color: light ? Colors.white24 : Colors.white, borderRadius: BorderRadius.circular(14)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(i, size: 16, color: light ? Colors.white : tViolet),
            const SizedBox(width: 6),
            Text(l, style: akT(12.5, w: FontWeight.w800, c: light ? Colors.white : tViolet)),
          ]),
        ),
      );

  void _manage(BuildContext context, Trainer t) => showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (c) {
          final s = TrainerStore.I;
          return Container(
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
            padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.paddingOf(c).bottom),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('Subscription', style: akT(20, w: FontWeight.w800)),
              const SizedBox(height: 12),
              _kv('Coach', t.name),
              _kv('Plan', '${s.planName}'),
              _kv('Started', dayName(s.since!)),
              _kv('Renews', dayName(s.until!)),
              const SizedBox(height: 16),
              ShopButton('Cancel subscription', color: const Color(0xFFEF4444), outline: true, onTap: () {
                Navigator.of(c).pop();
                s.cancel();
                shopToast(context, 'Subscription cancelled', icon: Icons.cancel_rounded);
              }),
            ]),
          );
        },
      );

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Text(k, style: akT(14, w: FontWeight.w500, c: akMuted)),
          const Spacer(),
          Text(v, style: akT(14, w: FontWeight.w800)),
        ]),
      );
}

class _WeekStreak extends StatelessWidget {
  final TrainerStore s;
  const _WeekStreak(this.s);
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = [for (var i = 6; i >= 0; i--) now.subtract(Duration(days: i))];
    const n = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.local_fire_department_rounded, color: Color(0xFFF97316)),
        const SizedBox(width: 6),
        Text('${s.streak}-day coaching streak', style: akT(15, w: FontWeight.w800)),
      ]),
      const SizedBox(height: 12),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        for (final d in days)
          Column(children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: s.daysDone.containsKey('${d.year}-${d.month}-${d.day}') ? tViolet : const Color(0xFFF1F2F4),
              ),
              child: s.daysDone.containsKey('${d.year}-${d.month}-${d.day}') ? const Icon(Icons.check_rounded, color: Colors.white, size: 18) : null,
            ),
            const SizedBox(height: 4),
            Text(n[d.weekday - 1], style: akT(11.5, w: FontWeight.w700, c: akMuted)),
          ]),
      ]),
    ]);
  }
}

// =====================================================================
//  1. LIVE TRAINING
// =====================================================================

class LiveSessionPage extends StatefulWidget {
  final Trainer trainer;
  final String title;
  const LiveSessionPage({super.key, required this.trainer, required this.title});
  @override
  State<LiveSessionPage> createState() => _LiveSessionPageState();
}

class _LiveSessionPageState extends State<LiveSessionPage> with TickerProviderStateMixin {
  final _sw = Stopwatch()..start();
  Timer? _t;
  final room = LiveRoom();
  int get viewers => room.viewers + 1;
  bool mic = false, cam = false;
  List<(String, String)> get msgs => room.messages.length > 6 ? room.messages.sublist(room.messages.length - 6) : room.messages;
  final List<(double, int)> hearts = [];
  final _r = math.Random(3);
  late final AnimationController _float = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
  final _chat = TextEditingController();
  int _seenHearts = 0;

  @override
  void initState() {
    super.initState();
    room.addListener(_changed);
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => hearts.removeWhere((h) => _sw.elapsedMilliseconds - h.$2 > 2600));
    });
    _join();
  }

  void _changed() {
    if (!mounted) return;
    setState(() {
      // Hearts other members send float up too.
      while (_seenHearts < room.hearts) {
        _seenHearts++;
        hearts.add((_r.nextDouble(), _sw.elapsedMilliseconds));
      }
    });
  }

  /// Joins the coach's live session, if one is running.
  Future<void> _join() async {
    try {
      final j = await Api.get('/live/sessions?status=live&trainerId=${widget.trainer.id}');
      final live = Api.list(j);
      if (live.isEmpty) {
        if (mounted) shopToast(context, '${widget.trainer.first} is not live right now. You will get a notification.');
        return;
      }
      final ok = await room.join(live.first['id'].toString());
      if (!ok && mounted && room.error != null) shopToast(context, room.error!);
    } catch (_) {}
  }

  @override
  void dispose() {
    _t?.cancel();
    room.removeListener(_changed);
    room.dispose();
    _float.dispose();
    _chat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.trainer;
    final ex = planDays[3].$3 + planDays[0].$3;
    final sec = _sw.elapsed.inSeconds;
    final idx = (sec ~/ 40) % ex.length;
    final left = 40 - sec % 40;
    final pad = MediaQuery.paddingOf(context);
    String two(int n) => n.toString().padLeft(2, '0');
    return AnnotatedRegion(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(children: [
          Positioned.fill(child: LiveRoomVideo(room: room, placeholder: NetImg(unsplash(t.photo, 900), alignment: Alignment.topCenter))),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0, 0.2, 0.55, 1],
                  colors: [Color(0xCC000000), Colors.transparent, Color(0x33000000), Color(0xEE000000)],
                ),
              ),
            ),
          ),
          // Top bar
          Positioned(
            top: pad.top + 8,
            left: 14,
            right: 14,
            child: Row(children: [
              TrainerAvatar(t, size: 40, ring: true),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.title, style: akT(15, w: FontWeight.w800, c: Colors.white)),
                  Text('with ${t.first} · ${two(sec ~/ 60)}:${two(sec % 60)}', style: akT(12, w: FontWeight.w600, c: Colors.white70)),
                ]),
              ),
              const LiveDot(),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(9)),
                child: Row(children: [
                  const Icon(Icons.visibility_rounded, size: 13, color: Colors.white),
                  const SizedBox(width: 4),
                  Text('$viewers', style: akT(11.5, w: FontWeight.w800, c: Colors.white)),
                ]),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                ),
              ),
            ]),
          ),
          // Self view
          Positioned(
            top: pad.top + 64,
            right: 14,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 92,
              height: 128,
              decoration: BoxDecoration(
                color: cam ? const Color(0xFF334155) : const Color(0xFF1F2937),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white24),
              ),
              child: Center(
                child: cam
                    ? CircleAvatar(radius: 26, backgroundColor: const Color(0xFF7C3AED), child: Text(Me.first.isEmpty ? 'Y' : Me.first[0], style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)))
                    : const Icon(Icons.videocam_off_rounded, color: Colors.white54),
              ),
            ),
          ),
          // Current exercise
          Positioned(
            left: 14,
            right: 14,
            bottom: pad.bottom + 250,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.94), borderRadius: BorderRadius.circular(22)),
              child: Row(children: [
                Container(
                  width: 58,
                  height: 58,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(14)),
                  child: Image.asset(exImg(ex[idx].img), fit: BoxFit.contain),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('NOW · ${idx + 1} of ${ex.length}', style: akT(10.5, w: FontWeight.w800, c: akFaint, ls: 1)),
                    Text(ex[idx].name, style: akT(16, w: FontWeight.w800)),
                    Text('Next: ${ex[(idx + 1) % ex.length].name}', maxLines: 1, overflow: TextOverflow.ellipsis, style: akT(12, w: FontWeight.w600, c: akMuted)),
                  ]),
                ),
                SizedBox(
                  width: 54,
                  height: 54,
                  child: Stack(alignment: Alignment.center, children: [
                    CircularProgressIndicator(value: left / 40, strokeWidth: 5, color: const Color(0xFFEF4444), backgroundColor: const Color(0xFFFEE2E2)),
                    Text('$left', style: akN(17)),
                  ]),
                ),
              ]),
            ),
          ),
          // Chat
          Positioned(
            left: 14,
            right: 110,
            bottom: pad.bottom + 92,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              for (final m in msgs)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(14)),
                    child: Text.rich(TextSpan(children: [
                      TextSpan(text: '${m.$1}  ', style: akT(12.5, w: FontWeight.w800, c: const Color(0xFFC4B5FD))),
                      TextSpan(text: m.$2, style: akT(12.5, w: FontWeight.w600, c: Colors.white)),
                    ])),
                  ),
                ),
            ]),
          ),
          // Floating hearts
          Positioned(
            right: 20,
            bottom: pad.bottom + 90,
            width: 70,
            height: 300,
            child: IgnorePointer(
              child: Stack(children: [
                for (final h in hearts)
                  Builder(builder: (_) {
                    final p = ((_sw.elapsedMilliseconds - h.$2) / 2600).clamp(0.0, 1.0);
                    return Positioned(
                      bottom: p * 280,
                      left: 20 + math.sin(p * 6 + h.$1 * 10) * 18,
                      child: Opacity(opacity: 1 - p, child: Icon(Icons.favorite_rounded, color: Color.lerp(const Color(0xFFEC4899), const Color(0xFFEF4444), h.$1), size: 26)),
                    );
                  }),
              ]),
            ),
          ),
          // Controls
          Positioned(
            left: 14,
            right: 14,
            bottom: pad.bottom + 18,
            child: Row(children: [
              Expanded(
                child: Container(
                  height: 50,
                  padding: const EdgeInsets.only(left: 16, right: 6),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(25)),
                  child: Row(children: [
                    Expanded(
                      child: TextField(
                        controller: _chat,
                        style: akT(14, c: Colors.white),
                        decoration: InputDecoration(border: InputBorder.none, hintText: 'Say something…', hintStyle: akT(14, c: Colors.white54)),
                        onSubmitted: _say,
                      ),
                    ),
                    IconButton(onPressed: () => _say(_chat.text), icon: const Icon(Icons.send_rounded, color: Colors.white)),
                  ]),
                ),
              ),
              const SizedBox(width: 8),
              _ctrl(mic ? Icons.mic_rounded : Icons.mic_off_rounded, () => setState(() => mic = !mic), on: mic),
              const SizedBox(width: 8),
              _ctrl(cam ? Icons.videocam_rounded : Icons.videocam_off_rounded, () => setState(() => cam = !cam), on: cam),
              const SizedBox(width: 8),
              _ctrl(Icons.favorite_rounded, () {
                HapticFeedback.lightImpact();
                _seenHearts++;
                room.sendHeart();
                setState(() => hearts.add((_r.nextDouble(), _sw.elapsedMilliseconds)));
              }, color: const Color(0xFFEC4899)),
            ]),
          ),
          // Repaint hearts smoothly between ticks.
          if (hearts.isNotEmpty) AnimatedBuilder(animation: _float, builder: (_, _) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && hearts.isNotEmpty) setState(() {});
            });
            return const SizedBox.shrink();
          }),
        ]),
      ),
    );
  }

  void _say(String s) {
    if (s.trim().isEmpty) return;
    room.sendChat(s);
    _chat.clear();
  }

  Widget _ctrl(IconData i, VoidCallback f, {bool on = false, Color? color}) => AkPress(
        onTap: f,
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(shape: BoxShape.circle, color: on ? Colors.white : Colors.white.withValues(alpha: 0.16)),
          child: Icon(i, color: color ?? (on ? akInk : Colors.white), size: 22),
        ),
      );
}

// =====================================================================
//  2. WORKOUT PLAN
// =====================================================================

class WorkoutPlanPage extends StatefulWidget {
  const WorkoutPlanPage({super.key});
  @override
  State<WorkoutPlanPage> createState() => _WorkoutPlanPageState();
}

class _WorkoutPlanPageState extends State<WorkoutPlanPage> {
  late int day = TrainerStore.I.planIndex;

  @override
  Widget build(BuildContext context) {
    final s = TrainerStore.I;
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) {
        final d = planDays[day];
        final today = day == s.planIndex;
        final done = d.$3.where((e) => s.isDone(e.name)).length;
        return ShopPage(
          title: 'Workout plan',
          caption: 'Set by ${s.trainer?.first ?? 'your coach'}',
          tint: const Color(0xFF16A34A),
          body: ListView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(0, 12, 0, 40 + MediaQuery.paddingOf(context).bottom),
            children: [
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: planDays.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => AkPress(
                    onTap: () => setState(() => day = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: day == i ? akInk : Colors.white, borderRadius: BorderRadius.circular(16)),
                      child: Text('Day ${i + 1}${i == s.planIndex ? ' · Today' : ''}',
                          style: akT(13, w: FontWeight.w800, c: day == i ? Colors.white : akInk)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              ShopCard(
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(d.$1, style: akT(20, w: FontWeight.w800)),
                      Text(d.$2, style: akT(13, w: FontWeight.w600, c: akMuted)),
                    ]),
                  ),
                  if (today) Text('$done/${d.$3.length}', style: akN(22, c: const Color(0xFF16A34A))),
                ]),
              ),
              const AkHead('Exercises', caption: 'Tap the circle when you finish a set block'),
              for (var i = 0; i < d.$3.length; i++)
                Rise(
                  delay: i * 50,
                  child: ShopCard(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    padding: const EdgeInsets.all(10),
                    child: Row(children: [
                      Container(
                        width: 70,
                        height: 70,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(16)),
                        child: Image.asset(exImg(d.$3[i].img), fit: BoxFit.contain),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(d.$3[i].name, style: akT(15, w: FontWeight.w800)),
                          Text('${d.$3[i].sets} · ${d.$3[i].muscle}', style: akT(12.5, w: FontWeight.w600, c: akMuted)),
                          if (i == 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text('Coach: keep 2 reps in reserve', style: akT(11.5, w: FontWeight.w700, c: tViolet)),
                            ),
                        ]),
                      ),
                      if (today)
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            s.toggleDone(d.$3[i].name, d.$3.length);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 260),
                            curve: akSpring,
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: s.isDone(d.$3[i].name) ? const Color(0xFF16A34A) : Colors.white,
                              border: Border.all(color: s.isDone(d.$3[i].name) ? const Color(0xFF16A34A) : const Color(0xFFD1D5DB), width: 2),
                            ),
                            child: s.isDone(d.$3[i].name) ? const Icon(Icons.check_rounded, color: Colors.white, size: 20) : null,
                          ),
                        ),
                    ]),
                  ),
                ),
              const AkHead('Coach suggestions'),
              for (final sg in const [
                (Icons.swap_horiz_rounded, 'No barbell today?', 'Swap bench press for dumbbell press, same sets and reps.'),
                (Icons.timer_rounded, 'Rest times', '90 s between heavy sets, 45 s for accessories.'),
                (Icons.trending_up_rounded, 'Progression', 'Add 2.5 kg when you hit the top of the rep range twice.'),
              ])
                ShopCard(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(sg.$1, color: tViolet),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(sg.$2, style: akT(14, w: FontWeight.w800)),
                        Text(sg.$3, style: akT(12.5, w: FontWeight.w500, c: akMuted, h: 1.35)),
                      ]),
                    ),
                  ]),
                ),
            ],
          ),
        );
      },
    );
  }
}

// =====================================================================
//  3. DIET PLAN
// =====================================================================

class DietPlanPage extends StatefulWidget {
  const DietPlanPage({super.key});
  @override
  State<DietPlanPage> createState() => _DietPlanPageState();
}

class _DietPlanPageState extends State<DietPlanPage> {
  final Set<int> eaten = {0};

  @override
  Widget build(BuildContext context) {
    final total = dietPlan.fold(0, (a, m) => a + m.$4);
    final got = [for (final i in eaten) dietPlan[i].$4].fold(0, (a, b) => a + b);
    return ShopPage(
      title: 'Diet plan',
      caption: '$total kcal · high protein',
      tint: const Color(0xFFF97316),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(0, 12, 0, 40 + MediaQuery.paddingOf(context).bottom),
        children: [
          ShopCard(
            child: Row(children: [
              SizedBox(
                width: 96,
                height: 96,
                child: Stack(alignment: Alignment.center, children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(end: got / total),
                    duration: const Duration(milliseconds: 800),
                    curve: akSpring,
                    builder: (_, v, _) => SizedBox(
                      width: 96,
                      height: 96,
                      child: CircularProgressIndicator(
                        value: v.clamp(0.0, 1.0),
                        strokeWidth: 9,
                        strokeCap: StrokeCap.round,
                        color: const Color(0xFFF97316),
                        backgroundColor: const Color(0xFFFFEDD5),
                      ),
                    ),
                  ),
                  Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('$got', style: akN(20)),
                    Text('of $total', style: akT(10.5, w: FontWeight.w700, c: akMuted)),
                  ]),
                ]),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(children: [
                  _macro('Protein', 128, 140, const Color(0xFF8B5CF6)),
                  _macro('Carbs', 190, 230, const Color(0xFFF59E0B)),
                  _macro('Fat', 52, 65, const Color(0xFFEC4899)),
                ]),
              ),
            ]),
          ),
          const AkHead("Today's meals", caption: 'Tick a meal when you eat it'),
          for (var i = 0; i < dietPlan.length; i++)
            Rise(
              delay: i * 50,
              child: ShopCard(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => eaten.contains(i) ? eaten.remove(i) : eaten.add(i));
                },
                child: Row(children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(color: dietPlan[i].$6.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(15)),
                    child: Icon(dietPlan[i].$5, color: dietPlan[i].$6),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Text(dietPlan[i].$1, style: akT(14.5, w: FontWeight.w800)),
                        const SizedBox(width: 6),
                        Text(dietPlan[i].$2, style: akT(11.5, w: FontWeight.w600, c: akFaint)),
                      ]),
                      Text(dietPlan[i].$3, style: akT(12.5, w: FontWeight.w500, c: akMuted, h: 1.3)),
                    ]),
                  ),
                  const SizedBox(width: 8),
                  Column(children: [
                    Text('${dietPlan[i].$4}', style: akN(15)),
                    Text('kcal', style: akT(10, w: FontWeight.w600, c: akFaint)),
                  ]),
                  const SizedBox(width: 10),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: eaten.contains(i) ? const Color(0xFF16A34A) : Colors.white,
                      border: Border.all(color: eaten.contains(i) ? const Color(0xFF16A34A) : const Color(0xFFD1D5DB), width: 2),
                    ),
                    child: eaten.contains(i) ? const Icon(Icons.check_rounded, color: Colors.white, size: 16) : null,
                  ),
                ]),
              ),
            ),
          const AkHead('Coach notes'),
          ShopCard(
            child: Text('Drink 3 L of water. Keep dinner light on rest days. Swap paneer for tofu or chicken any time.',
                style: akT(13.5, w: FontWeight.w500, c: akMuted, h: 1.5)),
          ),
        ],
      ),
    );
  }

  Widget _macro(String l, int v, int goal, Color c) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(l, style: akT(12.5, w: FontWeight.w700)),
            const Spacer(),
            Text('$v / ${goal}g', style: akT(11.5, w: FontWeight.w700, c: akMuted)),
          ]),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: v / goal, minHeight: 6, color: c, backgroundColor: c.withValues(alpha: 0.12)),
          ),
        ]),
      );
}

// =====================================================================
//  4. CHAT
// =====================================================================

class CoachChatPage extends StatefulWidget {
  const CoachChatPage({super.key});
  @override
  State<CoachChatPage> createState() => _CoachChatPageState();
}

class _CoachChatPageState extends State<CoachChatPage> {
  final _c = TextEditingController();
  final _sc = ScrollController();

  @override
  void dispose() {
    _c.dispose();
    _sc.dispose();
    super.dispose();
  }

  void _send(String text) {
    if (text.trim().isEmpty) return;
    HapticFeedback.selectionClick();
    TrainerStore.I.send(text.trim());
    _c.clear();
    _down();
  }

  void _down() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_sc.hasClients) _sc.animateTo(_sc.position.maxScrollExtent + 120, duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic);
      });

  @override
  Widget build(BuildContext context) {
    final s = TrainerStore.I;
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) {
        _down();
        final t = s.trainer;
        return ShopPage(
          title: t?.first ?? 'Coach',
          caption: 'Usually replies in minutes',
          tint: const Color(0xFF3B82F6),
          actions: [if (t != null) TrainerAvatar(t, size: 44, ring: true)],
          bottom: Container(
            padding: EdgeInsets.fromLTRB(12, 8, 12, 10 + MediaQuery.paddingOf(context).bottom),
            color: Colors.white.withValues(alpha: 0.96),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              SizedBox(
                height: 34,
                child: ListView(scrollDirection: Axis.horizontal, children: [
                  for (final q in const ['I missed today\'s workout', 'Can I change my diet?', 'Knee pain on squats', 'Feeling great! 💪'])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        label: Text(q, style: akT(12, w: FontWeight.w700)),
                        backgroundColor: const Color(0xFFF1F5F9),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        onPressed: () => _send(q),
                      ),
                    ),
                ]),
              ),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(24)),
                    child: TextField(
                      controller: _c,
                      style: akT(14.5, w: FontWeight.w500),
                      decoration: InputDecoration(border: InputBorder.none, hintText: 'Message your coach', hintStyle: akT(14, c: akFaint)),
                      onSubmitted: _send,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AkPress(
                  onTap: () => _send(_c.text),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(color: Color(0xFF3B82F6), shape: BoxShape.circle),
                    child: const Icon(Icons.arrow_upward_rounded, color: Colors.white),
                  ),
                ),
              ]),
            ]),
          ),
          body: ListView.builder(
            controller: _sc,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(14, 12, 14, 140 + MediaQuery.paddingOf(context).bottom),
            itemCount: s.chat.length,
            itemBuilder: (_, i) {
              final m = s.chat[i];
              return Rise(
                dy: 10,
                child: Align(
                  alignment: m.me ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.76),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: m.me ? const Color(0xFF3B82F6) : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: Radius.circular(m.me ? 20 : 6),
                        bottomRight: Radius.circular(m.me ? 6 : 20),
                      ),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 3))],
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text(m.text, style: akT(14, w: FontWeight.w500, c: m.me ? Colors.white : akInk, h: 1.35)),
                      const SizedBox(height: 3),
                      Text(hhmm(m.at), style: akT(10, w: FontWeight.w600, c: m.me ? Colors.white70 : akFaint)),
                    ]),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// =====================================================================
//  5. CHECK-INS
// =====================================================================

class CheckInPage extends StatefulWidget {
  const CheckInPage({super.key});
  @override
  State<CheckInPage> createState() => _CheckInPageState();
}

class _CheckInPageState extends State<CheckInPage> {
  late double weight = TrainerStore.I.checkins.isEmpty ? 74.0 : TrainerStore.I.checkins.first.weight;
  int energy = 4, sleep = 4;
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = TrainerStore.I;
    const faces = ['😫', '😕', '😐', '🙂', '🤩'];
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) {
        final hist = s.checkins.reversed.toList();
        return ShopPage(
          title: 'Weekly check-in',
          caption: 'Your coach reviews it within 24 h',
          tint: const Color(0xFF8B5CF6),
          bottom: ShopBottomBar(
            child: ShopButton('Send check-in', color: const Color(0xFF8B5CF6), icon: Icons.send_rounded, onTap: () {
              HapticFeedback.mediumImpact();
              s.addCheckIn(CheckIn(DateTime.now(), double.parse(weight.toStringAsFixed(1)), energy, sleep, _note.text.trim()));
              _note.clear();
              shopToast(context, 'Check-in sent to your coach', icon: Icons.check_circle_rounded);
            }),
          ),
          body: ListView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(0, 12, 0, 120 + MediaQuery.paddingOf(context).bottom),
            children: [
              if (hist.length >= 2)
                ShopCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text('Weight trend', style: akT(15, w: FontWeight.w800)),
                      const Spacer(),
                      Text('${(hist.last.weight - hist.first.weight).toStringAsFixed(1)} kg',
                          style: akT(14, w: FontWeight.w800, c: hist.last.weight <= hist.first.weight ? const Color(0xFF16A34A) : const Color(0xFFF97316))),
                    ]),
                    const SizedBox(height: 12),
                    SizedBox(height: 110, child: CustomPaint(size: Size.infinite, painter: _Trend([for (final c in hist) c.weight]))),
                  ]),
                ),
              const AkHead('This week'),
              ShopCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Body weight', style: akT(14, w: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Row(children: [
                    IconButton.filledTonal(onPressed: () => setState(() => weight -= 0.1), icon: const Icon(Icons.remove_rounded)),
                    Expanded(child: Center(child: Text('${weight.toStringAsFixed(1)} kg', style: akN(30)))),
                    IconButton.filledTonal(onPressed: () => setState(() => weight += 0.1), icon: const Icon(Icons.add_rounded)),
                  ]),
                  const SizedBox(height: 16),
                  for (final row in [('Energy', energy, (int v) => setState(() => energy = v)), ('Sleep', sleep, (int v) => setState(() => sleep = v))]) ...[
                    Text(row.$1, style: akT(14, w: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      for (var i = 1; i <= 5; i++)
                        AkPress(
                          onTap: () => row.$3(i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            width: 52,
                            height: 52,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: row.$2 == i ? const Color(0xFF8B5CF6).withValues(alpha: 0.14) : const Color(0xFFF5F6F8),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: row.$2 == i ? const Color(0xFF8B5CF6) : Colors.transparent, width: 1.6),
                            ),
                            child: Text(faces[i - 1], style: const TextStyle(fontSize: 24)),
                          ),
                        ),
                    ]),
                    const SizedBox(height: 14),
                  ],
                  TextField(
                    controller: _note,
                    maxLines: 3,
                    style: akT(14, w: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: 'How did training and food go this week?',
                      hintStyle: akT(13.5, c: akFaint),
                      filled: true,
                      fillColor: const Color(0xFFF5F6F8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                ]),
              ),
              const AkHead('History'),
              for (final c in s.checkins)
                ShopCard(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(dayName(c.at), style: akT(14, w: FontWeight.w800)),
                        if (c.note.isNotEmpty) Text(c.note, style: akT(12.5, w: FontWeight.w500, c: akMuted)),
                      ]),
                    ),
                    Text('${faces[c.energy - 1]} ${faces[c.sleep - 1]}', style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Text('${c.weight} kg', style: akN(15)),
                  ]),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Trend extends CustomPainter {
  final List<double> v;
  _Trend(this.v);
  @override
  void paint(Canvas canvas, Size s) {
    final lo = v.reduce(math.min) - 0.5, hi = v.reduce(math.max) + 0.5;
    Offset pt(int i) => Offset(s.width * i / (v.length - 1), s.height * (1 - (v[i] - lo) / (hi - lo)));
    final p = Path()..moveTo(pt(0).dx, pt(0).dy);
    for (var i = 1; i < v.length; i++) {
      final a = pt(i - 1), b = pt(i);
      p.cubicTo((a.dx + b.dx) / 2, a.dy, (a.dx + b.dx) / 2, b.dy, b.dx, b.dy);
    }
    final fill = Path.from(p)
      ..lineTo(s.width, s.height)
      ..lineTo(0, s.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [const Color(0xFF8B5CF6).withValues(alpha: 0.25), const Color(0x008B5CF6)]).createShader(Offset.zero & s),
    );
    canvas.drawPath(p, Paint()..color = const Color(0xFF8B5CF6)..strokeWidth = 3..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
    for (var i = 0; i < v.length; i++) {
      canvas.drawCircle(pt(i), 5, Paint()..color = Colors.white);
      canvas.drawCircle(pt(i), 3.5, Paint()..color = const Color(0xFF8B5CF6));
    }
  }

  @override
  bool shouldRepaint(_Trend o) => o.v != v;
}

// =====================================================================
//  6. BOOK A CALL
// =====================================================================

class BookCallPage extends StatefulWidget {
  const BookCallPage({super.key});
  @override
  State<BookCallPage> createState() => _BookCallPageState();
}

class _BookCallPageState extends State<BookCallPage> {
  int day = 1, slot = -1, type = 0;
  static const types = [('Video call', Icons.videocam_rounded), ('Form check', Icons.sports_gymnastics_rounded), ('Diet review', Icons.restaurant_rounded)];
  static const slots = [7, 8, 9, 12, 13, 17, 18, 19, 20];

  @override
  Widget build(BuildContext context) {
    final s = TrainerStore.I;
    final now = DateTime.now();
    final days = [for (var i = 0; i < 7; i++) DateTime(now.year, now.month, now.day).add(Duration(days: i))];
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) => ShopPage(
        title: 'Book a call',
        caption: '30 minutes with ${s.trainer?.first ?? 'your coach'}',
        tint: const Color(0xFF14B8A6),
        bottom: ShopBottomBar(
          child: ShopButton(
            slot < 0 ? 'Pick a time' : 'Book ${types[type].$1.toLowerCase()} · ${slots[slot] > 12 ? slots[slot] - 12 : slots[slot]}:00 ${slots[slot] < 12 ? 'AM' : 'PM'}',
            color: const Color(0xFF14B8A6),
            onTap: slot < 0
                ? null
                : () {
                    HapticFeedback.mediumImpact();
                    s.book(Booking(days[day].add(Duration(hours: slots[slot])), types[type].$1));
                    setState(() => slot = -1);
                    shopToast(context, 'Booked! Added to your notifications', icon: Icons.event_available_rounded);
                  },
          ),
        ),
        body: ListView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(0, 12, 0, 120 + MediaQuery.paddingOf(context).bottom),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                for (var i = 0; i < types.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: AkPress(
                      onTap: () => setState(() => type = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: type == i ? const Color(0xFF14B8A6) : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(children: [
                          Icon(types[i].$2, color: type == i ? Colors.white : const Color(0xFF14B8A6)),
                          const SizedBox(height: 4),
                          Text(types[i].$1, style: akT(12, w: FontWeight.w800, c: type == i ? Colors.white : akInk)),
                        ]),
                      ),
                    ),
                  ),
                ],
              ]),
            ),
            const AkHead('Day'),
            SizedBox(
              height: 78,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: days.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) => AkPress(
                  onTap: () => setState(() {
                    day = i;
                    slot = -1;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 60,
                    decoration: BoxDecoration(color: day == i ? akInk : Colors.white, borderRadius: BorderRadius.circular(20)),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][days[i].weekday - 1],
                          style: akT(12, w: FontWeight.w700, c: day == i ? Colors.white70 : akMuted)),
                      Text('${days[i].day}', style: akN(20, c: day == i ? Colors.white : akInk)),
                    ]),
                  ),
                ),
              ),
            ),
            const AkHead('Time'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(spacing: 8, runSpacing: 8, children: [
                for (var i = 0; i < slots.length; i++)
                  Builder(builder: (_) {
                    final at = days[day].add(Duration(hours: slots[i]));
                    final taken = at.isBefore(now) || s.bookings.any((b) => b.at == at) || (i + day) % 4 == 0;
                    final on = slot == i;
                    return AkPress(
                      onTap: taken ? null : () => setState(() => slot = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: (MediaQuery.sizeOf(context).width - 48) / 3,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: on ? const Color(0xFF14B8A6) : (taken ? const Color(0xFFF1F2F4) : Colors.white),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          '${slots[i] > 12 ? slots[i] - 12 : slots[i]}:00 ${slots[i] < 12 ? 'AM' : 'PM'}',
                          style: akT(13, w: FontWeight.w800, c: on ? Colors.white : (taken ? akFaint : akInk)).copyWith(
                            decoration: taken ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                    );
                  }),
              ]),
            ),
            if (s.bookings.isNotEmpty) ...[
              const AkHead('Upcoming'),
              for (final b in s.bookings)
                ShopCard(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: Row(children: [
                    const Icon(Icons.event_rounded, color: Color(0xFF14B8A6)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(b.type, style: akT(14, w: FontWeight.w800)),
                        Text('${dayName(b.at)} · ${hhmm(b.at)}', style: akT(12.5, w: FontWeight.w600, c: akMuted)),
                      ]),
                    ),
                    TextButton(onPressed: () => s.cancelBooking(b), child: Text('Cancel', style: akT(13, w: FontWeight.w800, c: const Color(0xFFEF4444)))),
                  ]),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

// =====================================================================
//  7. NOTIFICATIONS
// =====================================================================

class CoachNotesPage extends StatelessWidget {
  const CoachNotesPage({super.key});

  static const _kind = {
    'live': (Icons.live_tv_rounded, Color(0xFFEF4444)),
    'plan': (Icons.fitness_center_rounded, Color(0xFF16A34A)),
    'diet': (Icons.restaurant_menu_rounded, Color(0xFFF97316)),
    'chat': (Icons.chat_bubble_rounded, Color(0xFF3B82F6)),
    'checkin': (Icons.monitor_weight_rounded, Color(0xFF8B5CF6)),
    'booking': (Icons.event_available_rounded, Color(0xFF14B8A6)),
  };

  @override
  Widget build(BuildContext context) {
    final s = TrainerStore.I;
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) => ShopPage(
        title: 'Notifications',
        caption: s.unread == 0 ? 'All caught up' : '${s.unread} unread',
        tint: tPink,
        actions: [if (s.unread > 0) GlassIcon(Icons.done_all_rounded, onTap: s.readAll)],
        body: s.notes.isEmpty
            ? EmptyState(
                icon: Icons.notifications_none_rounded,
                title: 'Nothing yet',
                body: 'Updates from your coach show up here.',
                action: 'Back',
                color: tPink,
                onAction: () => Navigator.of(context).maybePop(),
              )
            : ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(0, 12, 0, 40 + MediaQuery.paddingOf(context).bottom),
                itemCount: s.notes.length,
                itemBuilder: (_, i) {
                  final n = s.notes[i];
                  final k = _kind[n.kind] ?? _kind['plan']!;
                  return Rise(
                    delay: math.min(i, 6) * 40,
                    child: ShopCard(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      color: n.read ? Colors.white : const Color(0xFFFDF2F8),
                      onTap: () {
                        s.markRead(n);
                        if (n.kind == 'chat') shopPush(context, const CoachChatPage());
                        if (n.kind == 'live' && s.trainer != null) shopPush(context, LiveSessionPage(trainer: s.trainer!, title: 'Full body burn'));
                      },
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(color: k.$2.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
                          child: Icon(k.$1, color: k.$2, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Expanded(child: Text(n.title, style: akT(14, w: FontWeight.w800))),
                              Text(ago(n.at), style: akT(11.5, w: FontWeight.w600, c: akFaint)),
                            ]),
                            const SizedBox(height: 2),
                            Text(n.body, style: akT(12.5, w: FontWeight.w500, c: akMuted, h: 1.35)),
                          ]),
                        ),
                        if (!n.read) ...[
                          const SizedBox(width: 8),
                          Container(width: 8, height: 8, margin: const EdgeInsets.only(top: 6), decoration: const BoxDecoration(color: tPink, shape: BoxShape.circle)),
                        ],
                      ]),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
