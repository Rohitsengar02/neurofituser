
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../shop/shop_ui.dart';
import '../trainer/trainer_data.dart' show unsplash, ago;
import '../widgets/apple_kit.dart';
import '../widgets/liquid_glass.dart';
import '../widgets/net_img.dart';
import 'community_data.dart';
import '../backend/me.dart';

// Community tab: stories, filters and a feed of photo, before/after,
// workout, poll and text posts. Like (double tap too), comment, save,
// share, report, follow, and a composer that uploads real photos.

const cBlue = Color(0xFF2563EB);
const cPink = Color(0xFFEC4899);

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});
  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  int filter = 0;
  static const filters = ['For you', 'Following', 'Transformations', 'Workouts', 'Polls', 'Saved'];

  List<Post> _list(CommunityStore s) {
    final v = s.visible;
    return switch (filter) {
      1 => v.where((p) => p.mine || s.following.contains(p.handle)).toList(),
      2 => v.where((p) => p.kind == PostKind.beforeAfter).toList(),
      3 => v.where((p) => p.kind == PostKind.workout).toList(),
      4 => v.where((p) => p.kind == PostKind.poll).toList(),
      5 => v.where((p) => p.saved).toList(),
      _ => v,
    };
  }

  @override
  Widget build(BuildContext context) {
    final s = CommunityStore.I;
    return Stack(children: [
      const Positioned.fill(child: ShopBackdrop(tint: cBlue, tint2: cPink)),
      ListenableBuilder(
        listenable: s,
        builder: (context, _) {
          final list = _list(s);
          return ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(top: 12, bottom: 130),
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  const Expanded(child: AkWelcome(caption: 'COMMUNITY · 48K MEMBERS', words: ['Share', 'the', 'grind'], accent: cBlue)),
                  AkPress(
                    onTap: () => openComposer(context),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(colors: [cBlue, cPink]),
                        boxShadow: [BoxShadow(color: cBlue.withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 6))],
                      ),
                      child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 16),
              const _Stories(),
              const SizedBox(height: 14),
              const _Composer(),
              const SizedBox(height: 14),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filters.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => AkPress(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => filter = i);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 240),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: filter == i ? akInk : Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(filters[i], style: akT(13, w: FontWeight.w800, c: filter == i ? Colors.white : akInk)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              if (list.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(30),
                  child: Column(children: [
                    Icon(filter == 5 ? Icons.bookmark_border_rounded : Icons.forum_outlined, size: 44, color: akFaint),
                    const SizedBox(height: 8),
                    Text(filter == 5 ? 'Saved posts show up here' : 'Nothing here yet', style: akT(15, w: FontWeight.w700, c: akMuted)),
                  ]),
                ),
              for (var i = 0; i < list.length; i++)
                ScrollReveal(delayMs: 0, child: Padding(padding: const EdgeInsets.only(bottom: 14), child: PostCard(list[i], key: ValueKey(list[i].id)))),
            ],
          );
        },
      ),
    ]);
  }
}

class _Stories extends StatelessWidget {
  const _Stories();
  @override
  Widget build(BuildContext context) {
    // Recent posters (with a photo) from the live feed.
    final seen = <String>{};
    final people = <(String, String)>[
      for (final p in CommunityStore.I.visible)
        if (!p.mine && (p.avatar ?? '').isNotEmpty && seen.add(p.handle)) (p.name.split(' ').first, p.pics.isNotEmpty && p.pics.first.url.isNotEmpty ? p.pics.first.url : p.avatar!),
    ].take(10).toList();
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: people.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          if (i == 0) {
            return GestureDetector(
              onTap: () => openComposer(context),
              child: Column(children: [
                Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
                  ),
                  child: const Icon(Icons.add_rounded, color: cBlue, size: 28),
                ),
                const SizedBox(height: 5),
                Text('Your post', style: akT(11.5, w: FontWeight.w700)),
              ]),
            );
          }
          final p = people[i - 1];
          return Rise(
            delay: i * 40,
            child: GestureDetector(
              onTap: () => _story(context, p.$1, p.$2),
              child: Column(children: [
                Container(
                  width: 66,
                  height: 66,
                  padding: const EdgeInsets.all(2.5),
                  decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFFF59E0B), cPink, Color(0xFF8B5CF6)])),
                  child: Container(
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2.5)),
                    child: ClipOval(child: NetImg(unsplash(p.$2, 200))),
                  ),
                ),
                const SizedBox(height: 5),
                Text(p.$1, style: akT(11.5, w: FontWeight.w700)),
              ]),
            ),
          );
        },
      ),
    );
  }

  void _story(BuildContext context, String name, String photo) {
    Navigator.of(context).push(PageRouteBuilder(
      opaque: false,
      pageBuilder: (_, _, _) => _StoryView(name: name, photo: photo),
      transitionsBuilder: (_, a, _, c) => FadeTransition(opacity: a, child: ScaleTransition(scale: Tween(begin: 0.92, end: 1.0).animate(a), child: c)),
    ));
  }
}

