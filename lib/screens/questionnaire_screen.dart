import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/onboarding/onboarding_kit.dart';
import 'plan_generation_screen.dart';

/// Eight-step onboarding questionnaire.
///
/// Phone: one column with a progress bar, the animated step and a bottom CTA.
/// Desktop / tablet (>= 900px): a live "your profile" panel on the left with
/// floating 3D objects, and the step card on the right.
class QuestionnaireScreen extends StatefulWidget {
  const QuestionnaireScreen({super.key});

  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _StepMeta {
  const _StepMeta(this.lead, this.accent, this.subtitle, this.color, this.icons);
  final String lead;
  final String accent;
  final String subtitle;
  final Color color;
  final List<IconData> icons;
}

const _steps = <_StepMeta>[
  _StepMeta('Your fitness journey', 'starts here',
      'Answer 7 quick questions and we will build a plan that fits your body and your goals.',
      Color(0xFF16A34A), [Icons.bolt_rounded, Icons.favorite_rounded, Icons.fitness_center_rounded]),
  _StepMeta('Tell us about', 'yourself', 'This helps us tune calories, intensity and recovery for you.',
      Color(0xFF2563EB), [Icons.person_rounded, Icons.auto_awesome_rounded, Icons.star_rounded]),
  _StepMeta('How old', 'are you?', 'Age changes how fast you recover and how hard you should train.',
      Color(0xFF7C3AED), [Icons.cake_rounded, Icons.celebration_rounded, Icons.timer_rounded]),
  _StepMeta('Your current', 'weight', 'Drag the ruler or use the buttons. You can change it later.',
      Color(0xFF0891B2), [Icons.monitor_weight_rounded, Icons.water_drop_rounded, Icons.speed_rounded]),
  _StepMeta('Your target', 'weight', 'Pick a goal weight you would feel great at.',
      Color(0xFF059669), [Icons.flag_rounded, Icons.trending_down_rounded, Icons.emoji_events_rounded]),
  _StepMeta('How tall', 'are you?', 'Height lets us work out your BMI and daily energy needs.',
      Color(0xFF0D9488), [Icons.height_rounded, Icons.straighten_rounded, Icons.accessibility_new_rounded]),
  _StepMeta('What are your', 'goals?', 'Pick everything that matters to you.',
      Color(0xFFD97706), [Icons.local_fire_department_rounded, Icons.fitness_center_rounded, Icons.bolt_rounded]),
  _StepMeta('How active', 'are you?', 'Be honest, we will meet you where you are.',
      Color(0xFFEA580C), [Icons.directions_run_rounded, Icons.directions_bike_rounded, Icons.pool_rounded]),
];

const _tiles = <String>[
  'assets/images/neon_green_dumbbell_1787819274202.jpg',
  'assets/images/neon_orange_kettlebell_1787819340750.jpg',
  'assets/images/neon_green_shoe_1787819288631.jpg',
  'assets/images/neon_orange_heartrate_1787819363247.jpg',
  'assets/images/neon_green_waterbottle_1787819315145.jpg',
  'assets/images/neon_orange_proteinshaker_1787819387813.jpg',
];

String _fmt(double v) => v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(1);

String _feetInches(double cm) {
  final totalIn = cm / 2.54;
  var ft = totalIn ~/ 12;
  var inch = (totalIn - ft * 12).round();
  if (inch == 12) {
    ft += 1;
    inch = 0;
  }
  return "$ft' $inch\"";
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  int _currentStep = 0;
  bool _forward = true;

  String _selectedGender = 'Male';
  int _selectedAge = 25;
  double _currentWeight = 70.0;
  double _targetWeight = 60.0;
  double _height = 170.0;
  String _heightUnit = 'cm';
  final Set<String> _selectedGoals = {'Lose Weight'};
  String _selectedActivity = 'Moderately Active';

  _StepMeta get _meta => _steps[_currentStep];

  void _go(int delta) {
    final next = _currentStep + delta;
    if (next < 0) {
      if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      return;
    }
    if (next >= _steps.length) {
      _finish();
      return;
    }
    HapticFeedback.lightImpact();
    setState(() {
      _forward = delta > 0;
      _currentStep = next;
    });
  }

  void _finish() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 700),
        pageBuilder: (context, animation, secondaryAnimation) => PlanGenerationScreen(
          gender: _selectedGender,
          age: _selectedAge,
          currentWeight: _currentWeight,
          targetWeight: _targetWeight,
          height: _height,
          goals: _selectedGoals.toList(),
          activityLevel: _selectedActivity,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Layout
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final color = _meta.color;
    return Scaffold(
      backgroundColor: OnbColors.base,
      body: AuroraBackground(
        colors: [color, OnbColors.lime, Color.lerp(color, Colors.white, 0.2)!],
        child: Stack(
          children: [
            Positioned.fill(
              child: DriftingIcons(key: ValueKey(_currentStep), icons: _meta.icons, color: color, count: 6),
            ),
            SafeArea(
              child: LayoutBuilder(builder: (context, box) {
                final wide = box.maxWidth >= 900;
                return wide ? _wideLayout(box) : _phoneLayout(box);
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _phoneLayout(BoxConstraints box) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: box.maxWidth < 380 ? 16 : 22),
          child: Column(
            children: [
              const SizedBox(height: 10),
              _topBar(),
              const SizedBox(height: 8),
              Expanded(child: _stage()),
              _bottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _wideLayout(BoxConstraints box) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 24),
      child: Row(
        children: [
          Expanded(flex: 5, child: _SidePanel(state: this)),
          const SizedBox(width: 32),
          Expanded(
            flex: 6,
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 560, maxHeight: math.min(box.maxHeight, 820)),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.78),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: Colors.white),
                    boxShadow: [
                      BoxShadow(color: _meta.color.withValues(alpha: 0.12), blurRadius: 60, offset: const Offset(0, 24)),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(28, 22, 28, 0),
                  child: Column(
                    children: [
                      _topBar(),
                      const SizedBox(height: 8),
                      Expanded(child: _stage()),
                      _bottomBar(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topBar() {
    final color = _meta.color;
    return Row(
      children: [
        AnimatedOpacity(
          duration: const Duration(milliseconds: 250),
          opacity: _currentStep == 0 && !Navigator.of(context).canPop() ? 0.0 : 1.0,
          child: RoundIconButton(icon: Icons.arrow_back_ios_new_rounded, onTap: () => _go(-1), size: 42),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Row(
            children: List.generate(_steps.length, (i) {
              final done = i <= _currentStep;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      height: 6,
                      color: OnbColors.line,
                      alignment: Alignment.centerLeft,
                      child: AnimatedFractionallySizedBox(
                        duration: Duration(milliseconds: 380 + i * 20),
                        curve: Curves.easeOutCubic,
                        widthFactor: done ? 1 : 0,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 380),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [color, Color.lerp(color, OnbColors.lime, 0.5)!]),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: 14),
        AnimatedContainer(
          duration: const Duration(milliseconds: 380),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text('${_currentStep + 1} of ${_steps.length}',
              style: onbFont(size: 12.5, weight: FontWeight.w700, color: color)),
        ),
      ],
    );
  }

  Widget _bottomBar() {
    final last = _currentStep == _steps.length - 1;
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 18),
      child: GlowButton(
        label: last ? 'Get Started' : 'Next',
        icon: last ? Icons.rocket_launch_rounded : Icons.arrow_forward_rounded,
        color: _meta.color,
        onTap: () => _go(1),
      ),
    );
  }

  Widget _stage() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 480),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (current, previous) =>
          Stack(fit: StackFit.expand, children: [...previous, if (current != null) current]),
      transitionBuilder: (child, anim) {
        final incoming = child.key == ValueKey(_currentStep);
        final dir = _forward ? 1.0 : -1.0;
        final begin = Offset((incoming ? 0.18 : -0.18) * dir, 0);
        return FadeTransition(
          opacity: anim,
          child: SlideTransition(position: Tween(begin: begin, end: Offset.zero).animate(anim), child: child),
        );
      },
      child: KeyedSubtree(key: ValueKey(_currentStep), child: _stepPage(_currentStep)),
    );
  }

  Widget _stepPage(int step) {
    final meta = _steps[step];
    return LayoutBuilder(builder: (context, box) {
      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: box.maxHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (step != 0) ...[
                  _Header(meta: meta, compact: box.maxHeight < 560),
                  SizedBox(height: box.maxHeight < 560 ? 16 : 26),
                ],
                _stepBody(step, box),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _stepBody(int step, BoxConstraints box) {
    switch (step) {
      case 0:
        return _WelcomeStep(meta: _steps[0], maxHeight: box.maxHeight);
      case 1:
        return _genderStep();
      case 2:
        return _ageStep();
      case 3:
        return _currentWeightStep();
      case 4:
        return _targetWeightStep();
      case 5:
        return _heightStep();
      case 6:
        return _goalsStep();
      default:
        return _activityStep();
    }
  }

  // ---------------------------------------------------------------------------
  // Steps
  // ---------------------------------------------------------------------------
  Widget _genderStep() {
    final color = _meta.color;
    Widget card(String g, IconData icon, String note, int i, {bool wide = false}) => Reveal(
          delay: Duration(milliseconds: 80 + i * 90),
          child: _ChoiceCard(
            selected: _selectedGender == g,
            color: color,
            onTap: () => setState(() => _selectedGender = g),
            horizontal: wide,
            icon: icon,
            title: g,
            subtitle: note,
          ),
        );
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: card('Male', Icons.male_rounded, 'He / him', 0)),
            const SizedBox(width: 14),
            Expanded(child: card('Female', Icons.female_rounded, 'She / her', 1)),
          ],
        ),
        const SizedBox(height: 14),
        card('Other', Icons.diversity_3_rounded, 'Prefer to self-describe', 2, wide: true),
      ],
    );
  }

  Widget _ageStep() {
    final color = _meta.color;
    final group = _selectedAge < 18
        ? 'Teen'
        : _selectedAge < 30
            ? 'Young adult'
            : _selectedAge < 45
                ? 'Adult'
                : _selectedAge < 60
                    ? 'Prime'
                    : 'Golden years';
    return _MeasureBlock(
      color: color,
      fraction: (_selectedAge - 13) / (80 - 13),
      value: BigValue(text: '$_selectedAge', unit: 'yrs', color: color),
      chips: [_InfoChip(icon: Icons.auto_awesome_rounded, text: group, color: color)],
      ruler: SnapRuler(
        min: 13,
        max: 80,
        step: 1,
        value: _selectedAge.toDouble(),
        majorEvery: 5,
        tickSpacing: 16,
        color: color,
        onChanged: (v) => setState(() => _selectedAge = v.round()),
      ),
      onMinus: () => setState(() => _selectedAge = math.max(13, _selectedAge - 1)),
      onPlus: () => setState(() => _selectedAge = math.min(80, _selectedAge + 1)),
    );
  }

  Widget _currentWeightStep() {
    final color = _meta.color;
    final bmi = _currentWeight / math.pow(_height / 100, 2);
    final bmiLabel = bmi < 18.5
        ? 'Underweight'
        : bmi < 25
            ? 'Healthy'
            : bmi < 30
                ? 'Overweight'
                : 'Obese';
    return _MeasureBlock(
      color: color,
      fraction: (_currentWeight - 30) / 170,
      value: BigValue(text: _fmt(_currentWeight), unit: 'kg', color: color),
      chips: [
        _InfoChip(icon: Icons.swap_horiz_rounded, text: '${(_currentWeight * 2.20462).round()} lb', color: color),
        _InfoChip(icon: Icons.monitor_heart_rounded, text: 'BMI ${bmi.toStringAsFixed(1)} · $bmiLabel', color: color),
      ],
      ruler: SnapRuler(
        min: 30,
        max: 200,
        step: 0.5,
        value: _currentWeight,
        majorEvery: 10,
        tickSpacing: 10,
        color: color,
        onChanged: (v) => setState(() => _currentWeight = v),
      ),
      onMinus: () => setState(() => _currentWeight = math.max(30, _currentWeight - 0.5)),
      onPlus: () => setState(() => _currentWeight = math.min(200, _currentWeight + 0.5)),
    );
  }

  Widget _targetWeightStep() {
    final color = _meta.color;
    final diff = _targetWeight - _currentWeight;
    final weeks = (diff.abs() / 0.5).ceil();
    final verb = diff < 0 ? 'Lose' : 'Gain';
    return _MeasureBlock(
      color: color,
      fraction: (_targetWeight - 30) / 170,
      value: BigValue(text: _fmt(_targetWeight), unit: 'kg', color: color),
      chips: [
        _InfoChip(
          icon: diff == 0 ? Icons.balance_rounded : (diff < 0 ? Icons.trending_down_rounded : Icons.trending_up_rounded),
          text: diff == 0 ? 'Maintain weight' : '$verb ${_fmt(diff.abs())} kg',
          color: color,
        ),
        if (diff != 0)
          _InfoChip(icon: Icons.event_available_rounded, text: '~$weeks weeks at a healthy pace', color: color),
      ],
      ruler: SnapRuler(
        min: 30,
        max: 200,
        step: 0.5,
        value: _targetWeight,
        majorEvery: 10,
        tickSpacing: 10,
        color: color,
        onChanged: (v) => setState(() => _targetWeight = v),
      ),
      onMinus: () => setState(() => _targetWeight = math.max(30, _targetWeight - 0.5)),
      onPlus: () => setState(() => _targetWeight = math.min(200, _targetWeight + 0.5)),
      extra: _WeightCompare(current: _currentWeight, target: _targetWeight, color: color),
    );
  }

  Widget _heightStep() {
    final color = _meta.color;
    final ft = _heightUnit == 'ft';
    return Column(
      children: [
        Reveal(
          delay: const Duration(milliseconds: 60),
          child: _UnitToggle(
            options: const ['cm', 'ft'],
            value: _heightUnit,
            color: color,
            onChanged: (u) => setState(() => _heightUnit = u),
          ),
        ),
        const SizedBox(height: 18),
        Reveal(
          delay: const Duration(milliseconds: 140),
          child: SizedBox(
            height: 220,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _HeightFigure(heightCm: _height, color: color),
                const SizedBox(width: 22),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 60),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          child: BigValue(
                            text: ft ? _feetInches(_height) : _height.round().toString(),
                            unit: ft ? '' : 'cm',
                            color: color,
                            size: 60,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _InfoChip(
                          icon: Icons.swap_vert_rounded,
                          text: ft ? '${_height.round()} cm' : _feetInches(_height),
                          color: color,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Reveal(
          delay: const Duration(milliseconds: 220),
          child: _RulerRow(
            color: color,
            onMinus: () => setState(() => _height = math.max(120, _height - 1)),
            onPlus: () => setState(() => _height = math.min(220, _height + 1)),
            ruler: SnapRuler(
              key: ValueKey(_heightUnit),
              min: 120,
              max: 220,
              step: 1,
              value: _height,
              majorEvery: 10,
              tickSpacing: 12,
              color: color,
              labelFor: ft ? (v) => _feetInches(v).replaceAll(' ', '') : null,
              onChanged: (v) => setState(() => _height = v),
            ),
          ),
        ),
      ],
    );
  }

  Widget _goalsStep() {
    final color = _meta.color;
    const goals = [
      ('Lose Weight', 'Burn fat & tone body', Icons.local_fire_department_rounded, Color(0xFFEF4444)),
      ('Build Muscle', 'Gain strength & mass', Icons.fitness_center_rounded, Color(0xFF7C3AED)),
      ('Keep Fit', 'Boost health & cardio', Icons.favorite_rounded, Color(0xFF0EA5E9)),
      ('Boost Energy', 'All-day endurance', Icons.bolt_rounded, Color(0xFFF59E0B)),
    ];
    return LayoutBuilder(builder: (context, box) {
      final cols = box.maxWidth < 300 ? 1 : 2;
      final w = (box.maxWidth - (cols - 1) * 14) / cols;
      return Wrap(
        spacing: 14,
        runSpacing: 14,
        children: [
          for (var i = 0; i < goals.length; i++)
            SizedBox(
              width: w,
              child: Reveal(
                delay: Duration(milliseconds: 80 + i * 80),
                child: _ChoiceCard(
                  selected: _selectedGoals.contains(goals[i].$1),
                  color: color,
                  accent: goals[i].$4,
                  icon: goals[i].$3,
                  title: goals[i].$1,
                  subtitle: goals[i].$2,
                  onTap: () => setState(() {
                    final g = goals[i].$1;
                    if (_selectedGoals.contains(g)) {
                      if (_selectedGoals.length > 1) _selectedGoals.remove(g);
                    } else {
                      _selectedGoals.add(g);
                    }
                  }),
                ),
              ),
            ),
          SizedBox(
            width: box.maxWidth,
            child: Text(
              '${_selectedGoals.length} selected · pick as many as you like',
              textAlign: TextAlign.center,
              style: onbFont(size: 12.5, color: OnbColors.muted, weight: FontWeight.w600),
            ),
          ),
        ],
      );
    });
  }

  Widget _activityStep() {
    final color = _meta.color;
    const levels = [
      ('Sedentary', 'Desk job / no workout', Icons.weekend_rounded),
      ('Lightly Active', '1–2 light workouts/wk', Icons.directions_walk_rounded),
      ('Moderately Active', '3–5 active workouts/wk', Icons.directions_run_rounded),
      ('Very Active', '6–7 intense sessions/wk', Icons.sports_gymnastics_rounded),
    ];
    return Column(
      children: [
        for (var i = 0; i < levels.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Reveal(
              delay: Duration(milliseconds: 80 + i * 80),
              offset: const Offset(0.15, 0),
              child: _ActivityRow(
                title: levels[i].$1,
                subtitle: levels[i].$2,
                icon: levels[i].$3,
                level: i + 1,
                color: color,
                selected: _selectedActivity == levels[i].$1,
                onTap: () => setState(() => _selectedActivity = levels[i].$1),
              ),
            ),
          ),
      ],
    );
  }
}

// =============================================================================
// Pieces
// =============================================================================

class _Header extends StatelessWidget {
  const _Header({required this.meta, this.compact = false});
  final _StepMeta meta;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 26.0 : 32.0;
    final style = onbFont(size: size, weight: FontWeight.w800, height: 1.12, spacing: -0.8);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Reveal(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              Text('${meta.lead} ', style: style),
              GradientText(meta.accent,
                  style: style, colors: [meta.color, Color.lerp(meta.color, OnbColors.lime, 0.65)!]),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Reveal(
          delay: const Duration(milliseconds: 70),
          child: Text(meta.subtitle, style: onbFont(size: compact ? 13.5 : 15, color: OnbColors.body, height: 1.45)),
        ),
      ],
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep({required this.meta, required this.maxHeight});
  final _StepMeta meta;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final heroH = (maxHeight * 0.42).clamp(180.0, 300.0);
    final tile = (heroH * 0.26).clamp(48.0, 74.0);
    final style = onbFont(size: maxHeight < 560 ? 28 : 34, weight: FontWeight.w800, height: 1.1, spacing: -1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Reveal(
          scale: 0.92,
          duration: const Duration(milliseconds: 700),
          child: SizedBox(
            height: heroH + tile * 0.5,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: tile * 0.45,
                  right: tile * 0.45,
                  top: tile * 0.25,
                  bottom: tile * 0.25,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF14532D), Color(0xFF16A34A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(color: meta.color.withValues(alpha: 0.30), blurRadius: 40, offset: const Offset(0, 18)),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset('assets/images/questionnaire_hero.jpg', fit: BoxFit.cover),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0x00000000), Color(0xAA000000)],
                              stops: [0.45, 1],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 18,
                          bottom: 16,
                          right: 18,
                          child: Row(
                            children: [
                              const _PulseDot(color: OnbColors.lime),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text('Personal plan in under a minute',
                                    style: onbFont(size: 13, weight: FontWeight.w700, color: Colors.white)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(left: 0, top: 0, child: FloatingTile(asset: _tiles[0], size: tile, phase: 0)),
                Positioned(right: 0, top: heroH * 0.18, child: FloatingTile(asset: _tiles[1], size: tile * 0.9, phase: 1.6)),
                Positioned(left: tile * 0.1, bottom: heroH * 0.22, child: FloatingTile(asset: _tiles[3], size: tile * 0.78, phase: 3.1)),
                Positioned(right: tile * 0.2, bottom: 0, child: FloatingTile(asset: _tiles[4], size: tile * 0.84, phase: 4.4)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        Reveal(
          delay: const Duration(milliseconds: 160),
          child: Wrap(
            children: [
              Text('${meta.lead} ', style: style),
              GradientText(meta.accent, style: style, colors: [meta.color, OnbColors.lime]),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Reveal(
          delay: const Duration(milliseconds: 230),
          child: Text(meta.subtitle, style: onbFont(size: 15, color: OnbColors.body, height: 1.45)),
        ),
        const SizedBox(height: 18),
        for (final (i, f) in const [
          (Icons.tune_rounded, 'Built around you', 'Workouts sized to your level'),
          (Icons.restaurant_rounded, 'Smart nutrition', 'Calories and macros that fit your goal'),
          (Icons.insights_rounded, 'Track progress', 'See every win, week by week'),
        ].indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Reveal(
              delay: Duration(milliseconds: 300 + i * 90),
              offset: const Offset(0.12, 0),
              child: _FeatureRow(icon: f.$1, title: f.$2, subtitle: f.$3, color: meta.color),
            ),
          ),
      ],
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.icon, required this.title, required this.subtitle, required this.color});
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: OnbColors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(13)),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: onbFont(size: 14.5, weight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(subtitle, style: onbFont(size: 12.5, color: OnbColors.body)),
              ],
            ),
          ),
          Icon(Icons.check_circle_rounded, color: color.withValues(alpha: 0.85), size: 20),
        ],
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot({required this.color});
  final Color color;

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 16,
      height: 16,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 8 + 8 * _c.value,
              height: 8 + 8 * _c.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withValues(alpha: 0.5 * (1 - _c.value)),
              ),
            ),
            Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color)),
          ],
        ),
      ),
    );
  }
}

/// Selectable card used for gender and goals.
class _ChoiceCard extends StatefulWidget {
  const _ChoiceCard({
    required this.selected,
    required this.color,
    required this.onTap,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.accent,
    this.horizontal = false,
  });

  final bool selected;
  final Color color;
  final Color? accent;
  final VoidCallback onTap;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool horizontal;

  @override
  State<_ChoiceCard> createState() => _ChoiceCardState();
}

class _ChoiceCardState extends State<_ChoiceCard> {
  bool _hover = false;
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.color;
    final accent = widget.accent ?? c;
    final sel = widget.selected;
    final iconBubble = AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutBack,
      width: widget.horizontal ? 48 : 60,
      height: widget.horizontal ? 48 : 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: sel ? LinearGradient(colors: [accent, Color.lerp(accent, Colors.black, 0.2)!]) : null,
        color: sel ? null : accent.withValues(alpha: 0.1),
        boxShadow: sel ? [BoxShadow(color: accent.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6))] : null,
      ),
      child: AnimatedRotation(
        turns: sel ? 0 : -0.05,
        duration: const Duration(milliseconds: 400),
        child: Icon(widget.icon, color: sel ? Colors.white : accent, size: widget.horizontal ? 24 : 30),
      ),
    );
    final check = AnimatedScale(
      scale: sel ? 1 : 0.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
        child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
      ),
    );
    final texts = Column(
      crossAxisAlignment: widget.horizontal ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.title, style: onbFont(size: 16, weight: FontWeight.w800), textAlign: TextAlign.center),
        const SizedBox(height: 3),
        Text(widget.subtitle,
            style: onbFont(size: 12.5, color: OnbColors.body),
            textAlign: widget.horizontal ? TextAlign.start : TextAlign.center),
      ],
    );
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onTap();
        },
        child: Semantics(
          button: true,
          selected: sel,
          label: widget.title,
          child: AnimatedScale(
            scale: _down ? 0.96 : (_hover ? 1.02 : 1),
            duration: const Duration(milliseconds: 160),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              padding: widget.horizontal ? const EdgeInsets.all(14) : const EdgeInsets.fromLTRB(14, 20, 14, 18),
              decoration: BoxDecoration(
                color: sel ? Color.lerp(Colors.white, c, 0.07) : Colors.white.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: sel ? c : OnbColors.line, width: sel ? 2 : 1.2),
                boxShadow: [
                  BoxShadow(
                    color: sel ? c.withValues(alpha: 0.18) : Colors.black.withValues(alpha: 0.04),
                    blurRadius: sel ? 24 : 12,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: widget.horizontal
                  ? Row(children: [iconBubble, const SizedBox(width: 14), Expanded(child: texts), check])
                  : Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Center(child: iconBubble),
                            const SizedBox(height: 12),
                            SizedBox(width: double.infinity, child: texts),
                          ],
                        ),
                        Positioned(right: -4, top: -8, child: check),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Value ring + chips + ruler with -/+ steppers. Used for age and weights.
class _MeasureBlock extends StatelessWidget {
  const _MeasureBlock({
    required this.color,
    required this.fraction,
    required this.value,
    required this.chips,
    required this.ruler,
    required this.onMinus,
    required this.onPlus,
    this.extra,
  });

  final Color color;
  final double fraction;
  final Widget value;
  final List<Widget> chips;
  final Widget ruler;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Reveal(
          scale: 0.85,
          duration: const Duration(milliseconds: 650),
          child: _ValueRing(fraction: fraction, color: color, child: FittedBox(child: value)),
        ),
        const SizedBox(height: 16),
        Reveal(
          delay: const Duration(milliseconds: 120),
          child: Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: chips),
        ),
        if (extra != null) ...[
          const SizedBox(height: 16),
          Reveal(delay: const Duration(milliseconds: 170), child: extra!),
        ],
        const SizedBox(height: 18),
        Reveal(
          delay: const Duration(milliseconds: 220),
          child: _RulerRow(color: color, ruler: ruler, onMinus: onMinus, onPlus: onPlus),
        ),
      ],
    );
  }
}

