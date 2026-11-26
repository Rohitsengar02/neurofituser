part of '../overview_home_cards.dart';

// =====================================================================
//  DETAIL PAGES (opened with a zoom from the card)
// =====================================================================

class _DetailScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;
  final Widget? bottom;
  const _DetailScaffold({
    required this.title,
    required this.subtitle,
    required this.children,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),
      body: Stack(
        children: [
          const Positioned.fill(
            child: FurBlobsBackdrop(blobCount: 3, doodles: false),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            size: 20,
                            color: _ink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: _t(20, w: FontWeight.w800, ls: -0.4),
                            ),
                            Text(
                              subtitle,
                              style: _t(12, w: FontWeight.w600, c: _faint),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      8,
                      16,
                      bottom != null ? 100 : 32,
                    ),
                    children: [
                      for (var i = 0; i < children.length; i++) ...[
                        _Rise(i, children[i]),
                        const SizedBox(height: 14),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (bottom != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: SafeArea(top: false, child: bottom!),
            ),
        ],
      ),
    );
  }
}

Widget _panel(Widget child, {EdgeInsets padding = const EdgeInsets.all(16)}) =>
    Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7D948A).withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );

Widget _statRow(List<(String, String, Color)> items) => Row(
  children: [
    for (var i = 0; i < items.length; i++) ...[
      if (i > 0) const SizedBox(width: 10),
      Expanded(
        child: _panel(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  items[i].$1,
                  style: _t(20, w: FontWeight.w800, c: items[i].$3, ls: -0.5),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                items[i].$2,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _t(11, w: FontWeight.w600, c: _faint),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
        ),
      ),
    ],
  ],
);

Widget _sectionTitle(String s) => Padding(
  padding: const EdgeInsets.only(bottom: 10),
  child: Text(s, style: _t(16, w: FontWeight.w800, ls: -0.2)),
);

class _StreakDetailPage extends StatelessWidget {
  const _StreakDetailPage();

