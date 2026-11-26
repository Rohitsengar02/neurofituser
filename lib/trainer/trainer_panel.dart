import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../shop/shop_ui.dart';
import '../widgets/apple_kit.dart';
import '../widgets/liquid_glass.dart';
import '../widgets/net_img.dart';
import 'panel_data.dart';
import 'panel_onboarding.dart';
import 'panel_pages.dart';
import 'trainer_data.dart';

// Trainer panel shell: replaces the app's home while panel mode is on. Its
// own glass bottom bar (Dashboard, Clients, Go live, Content, Earnings)
// plus a round Home button that returns to the normal app. The dashboard
// links to all 10 coach tools.

void panelPush(BuildContext context, Widget page) => shopPush(context, page);

class TrainerPanelShell extends StatefulWidget {
  const TrainerPanelShell({super.key});
  @override
  State<TrainerPanelShell> createState() => _TrainerPanelShellState();
}

class _TrainerPanelShellState extends State<TrainerPanelShell> {
  int tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        shopToast(context, 'Welcome to your trainer panel. Tap the house to go back home.', icon: Icons.sports_rounded);
      }
    });
  }

  void _home() {
    HapticFeedback.mediumImpact();
    PanelStore.I.exitPanel();
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    return Scaffold(
      backgroundColor: shopBg,
      body: Stack(children: [
        const Positioned.fill(
          child: ShopBackdrop(tint: pViolet, tint2: pPink, icons: panelIcons),
        ),
        Positioned.fill(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            switchInCurve: Curves.easeOutCubic,
            transitionBuilder: (c, a) => FadeTransition(
              opacity: a,
              child: SlideTransition(position: Tween(begin: const Offset(0.03, 0), end: Offset.zero).animate(a), child: c),
            ),
            child: KeyedSubtree(
              key: ValueKey(tab),
              child: switch (tab) {
                0 => PanelHome(onTab: (i) => setState(() => tab = i), onHome: _home),
                1 => const ClientsTab(),
                2 => const GoLiveSetup(inTab: true),
                3 => const ContentTab(),
                _ => const EarningsTab(),
              },
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 16 + pad.bottom * 0.5,
          child: RepaintBoundary(child: _PanelBar(tab: tab, onTab: (i) => setState(() => tab = i), onHome: _home)),
        ),
      ]),
    );
  }
}

class _PanelBar extends StatelessWidget {
  final int tab;
  final ValueChanged<int> onTab;
  final VoidCallback onHome;
  const _PanelBar({required this.tab, required this.onTab, required this.onHome});

  static const _items = [
    (Icons.space_dashboard_rounded, Icons.space_dashboard_outlined, 'Panel'),
    (Icons.groups_rounded, Icons.groups_outlined, 'Clients'),
    (Icons.sensors_rounded, Icons.sensors_rounded, 'Live'),
    (Icons.video_library_rounded, Icons.video_library_outlined, 'Content'),
    (Icons.account_balance_wallet_rounded, Icons.account_balance_wallet_outlined, 'Earn'),
  ];

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
          child: SizedBox(
            height: 66,
            child: LiquidGlass(
              style: LiquidGlassStyle.regular,
              borderRadius: BorderRadius.circular(36),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                for (var i = 0; i < _items.length; i++) _item(i),
              ]),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 66,
          height: 66,
          child: LiquidGlass(
            style: LiquidGlassStyle.regular,
            shape: BoxShape.circle,
            onTap: onHome,
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.home_rounded, size: 24, color: akInk),
              Text('Home', style: akT(9.5, w: FontWeight.w800, c: akInk)),
            ]),
          ),
        ),
      ]);

  Widget _item(int i) {
    final on = tab == i;
    final it = _items[i];
    final live = i == 2;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onTab(i);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: on
                ? const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [pViolet, pPink])
                : null,
            boxShadow: on ? [BoxShadow(color: pPink.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))] : null,
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Stack(clipBehavior: Clip.none, children: [
              Icon(on ? it.$1 : it.$2, size: 22, color: on ? Colors.white : (live ? const Color(0xFFE11D48) : akInk)),
              if (i == 1)
                ListenableBuilder(
                  listenable: PanelStore.I,
                  builder: (_, _) => PanelStore.I.unread == 0 || on
                      ? const SizedBox.shrink()
                      : Positioned(right: -6, top: -4, child: CountBadge(PanelStore.I.unread, color: pPink)),
                ),
            ]),
            const SizedBox(height: 2),
            Text(it.$3, style: akT(9.5, w: FontWeight.w800, c: on ? Colors.white : akMuted)),
          ]),
        ),
      ),
    );
  }
}