class _StoryView extends StatefulWidget {
  final String name, photo;
  const _StoryView({required this.name, required this.photo});
  @override
  State<_StoryView> createState() => _StoryViewState();
}

class _StoryViewState extends State<_StoryView> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 5))
    ..forward().whenComplete(() {
      if (mounted) Navigator.of(context).maybePop();
    });

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    return GestureDetector(
      onTap: () => Navigator.of(context).maybePop(),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(fit: StackFit.expand, children: [
          NetImg(unsplash(widget.photo, 900)),
          const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.center, colors: [Colors.black54, Colors.transparent]))),
          Positioned(
            top: pad.top + 10,
            left: 12,
            right: 12,
            child: Column(children: [
              AnimatedBuilder(
                animation: _c,
                builder: (_, _) => ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(value: _c.value, minHeight: 3, backgroundColor: Colors.white30, color: Colors.white),
                ),
              ),
              const SizedBox(height: 10),
              Row(children: [
                ClipOval(child: NetImg(unsplash(widget.photo, 120), width: 34, height: 34)),
                const SizedBox(width: 8),
                Text(widget.name, style: akT(14, w: FontWeight.w800, c: Colors.white)),
                const SizedBox(width: 6),
                Text('2h', style: akT(12.5, w: FontWeight.w600, c: Colors.white70)),
                const Spacer(),
                const Icon(Icons.close_rounded, color: Colors.white),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer();
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: LiquidGlass(
          style: LiquidGlassStyle.material,
          borderRadius: BorderRadius.circular(24),
          padding: const EdgeInsets.all(12),
          onTap: () => openComposer(context),
          child: Column(children: [
            Row(children: [
              CircleAvatar(radius: 19, backgroundColor: cBlue, child: Text(Me.initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
              const SizedBox(width: 10),
              Expanded(child: Text('Share a win, a workout or a question…', style: akT(14, w: FontWeight.w500, c: akFaint))),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              for (final k in const [
                (Icons.photo_library_rounded, 'Photo', Color(0xFF16A34A), 0),
                (Icons.compare_rounded, 'Before/after', Color(0xFFF97316), 1),
                (Icons.fitness_center_rounded, 'Workout', Color(0xFF8B5CF6), 2),
                (Icons.poll_rounded, 'Poll', cBlue, 3),
              ])
                Expanded(
                  child: GestureDetector(
                    onTap: () => openComposer(context, kind: k.$4),
                    child: Column(children: [
                      Icon(k.$1, color: k.$3, size: 20),
                      const SizedBox(height: 3),
                      Text(k.$2, style: akT(11, w: FontWeight.w700, c: akMuted)),
                    ]),
                  ),
                ),
            ]),
          ]),
        ),
      );
}

// =====================================================================
//  POST CARD
// =====================================================================

class PostCard extends StatefulWidget {
  final Post p;
  const PostCard(this.p, {super.key});
  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> with SingleTickerProviderStateMixin {
  late final AnimationController _burst = AnimationController(vsync: this, duration: const Duration(milliseconds: 750));
  int page = 0;
  bool more = false;

  @override
  void dispose() {
    _burst.dispose();
    super.dispose();
  }

  void _doubleLike() {
    HapticFeedback.mediumImpact();
    CommunityStore.I.like(widget.p, only: true);
    _burst.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    final s = CommunityStore.I;
    final fol = s.following.contains(p.handle);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: const Color(0xFF1F2937).withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 6, 8),
          child: Row(children: [
            p.avatar == null
                ? CircleAvatar(radius: 20, backgroundColor: cBlue, child: Text(Me.initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)))
                : ClipOval(child: NetImg(unsplash(p.avatar!, 120), width: 40, height: 40)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(child: Text(p.name, overflow: TextOverflow.ellipsis, style: akT(14.5, w: FontWeight.w800))),
                  if (p.coach) ...[
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFF7C3AED).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                      child: Text('COACH', style: akT(9, w: FontWeight.w900, c: const Color(0xFF7C3AED), ls: 0.6)),
                    ),
                  ],
                ]),
                Text('${p.handle} · ${ago(p.at)}', style: akT(12, w: FontWeight.w600, c: akFaint)),
              ]),
            ),
            if (!p.mine)
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  s.toggleFollow(p.handle);
                },
                child: Text(fol ? 'Following' : 'Follow', style: akT(13, w: FontWeight.w800, c: fol ? akMuted : cBlue)),
              ),
            IconButton(onPressed: () => _menu(context), icon: const Icon(Icons.more_horiz_rounded, color: akMuted)),
          ]),
        ),
        if (p.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: GestureDetector(
              onTap: () => setState(() => more = !more),
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(text: p.text, style: akT(14, w: FontWeight.w500, h: 1.4)),
                  if (p.tags.isNotEmpty) TextSpan(text: '  ${p.tags.join(' ')}', style: akT(14, w: FontWeight.w700, c: cBlue)),
                ]),
                maxLines: more ? null : 3,
                overflow: more ? null : TextOverflow.ellipsis,
              ),
            ),
          ),
        _media(p),
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 4, 6, 0),
          child: Row(children: [
            _Like(liked: p.liked, onTap: () {
              HapticFeedback.lightImpact();
              s.like(p);
            }),
            _act(Icons.chat_bubble_outline_rounded, '${p.commentCount}', () => showComments(context, p)),
            _act(Icons.send_rounded, '', () {
              Clipboard.setData(ClipboardData(text: 'https://neurofit.app/p/${p.id}'));
              shopToast(context, 'Link copied', icon: Icons.link_rounded);
            }),
            const Spacer(),
            IconButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                s.save(p);
                shopToast(context, p.saved ? 'Saved to your collection' : 'Removed from saved', icon: Icons.bookmark_rounded);
              },
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (w, a) => ScaleTransition(scale: a, child: w),
                child: Icon(p.saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, key: ValueKey(p.saved), color: p.saved ? akInk : akMuted),
              ),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: Text('${_k(p.likes)} likes', style: akT(13.5, w: FontWeight.w800)),
        ),
        if (p.comments.isNotEmpty)
          GestureDetector(
            onTap: () => showComments(context, p),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text.rich(TextSpan(children: [
                  TextSpan(text: '${p.comments.last.name}  ', style: akT(13, w: FontWeight.w800)),
                  TextSpan(text: p.comments.last.text, style: akT(13, w: FontWeight.w500)),
                ]), maxLines: 1, overflow: TextOverflow.ellipsis),
                if (p.commentCount > 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text('View all ${p.commentCount} comments', style: akT(12.5, w: FontWeight.w600, c: akFaint)),
                  ),
              ]),
            ),
          ),
        const SizedBox(height: 14),
      ]),
    );
  }

  String _k(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}K' : '$n';

  Widget _act(IconData i, String l, VoidCallback f) => TextButton.icon(
        onPressed: f,
        style: TextButton.styleFrom(foregroundColor: akInk, padding: const EdgeInsets.symmetric(horizontal: 10)),
        icon: Icon(i, size: 22, color: akInk),
        label: Text(l, style: akT(13.5, w: FontWeight.w700)),
      );

  Widget _heartBurst() => IgnorePointer(
        child: AnimatedBuilder(
          animation: _burst,
          builder: (_, _) {
            final v = _burst.value;
            if (v == 0 || v == 1) return const SizedBox.shrink();
            final sc = v < 0.3 ? Curves.easeOutBack.transform(v / 0.3) * 1.2 : 1.2 - (v - 0.3) * 0.3;
            return Center(
              child: Opacity(
                opacity: v < 0.75 ? 1 : (1 - (v - 0.75) / 0.25),
                child: Transform.scale(scale: sc, child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 96, shadows: [Shadow(color: Colors.black26, blurRadius: 20)])),
              ),
            );
          },
        ),
      );

  Widget _media(Post p) {
    switch (p.kind) {
      case PostKind.photo:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: GestureDetector(
            onDoubleTap: _doubleLike,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: AspectRatio(
                aspectRatio: 1,
                child: Stack(fit: StackFit.expand, children: [
                  PageView.builder(
                    itemCount: p.pics.length,
                    onPageChanged: (i) => setState(() => page = i),
                    itemBuilder: (_, i) => NetImg(p.pics[i].url, bytes: p.pics[i].bytes),
                  ),
                  if (p.pics.length > 1)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10)),
                        child: Text('${page + 1}/${p.pics.length}', style: akT(11.5, w: FontWeight.w800, c: Colors.white)),
                      ),
                    ),
                  _heartBurst(),
                ]),
              ),
            ),
          ),
        );
      case PostKind.beforeAfter:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: GestureDetector(
            onDoubleTap: _doubleLike,
            child: Stack(children: [
              BeforeAfter(before: p.pics[0], after: p.pics[1]),
              if (p.stat != null)
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(color: const Color(0xFF16A34A), borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [
                      const Icon(Icons.trending_down_rounded, color: Colors.white, size: 16),
                      const SizedBox(width: 5),
                      Text(p.stat!, style: akT(12.5, w: FontWeight.w800, c: Colors.white)),
                    ]),
                  ),
                ),
              Positioned.fill(child: _heartBurst()),
            ]),
          ),
        );
      case PostKind.workout:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1E1B4B), Color(0xFF4C1D95)]),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.fitness_center_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(p.workoutTitle ?? 'Workout', style: akT(16, w: FontWeight.w800, c: Colors.white))),
                Text('${p.exercises.length} moves', style: akT(12, w: FontWeight.w700, c: Colors.white60)),
              ]),
              const SizedBox(height: 10),
              for (var i = 0; i < p.exercises.length; i++)
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
                  child: Row(children: [
                    Text('${i + 1}', style: akN(14, c: const Color(0xFFC4B5FD))),
                    const SizedBox(width: 12),
                    Expanded(child: Text(p.exercises[i].$1, style: akT(13.5, w: FontWeight.w700, c: Colors.white))),
                    Text(p.exercises[i].$2, style: akT(12.5, w: FontWeight.w800, c: Colors.white70)),
                  ]),
                ),
              const SizedBox(height: 6),
              AkPress(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  CommunityStore.I.tryWorkout(p);
                  shopToast(context, p.tried ? 'Added to your workouts' : 'Removed from your workouts', icon: Icons.fitness_center_rounded);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: p.tried ? const Color(0xFF16A34A) : Colors.white, borderRadius: BorderRadius.circular(14)),
                  child: Text(p.tried ? 'Added to my workouts ✓' : 'Add to my workouts',
                      style: akT(13.5, w: FontWeight.w800, c: p.tried ? Colors.white : const Color(0xFF4C1D95))),
                ),
              ),
            ]),
          ),
        );
      case PostKind.poll:
        final total = p.totalVotes;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(children: [
            for (var i = 0; i < p.options.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: p.myVote != null
                      ? null
                      : () {
                          HapticFeedback.mediumImpact();
                          CommunityStore.I.vote(p, i);
                        },
                  child: LayoutBuilder(builder: (_, c) {
                    final share = total == 0 ? 0.0 : p.votes[i] / total;
                    final voted = p.myVote != null;
                    return Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: p.myVote == i ? cBlue : Colors.transparent, width: 1.6),
                      ),
                      child: Stack(children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(end: voted ? share : 0),
                          duration: const Duration(milliseconds: 700),
                          curve: akSpring,
                          builder: (_, v, _) => Container(
                            width: c.maxWidth * v.clamp(0.0, 1.0),
                            decoration: BoxDecoration(
                              color: (p.myVote == i ? cBlue : const Color(0xFF93C5FD)).withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(13),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Row(children: [
                            Expanded(child: Text(p.options[i], style: akT(14, w: FontWeight.w700))),
                            if (p.myVote == i) const Icon(Icons.check_circle_rounded, color: cBlue, size: 18),
                            if (voted) ...[
                              const SizedBox(width: 6),
                              Text('${(share * 100).round()}%', style: akT(13.5, w: FontWeight.w800)),
                            ],
                          ]),
                        ),
                      ]),
                    );
                  }),
                ),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(p.myVote == null ? '$total votes · tap to vote' : '$total votes', style: akT(12, w: FontWeight.w600, c: akFaint)),
            ),
          ]),
        );
      case PostKind.text:
        return const SizedBox.shrink();
    }
  }

  void _menu(BuildContext context) {
    final p = widget.p;
    final s = CommunityStore.I;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (c) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        padding: EdgeInsets.fromLTRB(8, 12, 8, 12 + MediaQuery.paddingOf(c).bottom),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 38, height: 5, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(3))),
          const SizedBox(height: 8),
          ListTile(
            leading: Icon(p.saved ? Icons.bookmark_remove_rounded : Icons.bookmark_add_rounded),
            title: Text(p.saved ? 'Remove from saved' : 'Save post', style: akT(15, w: FontWeight.w700)),
            onTap: () {
              Navigator.of(c).pop();
              s.save(p);
            },
          ),
          ListTile(
            leading: const Icon(Icons.link_rounded),
            title: Text('Copy link', style: akT(15, w: FontWeight.w700)),
            onTap: () {
              Navigator.of(c).pop();
              Clipboard.setData(ClipboardData(text: 'https://neurofit.app/p/${p.id}'));
              shopToast(context, 'Link copied', icon: Icons.link_rounded);
            },
          ),
          if (!p.mine)
            ListTile(
              leading: Icon(s.following.contains(p.handle) ? Icons.person_remove_rounded : Icons.person_add_rounded),
              title: Text(s.following.contains(p.handle) ? 'Unfollow ${p.name.split(' ').first}' : 'Follow ${p.name.split(' ').first}',
                  style: akT(15, w: FontWeight.w700)),
              onTap: () {
                Navigator.of(c).pop();
                s.toggleFollow(p.handle);
              },
            ),
          if (p.mine)
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
              title: Text('Delete post', style: akT(15, w: FontWeight.w700, c: const Color(0xFFEF4444))),
              onTap: () {
                Navigator.of(c).pop();
                s.delete(p);
                shopToast(context, 'Post deleted', icon: Icons.delete_outline_rounded);
              },
            )
          else
            ListTile(
              leading: const Icon(Icons.flag_outlined, color: Color(0xFFEF4444)),
              title: Text('Report post', style: akT(15, w: FontWeight.w700, c: const Color(0xFFEF4444))),
              onTap: () {
                Navigator.of(c).pop();
                _report(context);
              },
            ),
        ]),
      ),
    );
  }

  void _report(BuildContext context) {
    final p = widget.p;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (c) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        padding: EdgeInsets.fromLTRB(8, 18, 8, 12 + MediaQuery.paddingOf(c).bottom),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Why are you reporting this?', style: akT(17, w: FontWeight.w800)),
          const SizedBox(height: 6),
          for (final r in const ['Spam or misleading', 'Nudity or sexual content', 'Hate or harassment', 'Dangerous advice', 'Something else'])
            ListTile(
              title: Text(r, style: akT(14.5, w: FontWeight.w600)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.of(c).pop();
                CommunityStore.I.report(p);
                shopToast(context, 'Thanks. We hid this post and will review it.', icon: Icons.flag_rounded);
              },
            ),
        ]),
      ),
    );
  }
}

