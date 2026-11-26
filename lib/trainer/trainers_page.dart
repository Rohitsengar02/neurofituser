import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../shop/shop_ui.dart';
import '../widgets/apple_kit.dart';
import '../widgets/liquid_glass.dart';
import '../widgets/net_img.dart';
import 'panel_onboarding.dart';
import 'trainer_data.dart';
import 'trainer_hub.dart';

// Trainers tab: search, your coach, categories, recommended carousel, live
// now, top rated, programs, success stories and a become-a-coach banner.
// Trainer detail with plans and subscribe checkout.

const tViolet = Color(0xFF7C3AED);
const tPink = Color(0xFFEC4899);

void openTrainer(BuildContext context, Trainer t) => shopPush(context, TrainerDetailPage(t));

class TrainersPage extends StatefulWidget {
  const TrainersPage({super.key});
  @override
  State<TrainersPage> createState() => _TrainersPageState();
}

class _TrainersPageState extends State<TrainersPage> {
  int cat = -1;
  String q = '';

  List<Trainer> get _list => trainers
      .where((t) => cat < 0 || t.cat == trainerCats[cat].name)
      .where((t) => q.isEmpty || '${t.name} ${t.role} ${t.tags.join(' ')}'.toLowerCase().contains(q.toLowerCase()))
      .toList();

  @override
  Widget build(BuildContext context) {
    final list = _list;
    final top = [...list]..sort((a, b) => b.rating.compareTo(a.rating));
    final live = trainers.where((t) => t.live).toList();
    return Stack(children: [
      const Positioned.fill(child: ShopBackdrop(tint: tViolet, tint2: tPink)),
      ListenableBuilder(
        listenable: TrainerStore.I,
        builder: (context, _) => ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(top: 12, bottom: 130),
          children: [
            const AkWelcome(caption: 'TRAINERS · 1:1 COACHING', words: ['Train', 'with', 'the', 'best'], accent: tViolet),
            const SizedBox(height: 14),
            _search(),
            if (TrainerStore.I.active) ...[
              const SizedBox(height: 16),
              const YourTrainerCard(),
            ],
            const AkHead('Categories'),
            _cats(),
            if (list.isEmpty)
              Padding(
                padding: const EdgeInsets.all(30),
                child: Text('No coaches match that yet.', textAlign: TextAlign.center, style: akT(14, c: akMuted)),
              )
            else ...[
              AkHead('Recommended for you', caption: cat < 0 ? 'Based on your goals and workouts' : trainerCats[cat].name),
              _Recommended(items: list),
            ],
            const AkHead('Live now', caption: 'Drop in for free'),
            _LiveRail(items: live),
            const AkHead('Top rated'),
            for (var i = 0; i < math.min(top.length, 5); i++)
              Rise(delay: i * 50, child: Padding(padding: const EdgeInsets.only(bottom: 10), child: _RankRow(rank: i + 1, t: top[i]))),
            const AkHead('Coach programs', caption: 'Ready-made plans from our coaches'),
            const _Programs(),
            const AkHead('Success stories'),
            const _Stories(),
            const SizedBox(height: 18),
            const ScrollReveal(child: BecomeCoachBanner()),
          ],
        ),
      ),
    ]);
  }

  Widget _search() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: LiquidGlass(
          style: LiquidGlassStyle.material,
          borderRadius: BorderRadius.circular(20),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(children: [
            const Icon(Icons.search_rounded, color: akMuted, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                onChanged: (v) => setState(() => q = v),
                style: akT(14.5, w: FontWeight.w600),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Search coaches, goals, styles…',
                  hintStyle: akT(14, w: FontWeight.w500, c: akFaint),
                ),
              ),
            ),
            const Icon(Icons.tune_rounded, color: akMuted, size: 20),
          ]),
        ),
      );

  Widget _cats() => SizedBox(
        height: 96,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: trainerCats.length + 1,
          separatorBuilder: (_, _) => const SizedBox(width: 10),
          itemBuilder: (_, i) {
            final on = cat == i - 1;
            final c = i == 0 ? const TrainerCat('All', Icons.apps_rounded, tViolet) : trainerCats[i - 1];
            return AkPress(
              onTap: () => setState(() => cat = i - 1),
              child: Column(children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: akSpring,
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: on ? LinearGradient(colors: [c.color.withValues(alpha: 0.75), c.color]) : null,
                    color: on ? null : Colors.white.withValues(alpha: 0.9),
                    boxShadow: [BoxShadow(color: c.color.withValues(alpha: on ? 0.4 : 0.1), blurRadius: on ? 14 : 8, offset: const Offset(0, 5))],
                  ),
                  child: Icon(c.icon, color: on ? Colors.white : c.color, size: 26),
                ),
                const SizedBox(height: 7),
                Text(c.name, style: akT(12, w: on ? FontWeight.w800 : FontWeight.w600, c: on ? akInk : akMuted)),
              ]),
            );
          },
        ),
      );
}

