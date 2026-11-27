import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../screens/ai_coach_screen.dart';
import '../screens/steps_screen.dart';
import '../screens/date_nutrition_detail_screen.dart';
import 'live_page_route.dart';

class NeuroDynamicIsland extends StatefulWidget {
  final Color? themeColor;
  final bool initiallyExpanded;
  final VoidCallback? onExpandChanged;

  const NeuroDynamicIsland({
    super.key,
    this.themeColor,
    this.initiallyExpanded = false,
    this.onExpandChanged,
  });

  @override
  State<NeuroDynamicIsland> createState() => _NeuroDynamicIslandState();
}

class _NeuroDynamicIslandState extends State<NeuroDynamicIsland>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animController;
  late Animation<double> _expandAnimation;

  // Metric values
  final int _steps = 8542;
  final int _stepGoal = 10000;
  final int _calories = 320;
  final int _calorieGoal = 600;
  final int _waterMl = 1800;
  final int _waterGoalMl = 2500;
  final int _activeMinutes = 42;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    if (_isExpanded) {
      _animController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animController.forward();
      } else {
        _animController.reverse();
      }
    });
    widget.onExpandChanged?.call();
  }

  // Dynamic Theme Colors based on Selected Tab Color
  Color get _accent => widget.themeColor ?? const Color(0xFF16A34A);

  Color get _brightAccent {
    final hsl = HSLColor.fromColor(_accent);
    return hsl.withLightness((hsl.lightness + 0.18).clamp(0.0, 0.95)).toColor();
  }

  Color get _deepBg1 {
    final hsl = HSLColor.fromColor(_accent);
    return hsl.withSaturation(0.65).withLightness(0.09).toColor();
  }

  Color get _deepBg2 {
    final hsl = HSLColor.fromColor(_accent);
    return hsl.withSaturation(0.40).withLightness(0.04).toColor();
  }

  Color get _cardBg {
    final hsl = HSLColor.fromColor(_accent);
    return hsl.withSaturation(0.45).withLightness(0.07).toColor();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _expandAnimation,
      builder: (context, child) {
        final progress = _expandAnimation.value;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(lerpDouble(24, 28, progress)!),
            boxShadow: [
              // Ambient outer glow adopting the selected tab color
              BoxShadow(
                color: _accent.withValues(alpha: lerpDouble(0.32, 0.48, progress)!),
                blurRadius: lerpDouble(14, 28, progress)!,
                spreadRadius: lerpDouble(1, 3, progress)!,
                offset: const Offset(0, 3),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.75),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(lerpDouble(24, 28, progress)!),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(lerpDouble(24, 28, progress)!),
                  border: Border.all(
                    color: Color.lerp(
                      _accent.withValues(alpha: 0.55),
                      _brightAccent.withValues(alpha: 0.85),
                      progress,
                    )!,
                    width: lerpDouble(1.2, 1.4, progress)!,
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _deepBg1.withValues(alpha: 0.96),
                      _deepBg2.withValues(alpha: 0.98),
                    ],
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _toggleExpand,
                    splashColor: _accent.withValues(alpha: 0.12),
                    highlightColor: Colors.transparent,
                    borderRadius: BorderRadius.circular(lerpDouble(24, 28, progress)!),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: lerpDouble(10, 14, progress)!,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 1. Full-Width Top Header Row
                          _buildFullWidthHeader(progress),

                          // 2. Expanded Content Section
                          if (progress > 0.01) ...[
                            SizedBox(height: lerpDouble(0, 14, progress)!),
                            Opacity(
                              opacity: progress.clamp(0.0, 1.0),
                              child: Transform.scale(
                                scale: lerpDouble(0.95, 1.0, progress)!,
                                alignment: Alignment.topCenter,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Horizontal Card Carousel (No Overflows!)
                                    _buildMetricsCarousel(),

                                    const SizedBox(height: 14),

                                    // Scrollable Quick Action Bar
                                    _buildQuickActionsBar(),

                                    const SizedBox(height: 10),

                                    // Glowing Bottom Collapse Indicator
                                    Center(
                                      child: Container(
                                        width: 44,
                                        height: 4.5,
                                        decoration: BoxDecoration(
                                          color: _brightAccent,
                                          borderRadius: BorderRadius.circular(3),
                                          boxShadow: [
                                            BoxShadow(
                                              color: _accent.withValues(alpha: 0.8),
                                              blurRadius: 8,
                                              spreadRadius: 1,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------
  // FULL-WIDTH TOP HEADER ROW (STEPS | CALORIES | RANK)
  // -------------------------------------------------------------
  Widget _buildFullWidthHeader(double progress) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 1. Steps Badge (Theme Color)
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.directions_run_rounded,
                  color: _brightAccent,
                  size: 15,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '8,542',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      'Steps',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF94A3B8),
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Divider
        Container(
          width: 1,
          height: 20,
          color: Colors.white.withValues(alpha: 0.15),
        ),

        // 2. Calories Badge
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF97316).withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  color: Color(0xFFFB923C),
                  size: 15,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '320',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      'kcal',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF94A3B8),
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Divider
        Container(
          width: 1,
          height: 20,
          color: Colors.white.withValues(alpha: 0.15),
        ),

        // 3. Trophy Rank Badge
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.emoji_events_rounded,
                color: Color(0xFFFBBF24),
                size: 16,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '2nd',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      'Today',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF94A3B8),
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Chevron Icon
        AnimatedRotation(
          turns: progress * 0.5,
          duration: const Duration(milliseconds: 280),
          child: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.white.withValues(alpha: 0.75),
            size: 19,
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // HORIZONTAL METRICS CAROUSEL (WORKOUT, STEPS, CALORIES, HYDRATION)
  // -------------------------------------------------------------
  Widget _buildMetricsCarousel() {
    final cards = [
      _buildWorkoutCard(),
      _buildStepsCard(),
      _buildCaloriesCard(),
      _buildHydrationCard(),
    ];

    return SizedBox(
      height: 168,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) => cards[index],
      ),
    );
  }

  // 1. WORKOUT CARD (42 min + 7-Day Bar Chart)
  Widget _buildWorkoutCard() {
    final barHeights = [0.35, 0.65, 0.45, 0.70, 0.40, 0.85, 1.0];
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return _buildCardWrapper(
      width: 148,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            icon: Icons.fitness_center_rounded,
            iconColor: _brightAccent,
            title: 'Workout',
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$_activeMinutes',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'min',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          Text(
            'Active today',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),
          const Spacer(),
          // Weekly Bar Chart with theme accent color
          SizedBox(
            height: 48,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final h = barHeights[i];
                final isToday = i == 6;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 6,
                      height: 32 * h,
                      decoration: BoxDecoration(
                        color: isToday
                            ? _brightAccent
                            : _accent.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: isToday
                            ? [
                                BoxShadow(
                                  color: _accent,
                                  blurRadius: 6,
                                ),
                              ]
                            : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      days[i],
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: isToday ? Colors.white : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // 2. STEPS CARD (Circular Gauge with Theme Accent)
  Widget _buildStepsCard() {
    final ratio = (_steps / _stepGoal).clamp(0.0, 1.0);
    final percent = (ratio * 100).toInt();

    return _buildCardWrapper(
      width: 148,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StepsScreen()),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            icon: Icons.directions_walk_rounded,
            iconColor: _brightAccent,
            title: 'Steps',
          ),
          const Spacer(),
          Center(
            child: SizedBox(
              width: 68,
              height: 68,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(68, 68),
                    painter: _CircularGaugePainter(
                      progress: ratio,
                      trackColor: Colors.white.withValues(alpha: 0.1),
                      progressColor: _brightAccent,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.directions_run_rounded,
                        color: _brightAccent,
                        size: 13,
                      ),
                      Text(
                        '8,542',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '/ 10,000',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 7.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          Center(
            child: Text(
              '$percent% complete',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: _brightAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 3. CALORIES CARD (Circular Orange Gauge)
  Widget _buildCaloriesCard() {
    final ratio = (_calories / _calorieGoal).clamp(0.0, 1.0);
    final percent = (ratio * 100).toInt();

    return _buildCardWrapper(
      width: 148,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            icon: Icons.local_fire_department_rounded,
            iconColor: const Color(0xFFFB923C),
            title: 'Calories',
          ),
          const Spacer(),
          Center(
            child: SizedBox(
              width: 68,
              height: 68,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(68, 68),
                    painter: _CircularGaugePainter(
                      progress: ratio,
                      trackColor: Colors.white.withValues(alpha: 0.1),
                      progressColor: const Color(0xFFF97316),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_fire_department_rounded,
                        color: Color(0xFFFB923C),
                        size: 13,
                      ),
                      Text(
                        '$_calories',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '/ $_calorieGoal kcal',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 7.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          Center(
            child: Text(
              '$percent% complete',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFFB923C),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 4. HYDRATION CARD (Water Bottle Fill Graphic)
  Widget _buildHydrationCard() {
    final ratio = (_waterMl / _waterGoalMl).clamp(0.0, 1.0);
    final percent = (ratio * 100).toInt();

    return _buildCardWrapper(
      width: 148,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            icon: Icons.water_drop_rounded,
            iconColor: const Color(0xFF38BDF8),
            title: 'Hydration',
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Bottle graphic with liquid fill level
              Container(
                width: 24,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.6),
                    width: 1.5,
                  ),
                  color: Colors.black.withValues(alpha: 0.5),
                ),
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Container(
                      height: 48 * ratio,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(4)),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [_brightAccent, _accent],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _accent.withValues(alpha: 0.6),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '1,800',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '/ 2,500 ml',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            '$percent% complete',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF38BDF8),
            ),
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 4,
              backgroundColor: Colors.white.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(_brightAccent),
            ),
          ),
        ],
      ),
    );
  }

  // Common Card Wrapper with themed glassmorphic background & glow
  Widget _buildCardWrapper({
    required Widget child,
    double? width,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap?.call();
      },
      child: Container(
        width: width,
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: _cardBg.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _accent.withValues(alpha: 0.32),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      ),
    );
  }

  Widget _buildCardHeader({
    required IconData icon,
    required Color iconColor,
    required String title,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 14),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
        Icon(
          Icons.arrow_forward_ios_rounded,
          color: Colors.white.withValues(alpha: 0.4),
          size: 9,
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // SCROLLABLE QUICK ACTIONS BAR (NO OVERFLOWS!)
  // -------------------------------------------------------------
  Widget _buildQuickActionsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _deepBg2.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _accent.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            // 1. Trainer
            _buildActionItem(
              icon: Icons.person_rounded,
              iconBgColor: _accent,
              label: 'Trainer',
              sub: 'Get guidance',
              onTap: () {
                Navigator.push(context, trainersRoute());
              },
            ),
            const SizedBox(width: 12),
            // 2. Active Workouts
            _buildActionItem(
              icon: Icons.fitness_center_rounded,
              iconBgColor: const Color(0xFF0284C7),
              label: 'Active Workouts',
              sub: 'Continue',
              onTap: () {},
            ),
            const SizedBox(width: 12),
            // 3. Add Nutrition
            _buildActionItem(
              icon: Icons.eco_rounded,
              iconBgColor: const Color(0xFF16A34A),
              label: 'Add Nutrition',
              sub: 'Log meal',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DateNutritionDetailScreen(
                      initialDate: DateTime.now(),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            // 4. Play Music
            _buildActionItem(
              icon: Icons.play_arrow_rounded,
              iconBgColor: const Color(0xFFE11D48),
              label: 'Play',
              sub: 'Music & focus',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🎵 Workout Beats Radio Playing...'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            // 5. AI Coach
            _buildActionItem(
              icon: Icons.auto_awesome_rounded,
              iconBgColor: const Color(0xFF7C3AED),
              label: 'AI Coach',
              sub: 'Ask anything',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AiCoachScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required Color iconBgColor,
    required String label,
    required String sub,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: iconBgColor.withValues(alpha: 0.45),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                Text(
                  sub,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// CUSTOM CIRCULAR PROGRESS GAUGE PAINTER
// -------------------------------------------------------------
class _CircularGaugePainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;

  _CircularGaugePainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 8) / 2;
    const strokeWidth = 5.0;

    // Track Paint
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Progress Paint
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * 3.141592653589793 * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.141592653589793 / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularGaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.trackColor != trackColor;
  }
}