class _Like extends StatelessWidget {
  final bool liked;
  final VoidCallback onTap;
  const _Like({required this.liked, required this.onTap});
  @override
  Widget build(BuildContext context) => IconButton(
        onPressed: onTap,
        icon: TweenAnimationBuilder<double>(
          key: ValueKey(liked),
          tween: Tween(begin: liked ? 1.5 : 1, end: 1),
          duration: const Duration(milliseconds: 450),
          curve: akSpring,
          builder: (_, s, c) => Transform.scale(scale: s, child: c),
          child: Icon(liked ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: liked ? const Color(0xFFEF4444) : akInk, size: 25),
        ),
      );
}

/// Drag the handle to compare before and after.
class BeforeAfter extends StatefulWidget {
  final Pic before, after;
  final double aspect;
  const BeforeAfter({super.key, required this.before, required this.after, this.aspect = 1});
  @override
  State<BeforeAfter> createState() => _BeforeAfterState();
}

class _BeforeAfterState extends State<BeforeAfter> {
  double split = 0.5;
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: AspectRatio(
        aspectRatio: widget.aspect,
        child: LayoutBuilder(builder: (_, c) {
          final x = c.maxWidth * split;
          return GestureDetector(
            onHorizontalDragUpdate: (d) => setState(() => split = (split + d.delta.dx / c.maxWidth).clamp(0.05, 0.95)),
            child: Stack(fit: StackFit.expand, children: [
              NetImg(widget.after.url, bytes: widget.after.bytes),
              ClipRect(
                clipper: _Left(x),
                child: NetImg(widget.before.url, bytes: widget.before.bytes),
              ),
              Positioned(left: x - 1.5, top: 0, bottom: 0, child: Container(width: 3, color: Colors.white)),
              Positioned(
                left: x - 20,
                top: c.maxHeight / 2 - 20,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 10)],
                  ),
                  child: const Icon(Icons.compare_arrows_rounded, color: akInk, size: 22),
                ),
              ),
              Positioned(left: 10, top: 10, child: _tag('BEFORE', Colors.black54)),
              Positioned(right: 10, top: 10, child: _tag('AFTER', const Color(0xFF16A34A))),
            ]),
          );
        }),
      ),
    );
  }

  Widget _tag(String t, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(9)),
        child: Text(t, style: akT(10.5, w: FontWeight.w900, c: Colors.white, ls: 0.8)),
      );
}