// =====================================================================
//  SHARED BITS
// =====================================================================

/// Tab scaffold inside the panel: large title, optional trailing, list body.
class PanelTab extends StatelessWidget {
  final String caption, title;
  final Widget? trailing;
  final List<Widget> children;
  const PanelTab({super.key, required this.caption, required this.title, this.trailing, required this.children});
  @override
  Widget build(BuildContext context) => ListView(
        padding: EdgeInsets.fromLTRB(0, MediaQuery.paddingOf(context).top + 12, 0, 130),
        physics: const BouncingScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 16, 6),
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(
                child: Rise(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(caption.toUpperCase(), style: akT(11.5, w: FontWeight.w800, c: akFaint, ls: 1.3)),
                    Text(title, style: akT(30, w: FontWeight.w800, ls: -1)),
                  ]),
                ),
              ),
              ?trailing,
            ]),
          ),
          ...children,
        ],
      );
}

class Kpi extends StatelessWidget {
  final String value, label;
  final IconData icon;
  final Color color;
  final String? delta;
  const Kpi(this.value, this.label, this.icon, this.color, {super.key, this.delta});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white),
          boxShadow: [BoxShadow(color: const Color(0xFF1F2937).withValues(alpha: 0.05), blurRadius: 14, offset: const Offset(0, 6))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 18, color: color),
            ),
            const Spacer(),
            if (delta != null)
              Text(delta!, style: akT(11.5, w: FontWeight.w800, c: delta!.startsWith('-') ? shopRed : shopGreen)),
          ]),
          const SizedBox(height: 12),
          FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(value, style: akN(22))),
          const SizedBox(height: 3),
          Text(label, style: akT(11.5, w: FontWeight.w700, c: akMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
        ]),
      );
}

/// Simple animated bars (used for weekly earnings).
class MiniBars extends StatelessWidget {
  final List<int> values;
  final Color color;
  final Color rest;
  final double height;
  final List<String>? labels;
  final TextStyle? labelStyle;
  const MiniBars(this.values, {super.key, this.color = Colors.white, this.rest = Colors.white24, this.height = 70, this.labels, this.labelStyle});
  @override
  Widget build(BuildContext context) {
    final mx = values.fold<int>(1, math.max);
    return AkSeen(
      duration: const Duration(milliseconds: 1100),
      builder: (_, t) => Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        for (var i = 0; i < values.length; i++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  height: math.max(4, height * values[i] / mx * Curves.easeOutBack.transform(t.clamp(0, 1)).clamp(0, 1.1)),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: i == values.length - 1 ? color : rest,
                  ),
                ),
                if (labels != null) ...[
                  const SizedBox(height: 6),
                  Text(labels![i], style: labelStyle ?? akT(10, w: FontWeight.w700, c: akMuted)),
                ],
              ]),
            ),
          ),
      ]),
    );
  }
}

class ClientAvatar extends StatelessWidget {
  final PClient c;
  final double size;
  const ClientAvatar(this.c, {super.key, this.size = 46});
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8)],
        ),
        clipBehavior: Clip.antiAlias,
        child: NetImg(c.photo, width: size, height: size, cacheWidth: (size * 2.5).round()),
      );
}

Widget statusPill(String s) {
  final (c, t) = switch (s) {
    'expiring' => (shopAmber, 'Expiring'),
    'paused' => (akMuted, 'Paused'),
    _ => (shopGreen, 'Active'),
  };
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
    child: Text(t, style: akT(10.5, w: FontWeight.w800, c: c)),
  );
}

// =====================================================================
//  DASHBOARD
// =====================================================================

