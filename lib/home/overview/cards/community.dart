part of '../overview_home_cards.dart';

// =====================================================================
//  5. COMMUNITY
// =====================================================================

/// Active challenges the admin publishes (`/api/challenges`).
class _Challenges {
  static final ValueNotifier<List<Map<String, dynamic>>> list = ValueNotifier(const []);
  static bool _asked = false;
  static void load() {
    if (_asked) return;
    _asked = true;
    Api.get('/challenges?activeOnly=true&limit=20').then((j) {
      list.value = Api.list(j);
    }).catchError((_) {});
  }

  static String title(Map<String, dynamic> c) => (c['title'] ?? c['name'] ?? 'Challenge').toString();
  static String sub(Map<String, dynamic> c) {
    final n = (c['participants'] ?? c['joined'] ?? c['participantCount']);
    final days = c['durationDays'] ?? c['days'];
    return [if (n != null) '$n joined', if (days != null) '$days days'].join(' · ');
  }
}

bool _today(DateTime t) {
  final n = DateTime.now();
  return t.year == n.year && t.month == n.month && t.day == n.day;
}

class _CommunityCard extends StatelessWidget {
  const _CommunityCard();

  @override
  Widget build(BuildContext context) {
    _Challenges.load();
    return ListenableBuilder(
      listenable: Listenable.merge([CommunityStore.I, _Challenges.list]),
      builder: (context, _) => _build(context),
    );
  }

  Widget _build(BuildContext context) {
    final posts = CommunityStore.I.visible;
    final seen = <String>{};
    final faces = [
      for (final p in posts)
        if ((p.avatar ?? '').startsWith('http') && seen.add(p.handle)) (p.avatar!, p.name),
    ].take(4).toList();
    final today = posts.where((p) => _today(p.at)).toList();
    final top = posts.isEmpty ? null : posts.first;
    final ch = _Challenges.list.value.isEmpty ? null : _Challenges.list.value.first;
    const ring = [_green, _orange, _blue, _purple];
    return _NeuCard(
      page: () => const _CommunityDetailPage(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHead('Community', Icons.groups_rounded, _blue),
          const SizedBox(height: 14),
          Row(
            children: [
              if (faces.isNotEmpty) ...[
                SizedBox(
                  width: 34 + (faces.length - 1) * 22.0,
                  height: 34,
                  child: Stack(
                    children: [
                      for (var i = 0; i < faces.length; i++)
                        Positioned(
                          left: i * 22.0,
                          child: Container(
                            width: 34,
                            height: 34,
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: ClipOval(
                              child: _photo(faces[i].$1, faces[i].$2, ring[i % ring.length], radius: 0),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const TickerGate(child: _LiveDot()),
                        const SizedBox(width: 6),
                        Text(
                          '${today.length} ${today.length == 1 ? 'post' : 'posts'} today',
                          style: _t(13, w: FontWeight.w800),
                        ),
                      ],
                    ),
                    Text(
                      '${today.where((p) => p.kind == PostKind.workout).length} workouts shared today',
                      style: _t(11, w: FontWeight.w600, c: _faint),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (top != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F8F7),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: _photo(top.avatar ?? '', top.name, _purple, radius: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          text: TextSpan(
                            style: _t(12.5, w: FontWeight.w600, c: _muted),
                            children: [
                              TextSpan(
                                text: '${top.name.split(' ').first} ',
                                style: _t(12.5, w: FontWeight.w800),
                              ),
                              TextSpan(text: top.text.isNotEmpty ? top.text : (top.workoutTitle ?? 'shared a post')),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.favorite_rounded,
                              size: 13,
                              color: _pink,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${top.likes}',
                              style: _t(11, w: FontWeight.w700, c: _muted),
                            ),
                            const SizedBox(width: 10),
                            const Icon(
                              Icons.chat_bubble_rounded,
                              size: 12,
                              color: _faint,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${top.commentCount}',
                              style: _t(11, w: FontWeight.w700, c: _muted),
                            ),
                            const Spacer(),
                            Text(
                              ago(top.at),
                              style: _t(11, w: FontWeight.w600, c: _faint),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (ch != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _blue.withValues(alpha: 0.2)),
                color: _blue.withValues(alpha: 0.05),
              ),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events_rounded, size: 18, color: _blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      [_Challenges.title(ch), _Challenges.sub(ch)].where((x) => x.isNotEmpty).join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _t(12.5, w: FontWeight.w700),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Join',
                      style: _t(12, w: FontWeight.w800, c: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LiveDot extends StatefulWidget {
  const _LiveDot();
  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 12,
      height: 12,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 6 + 6 * _c.value,
              height: 6 + 6 * _c.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _mint.withValues(alpha: 0.4 * (1 - _c.value)),
              ),
            ),
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: _mint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