// ---------------------------------------------------------------- pieces

class TrainerAvatar extends StatelessWidget {
  final Trainer t;
  final double size;
  final bool ring;
  const TrainerAvatar(this.t, {super.key, this.size = 48, this.ring = false});
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(ring ? 2.5 : 0),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: ring ? const LinearGradient(colors: [tViolet, tPink, Color(0xFFF97316)]) : null,
        ),
        child: Container(
          decoration: BoxDecoration(shape: BoxShape.circle, border: ring ? Border.all(color: Colors.white, width: 2) : null),
          child: ClipOval(child: NetImg(unsplash(t.photo, 200), width: size, height: size)),
        ),
      );
}

class RatingPill extends StatelessWidget {
  final double rating;
  final bool dark;
  const RatingPill(this.rating, {super.key, this.dark = false});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: dark ? Colors.white.withValues(alpha: 0.22) : const Color(0xFFFFF7E6),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
          const SizedBox(width: 3),
          Text('$rating', style: akT(12, w: FontWeight.w800, c: dark ? Colors.white : akInk)),
        ]),
      );
}

class LiveDot extends StatefulWidget {
  final String label;
  const LiveDot({super.key, this.label = 'LIVE'});
  @override
  State<LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<LiveDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(9)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          FadeTransition(
            opacity: Tween(begin: 0.3, end: 1.0).animate(_c),
            child: Container(width: 7, height: 7, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
          ),
          const SizedBox(width: 5),
          Text(widget.label, style: akT(10.5, w: FontWeight.w900, c: Colors.white, ls: 0.8)),
        ]),
      );
}

class _Recommended extends StatefulWidget {
  final List<Trainer> items;
  const _Recommended({required this.items});
  @override
  State<_Recommended> createState() => _RecommendedState();
}

class _RecommendedState extends State<_Recommended> {
  final _pc = PageController(viewportFraction: 0.78);

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 360,
      child: PageView.builder(
        controller: _pc,
        padEnds: false,
        itemCount: widget.items.length,
        itemBuilder: (_, i) {
          final t = widget.items[i];
          return AnimatedBuilder(
            animation: _pc,
            builder: (_, c) {
              final d = _pc.hasClients && _pc.position.haveDimensions ? ((_pc.page ?? 0) - i).abs().clamp(0.0, 1.0) : (i == 0 ? 0.0 : 1.0);
              return Transform.scale(scale: 1 - d * 0.06, alignment: Alignment.centerLeft, child: c);
            },
            child: Padding(
              padding: EdgeInsets.only(left: i == 0 ? 16 : 6, right: 6, bottom: 8),
              child: AkPress(
                scale: 0.97,
                onTap: () => openTrainer(context, t),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [BoxShadow(color: tViolet.withValues(alpha: 0.18), blurRadius: 22, offset: const Offset(0, 10))],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(fit: StackFit.expand, children: [
                    NetImg(t.img, alignment: Alignment.topCenter),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: [0.35, 1],
                          colors: [Colors.transparent, Color(0xE6120A2A)],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 14,
                      left: 14,
                      right: 14,
                      child: Row(children: [
                        if (t.live) const LiveDot(),
                        const Spacer(),
                        RatingPill(t.rating, dark: true),
                      ]),
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Flexible(child: Text(t.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: akT(21, w: FontWeight.w800, c: Colors.white, ls: -0.5))),
                          const SizedBox(width: 5),
                          const Icon(Icons.verified_rounded, color: Color(0xFF60A5FA), size: 18),
                        ]),
                        Text(t.role, style: akT(13, w: FontWeight.w600, c: Colors.white70)),
                        const SizedBox(height: 10),
                        Row(children: [
                          _mini(Icons.workspace_premium_rounded, '${t.years} yrs'),
                          const SizedBox(width: 6),
                          _mini(Icons.people_alt_rounded, '${(t.clients / 1000).toStringAsFixed(1)}K'),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                            child: Text('${inr(t.price)}/mo', style: akT(13, w: FontWeight.w800)),
                          ),
                        ]),
                      ]),
                    ),
                  ]),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _mini(IconData i, String l) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(10)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(i, size: 13, color: Colors.white),
          const SizedBox(width: 4),
          Text(l, style: akT(11.5, w: FontWeight.w700, c: Colors.white)),
        ]),
      );
}