class _Left extends CustomClipper<Rect> {
  final double x;
  _Left(this.x);
  @override
  Rect getClip(Size s) => Rect.fromLTWH(0, 0, x, s.height);
  @override
  bool shouldReclip(_Left o) => o.x != x;
}

// =====================================================================
//  COMMENTS
// =====================================================================

Future<void> showComments(BuildContext context, Post p) => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _Comments(p),
    );

class _Comments extends StatefulWidget {
  final Post p;
  const _Comments(this.p);
  @override
  State<_Comments> createState() => _CommentsState();
}

class _CommentsState extends State<_Comments> {
  final _c = TextEditingController();

  @override
  void initState() {
    super.initState();
    CommunityStore.I.loadComments(widget.p).then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _send() {
    if (_c.text.trim().isEmpty) return;
    HapticFeedback.selectionClick();
    CommunityStore.I.comment(widget.p, _c.text.trim());
    _c.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        height: MediaQuery.sizeOf(context).height * 0.7,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        child: Column(children: [
          const SizedBox(height: 10),
          Container(width: 38, height: 5, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(3))),
          Padding(padding: const EdgeInsets.all(12), child: Text('Comments', style: akT(16, w: FontWeight.w800))),
          const Divider(height: 1),
          Expanded(
            child: p.comments.isEmpty
                ? Center(child: Text('Be the first to comment', style: akT(14, w: FontWeight.w600, c: akMuted)))
                : ListenableBuilder(
                    listenable: CommunityStore.I,
                    builder: (_, _) => ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: p.comments.length,
                      itemBuilder: (_, i) {
                        final c = p.comments[i];
                        return Rise(
                          dy: 10,
                          child: ListTile(
                            leading: c.avatar == null
                                ? CircleAvatar(backgroundColor: cBlue, child: Text(Me.initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)))
                                : ClipOval(child: NetImg(unsplash(c.avatar!, 100), width: 40, height: 40)),
                            title: Text.rich(TextSpan(children: [
                              TextSpan(text: '${c.name}  ', style: akT(13.5, w: FontWeight.w800)),
                              TextSpan(text: ago(c.at), style: akT(11.5, w: FontWeight.w600, c: akFaint)),
                            ])),
                            subtitle: Text(c.text, style: akT(13.5, w: FontWeight.w500, c: akInk)),
                            trailing: GestureDetector(
                              onTap: () => CommunityStore.I.likeComment(c),
                              child: Column(mainAxisSize: MainAxisSize.min, children: [
                                Icon(c.liked ? Icons.favorite_rounded : Icons.favorite_border_rounded, size: 18, color: c.liked ? const Color(0xFFEF4444) : akFaint),
                                if (c.likes > 0) Text('${c.likes}', style: akT(10.5, w: FontWeight.w700, c: akFaint)),
                              ]),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(12, 8, 12, 10 + MediaQuery.paddingOf(context).bottom),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFF1F2F4)))),
            child: Row(children: [
              CircleAvatar(radius: 18, backgroundColor: cBlue, child: Text(Me.initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _c,
                  style: akT(14, w: FontWeight.w500),
                  decoration: InputDecoration(border: InputBorder.none, hintText: 'Add a comment…', hintStyle: akT(14, c: akFaint)),
                  onSubmitted: (_) => _send(),
                ),
              ),
              TextButton(onPressed: _send, child: Text('Post', style: akT(14, w: FontWeight.w800, c: cBlue))),
            ]),
          ),
        ]),
      ),
    );
  }
}

