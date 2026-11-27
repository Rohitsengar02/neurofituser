part of '../overview_home_cards.dart';

// =====================================================================
//  4. TOP TRAINERS
// =====================================================================

const _coachColors = [_green, _orange, _blue, _purple];

/// Approved coaches from the API, best rated first:
/// (name, speciality, rating, clients, photo, colour, category).
List<(String, String, String, String, String, Color, String)> get _trainers {
  final list = [...trainers]..sort((a, b) => b.rating.compareTo(a.rating));
  return [
    for (var i = 0; i < list.length && i < 8; i++)
      (
        list[i].name,
        list[i].role,
        list[i].rating > 0 ? list[i].rating.toStringAsFixed(1) : 'New',
        '${list[i].clients} clients',
        list[i].img,
        _coachColors[i % _coachColors.length],
        list[i].cat,
      ),
  ];
}

Widget _photo(String url, String name, Color c, {double radius = 18}) =>
    ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [c.withValues(alpha: 0.25), c.withValues(alpha: 0.6)],
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            name.split(' ').where((e) => e.isNotEmpty).map((e) => e[0]).join(),
            style: _t(20, w: FontWeight.w800, c: Colors.white),
          ),
        ),
      ),
    );

class _TrainersCard extends StatelessWidget {
  const _TrainersCard();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(listenable: TrainerStore.I, builder: (context, _) => _trainers.isEmpty ? const SizedBox.shrink() : _build(context));
  }

  Widget _build(BuildContext context) {
    return _NeuCard(
      page: () => const _TrainersDetailPage(),
      padding: const EdgeInsets.fromLTRB(18, 18, 0, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 18),
            child: _cardHead(
              'Top trainers for you',
              Icons.workspace_premium_rounded,
              _purple,
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 44),
            child: Text(
              'Top rated coaches on NeuroFit',
              style: _t(11.5, w: FontWeight.w600, c: _faint),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 196,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 18),
              itemCount: _trainers.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final tr = _trainers[i];
                return Container(
                  width: 138,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F8F7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 110,
                        width: double.infinity,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            _photo(tr.$5, tr.$1, tr.$6, radius: 15),
                            Positioned(
                              left: 6,
                              top: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.92),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  tr.$7,
                                  style: _t(11, w: FontWeight.w800, c: tr.$6),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr.$1,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _t(13, w: FontWeight.w800),
                            ),
                            Text(
                              tr.$2,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _t(11, w: FontWeight.w600, c: _muted),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  size: 14,
                                  color: _amber,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  tr.$3,
                                  style: _t(11.5, w: FontWeight.w800),
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    tr.$4,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: _t(11,
                                      w: FontWeight.w600,
                                      c: _faint,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