  @override
  Widget build(BuildContext context) {
    return _DetailScaffold(
      title: 'Day 13 · Upper Body Push',
      subtitle: 'Muscle Builder · 30 day plan',
      bottom: _PrimaryButton(
        icon: Icons.play_arrow_rounded,
        label: 'Start workout',
        onTap: () {},
      ),
      children: [
        _panel(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Minutes trained', style: _t(14, w: FontWeight.w700)),
                  const Spacer(),
                  Text(
                    'Last 14 days',
                    style: _t(12, w: FontWeight.w600, c: _faint),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const DottedLineChart(
                values: _streakMinutes,
                color: _green,
                label: '48 min',
                height: 170,
                xLabels: [
                  '13',
                  '14',
                  '15',
                  '16',
                  '17',
                  '18',
                  '19',
                  '20',
                  '21',
                  '22',
                  '23',
                  '24',
                  '25',
                  '26',
                ],
              ),
            ],
          ),
        ),
        _statRow(const [
          ('12', 'Day streak', _orange),
          ('41', 'Avg min', _green),
          ('18', 'Best streak', _purple),
        ]),
        _panel(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle("Today's exercises"),
              for (var i = 0; i < _todayPlan.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(_todayPlan[i].$3, size: 19, color: _green),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _todayPlan[i].$1,
                          style: _t(13.5, w: FontWeight.w700),
                        ),
                      ),
                      Text(
                        _todayPlan[i].$2,
                        style: _t(12.5, w: FontWeight.w700, c: _muted),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        _panel(
          Row(
            children: [
              const Icon(Icons.tips_and_updates_rounded, color: _amber),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Kemo: rest 90 s between sets today. Your pressing volume is up 12% this week.',
                  style: _t(12.5, w: FontWeight.w600, c: _muted, h: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NutritionDetailPage extends StatelessWidget {
  const _NutritionDetailPage();

  @override
  Widget build(BuildContext context) {
    const meals = [
      (
        'Breakfast',
        'Oats, banana, whey',
        420,
        Icons.free_breakfast_rounded,
        _amber,
      ),
      ('Lunch', 'Chicken rice bowl', 610, Icons.lunch_dining_rounded, _green),
      ('Snack', 'Greek yogurt, almonds', 390, Icons.icecream_rounded, _pink),
      ('Dinner', 'Not logged yet', 0, Icons.dinner_dining_rounded, _faint),
    ];
    return _DetailScaffold(
      title: 'Nutrition',
      subtitle: 'Today · ${IslandStats.left} kcal left',
      children: [
        _panel(
          Row(
            children: [
              SizedBox(
                width: 130,
                height: 130,
                child: _AnimRing(
                  value: IslandStats.eaten / IslandStats.budget,
                  color: _orange,
                  stroke: 13,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Count(
                        IslandStats.eaten.toDouble(),
                        _t(26, w: FontWeight.w800),
                      ),
                      Text(
                        'kcal eaten',
                        style: _t(11, w: FontWeight.w600, c: _faint),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    for (final m in _macros) ...[
                      _MacroBar(
                        name: m.$1,
                        value: m.$2,
                        goal: m.$3,
                        unit: m.$4,
                        color: m.$5,
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        _panel(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('Calories this week'),
              const DottedLineChart(
                values: <double>[1650, 1820, 1540, 1760, 1900, 1610, 1420],
                color: _orange,
                label: '1,420',
                height: 150,
                xLabels: ['Fri', 'Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Today'],
              ),
            ],
          ),
        ),
        _panel(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('Meals'),
              for (final m in meals)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: m.$5.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(m.$4, size: 20, color: m.$5),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.$1, style: _t(13.5, w: FontWeight.w800)),
                            Text(
                              m.$2,
                              style: _t(11.5, w: FontWeight.w600, c: _faint),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        m.$3 == 0 ? '+ Add' : '${m.$3} kcal',
                        style: _t(
                          12.5,
                          w: FontWeight.w800,
                          c: m.$3 == 0 ? _green : _ink,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        _statRow(const [
          ('1.25 L', 'Water', _blue),
          ('18 g', 'Fiber', _green),
          ('42 mg', 'Sodium ok', _purple),
        ]),
      ],
    );
  }
}

class _StepsDetailPage extends StatelessWidget {
  const _StepsDetailPage();

  @override
  Widget build(BuildContext context) {
    return _DetailScaffold(
      title: 'Steps',
      subtitle: 'Today · goal 10,000',
      bottom: _PrimaryButton(
        icon: Icons.directions_walk_rounded,
        label: 'Open step tracker',
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const StepsScreen())),
      ),
      children: [
        _panel(
          Column(
            children: [
              SizedBox(
                width: 190,
                height: 190,
                child: _AnimRing(
                  value: IslandStats.steps / 10000,
                  color: _green,
                  stroke: 16,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Count(
                        IslandStats.steps.toDouble(),
                        _t(34, w: FontWeight.w800, ls: -1),
                        group: true,
                      ),
                      Text(
                        'steps today',
                        style: _t(12, w: FontWeight.w600, c: _faint),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const SizedBox(
                height: 80,
                child: _HourBars(values: _hourly, color: _green),
              ),
            ],
          ),
        ),
        _statRow(const [
          ('6.1 km', 'Distance', _blue),
          ('320', 'kcal burned', _orange),
          ('54 min', 'Active', _green),
        ]),
        _panel(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('This week'),
              const DottedLineChart(
                values: <double>[7200, 9100, 6400, 10300, 8800, 11200, 8542],
                color: _green,
                label: '8,542',
                height: 150,
                xLabels: ['Fri', 'Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Today'],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TrainersDetailPage extends StatelessWidget {
  const _TrainersDetailPage();

  @override
  Widget build(BuildContext context) {
    return _DetailScaffold(
      title: 'Top trainers for you',
      subtitle: 'Matched to your goal and schedule',
      bottom: _PrimaryButton(
        icon: Icons.search_rounded,
        label: 'See all trainers',
        onTap: () => Navigator.of(
          context,
        ).push(trainersRoute()),
      ),
      children: [
        for (final tr in _trainers)
          _panel(
            Row(
              children: [
                SizedBox(
                  width: 84,
                  height: 96,
                  child: _photo(tr.$5, tr.$1, tr.$6),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              tr.$1,
                              style: _t(15, w: FontWeight.w800),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: tr.$6.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              tr.$7,
                              style: _t(11, w: FontWeight.w800, c: tr.$6),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${tr.$2} coach',
                        style: _t(12, w: FontWeight.w600, c: _muted),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 15,
                            color: _amber,
                          ),
                          Text(' ${tr.$3}', style: _t(12, w: FontWeight.w800)),
                          Text(
                            '  ·  ${tr.$4}',
                            style: _t(11.5, w: FontWeight.w600, c: _faint),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: _ink,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Book session',
                              style: _t(
                                11.5,
                                w: FontWeight.w700,
                                c: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Free intro call',
                            style: _t(11, w: FontWeight.w600, c: _green),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            padding: const EdgeInsets.all(12),
          ),
      ],
    );
  }
}

class _CommunityDetailPage extends StatelessWidget {
  const _CommunityDetailPage();

  @override
  Widget build(BuildContext context) {
    final posts = [
      for (final p in CommunityStore.I.visible.take(5))
        (p.name, p.text.isNotEmpty ? p.text : (p.workoutTitle ?? ''), p.likes, p.commentCount, ago(p.at), p.avatar ?? ''),
    ];
    const looks = [
      (Icons.directions_walk_rounded, _green),
      (Icons.fitness_center_rounded, _orange),
      (Icons.self_improvement_rounded, _purple),
    ];
    final challenges = [
      for (var i = 0; i < _Challenges.list.value.length; i++)
        (
          _Challenges.title(_Challenges.list.value[i]),
          _Challenges.sub(_Challenges.list.value[i]),
          looks[i % looks.length].$1,
          looks[i % looks.length].$2,
        ),
    ];
    final today = CommunityStore.I.visible.where((p) => _today(p.at)).length;
    return _DetailScaffold(
      title: 'Community',
      subtitle: '$today ${today == 1 ? 'post' : 'posts'} today',
      bottom: _PrimaryButton(
        icon: Icons.groups_rounded,
        label: 'Open community',
        onTap: () => Navigator.of(
          context,
        ).push(communityRoute()),
      ),
      children: [
        if (challenges.isNotEmpty)
        _panel(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('Challenges'),
              for (final c in challenges)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: c.$4.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(c.$3, size: 20, color: c.$4),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.$1, style: _t(13.5, w: FontWeight.w800)),
                            Text(
                              c.$2,
                              style: _t(11.5, w: FontWeight.w600, c: _faint),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: c.$4.withValues(alpha: 0.4),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Join',
                          style: _t(12, w: FontWeight.w800, c: c.$4),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        for (final p in posts)
          _panel(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 38,
                      height: 38,
                      child: _photo(
                        p.$6,
                        p.$1,
                        _blue,
                        radius: 19,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(p.$1, style: _t(13.5, w: FontWeight.w800)),
                    ),
                    Text(
                      p.$5,
                      style: _t(11, w: FontWeight.w600, c: _faint),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  p.$2,
                  style: _t(13, w: FontWeight.w500, c: _ink, h: 1.45),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.favorite_rounded, size: 16, color: _pink),
                    Text(
                      ' ${p.$3}',
                      style: _t(12, w: FontWeight.w700, c: _muted),
                    ),
                    const SizedBox(width: 14),
                    const Icon(
                      Icons.chat_bubble_rounded,
                      size: 15,
                      color: _faint,
                    ),
                    Text(
                      ' ${p.$4}',
                      style: _t(12, w: FontWeight.w700, c: _muted),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}