// =====================================================================
//  COMPOSER
// =====================================================================

void openComposer(BuildContext context, {int kind = 0}) => shopPush(context, ComposerPage(kind: kind));

class ComposerPage extends StatefulWidget {
  final int kind;
  const ComposerPage({super.key, this.kind = 0});
  @override
  State<ComposerPage> createState() => _ComposerPageState();
}

class _ComposerPageState extends State<ComposerPage> {
  late int kind = widget.kind;
  final _text = TextEditingController();
  final _title = TextEditingController();
  final _stat = TextEditingController();
  final List<Uint8List> photos = [];
  Uint8List? before, after;
  final List<(String, String)> moves = [];
  final List<TextEditingController> opts = [TextEditingController(), TextEditingController()];
  bool picking = false;

  static const kinds = [
    (Icons.photo_library_rounded, 'Photo', Color(0xFF16A34A)),
    (Icons.compare_rounded, 'Before/after', Color(0xFFF97316)),
    (Icons.fitness_center_rounded, 'Workout', Color(0xFF8B5CF6)),
    (Icons.poll_rounded, 'Poll', cBlue),
  ];
  static const suggestions = [
    ('Push-up', '3 × 15'),
    ('Squat', '4 × 10'),
    ('Plank', '3 × 45 s'),
    ('Burpee', '3 × 12'),
    ('Lunge', '3 × 12'),
    ('Deadlift', '4 × 6'),
    ('Pull-up', '3 × max'),
    ('Jump rope', '5 × 1 min'),
  ];