class PanelHome extends StatelessWidget {
  final ValueChanged<int> onTab;
  final VoidCallback onHome;
  const PanelHome({super.key, required this.onTab, required this.onHome});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PanelStore.I,
      builder: (context, _) {
        final s = PanelStore.I;
        final top = MediaQuery.paddingOf(context).top;
        final w = s.weekly;
        final last = w[7], prev = w[6] == 0 ? 1 : w[6];
        final delta = ((last - prev) / prev * 100).round();
        final next = s.upcoming.isEmpty ? null : s.upcoming.first;
        final tools = <(IconData, String, String, Color, Widget?, int?)>[
          (Icons.workspace_premium_rounded, 'Subscriptions', '${s.plans.where((p) => p.active).length} plans', const Color(0xFFF59E0B), const SubscriptionsPage(), null),
          (Icons.sensors_rounded, 'Go live', s.live ? 'You are live' : 'Stream a class', const Color(0xFFE11D48), null, 2),
          (Icons.cloud_upload_rounded, 'Upload workout', 'Video or plan', pViolet, const UploadWorkoutPage(), null),
          (Icons.groups_rounded, 'Clients', '${s.activeClients} active', akBlue, null, 1),
          (Icons.calendar_month_rounded, 'Schedule', '${s.upcoming.length} upcoming', const Color(0xFF0EA5E9), const SchedulePage(), null),
          (Icons.chat_bubble_rounded, 'Messages', s.unread == 0 ? 'All caught up' : '${s.unread} unread', pPink, const MessagesPage(), null),
          (Icons.account_balance_wallet_rounded, 'Earnings', '${inr(s.balance)} ready', shopGreen, null, 4),
          (Icons.insights_rounded, 'Analytics', 'Growth & retention', const Color(0xFF6366F1), const AnalyticsPage(), null),
          (Icons.restaurant_menu_rounded, 'Diet plans', '${s.diets.length} templates', const Color(0xFFF97316), const DietPlansPage(), null),
          (Icons.star_rounded, 'Reviews', '${s.rating.toStringAsFixed(1)} ★ · ${s.reviews.length}', const Color(0xFFEAB308), const ReviewsPage(), null),
        ];
        return ListView(
          padding: EdgeInsets.fromLTRB(0, top + 10, 0, 130),
          physics: const BouncingScrollPhysics(),
          children: [
            // Header.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                AkPress(
                  onTap: () => panelPush(context, const PanelProfilePage()),
                  child: PanelAvatar(photo: s.photo, name: s.name, size: 46),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('TRAINER PANEL', style: akT(10.5, w: FontWeight.w800, c: akFaint, ls: 1.3)),
                    Text(s.name.split(' ').first, style: akT(19, w: FontWeight.w800, ls: -0.4), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ]),
                ),
                LiquidGlass(
                  style: LiquidGlassStyle.regular,
                  borderRadius: BorderRadius.circular(22),
                  onTap: onHome,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.home_rounded, size: 18, color: akInk),
                    const SizedBox(width: 6),
                    Text('Go to home', style: akT(13, w: FontWeight.w800)),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 18),
            const AkWelcome(caption: 'GOOD TO SEE YOU', words: ['Your', 'coaching', 'today'], accent: pViolet),
            const SizedBox(height: 16),
            // Earnings hero.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Rise(
                child: AkPress(
                  scale: 0.98,
                  onTap: () => onTab(4),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1E1B4B), Color(0xFF5B21B6), Color(0xFFBE185D)],
                      ),
                      boxShadow: [BoxShadow(color: pViolet.withValues(alpha: 0.4), blurRadius: 30, offset: const Offset(0, 14))],
                    ),
                    child: Stack(clipBehavior: Clip.none, children: [
                      Positioned(
                        right: -30,
                        top: -40,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.07)),
                        ),
                      ),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Text('EARNED THIS MONTH', style: akT(11, w: FontWeight.w800, c: Colors.white60, ls: 1.2)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(10)),
                            child: Text('${delta >= 0 ? '▲' : '▼'} ${delta.abs()}% wk', style: akT(11, w: FontWeight.w800, c: Colors.white)),
                          ),
                        ]),
                        const SizedBox(height: 6),
                        AkSeen(
                          duration: const Duration(milliseconds: 1200),
                          builder: (_, t) => Text('${inr((s.monthEarnings * t).round())}', style: akN(38, c: Colors.white)),
                        ),
                        const SizedBox(height: 14),
                        MiniBars(w, height: 56),
                        const SizedBox(height: 16),
                        Row(children: [
                          _heroStat('${s.activeClients}', 'clients'),
                          _heroStat(s.rating.toStringAsFixed(1), 'rating'),
                          _heroStat('${s.liveSessions + 14}', 'live classes'),
                          _heroStat('${s.workouts.where((w) => w.published).length}', 'workouts'),
                        ]),
                      ]),
                    ]),
                  ),
                ),
              ),
            ),
            // Live banner or next session.
            if (s.live)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: ShopCard(
                  margin: EdgeInsets.zero,
                  color: const Color(0xFFFFF1F2),
                  border: Border.all(color: const Color(0xFFFECDD3)),
                  onTap: () => panelPush(context, const BroadcastPage()),
                  child: Row(children: [
                    const Icon(Icons.sensors_rounded, color: Color(0xFFE11D48)),
                    const SizedBox(width: 10),
                    Expanded(child: Text('You are live: ${s.liveTitle}', style: akT(14, w: FontWeight.w800))),
                    Text('Return ›', style: akT(13, w: FontWeight.w800, c: const Color(0xFFE11D48))),
                  ]),
                ),
              )
            else if (next != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Rise(delay: 80, child: _NextUp(next, onLive: () => onTab(2))),
              ),
            AkHead('Your tools', caption: '10 ways to run your coaching'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: tools.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.55,
                ),
                itemBuilder: (_, i) {
                  final t = tools[i];
                  return AkSeen(
                    builder: (_, v) => Opacity(
                      opacity: v.clamp(0, 1),
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - v)),
                        child: _ToolTile(
                          icon: t.$1,
                          title: t.$2,
                          sub: t.$3,
                          color: t.$4,
                          badge: i == 5 ? s.unread : 0,
                          onTap: () => t.$6 != null ? onTab(t.$6!) : panelPush(context, t.$5!),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (s.expiring > 0 || s.unread > 0) ...[
              AkHead('Needs attention'),
              for (final c in s.clients.where((c) => c.status == 'expiring'))
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ShopCard(
                    onTap: () => panelPush(context, ClientDetailPage(c)),
                    padding: const EdgeInsets.all(12),
                    child: Row(children: [
                      ClientAvatar(c, size: 42),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(c.name, style: akT(14.5, w: FontWeight.w800)),
                          Text('${c.plan} plan ends ${c.daysLeft <= 0 ? 'today' : c.daysLeft == 1 ? 'tomorrow' : 'in ${c.daysLeft} days'}', style: akT(12, w: FontWeight.w600, c: shopAmber)),
                        ]),
                      ),
                      _SmallBtn('Remind', onTap: () {
                        PanelStore.I.sendTo(c, 'Hey ${c.name.split(' ').first}, your plan ends soon. Renew to keep your streak going 💪');
                        shopToast(context, 'Renewal reminder sent to ${c.name.split(' ').first}');
                      }),
                    ]),
                  ),
                ),
              for (final c in s.clients.where((c) => c.unread > 0).take(3))
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ShopCard(
                    onTap: () => panelPush(context, PanelChatPage(c)),
                    padding: const EdgeInsets.all(12),
                    child: Row(children: [
                      ClientAvatar(c, size: 42),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(c.name, style: akT(14.5, w: FontWeight.w800)),
                          Text(c.chat.last.text, style: akT(12, w: FontWeight.w600, c: akMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ]),
                      ),
                      CountBadge(c.unread, color: pPink),
                    ]),
                  ),
                ),
            ],
            AkHead('Recent activity'),
            ShopCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Column(children: [
                for (final t in s.txns.take(5))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    child: Row(children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: (t.amount > 0 ? shopGreen : akBlue).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(t.amount > 0 ? Icons.south_west_rounded : Icons.north_east_rounded,
                            size: 18, color: t.amount > 0 ? shopGreen : akBlue),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(t.title, style: akT(13.5, w: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text(ago(t.at), style: akT(11.5, w: FontWeight.w600, c: akMuted)),
                        ]),
                      ),
                      Text('${t.amount > 0 ? '+' : '−'}${inr(t.amount.abs())}',
                          style: akN(14, c: t.amount > 0 ? shopGreen : akInk)),
                    ]),
                  ),
              ]),
            ),
          ],
        );
      },
    );
  }

  Widget _heroStat(String v, String l) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(v, style: akN(18, c: Colors.white)),
          const SizedBox(height: 3),
          Text(l, style: akT(10.5, w: FontWeight.w700, c: Colors.white60)),
        ]),
      );
}