class _LiveRail extends StatelessWidget {
  final List<Trainer> items;
  const _LiveRail({required this.items});
  @override
  Widget build(BuildContext context) {
    const titles = ['Full body burn', 'Strength basics', 'Core & cardio'];
    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final t = items[i];
          return Rise(
            delay: i * 60,
            child: AkPress(
              onTap: () => shopPush(context, LiveSessionPage(trainer: t, title: titles[i % 3])),
              child: Container(
                width: 230,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(26)),
                clipBehavior: Clip.antiAlias,
                child: Stack(fit: StackFit.expand, children: [
                  NetImg(t.img, alignment: Alignment.topCenter),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x33000000), Color(0xCC000000)]),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: Row(children: [
                      const LiveDot(),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(9)),
                        child: Row(children: [
                          const Icon(Icons.visibility_rounded, size: 12, color: Colors.white),
                          const SizedBox(width: 4),
                          Text('${120 + i * 87}', style: akT(11, w: FontWeight.w800, c: Colors.white)),
                        ]),
                      ),
                    ]),
                  ),
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 14,
                    child: Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(titles[i % 3], style: akT(16, w: FontWeight.w800, c: Colors.white)),
                          Text('with ${t.first}', style: akT(12.5, w: FontWeight.w600, c: Colors.white70)),
                        ]),
                      ),
                      Container(
                        width: 38,
                        height: 38,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.play_arrow_rounded, color: akInk),
                      ),
                    ]),
                  ),
                ]),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  final int rank;
  final Trainer t;
  const _RankRow({required this.rank, required this.t});
  @override
  Widget build(BuildContext context) {
    final fol = TrainerStore.I.following.contains(t.id);
    return ShopCard(
      onTap: () => openTrainer(context, t),
      padding: const EdgeInsets.all(12),
      child: Row(children: [
        SizedBox(
          width: 26,
          child: Text('$rank',
              style: akN(20, c: rank == 1 ? const Color(0xFFF59E0B) : (rank <= 3 ? tViolet : akFaint))),
        ),
        TrainerAvatar(t, size: 54, ring: rank <= 3),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(child: Text(t.name, overflow: TextOverflow.ellipsis, style: akT(15, w: FontWeight.w800))),
              const SizedBox(width: 4),
              const Icon(Icons.verified_rounded, color: Color(0xFF3B82F6), size: 15),
            ]),
            Text(t.role, maxLines: 1, overflow: TextOverflow.ellipsis, style: akT(12.5, w: FontWeight.w500, c: akMuted)),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
              Text(' ${t.rating} · ${t.reviews} reviews', style: akT(11.5, w: FontWeight.w700, c: akMuted)),
            ]),
          ]),
        ),
        AkPress(
          onTap: () {
            HapticFeedback.selectionClick();
            TrainerStore.I.toggleFollow(t);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: fol ? const Color(0xFFF3F4F6) : akInk,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(fol ? 'Following' : 'Follow', style: akT(12, w: FontWeight.w800, c: fol ? akInk : Colors.white)),
          ),
        ),
      ]),
    );
  }
}