  @override
  void dispose() {
    _text.dispose();
    _title.dispose();
    _stat.dispose();
    for (final o in opts) {
      o.dispose();
    }
    super.dispose();
  }

  Future<Uint8List?> _pickOne() async {
    try {
      final f = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1080, imageQuality: 72);
      return f == null ? null : await f.readAsBytes();
    } catch (_) {
      if (mounted) shopToast(context, 'Could not open your photos', icon: Icons.error_outline_rounded);
      return null;
    }
  }

  Future<void> _pickMany() async {
    setState(() => picking = true);
    try {
      final fs = await ImagePicker().pickMultiImage(maxWidth: 1080, imageQuality: 72, limit: 4);
      for (final f in fs.take(4 - photos.length)) {
        photos.add(await f.readAsBytes());
      }
    } catch (_) {
      if (mounted) shopToast(context, 'Could not open your photos', icon: Icons.error_outline_rounded);
    }
    if (mounted) setState(() => picking = false);
  }

  String? get _problem {
    switch (kind) {
      case 0:
        if (photos.isEmpty && _text.text.trim().isEmpty) return 'Add a photo or write something';
      case 1:
        if (before == null || after == null) return 'Add both a before and an after photo';
      case 2:
        if (moves.isEmpty) return 'Add at least one exercise';
      case 3:
        if (_text.text.trim().isEmpty) return 'Write your poll question';
        if (opts.where((o) => o.text.trim().isNotEmpty).length < 2) return 'Add at least two options';
    }
    return null;
  }

  void _post() {
    final e = _problem;
    if (e != null) {
      HapticFeedback.heavyImpact();
      shopToast(context, e, icon: Icons.info_outline_rounded);
      return;
    }
    HapticFeedback.mediumImpact();
    final id = 'm${DateTime.now().millisecondsSinceEpoch}';
    final tags = RegExp(r'#\w+').allMatches(_text.text).map((m) => m.group(0)!).toList();
    final text = _text.text.replaceAll(RegExp(r'#\w+'), '').trim();
    final p = switch (kind) {
      0 => Post(
          id: id,
          name: Me.name,
          handle: Me.handle,
          text: text,
          at: DateTime.now(),
          kind: photos.isEmpty ? PostKind.text : PostKind.photo,
          mine: true,
          pics: [for (final b in photos) Pic(bytes: b)],
          tags: tags),
      1 => Post(
          id: id,
          name: Me.name,
          handle: Me.handle,
          text: text,
          at: DateTime.now(),
          kind: PostKind.beforeAfter,
          mine: true,
          pics: [Pic(bytes: before), Pic(bytes: after)],
          stat: _stat.text.trim().isEmpty ? null : _stat.text.trim(),
          tags: tags),
      2 => Post(
          id: id,
          name: Me.name,
          handle: Me.handle,
          text: text,
          at: DateTime.now(),
          kind: PostKind.workout,
          mine: true,
          workoutTitle: _title.text.trim().isEmpty ? 'My workout' : _title.text.trim(),
          exercises: List.of(moves),
          tags: tags),
      _ => Post(
          id: id,
          name: Me.name,
          handle: Me.handle,
          text: text,
          at: DateTime.now(),
          kind: PostKind.poll,
          mine: true,
          options: [for (final o in opts) if (o.text.trim().isNotEmpty) o.text.trim()],
          tags: tags),
    };
    CommunityStore.I.add(p);
    Navigator.of(context).pop();
    shopToast(context, 'Posted to the community 🎉', icon: Icons.check_circle_rounded);
  }

  @override
  Widget build(BuildContext context) {
    return ShopPage(
      title: 'New post',
      caption: 'Share with 48K members',
      tint: kinds[kind].$3,
      actions: [
        AkPress(
          onTap: _post,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [cBlue, cPink]), borderRadius: BorderRadius.circular(22)),
            child: Text('Post', style: akT(14, w: FontWeight.w800, c: Colors.white)),
          ),
        ),
      ],
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, 12, 16, 40 + MediaQuery.paddingOf(context).bottom),
        children: [
          Row(children: [
            for (var i = 0; i < kinds.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: AkPress(
                  onTap: () => setState(() => kind = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    curve: akSpring,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: kind == i ? kinds[i].$3 : Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: kind == i ? [BoxShadow(color: kinds[i].$3.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 5))] : null,
                    ),
                    child: Column(children: [
                      Icon(kinds[i].$1, color: kind == i ? Colors.white : kinds[i].$3),
                      const SizedBox(height: 4),
                      Text(kinds[i].$2, style: akT(11.5, w: FontWeight.w800, c: kind == i ? Colors.white : akInk)),
                    ]),
                  ),
                ),
              ),
            ],
          ]),
          const SizedBox(height: 14),
          ShopCard(
            margin: EdgeInsets.zero,
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              CircleAvatar(radius: 19, backgroundColor: cBlue, child: Text(Me.initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _text,
                  maxLines: 5,
                  minLines: 3,
                  style: akT(15, w: FontWeight.w500, h: 1.4),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: kind == 3 ? 'Ask a question…' : 'What\'s on your mind? Add #tags too',
                    hintStyle: akT(14.5, c: akFaint),
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 14),
          AnimatedSwitcher(duration: const Duration(milliseconds: 280), child: KeyedSubtree(key: ValueKey(kind), child: _body())),
        ],
      ),
    );
  }

  Widget _body() {
    switch (kind) {
      case 0:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: [
              for (var i = 0; i < photos.length; i++)
                Stack(fit: StackFit.expand, children: [
                  ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.memory(photos[i], fit: BoxFit.cover)),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () => setState(() => photos.removeAt(i)),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(Icons.close_rounded, color: Colors.white, size: 17),
                      ),
                    ),
                  ),
                ]),
              if (photos.length < 4) _addTile('Add photos', picking ? null : _pickMany),
            ],
          ),
          const SizedBox(height: 8),
          Text('Up to 4 photos', style: akT(12, w: FontWeight.w600, c: akFaint)),
        ]);
      case 1:
        return Column(children: [
          Row(children: [
            Expanded(child: _slot('Before', before, () async {
              final b = await _pickOne();
              if (b != null) setState(() => before = b);
            })),
            const SizedBox(width: 10),
            Expanded(child: _slot('After', after, () async {
              final b = await _pickOne();
              if (b != null) setState(() => after = b);
            })),
          ]),
          const SizedBox(height: 12),
          _field(_stat, 'Result, e.g. -8 kg · 12 weeks', Icons.trending_down_rounded),
          if (before != null && after != null) ...[
            const SizedBox(height: 12),
            BeforeAfter(before: Pic(bytes: before), after: Pic(bytes: after)),
          ],
        ]);
      case 2:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _field(_title, 'Workout name, e.g. 20-min core', Icons.fitness_center_rounded),
          const SizedBox(height: 12),
          for (var i = 0; i < moves.length; i++)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Row(children: [
                Text('${i + 1}', style: akN(15, c: const Color(0xFF8B5CF6))),
                const SizedBox(width: 12),
                Expanded(child: Text(moves[i].$1, style: akT(14, w: FontWeight.w700))),
                Text(moves[i].$2, style: akT(13, w: FontWeight.w700, c: akMuted)),
                IconButton(onPressed: () => setState(() => moves.removeAt(i)), icon: const Icon(Icons.close_rounded, size: 18)),
              ]),
            ),
          Text('Tap to add', style: akT(13, w: FontWeight.w800)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final s in suggestions)
              ActionChip(
                avatar: const Icon(Icons.add_rounded, size: 16),
                label: Text('${s.$1} · ${s.$2}', style: akT(12.5, w: FontWeight.w700)),
                backgroundColor: Colors.white,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => moves.add(s));
                },
              ),
          ]),
        ]);
      default:
        return Column(children: [
          for (var i = 0; i < opts.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Expanded(child: _field(opts[i], 'Option ${i + 1}', Icons.radio_button_unchecked_rounded)),
                if (opts.length > 2)
                  IconButton(onPressed: () => setState(() => opts.removeAt(i).dispose()), icon: const Icon(Icons.remove_circle_outline_rounded, color: akMuted)),
              ]),
            ),
          if (opts.length < 4)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() => opts.add(TextEditingController())),
                icon: const Icon(Icons.add_rounded),
                label: Text('Add option', style: akT(13.5, w: FontWeight.w800, c: cBlue)),
              ),
            ),
        ]);
    }
  }

  Widget _field(TextEditingController c, String hint, IconData icon) => TextField(
        controller: c,
        style: akT(14.5, w: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: akT(14, c: akFaint),
          prefixIcon: Icon(icon, size: 19, color: akMuted),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        ),
      );

  Widget _addTile(String label, VoidCallback? onTap) => AkPress(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            onTap == null ? const CircularProgressIndicator(strokeWidth: 2.5) : const Icon(Icons.add_photo_alternate_rounded, size: 34, color: cBlue),
            const SizedBox(height: 6),
            Text(label, style: akT(13, w: FontWeight.w800)),
          ]),
        ),
      );

  Widget _slot(String label, Uint8List? b, VoidCallback onTap) => AspectRatio(
        aspectRatio: 0.8,
        child: b == null
            ? _addTile('Add $label', onTap)
            : GestureDetector(
                onTap: onTap,
                child: Stack(fit: StackFit.expand, children: [
                  ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.memory(b, fit: BoxFit.cover)),
                  Positioned(
                    left: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: label == 'After' ? const Color(0xFF16A34A) : Colors.black54, borderRadius: BorderRadius.circular(8)),
                      child: Text(label.toUpperCase(), style: akT(10, w: FontWeight.w900, c: Colors.white)),
                    ),
                  ),
                ]),
              ),
      );
}

/// Unused import guard for math on some builds.