class _NextUp extends StatelessWidget {
  final PSession s;
  final VoidCallback onLive;
  const _NextUp(this.s, {required this.onLive});
  @override
  Widget build(BuildContext context) {
    final mins = s.at.difference(DateTime.now()).inMinutes;
    final soon = mins < 60;
    final when = mins <= 0
        ? 'Now'
        : mins < 60
            ? 'in $mins min'
            : mins < 24 * 60
                ? 'in ${mins ~/ 60} h ${mins % 60} m'
                : dayName(s.at);
    return ShopCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(colors: s.kind == 'Live class' ? const [Color(0xFFF43F5E), pPink] : const [akBlue, Color(0xFF6366F1)]),
          ),
          child: Icon(s.kind == 'Live class' ? Icons.sensors_rounded : Icons.videocam_rounded, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('NEXT UP · ${when.toUpperCase()}', style: akT(10.5, w: FontWeight.w800, c: soon ? const Color(0xFFE11D48) : akFaint, ls: 1)),
            const SizedBox(height: 2),
            Text(s.title, style: akT(15, w: FontWeight.w800)),
            Text('${hhmm(s.at)} · ${s.minutes} min${s.client != null ? ' · ${s.client}' : ''}',
                style: akT(12, w: FontWeight.w600, c: akMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),
        ),
        _SmallBtn(s.kind == 'Live class' ? 'Go live' : 'Join', color: s.kind == 'Live class' ? const Color(0xFFE11D48) : akInk, onTap: () {
          if (s.kind == 'Live class') {
            onLive();
          } else {
            shopToast(context, 'Calling ${s.client ?? 'client'}…', icon: Icons.videocam_rounded);
          }
        }),
      ]),
    );
  }
}