class _Programs extends StatelessWidget {
  const _Programs();
  @override
  Widget build(BuildContext context) {
    const items = [
      ('12-week strength', '4 days/wk · Rahul', '0043-qXTaZnJ.jpg', Color(0xFF16A34A), 't1'),
      ('Fat loss kickstart', '5 days/wk · Anjali', '1160-dK9394r.jpg', Color(0xFFF97316), 't2'),
      ('Lean bulk', '5 days/wk · Vikram', '0025-EIeI8Vf.jpg', Color(0xFF0EA5E9), 't3'),
      ('20-min HIIT', '3 days/wk · Arjun', '0630-RJgzwny.jpg', Color(0xFFEAB308), 't5'),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.86,
        children: [
          for (var i = 0; i < items.length; i++)
            ScrollReveal(
              delayMs: (i % 2) * 80,
              child: AkPress(
                onTap: () => openTrainer(context, trainerById(items[i].$5)),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: items[i].$4.withValues(alpha: 0.14), blurRadius: 16, offset: const Offset(0, 8))],
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: items[i].$4.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        padding: const EdgeInsets.all(6),
                        child: Image.asset(exImg(items[i].$3), fit: BoxFit.contain),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(items[i].$1, maxLines: 1, overflow: TextOverflow.ellipsis, style: akT(14, w: FontWeight.w800)),
                    Text(items[i].$2, maxLines: 1, overflow: TextOverflow.ellipsis, style: akT(11.5, w: FontWeight.w600, c: akMuted)),
                  ]),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Stories extends StatelessWidget {
  const _Stories();
  @override
  Widget build(BuildContext context) {
    const s = [
      ('-12 kg', 'Weight loss · 12 weeks', '1581009146145-b5ef050c2e1e', '1534528741775-53994a69daeb', 'with Anjali'),
      ('-8 kg', 'Fat loss · 10 weeks', '1531746020798-e6953c6e8e04', '1544005313-94ddf0286df2', 'with Arjun'),
      ('+6 kg', 'Muscle gain · 16 weeks', '1567013127542-490d757e51fc', '1583454110551-21f2fa2afe61', 'with Vikram'),
    ];
    return SizedBox(
      height: 210,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: s.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, i) => Rise(
          delay: i * 60,
          child: Container(
            width: 260,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 14, offset: const Offset(0, 6))],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Row(children: [
                  for (final k in [0, 1])
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: k == 0 ? 4 : 0, left: k == 1 ? 4 : 0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(fit: StackFit.expand, children: [
                            NetImg(unsplash(k == 0 ? s[i].$3 : s[i].$4, 300)),
                            Positioned(
                              left: 6,
                              top: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(color: k == 0 ? Colors.black54 : const Color(0xFF16A34A), borderRadius: BorderRadius.circular(8)),
                                child: Text(k == 0 ? 'BEFORE' : 'AFTER', style: akT(9.5, w: FontWeight.w900, c: Colors.white, ls: 0.6)),
                              ),
                            ),
                          ]),
                        ),
                      ),
                    ),
                ]),
              ),
              const SizedBox(height: 8),
              Row(children: [
                Text(s[i].$1, style: akN(18, c: const Color(0xFF16A34A))),
                const SizedBox(width: 8),
                Expanded(child: Text(s[i].$2, maxLines: 1, overflow: TextOverflow.ellipsis, style: akT(12.5, w: FontWeight.w700))),
                Text(s[i].$5, style: akT(11.5, w: FontWeight.w600, c: akMuted)),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}

class BecomeCoachBanner extends StatelessWidget {
  const BecomeCoachBanner({super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: AkPress(
          onTap: () => openTrainerPanel(context),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1E1B4B), tViolet, tPink]),
              boxShadow: [BoxShadow(color: tViolet.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 12))],
            ),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('ARE YOU A COACH?', style: akT(11, w: FontWeight.w800, c: Colors.white70, ls: 1.3)),
                  const SizedBox(height: 4),
                  Text('Train clients on NeuroFit', style: akT(20, w: FontWeight.w800, c: Colors.white, ls: -0.5)),
                  const SizedBox(height: 4),
                  Text('Go live, sell plans and manage clients in one place.', style: akT(12.5, w: FontWeight.w500, c: Colors.white70, h: 1.35)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                    child: Text('Open trainer panel', style: akT(13, w: FontWeight.w800, c: tViolet)),
                  ),
                ]),
              ),
              const SizedBox(width: 10),
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.15)),
                child: const Icon(Icons.sports_rounded, color: Colors.white, size: 40),
              ),
            ]),
          ),
        ),
      );
}

