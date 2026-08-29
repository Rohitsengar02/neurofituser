import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/staggered_slide_fade.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> with TickerProviderStateMixin {
  int _badgeIconIndex = 0;
  Timer? _badgeIconTimer;
  int _selectedCategoryIndex = 0;

  final List<IconData> _badgeIcons = [
    Icons.card_giftcard_rounded,
    Icons.emoji_events_rounded,
    Icons.military_tech_rounded,
    Icons.stars_rounded,
  ];

  final List<String> _categories = [
    'All',
    'Activity',
    'Workouts',
    'Consistency',
    'Special',
  ];

  final List<Map<String, dynamic>> _myBadges = [
    {
      'title': 'First Step',
      'subtitle': '10 Steps',
      'icon': Icons.directions_run_rounded,
      'color': const Color(0xFF16A34A),
      'bg': const Color(0xFFDCFCE7),
    },
    {
      'title': 'Consistency',
      'subtitle': '7 Day Streak',
      'icon': Icons.local_fire_department_rounded,
      'color': const Color(0xFF2563EB),
      'bg': const Color(0xFFDBEAFE),
    },
    {
      'title': 'Workout Pro',
      'subtitle': '25 Workouts',
      'icon': Icons.fitness_center_rounded,
      'color': const Color(0xFF9333EA),
      'bg': const Color(0xFFF3E8FF),
    },
    {
      'title': 'Calorie Crusher',
      'subtitle': '10K Calories',
      'icon': Icons.whatshot_rounded,
      'color': const Color(0xFFD97706),
      'bg': const Color(0xFFFEF3C7),
    },
    {
      'title': 'Early Bird',
      'subtitle': '5 AM Workout',
      'icon': Icons.star_rounded,
      'color': const Color(0xFF4F46E5),
      'bg': const Color(0xFFEEF2FF),
    },
  ];

  final List<Map<String, dynamic>> _detailedBadges = [
    {
      'title': 'Marathoner',
      'desc': 'Walk 42 km',
      'current': 32,
      'total': 42,
      'unit': '',
      'badgeText': '42K',
      'icon': Icons.terrain_rounded,
      'color': const Color(0xFF16A34A),
    },
    {
      'title': 'Step Master',
      'desc': 'Take 100,000 steps',
      'current': 68,
      'total': 100,
      'unit': 'K',
      'icon': Icons.directions_walk_rounded,
      'color': const Color(0xFF0D9488),
    },
    {
      'title': 'Streak Legend',
      'desc': 'Maintain 30 day streak',
      'current': 12,
      'total': 30,
      'unit': '',
      'icon': Icons.local_fire_department_rounded,
      'color': const Color(0xFFEA580C),
    },
    {
      'title': 'Iron Will',
      'desc': 'Complete 50 workouts',
      'current': 32,
      'total': 50,
      'unit': '',
      'icon': Icons.shield_rounded,
      'color': const Color(0xFF7C3AED),
    },
    {
      'title': 'Muscle Builder',
      'desc': 'Strength 25 workouts',
      'current': 12,
      'total': 25,
      'unit': '',
      'icon': Icons.sports_gymnastics_rounded,
      'color': const Color(0xFF6366F1),
    },
    {
      'title': 'Calorie King',
      'desc': 'Burn 50,000 calories',
      'current': 21,
      'total': 50,
      'unit': 'K',
      'icon': Icons.workspace_premium_rounded,
      'color': const Color(0xFFD97706),
    },
    {
      'title': 'Hydration Hero',
      'desc': 'Drink water 100 days',
      'current': 64,
      'total': 100,
      'unit': '',
      'icon': Icons.water_drop_rounded,
      'color': const Color(0xFF0284C7),
    },
    {
      'title': 'Yoga Master',
      'desc': 'Complete 15 yoga sessions',
      'current': 7,
      'total': 15,
      'unit': '',
      'icon': Icons.self_improvement_rounded,
      'color': const Color(0xFFDB2777),
    },
  ];

  @override
  void initState() {
    super.initState();
    _badgeIconTimer = Timer.periodic(const Duration(milliseconds: 2200), (timer) {
      if (mounted) {
        setState(() {
          _badgeIconIndex = (_badgeIconIndex + 1) % _badgeIcons.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _badgeIconTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFD),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // 1. Header
              StaggeredSlideFade(
                index: 0,
                child: _buildHeader(),
              ),

              const SizedBox(height: 18),

              // 2. Hero Points & 3D Trophy Card
              StaggeredSlideFade(
                index: 1,
                child: _buildPointsHeroCard(),
              ),

              const SizedBox(height: 16),

              // 3. Next Reward Level Progress Card
              StaggeredSlideFade(
                index: 2,
                child: _buildNextRewardCard(),
              ),

              const SizedBox(height: 24),

              // 4. My Badges
              StaggeredSlideFade(
                index: 3,
                child: _buildMyBadgesSection(),
              ),

              const SizedBox(height: 24),

              // 5. Badge Categories & Detailed Cards Grid
              StaggeredSlideFade(
                index: 4,
                child: _buildBadgeCategoriesAndGrid(),
              ),

              const SizedBox(height: 24),

              // 6. Redeem Your Points Card
              StaggeredSlideFade(
                index: 5,
                child: _buildRedeemPointsCard(),
              ),

              const SizedBox(height: 24),

              // 7. Daily Streak Tracker
              StaggeredSlideFade(
                index: 6,
                child: _buildDailyStreakSection(),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // 1. TOP HEADER WITH BACK BUTTON & ANIMATED BADGE
  // -------------------------------------------------------------
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Back Button
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
            child: Container(
              width: 38,
              height: 38,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Color(0xFF0F172A),
                size: 16,
              ),
            ),
          ),

          // Title & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Rewards',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0F172A),
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildAnimatedHeaderBadge(),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Stay active. Earn rewards. Be your best. 💚',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Points History Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.access_time_rounded, size: 13, color: Color(0xFF0F172A)),
                const SizedBox(width: 4),
                Text(
                  'Points History',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedHeaderBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A), Color(0xFFDCFCE7)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (child, animation) {
          return ScaleTransition(
            scale: animation,
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        child: Icon(
          _badgeIcons[_badgeIconIndex],
          key: ValueKey<int>(_badgeIconIndex),
          color: const Color(0xFFD97706),
          size: 16,
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // 2. HERO POINTS & 3D TROPHY CARD
  // -------------------------------------------------------------
  Widget _buildPointsHeroCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF0C1017),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Gold sparkles gradient background on right
            Positioned(
              right: -10,
              top: 0,
              bottom: 0,
              width: 140,
              child: Image.asset(
                'assets/images/rewards_gold_trophy_3d.jpg',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.emoji_events_rounded,
                  size: 90,
                  color: Color(0xFFF59E0B),
                ),
              ),
            ),

            // Content Left
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Points',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '12,450',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF22C55E),
                        letterSpacing: -1.0,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'XP',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF22C55E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "Keep going! You're doing great 🎉",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 16),

                // 3 Stat Pills (Streak, This Week, Weekly Goal)
                Row(
                  children: [
                    _buildTrophyStatPill(
                      icon: Icons.local_fire_department_rounded,
                      value: '12',
                      label: 'Day Streak',
                      color: const Color(0xFFF97316),
                    ),
                    const SizedBox(width: 8),
                    _buildTrophyStatPill(
                      icon: Icons.star_rounded,
                      value: '2,450',
                      label: 'This Week',
                      color: const Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 8),
                    _buildTrophyStatPill(
                      icon: Icons.track_changes_rounded,
                      value: '8/10',
                      label: 'Weekly Goal',
                      color: const Color(0xFFEC4899),
                    ),
                  ],
                ),
              ],
            ),

            // Circular 80% completion badge over trophy
            Positioned(
              right: 10,
              bottom: 10,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF22C55E), width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  '80%',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrophyStatPill({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 12),
              const SizedBox(width: 3),
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 8.5,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 3. NEXT REWARD LEVEL PROGRESS CARD
  // -------------------------------------------------------------
  Widget _buildNextRewardCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFDCFCE7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shield_rounded, color: Color(0xFF16A34A), size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Next Reward',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                      Text(
                        '1,550 XP to go',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '14,000 XP for Platinum Badge',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: const LinearProgressIndicator(
                      value: 0.88,
                      minHeight: 5,
                      backgroundColor: Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF22C55E)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.stars_rounded, color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // 4. MY BADGES SECTION
  // -------------------------------------------------------------
  Widget _buildMyBadgesSection() {
    return Column(
      children: [
        _buildSectionHeader('My Badges', onSeeAll: () {}),
        const SizedBox(height: 14),
        SizedBox(
          height: 98,
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _myBadges.length,
            itemBuilder: (context, index) {
              final badge = _myBadges[index];
              return Container(
                width: 72,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: badge['color'] as Color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (badge['color'] as Color).withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(badge['icon'] as IconData, color: Colors.white, size: 24),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      badge['title'] as String,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      badge['subtitle'] as String,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // 5. BADGE CATEGORIES & DETAILED 2x4 GRID
  // -------------------------------------------------------------
  Widget _buildBadgeCategoriesAndGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            'Badge Categories',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0F172A),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Categories Filter Bar
        SizedBox(
          height: 34,
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final bool isSelected = _selectedCategoryIndex == index;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedCategoryIndex = index);
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFDCFCE7) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Text(
                    _categories[index],
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 16),

        // 4x2 Grid of Badge Cards
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _detailedBadges.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.05,
            ),
            itemBuilder: (context, index) {
              final badge = _detailedBadges[index];
              return _buildDetailedBadgeCard(badge);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedBadgeCard(Map<String, dynamic> badge) {
    final double progress = (badge['current'] as num) / (badge['total'] as num);
    final Color color = badge['color'] as Color;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Hexagon / Circle Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: badge['badgeText'] != null
                ? Text(
                    badge['badgeText'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  )
                : Icon(badge['icon'] as IconData, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 8),

          Text(
            badge['title'] as String,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          Text(
            badge['desc'] as String,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 6),

          // Progress Ratio
          Text(
            '${badge['current']}${badge['unit']}/${badge['total']}${badge['unit']}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 4),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 6. REDEEM YOUR POINTS CARD
  // -------------------------------------------------------------
  Widget _buildRedeemPointsCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFBBF7D0)),
        ),
        child: Row(
          children: [
            const Icon(Icons.card_giftcard_rounded, color: Color(0xFF16A34A), size: 36),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Redeem Your Points',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Use your points to unlock premium features, exclusive products and more!',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16A34A),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Explore Rewards',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 8),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // 7. DAILY STREAK TRACKER
  // -------------------------------------------------------------
  Widget _buildDailyStreakSection() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily Streak',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    'Come back every day and earn more!',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_fire_department_rounded, color: Color(0xFFF97316), size: 12),
                    const SizedBox(width: 3),
                    Text(
                      '12 Days',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFF97316),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 7 Days Circles Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(days.length, (index) {
              final bool isToday = index == 6; // Sunday
              final bool isDone = index < 6;

              return Column(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isToday
                          ? const Color(0xFFFFF7ED)
                          : isDone
                              ? const Color(0xFFDCFCE7)
                              : const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                      border: isToday ? Border.all(color: const Color(0xFFF97316), width: 1.5) : null,
                    ),
                    child: Icon(
                      isToday
                          ? Icons.local_fire_department_rounded
                          : isDone
                              ? Icons.check_rounded
                              : Icons.circle_outlined,
                      color: isToday
                          ? const Color(0xFFF97316)
                          : isDone
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFCBD5E1),
                      size: 18,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    days[index],
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {required VoidCallback onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0F172A),
            ),
          ),
          GestureDetector(
            onTap: onSeeAll,
            child: Row(
              children: [
                Text(
                  'View All',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF16A34A),
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF16A34A), size: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