class _ToolTile extends StatelessWidget {
  final IconData icon;
  final String title, sub;
  final Color color;
  final int badge;
  final VoidCallback onTap;
  const _ToolTile({required this.icon, required this.title, required this.sub, required this.color, required this.onTap, this.badge = 0});
  @override
  Widget build(BuildContext context) => AkPress(
        onTap: onTap,
        child: LiquidGlass(
          style: LiquidGlassStyle.material,
          borderRadius: BorderRadius.circular(24),
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [color, Color.lerp(color, Colors.black, 0.2)!]),
                  boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Icon(icon, color: Colors.white, size: 21),
              ),
              const Spacer(),
              if (badge > 0) CountBadge(badge, color: pPink) else Icon(Icons.arrow_outward_rounded, size: 18, color: akMuted.withValues(alpha: 0.6)),
            ]),
            const Spacer(),
            Text(title, style: akT(14.5, w: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(sub, style: akT(11.5, w: FontWeight.w600, c: akMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),
        ),
      );
}

class _SmallBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;
  const _SmallBtn(this.label, {required this.onTap, this.color = akInk});
  @override
  Widget build(BuildContext context) => AkPress(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
          child: Text(label, style: akT(12.5, w: FontWeight.w800, c: Colors.white)),
        ),
      );
}

// =====================================================================
//  CLIENTS TAB
// =====================================================================

class ClientsTab extends StatefulWidget {
  final bool asPage;
  const ClientsTab({super.key, this.asPage = false});
  @override
  State<ClientsTab> createState() => _ClientsTabState();
}