/// "Your trainer" card, used on the Trainers tab and on Overview.
class YourTrainerCard extends StatelessWidget {
  const YourTrainerCard({super.key});
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: TrainerStore.I,
      builder: (context, _) {
        final s = TrainerStore.I;
        final t = s.trainer;
        if (!s.active || t == null) return const SizedBox.shrink();
        final day = planDays[s.planIndex];
        final done = day.$3.where((e) => s.isDone(e.name)).length;
        final p = done / day.$3.length;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AkPress(
            scale: 0.98,
            onTap: () => shopPush(context, const TrainerHubPage()),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF2E1065), tViolet]),
                boxShadow: [BoxShadow(color: tViolet.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  TrainerAvatar(t, size: 46, ring: true),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('YOUR TRAINER', style: akT(10.5, w: FontWeight.w800, c: Colors.white60, ls: 1.2)),
                      Text(t.name, style: akT(17, w: FontWeight.w800, c: Colors.white)),
                    ]),
                  ),
                  if (s.liveNow) const LiveDot() else if (s.unread > 0) CountBadge(s.unread, color: tPink),
                ]),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text("Today · ${day.$1}", style: akT(14.5, w: FontWeight.w800, c: Colors.white)),
                      Text('$done of ${day.$3.length} exercises done', style: akT(12, w: FontWeight.w600, c: Colors.white70)),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(value: p, minHeight: 6, backgroundColor: Colors.white24, color: Colors.white),
                      ),
                    ]),
                  ),
                  const SizedBox(width: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.play_arrow_rounded, color: tViolet, size: 18),
                      Text(p >= 1 ? 'Review' : 'Continue', style: akT(13, w: FontWeight.w800, c: tViolet)),
                    ]),
                  ),
                ]),
              ]),
            ),
          ),
        );
      },
    );
  }
}

// =====================================================================
//  TRAINER DETAIL
// =====================================================================

class TrainerDetailPage extends StatefulWidget {
  final Trainer t;
  const TrainerDetailPage(this.t, {super.key});
  @override
  State<TrainerDetailPage> createState() => _TrainerDetailPageState();
}

class _TrainerDetailPageState extends State<TrainerDetailPage> {
  int plan = 1;