class _RulerRow extends StatelessWidget {
  const _RulerRow({required this.color, required this.ruler, required this.onMinus, required this.onPlus});
  final Color color;
  final Widget ruler;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: OnbColors.line),
      ),
      child: Row(
        children: [
          RoundIconButton(icon: Icons.remove_rounded, onTap: onMinus, size: 40, color: color),
          Expanded(child: ruler),
          RoundIconButton(icon: Icons.add_rounded, onTap: onPlus, size: 40, color: color),
        ],
      ),
    );
  }
}

class _ValueRing extends StatelessWidget {
  const _ValueRing({required this.fraction, required this.color, required this.child});
  final double fraction;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: fraction.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (context, f, inner) => SizedBox(
        width: 210,
        height: 210,
        child: CustomPaint(painter: _RingPainter(f, color), child: inner),
      ),
      child: Padding(padding: const EdgeInsets.all(40), child: Center(child: child)),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.f, this.color);
  final double f;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 10;
    const start = math.pi * 0.75;
    const sweep = math.pi * 1.5;
    final rect = Rect.fromCircle(center: c, radius: r);

    canvas.drawCircle(c, r - 14, Paint()..color = Colors.white.withValues(alpha: 0.9));
    canvas.drawCircle(
      c,
      r - 14,
      Paint()
        ..color = color.withValues(alpha: 0.10)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    final track = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, start, sweep, false, track);
    final prog = Paint()
      ..shader = SweepGradient(
        startAngle: start,
        endAngle: start + sweep,
        colors: [Color.lerp(color, OnbColors.lime, 0.6)!, color],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, start, math.max(0.001, sweep * f), false, prog);

    final a = start + sweep * f;
    final knob = c + Offset(math.cos(a), math.sin(a)) * r;
    canvas.drawCircle(knob, 11, Paint()..color = color.withValues(alpha: 0.25));
    canvas.drawCircle(knob, 8, Paint()..color = Colors.white);
    canvas.drawCircle(knob, 5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.f != f || old.color != color;
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.text, required this.color});
  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(text,
                overflow: TextOverflow.ellipsis,
                style: onbFont(size: 12.5, weight: FontWeight.w700, color: OnbColors.ink)),
          ),
        ],
      ),
    );
  }
}