class _ClientsTabState extends State<ClientsTab> {
  int f = 0;
  String q = '';
  static const filters = ['All', 'Active', 'Expiring', 'Paused'];

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: PanelStore.I,
        builder: (context, _) {
          final s = PanelStore.I;
          final list = s.clients
              .where((c) => f == 0 || c.status == filters[f].toLowerCase())
              .where((c) => q.isEmpty || '${c.name} ${c.goal}'.toLowerCase().contains(q.toLowerCase()))
              .toList();
          return PanelTab(
            caption: '${s.activeClients} active · ${s.expiring} expiring',
            title: 'Clients',
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Row(children: [
                  Expanded(child: Kpi('${s.clients.length}', 'Total clients', Icons.groups_rounded, akBlue, delta: '+3')),
                  const SizedBox(width: 10),
                  Expanded(child: Kpi('${(s.clients.where((c) => c.streak > 0).length / s.clients.length * 100).round()}%', 'Trained this week', Icons.local_fire_department_rounded, shopOrange)),
                  const SizedBox(width: 10),
                  Expanded(child: Kpi('92%', 'Renewal rate', Icons.autorenew_rounded, shopGreen)),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.92), borderRadius: BorderRadius.circular(16)),
                  child: Row(children: [
                    const Icon(Icons.search_rounded, color: akMuted, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        onChanged: (v) => setState(() => q = v),
                        style: akT(14.5, w: FontWeight.w600),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          hintText: 'Search clients or goals',
                          hintStyle: akT(14, w: FontWeight.w500, c: akMuted),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
              SizedBox(
                height: 54,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  children: [
                    for (var i = 0; i < filters.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: AkPress(
                          onTap: () => setState(() => f = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: f == i ? akInk : Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(filters[i], style: akT(13, w: FontWeight.w800, c: f == i ? Colors.white : akInk)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              if (list.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Column(children: [
                    const Icon(Icons.person_search_rounded, size: 46, color: akMuted),
                    const SizedBox(height: 10),
                    Text('No clients here', style: akT(16, w: FontWeight.w800)),
                    Text('Try another filter or search.', style: akT(13, w: FontWeight.w600, c: akMuted)),
                  ]),
                ),
              for (var i = 0; i < list.length; i++)
                Rise(
                  delay: 40 * i,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ClientRow(list[i]),
                  ),
                ),
            ],
          );
        },
      );
}

class ClientRow extends StatelessWidget {
  final PClient c;
  const ClientRow(this.c, {super.key});
  @override
  Widget build(BuildContext context) {
    final diff = c.nowKg - c.startKg;
    return ShopCard(
      onTap: () => panelPush(context, ClientDetailPage(c)),
      padding: const EdgeInsets.all(12),
      child: Row(children: [
        Stack(clipBehavior: Clip.none, children: [
          ClientAvatar(c, size: 50),
          if (c.unread > 0) Positioned(right: -4, top: -4, child: CountBadge(c.unread, color: pPink)),
        ]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(child: Text(c.name, style: akT(15, w: FontWeight.w800), overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 6),
              statusPill(c.status),
            ]),
            const SizedBox(height: 2),
            Text('${c.goal} · ${c.plan}', style: akT(12, w: FontWeight.w600, c: akMuted)),
            const SizedBox(height: 7),
            Row(children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: c.progress,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFEDE9FE),
                    color: pViolet,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text('${diff >= 0 ? '+' : ''}${diff.toStringAsFixed(1)} kg', style: akN(12.5, c: diff <= 0 ? shopGreen : akBlue)),
            ]),
          ]),
        ),
        const SizedBox(width: 6),
        const Icon(Icons.chevron_right_rounded, color: akMuted),
      ]),
    );
  }
}

// =====================================================================
//  CONTENT TAB
// =====================================================================

class ContentTab extends StatelessWidget {
  const ContentTab({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: PanelStore.I,
        builder: (context, _) {
          final s = PanelStore.I;
          final views = s.workouts.fold<int>(0, (a, w) => a + w.views);
          final saves = s.workouts.fold<int>(0, (a, w) => a + w.saves);
          return PanelTab(
            caption: '${s.workouts.length} workouts',
            title: 'Content',
            trailing: GlassIcon(Icons.add_rounded, onTap: () => panelPush(context, const UploadWorkoutPage())),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Row(children: [
                  Expanded(child: Kpi(_k(views), 'Views', Icons.visibility_rounded, pViolet, delta: '+18%')),
                  const SizedBox(width: 10),
                  Expanded(child: Kpi(_k(saves), 'Saves', Icons.bookmark_rounded, pPink, delta: '+9%')),
                  const SizedBox(width: 10),
                  Expanded(child: Kpi('${s.workouts.where((w) => w.published).length}', 'Published', Icons.public_rounded, shopGreen)),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                child: AkPress(
                  onTap: () => panelPush(context, const UploadWorkoutPage()),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: pViolet.withValues(alpha: 0.35), width: 1.5),
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                    child: Row(children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [pViolet, pPink])),
                        child: const Icon(Icons.cloud_upload_rounded, color: Colors.white),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Upload a workout', style: akT(15.5, w: FontWeight.w800)),
                          Text('Video, plan or circuit for your clients', style: akT(12, w: FontWeight.w600, c: akMuted)),
                        ]),
                      ),
                    ]),
                  ),
                ),
              ),
              AkHead('Library'),
              for (final w in s.workouts)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: WorkoutRow(w),
                ),
            ],
          );
        },
      );
}