  static const features = [
    (Icons.live_tv_rounded, 'Live training', Color(0xFFEF4444)),
    (Icons.fitness_center_rounded, 'Workout plan', Color(0xFF16A34A)),
    (Icons.restaurant_menu_rounded, 'Diet plan', Color(0xFFF97316)),
    (Icons.chat_bubble_rounded, '1:1 chat', Color(0xFF3B82F6)),
    (Icons.monitor_weight_rounded, 'Weekly check-ins', Color(0xFF8B5CF6)),
    (Icons.event_available_rounded, 'Book calls', Color(0xFF14B8A6)),
    (Icons.notifications_active_rounded, 'Smart reminders', Color(0xFFEC4899)),
  ];

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    final s = TrainerStore.I;
    final top = MediaQuery.paddingOf(context).top;
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) {
        final mine = s.active && s.trainerId == t.id;
        final p = t.plans[plan];
        return Scaffold(
          backgroundColor: shopBg,
          body: Stack(children: [
            const Positioned.fill(child: ShopBackdrop(tint: tViolet, tint2: tPink)),
            CustomScrollView(physics: const BouncingScrollPhysics(), slivers: [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 430 + top,
                  child: Stack(fit: StackFit.expand, children: [
                    Hero(tag: 'trainer-${t.id}', child: NetImg(unsplash(t.photo, 900), alignment: Alignment.topCenter)),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: [0, 0.25, 0.6, 1],
                          colors: [Color(0x66000000), Colors.transparent, Colors.transparent, shopBg],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 4,
                      child: Rise(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            if (t.live) ...[const LiveDot(), const SizedBox(width: 8)],
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(9)),
                              child: Text(t.cat.toUpperCase(), style: akT(10.5, w: FontWeight.w900, c: tViolet, ls: 0.8)),
                            ),
                          ]),
                          const SizedBox(height: 8),
                          Row(children: [
                            Flexible(child: Text(t.name, style: akT(32, w: FontWeight.w800, ls: -1.2))),
                            const SizedBox(width: 6),
                            const Icon(Icons.verified_rounded, color: Color(0xFF3B82F6), size: 24),
                          ]),
                          Text('${t.role} · ${t.city}', style: akT(14, w: FontWeight.w600, c: akMuted)),
                        ]),
                      ),
                    ),
                  ]),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Rise(
                    delay: 80,
                    child: Row(children: [
                      _stat('${t.rating}', '${t.reviews} reviews', Icons.star_rounded, const Color(0xFFF59E0B)),
                      const SizedBox(width: 10),
                      _stat('${(t.clients / 1000).toStringAsFixed(1)}K', 'clients', Icons.people_alt_rounded, const Color(0xFF3B82F6)),
                      const SizedBox(width: 10),
                      _stat('${t.years} yrs', 'experience', Icons.workspace_premium_rounded, tViolet),
                    ]),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Rise(
                  delay: 120,
                  child: ShopCard(
                    margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('About', style: akT(16, w: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Text(t.bio, style: akT(13.5, w: FontWeight.w500, c: akMuted, h: 1.5)),
                      const SizedBox(height: 12),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        for (final g in t.tags)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(color: tViolet.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
                            child: Text(g, style: akT(12.5, w: FontWeight.w700, c: tViolet)),
                          ),
                      ]),
                    ]),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: AkHead('What you get', caption: '7 features once you subscribe')),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(spacing: 10, runSpacing: 10, children: [
                    for (var i = 0; i < features.length; i++)
                      Rise(
                        delay: i * 40,
                        child: Container(
                          width: (MediaQuery.sizeOf(context).width - 52) / 3,
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.92), borderRadius: BorderRadius.circular(20)),
                          child: Column(children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(color: features[i].$3.withValues(alpha: 0.12), shape: BoxShape.circle),
                              child: Icon(features[i].$1, color: features[i].$3, size: 20),
                            ),
                            const SizedBox(height: 6),
                            Text(features[i].$2, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: akT(11.5, w: FontWeight.w700)),
                          ]),
                        ),
                      ),
                  ]),
                ),
              ),
              const SliverToBoxAdapter(child: AkHead('Choose a plan')),
              SliverToBoxAdapter(
                child: Column(children: [
                  for (var i = 0; i < t.plans.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _PlanCard(t.plans[i], selected: plan == i, best: i == 1, onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => plan = i);
                      }),
                    ),
                ]),
              ),
              const SliverToBoxAdapter(child: AkHead('Reviews')),
              SliverToBoxAdapter(
                child: Column(children: [
                  for (final r in const [
                    ('Aman', 5, 'Lost 9 kg in 3 months and never felt like I was dieting. The weekly check-ins kept me honest.'),
                    ('Riya', 5, 'Live sessions are so much fun, and the plan adapts every week.'),
                    ('Dev', 4, 'Great coach, quick replies. I wish there were more evening slots.'),
                  ])
                    ShopCard(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          CircleAvatar(radius: 14, backgroundColor: tViolet.withValues(alpha: 0.12), child: Text(r.$1[0], style: akT(12, w: FontWeight.w800, c: tViolet))),
                          const SizedBox(width: 8),
                          Expanded(child: Text(r.$1, style: akT(13.5, w: FontWeight.w800))),
                          for (var k = 0; k < 5; k++) Icon(Icons.star_rounded, size: 14, color: k < r.$2 ? const Color(0xFFF59E0B) : Colors.black12),
                        ]),
                        const SizedBox(height: 6),
                        Text(r.$3, style: akT(13, w: FontWeight.w500, c: akMuted, h: 1.4)),
                      ]),
                    ),
                ]),
              ),
              const SliverToBoxAdapter(child: AkHead('More coaches like this')),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 150,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      for (final o in trainers.where((x) => x != t))
                        Padding(
                          padding: const EdgeInsets.only(right: 14),
                          child: GestureDetector(
                            onTap: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => TrainerDetailPage(o))),
                            child: Column(children: [
                              TrainerAvatar(o, size: 76, ring: o.live),
                              const SizedBox(height: 6),
                              Text(o.first, style: akT(13, w: FontWeight.w800)),
                              Text(o.cat, style: akT(11, w: FontWeight.w600, c: akMuted)),
                            ]),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: 120 + MediaQuery.paddingOf(context).bottom)),
            ]),
            Positioned(
              top: top + 8,
              left: 12,
              right: 12,
              child: Row(children: [
                GlassIcon(Icons.arrow_back_ios_new_rounded, onTap: () => Navigator.of(context).maybePop()),
                const Spacer(),
                GlassIcon(
                  s.following.contains(t.id) ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: s.following.contains(t.id) ? const Color(0xFFEF4444) : akInk,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    s.toggleFollow(t);
                  },
                ),
              ]),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ShopBottomBar(
                child: mine
                    ? ShopButton('Open your coaching', icon: Icons.arrow_forward_rounded, color: tViolet, onTap: () => shopPush(context, const TrainerHubPage()))
                    : Row(children: [
                        Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(inr(p.price), style: akN(22)),
                          Text('${p.name} · ${inr(p.perMonth)}/mo', style: akT(11.5, w: FontWeight.w700, c: akMuted)),
                        ]),
                        const SizedBox(width: 14),
                        Expanded(
                          child: ShopButton('Subscribe', icon: Icons.bolt_rounded, color: tViolet, onTap: () => _subscribe(t, p)),
                        ),
                      ]),
              ),
            ),
          ]),
        );
      },
    );
  }

  Widget _stat(String v, String l, IconData i, Color c) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.92), borderRadius: BorderRadius.circular(20)),
          child: Column(children: [
            Icon(i, color: c, size: 20),
            const SizedBox(height: 4),
            Text(v, style: akN(18)),
            Text(l, style: akT(11, w: FontWeight.w600, c: akMuted)),
          ]),
        ),
      );

  Future<void> _subscribe(Trainer t, Plan p) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PaySheet(t: t, p: p),
    );
    if (ok == true && mounted) {
      TrainerStore.I.subscribe(t, p);
      HapticFeedback.heavyImpact();
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const TrainerHubPage(welcome: true)));
    }
  }
}

