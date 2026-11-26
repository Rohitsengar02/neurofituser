part of '../overview_home_cards.dart';

// =====================================================================
//  5. COMMUNITY
// =====================================================================

class _CommunityCard extends StatelessWidget {
  const _CommunityCard();

  @override
  Widget build(BuildContext context) {
    return _NeuCard(
      page: () => const _CommunityDetailPage(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHead('Community', Icons.groups_rounded, _blue),
          const SizedBox(height: 14),
          Row(
            children: [
              SizedBox(
                width: 104,
                height: 34,
                child: Stack(
                  children: [
                    for (var i = 0; i < 4; i++)
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
                            child: _photo(
                              _trainers[i].$5,
                              _trainers[i].$1,
                              _trainers[i].$6,
                              radius: 0,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const TickerGate(child: _LiveDot()),
                        const SizedBox(width: 6),
                        Text(
                          '2.4k active now',
                          style: _t(13, w: FontWeight.w800),
                        ),
                      ],
                    ),
                    Text(
                      '128 workouts shared today',
                      style: _t(11, w: FontWeight.w600, c: _faint),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
                  child: _photo(
                    _trainers[3].$5,
                    'Neha Patel',
                    _purple,
                    radius: 20,
                  ),
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
                              text: 'Neha ',
                              style: _t(12.5, w: FontWeight.w800),
                            ),
                            const TextSpan(
                              text: 'finished the 30-day plank challenge 🎉',
                            ),
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
                            '342',
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
                            '48',
                            style: _t(11, w: FontWeight.w700, c: _muted),
                          ),
                          const Spacer(),
                          Text(
                            '12m',
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
                    '10K Steps Weekend · 312 joined',
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