class _WeightCompare extends StatelessWidget {
  const _WeightCompare({required this.current, required this.target, required this.color});
  final double current;
  final double target;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final maxV = math.max(current, target);
    Widget bar(String label, double v, Color c) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: onbFont(size: 12, color: OnbColors.muted, weight: FontWeight.w600)),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  height: 10,
                  color: OnbColors.line,
                  alignment: Alignment.centerLeft,
                  child: AnimatedFractionallySizedBox(
                    duration: const Duration(milliseconds: 420),
                    curve: Curves.easeOutCubic,
                    widthFactor: (v / maxV).clamp(0.05, 1.0),
                    child: Container(
                        decoration: BoxDecoration(gradient: LinearGradient(colors: [c.withValues(alpha: 0.6), c]))),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text('${_fmt(v)} kg', style: onbFont(size: 13, weight: FontWeight.w800)),
            ],
          ),
        );
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: OnbColors.line),
      ),
      child: Row(
        children: [
          bar('Now', current, OnbColors.muted),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Icon(Icons.arrow_forward_rounded, color: OnbColors.muted, size: 18),
          ),
          bar('Goal', target, color),
        ],
      ),
    );
  }
}

class _UnitToggle extends StatelessWidget {
  const _UnitToggle({required this.options, required this.value, required this.color, required this.onChanged});
  final List<String> options;
  final String value;
  final Color color;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final idx = options.indexOf(value).clamp(0, options.length - 1);
    const w = 76.0;
    return Center(
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: OnbColors.line),
        ),
        child: SizedBox(
          width: w * options.length,
          height: 38,
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                left: idx * w,
                top: 0,
                bottom: 0,
                width: w,
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                ),
              ),
              Row(
                children: [
                  for (final o in options)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onChanged(o);
                      },
                      child: SizedBox(
                        width: w,
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: onbFont(
                              size: 14,
                              weight: FontWeight.w700,
                              color: o == value ? Colors.white : OnbColors.body,
                            ),
                            child: Text(o.toUpperCase()),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A person silhouette that grows with the chosen height, next to a scale.
class _HeightFigure extends StatelessWidget {
  const _HeightFigure({required this.heightCm, required this.color});
  final double heightCm;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = ((heightCm - 120) / 100).clamp(0.0, 1.0);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: t),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutBack,
      builder: (context, v, _) {
        final h = 120 + 90 * v;
        return SizedBox(
          width: 110,
          height: 220,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Positioned.fill(child: CustomPaint(painter: _ScalePainter(color))),
              Positioned(
                bottom: h - 2,
                left: 0,
                right: 0,
                child: Container(height: 2, color: color.withValues(alpha: 0.6)),
              ),
              Positioned(
                bottom: 0,
                child: Container(
                  width: 70,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.08),
                    borderRadius: const BorderRadius.all(Radius.elliptical(35, 5)),
                  ),
                ),
              ),
              Positioned(
                bottom: 2,
                child: ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (r) => LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color.lerp(color, OnbColors.lime, 0.5)!, color],
                  ).createShader(r),
                  child: SizedBox(
                    height: h,
                    child: const FittedBox(
                      fit: BoxFit.fitHeight,
                      child: Icon(Icons.accessibility_new_rounded, size: 100),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ScalePainter extends CustomPainter {
  _ScalePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..strokeWidth = 1.5;
    for (var i = 0; i <= 20; i++) {
      final y = size.height - 2 - i * (size.height - 10) / 20;
      final w = i % 5 == 0 ? 12.0 : 6.0;
      canvas.drawLine(Offset(0, y), Offset(w, y), p);
    }
  }

  @override
  bool shouldRepaint(_ScalePainter old) => old.color != color;
}

class _ActivityRow extends StatefulWidget {
  const _ActivityRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.level,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final int level;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_ActivityRow> createState() => _ActivityRowState();
}

class _ActivityRowState extends State<_ActivityRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.color;
    final sel = widget.selected;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onTap();
        },
        child: Semantics(
          button: true,
          selected: sel,
          label: widget.title,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(sel ? 6 : (_hover ? 3 : 0), 0, 0),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: sel ? Color.lerp(Colors.white, c, 0.07) : Colors.white.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: sel ? c : OnbColors.line, width: sel ? 2 : 1.2),
              boxShadow: [
                BoxShadow(
                  color: sel ? c.withValues(alpha: 0.16) : Colors.black.withValues(alpha: 0.03),
                  blurRadius: sel ? 22 : 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: sel ? c : c.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(widget.icon, color: sel ? Colors.white : c, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.title, style: onbFont(size: 15, weight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(widget.subtitle, style: onbFont(size: 12.5, color: OnbColors.body)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 28,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(4, (i) {
                      final on = i < widget.level;
                      return AnimatedContainer(
                        duration: Duration(milliseconds: 250 + i * 70),
                        curve: Curves.easeOutBack,
                        margin: const EdgeInsets.only(left: 3),
                        width: 5,
                        height: sel ? 8.0 + i * 6 : 6.0 + i * 4,
                        decoration: BoxDecoration(
                          color: on ? (sel ? c : c.withValues(alpha: 0.45)) : OnbColors.line,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Desktop-only left panel: floating objects and a live summary of answers.
class _SidePanel extends StatelessWidget {
  const _SidePanel({required this.state});
  final _QuestionnaireScreenState state;

  @override
  Widget build(BuildContext context) {
    final s = state;
    final color = s._meta.color;
    final step = s._currentStep;
    final rows = <(IconData, String, String, int)>[
      (Icons.person_rounded, 'Gender', s._selectedGender, 1),
      (Icons.cake_rounded, 'Age', '${s._selectedAge} years', 2),
      (Icons.monitor_weight_rounded, 'Weight', '${_fmt(s._currentWeight)} kg', 3),
      (Icons.flag_rounded, 'Target', '${_fmt(s._targetWeight)} kg', 4),
      (Icons.height_rounded, 'Height', s._heightUnit == 'ft' ? _feetInches(s._height) : '${s._height.round()} cm', 5),
      (Icons.emoji_events_rounded, 'Goals', s._selectedGoals.join(', '), 6),
      (Icons.directions_run_rounded, 'Activity', s._selectedActivity, 7),
    ];
    return LayoutBuilder(builder: (context, box) {
      final tile = (box.maxWidth * 0.14).clamp(56.0, 92.0);
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(left: box.maxWidth * 0.02, top: box.maxHeight * 0.04, child: FloatingTile(asset: _tiles[0], size: tile, phase: 0)),
          Positioned(right: box.maxWidth * 0.06, top: box.maxHeight * 0.02, child: FloatingTile(asset: _tiles[1], size: tile * 0.8, phase: 1.2)),
          Positioned(right: 0, top: box.maxHeight * 0.42, child: FloatingTile(asset: _tiles[2], size: tile * 0.9, phase: 2.4)),
          Positioned(left: box.maxWidth * 0.05, bottom: box.maxHeight * 0.04, child: FloatingTile(asset: _tiles[5], size: tile * 0.85, phase: 3.6)),
          Positioned(right: box.maxWidth * 0.12, bottom: 0, child: FloatingTile(asset: _tiles[4], size: tile * 0.7, phase: 4.8)),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset('assets/images/app_logo.png', width: 40, height: 40, fit: BoxFit.cover),
                        ),
                        const SizedBox(width: 10),
                        Text('NeuroFit', style: onbFont(size: 20, weight: FontWeight.w800)),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Text('Your profile', style: onbFont(size: 30, weight: FontWeight.w800, spacing: -0.8)),
                    const SizedBox(height: 6),
                    Text('Updates live as you answer.', style: onbFont(size: 14.5, color: OnbColors.body)),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white),
                      ),
                      child: Column(
                        children: [
                          for (final r in rows)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 350),
                              margin: const EdgeInsets.symmetric(vertical: 2),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: r.$4 == step ? color.withValues(alpha: 0.10) : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 350),
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: r.$4 < step ? OnbColors.green : (r.$4 == step ? color : OnbColors.line),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(r.$4 < step ? Icons.check_rounded : r.$1,
                                        size: 17, color: r.$4 <= step ? Colors.white : OnbColors.muted),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(r.$2, style: onbFont(size: 13.5, color: OnbColors.body, weight: FontWeight.w600)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: AnimatedOpacity(
                                      duration: const Duration(milliseconds: 300),
                                      opacity: r.$4 <= step ? 1 : 0.35,
                                      child: Text(
                                        r.$4 <= step ? r.$3 : '—',
                                        textAlign: TextAlign.right,
                                        overflow: TextOverflow.ellipsis,
                                        style: onbFont(size: 13.5, weight: FontWeight.w800),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}