class _PlanCard extends StatelessWidget {
  final Plan p;
  final bool selected, best;
  final VoidCallback onTap;
  const _PlanCard(this.p, {required this.selected, required this.best, required this.onTap});

  @override
  Widget build(BuildContext context) => ShopCard(
        onTap: onTap,
        border: Border.all(color: selected ? tViolet : Colors.white, width: selected ? 2 : 1),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(p.name, style: akT(17, w: FontWeight.w800)),
            if (best) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(gradient: const LinearGradient(colors: [tViolet, tPink]), borderRadius: BorderRadius.circular(8)),
                child: Text('MOST POPULAR', style: akT(9.5, w: FontWeight.w900, c: Colors.white, ls: 0.6)),
              ),
            ],
            const Spacer(),
            AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              width: 24,
              height: 24,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: selected ? tViolet : const Color(0xFFD1D5DB), width: selected ? 7 : 2)),
            ),
          ]),
          const SizedBox(height: 4),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(inr(p.price), style: akN(26)),
            Padding(
              padding: const EdgeInsets.only(left: 6, bottom: 3),
              child: Text(p.months == 1 ? 'per month' : '${inr(p.perMonth)}/mo · ${p.months} months', style: akT(12.5, w: FontWeight.w600, c: akMuted)),
            ),
          ]),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child: selected
                ? Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Column(children: [
                      for (final k in p.perks)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(children: [
                            const Icon(Icons.check_circle_rounded, color: tViolet, size: 17),
                            const SizedBox(width: 8),
                            Expanded(child: Text(k, style: akT(13, w: FontWeight.w600))),
                          ]),
                        ),
                    ]),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ]),
      );
}

