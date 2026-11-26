part of '../workout_tab_v2.dart';

// =====================================================================
//  CHALLENGES (banner carousel)
// =====================================================================

class _Challenges extends StatefulWidget {
  const _Challenges();
  @override
  State<_Challenges> createState() => _ChallengesState();
}

class _ChallengesState extends State<_Challenges> {
  final _pc = PageController(viewportFraction: 0.9);
  int _page = 0;
  static const _banners = [
    'assets/images/workout_banner_2.png',
    'assets/images/workout_banner_1.png',
    'assets/images/workout_banner_4.png',
    'assets/images/workout_banner_3.png',
  ];

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      SizedBox(
        height: 190,
        child: PageView.builder(
          controller: _pc,
          itemCount: _banners.length,
          onPageChanged: (p) => setState(() => _page = p),
          itemBuilder: (_, i) => AnimatedBuilder(
            animation: _pc,
            builder: (_, c) {
              var d = 0.0;
              if (_pc.hasClients && _pc.position.haveDimensions) d = (_pc.page ?? 0) - i;
              final s = 1 - (d.abs() * 0.08).clamp(0.0, 0.08);
              return Transform.scale(scale: s, child: c);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 10))],
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(_banners[i], fit: BoxFit.cover),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        for (var i = 0; i < _banners.length; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 380),
            curve: _spring,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == _page ? 22 : 7,
            height: 7,
            decoration: BoxDecoration(
              color: i == _page ? _ink : _ink.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ]),
    ]);
  }
}