String _k(int v) => v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}K' : '$v';

class WorkoutRow extends StatelessWidget {
  final PWorkout w;
  const WorkoutRow(this.w, {super.key});
  @override
  Widget build(BuildContext context) => ShopCard(
        padding: const EdgeInsets.all(10),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 76,
              height: 76,
              child: w.cover == null
                  ? Container(
                      decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFEDE9FE), Color(0xFFFCE7F3)])),
                      child: Icon(w.kind == 'Live replay' ? Icons.sensors_rounded : Icons.play_circle_fill_rounded, color: pViolet, size: 30),
                    )
                  : w.cover!.startsWith('assets/')
                      ? NetImg(w.cover!, fit: BoxFit.cover)
                      : Image.memory(base64Decode(w.cover!), fit: BoxFit.cover, gaplessPlayback: true),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(w.title, style: akT(14.5, w: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text('${w.kind} · ${w.level} · ${w.minutes} min', style: akT(11.5, w: FontWeight.w600, c: akMuted)),
              const SizedBox(height: 6),
              Row(children: [
                Icon(Icons.visibility_rounded, size: 14, color: akMuted.withValues(alpha: 0.8)),
                const SizedBox(width: 3),
                Text(_k(w.views), style: akT(11.5, w: FontWeight.w700, c: akMuted)),
                const SizedBox(width: 10),
                Icon(Icons.bookmark_rounded, size: 14, color: akMuted.withValues(alpha: 0.8)),
                const SizedBox(width: 3),
                Text(_k(w.saves), style: akT(11.5, w: FontWeight.w700, c: akMuted)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (w.published ? shopGreen : akMuted).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(w.published ? 'Live' : 'Draft', style: akT(10.5, w: FontWeight.w800, c: w.published ? shopGreen : akMuted)),
                ),
              ]),
            ]),
          ),
          PopupMenuButton<int>(
            icon: const Icon(Icons.more_vert_rounded, color: akMuted),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: (v) {
              if (v == 0) {
                PanelStore.I.toggleWorkout(w);
                shopToast(context, w.published ? 'Published to your clients' : 'Moved to drafts');
              } else if (v == 1) {
                shopToast(context, 'Sent "${w.title}" to ${PanelStore.I.activeClients} clients', icon: Icons.send_rounded);
              } else {
                PanelStore.I.deleteWorkout(w);
                shopToast(context, 'Workout deleted', icon: Icons.delete_rounded);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 0, child: Text(w.published ? 'Move to drafts' : 'Publish', style: akT(14))),
              PopupMenuItem(value: 1, child: Text('Send to all clients', style: akT(14))),
              PopupMenuItem(value: 2, child: Text('Delete', style: akT(14, c: shopRed))),
            ],
          ),
        ]),
      );
}

// =====================================================================
//  EARNINGS TAB
// =====================================================================