class _PaySheet extends StatefulWidget {
  final Trainer t;
  final Plan p;
  const _PaySheet({required this.t, required this.p});
  @override
  State<_PaySheet> createState() => _PaySheetState();
}

class _PaySheetState extends State<_PaySheet> {
  int method = 0;
  bool busy = false, done = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.t, p = widget.p;
    const methods = [(Icons.qr_code_2_rounded, 'UPI'), (Icons.credit_card_rounded, 'Card'), (Icons.account_balance_wallet_rounded, 'Wallet')];
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      padding: EdgeInsets.fromLTRB(20, 10, 20, 20 + MediaQuery.paddingOf(context).bottom),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        child: done
            ? Column(mainAxisSize: MainAxisSize.min, children: [
                const SizedBox(height: 20),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 700),
                  curve: akSpring,
                  builder: (_, v, _) => Transform.scale(
                    scale: v,
                    child: Container(
                      width: 86,
                      height: 86,
                      decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [tViolet, tPink])),
                      child: const Icon(Icons.check_rounded, color: Colors.white, size: 46),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text('You are in!', style: akT(24, w: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('${t.first} is now your coach. Your plan is ready.', textAlign: TextAlign.center, style: akT(14, w: FontWeight.w500, c: akMuted)),
                const SizedBox(height: 20),
                ShopButton('Meet your coach', color: tViolet, onTap: () => Navigator.of(context).pop(true)),
              ])
            : Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Center(child: Container(width: 38, height: 5, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(3)))),
                const SizedBox(height: 16),
                Row(children: [
                  TrainerAvatar(t, size: 50, ring: true),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Coaching with ${t.first}', style: akT(17, w: FontWeight.w800)),
                      Text('${p.name} plan · ${p.months} month${p.months > 1 ? 's' : ''}', style: akT(12.5, w: FontWeight.w600, c: akMuted)),
                    ]),
                  ),
                  Text(inr(p.price), style: akN(20)),
                ]),
                const SizedBox(height: 18),
                Text('Pay with', style: akT(14, w: FontWeight.w800)),
                const SizedBox(height: 10),
                Row(children: [
                  for (var i = 0; i < methods.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: AkPress(
                        onTap: () => setState(() => method = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: method == i ? tViolet.withValues(alpha: 0.08) : const Color(0xFFF5F6F8),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: method == i ? tViolet : Colors.transparent, width: 1.6),
                          ),
                          child: Column(children: [
                            Icon(methods[i].$1, color: method == i ? tViolet : akMuted),
                            const SizedBox(height: 4),
                            Text(methods[i].$2, style: akT(12.5, w: FontWeight.w800, c: method == i ? tViolet : akInk)),
                          ]),
                        ),
                      ),
                    ),
                  ],
                ]),
                const SizedBox(height: 14),
                Row(children: [
                  const Icon(Icons.autorenew_rounded, size: 16, color: akMuted),
                  const SizedBox(width: 6),
                  Expanded(child: Text('Renews automatically. Cancel any time from your coaching page.', style: akT(12, w: FontWeight.w500, c: akMuted))),
                ]),
                const SizedBox(height: 16),
                ShopButton('Pay ${inr(p.price)}', icon: Icons.lock_rounded, color: tViolet, busy: busy, onTap: () async {
                  setState(() => busy = true);
                  await Future.delayed(const Duration(milliseconds: 1400));
                  if (!mounted) return;
                  HapticFeedback.heavyImpact();
                  setState(() {
                    busy = false;
                    done = true;
                  });
                }),
              ]),
      ),
    );
  }
}

/// Small ticker used by live screens to rebuild once a second.
mixin SecondTicker<T extends StatefulWidget> on State<T> {
  Timer? _sec;
  void startTicker() => _sec = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
  @override
  void dispose() {
    _sec?.cancel();
    super.dispose();
  }
}