class EarningsTab extends StatelessWidget {
  final bool asPage;
  const EarningsTab({super.key, this.asPage = false});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: PanelStore.I,
        builder: (context, _) {
          final s = PanelStore.I;
          final w = s.weekly;
          final total = w.fold<int>(0, (a, b) => a + b);
          return PanelTab(
            caption: 'Payouts every Monday',
            title: 'Earnings',
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Rise(
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF064E3B), Color(0xFF047857), Color(0xFF10B981)]),
                      boxShadow: [BoxShadow(color: shopGreen.withValues(alpha: 0.35), blurRadius: 26, offset: const Offset(0, 12))],
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('AVAILABLE TO WITHDRAW', style: akT(11, w: FontWeight.w800, c: Colors.white60, ls: 1.2)),
                      const SizedBox(height: 6),
                      Text('${inr(s.balance)}', style: akN(38, c: Colors.white)),
                      const SizedBox(height: 4),
                      Text('You keep 85% · NeuroFit fee already deducted', style: akT(12, w: FontWeight.w600, c: Colors.white70)),
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(
                          child: AkPress(
                            onTap: () => showWithdrawSheet(context),
                            child: Container(
                              height: 46,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                              child: Text('Withdraw', style: akT(14.5, w: FontWeight.w800, c: const Color(0xFF047857))),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            height: 46,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(16)),
                            child: Text('HDFC ••4821', style: akT(13.5, w: FontWeight.w800, c: Colors.white)),
                          ),
                        ),
                      ]),
                    ]),
                  ),
                ),
              ),
              AkHead('Last 8 weeks', caption: '${inr(total)} earned'),
              ShopCard(
                child: MiniBars(
                  w,
                  color: pViolet,
                  rest: const Color(0xFFDDD6FE),
                  height: 120,
                  labels: const ['W1', 'W2', 'W3', 'W4', 'W5', 'W6', 'W7', 'Now'],
                ),
              ),
              AkHead('By plan'),
              ShopCard(
                child: Column(children: [
                  for (final p in s.plans) ...[
                    Row(children: [
                      Text(p.name, style: akT(14, w: FontWeight.w800)),
                      const Spacer(),
                      Text('${p.subs} subs · ${inr(p.subs * p.price)}', style: akT(12.5, w: FontWeight.w700, c: akMuted)),
                    ]),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: AkSeen(
                        builder: (_, t) => LinearProgressIndicator(
                          value: t * p.subs / math.max(1, s.plans.fold<int>(0, (a, b) => math.max(a, b.subs))),
                          minHeight: 8,
                          backgroundColor: const Color(0xFFF3F4F6),
                          color: [pViolet, pPink, shopAmber][s.plans.indexOf(p) % 3],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                ]),
              ),
              AkHead('Transactions'),
              ShopCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: Column(children: [
                  for (final t in s.txns.take(14))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(children: [
                        Icon(t.amount > 0 ? Icons.add_circle_rounded : Icons.account_balance_rounded,
                            color: t.amount > 0 ? shopGreen : akBlue, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(t.title, style: akT(13.5, w: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text('${t.sub} · ${ago(t.at)}', style: akT(11.5, w: FontWeight.w600, c: akMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ]),
                        ),
                        Text('${t.amount > 0 ? '+' : '−'}${inr(t.amount.abs())}', style: akN(14, c: t.amount > 0 ? shopGreen : akInk)),
                      ]),
                    ),
                ]),
              ),
            ],
          );
        },
      );
}

Future<void> showWithdrawSheet(BuildContext context) => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _Withdraw(),
    );

class _Withdraw extends StatefulWidget {
  const _Withdraw();
  @override
  State<_Withdraw> createState() => _WithdrawState();
}

class _WithdrawState extends State<_Withdraw> {
  late double v = PanelStore.I.balance.toDouble();
  bool busy = false;
  @override
  Widget build(BuildContext context) {
    final bal = PanelStore.I.balance;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + MediaQuery.paddingOf(context).bottom),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(3)))),
        const SizedBox(height: 16),
        Text('Withdraw', style: akT(22, w: FontWeight.w800)),
        Text('To HDFC Bank ••4821 · usually within 1 day', style: akT(13, w: FontWeight.w600, c: akMuted)),
        const SizedBox(height: 18),
        Center(child: Text('${inr(v.round())}', style: akN(44))),
        if (bal > 0)
          Slider(
            value: v.clamp(0, bal.toDouble()),
            min: 0,
            max: bal.toDouble(),
            activeColor: shopGreen,
            onChanged: (x) => setState(() => v = (x / 100).roundToDouble() * 100),
          ),
        Row(children: [
          for (final f in const [0.25, 0.5, 1.0])
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ShopButton(f == 1 ? 'All' : '${(f * 100).round()}%', outline: true, color: shopGreen, height: 42, onTap: () => setState(() => v = (bal * f).floorToDouble())),
              ),
            ),
        ]),
        const SizedBox(height: 16),
        ShopButton('Withdraw ${inr(v.round())}', color: shopGreen, busy: busy, onTap: v < 100
            ? null
            : () async {
                setState(() => busy = true);
                await Future.delayed(const Duration(milliseconds: 900));
                final ok = PanelStore.I.withdraw(v.round());
                if (!context.mounted) return;
                Navigator.pop(context);
                shopToast(context, ok ? 'Payout of ${inr(v.round())} is on its way' : 'Could not withdraw that amount',
                    icon: ok ? Icons.check_circle_rounded : Icons.error_rounded);
              }),
      ]),
    );
  }
}
