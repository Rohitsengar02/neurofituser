import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/staggered_slide_fade.dart';
import 'rewards_screen.dart';
import 'trainers_screen.dart';
import 'social_screen.dart';
import 'shop_screen.dart';
import 'challenges_screen.dart';
import 'vendor_registration_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  int _badgeIconIndex = 0;
  Timer? _badgeIconTimer;

  final List<IconData> _badgeIcons = [
    Icons.person_rounded,
    Icons.emoji_events_rounded,
    Icons.military_tech_rounded,
    Icons.fitness_center_rounded,
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

              // 2. Main Profile Card
              StaggeredSlideFade(
                index: 1,
                child: _buildProfileHeroCard(),
              ),

              const SizedBox(height: 20),

              // 3. Your Goal Banner
              StaggeredSlideFade(
                index: 2,
                child: _buildGoalCard(),
              ),

              const SizedBox(height: 24),

              // 4. Quick Actions
              StaggeredSlideFade(
                index: 3,
                child: _buildQuickActionsSection(),
              ),

              const SizedBox(height: 24),

              // 5. Achievements
              StaggeredSlideFade(
                index: 4,
                child: _buildAchievementsSection(),
              ),

              const SizedBox(height: 24),

              // 6. Navigation Options 2-Column Menu
              StaggeredSlideFade(
                index: 5,
                child: _buildNavigationLinksGrid(),
              ),

              const SizedBox(height: 24),

              // 7. NeuroFit Pro Banner
              StaggeredSlideFade(
                index: 6,
                child: _buildNeuroFitProBanner(),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // 1. TOP HEADER
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
                      'Profile',
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
                  'Your Fitness Journey 💚',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeaderIcon(Icons.share_outlined),
              const SizedBox(width: 8),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  _buildHeaderIcon(Icons.notifications_outlined),
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF22C55E),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '3',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              _buildHeaderIcon(Icons.settings_outlined),
            ],
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
          colors: [Color(0xFFE0F2FE), Color(0xFFBAE6FD), Color(0xFFDCFCE7)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
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
          color: const Color(0xFF0284C7),
          size: 16,
        ),
      ),
    );
  }

  Widget _buildHeaderIcon(IconData icon) {
    return Container(
      width: 38,
      height: 38,
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
      child: Icon(icon, color: const Color(0xFF0F172A), size: 18),
    );
  }

  // -------------------------------------------------------------
  // 2. MAIN USER PROFILE HERO CARD
  // -------------------------------------------------------------
  Widget _buildProfileHeroCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.04),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            // Avatar, Info & Edit Button
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar with green status dot
                Stack(
                  children: [
                    Container(
                      width: 82,
                      height: 82,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: NetworkImage(
                            'https://images.unsplash.com/photo-1567013127542-490d757e51fc?w=400&auto=format&fit=crop&q=80',
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),

                // Name, Handle, Bio & Level Pills
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Rohit Sengar',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.verified_rounded, color: Color(0xFF3B82F6), size: 16),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.edit_outlined, size: 11, color: Color(0xFF0F172A)),
                                const SizedBox(width: 4),
                                Text(
                                  'Edit Profile',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '@rohitfit',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '"Dream • Train • Transform" 🔥',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Level 24 & 12 Day Streak Pills
                      Row(
                        children: [
                          _buildMiniBadge(
                            icon: Icons.emoji_events_rounded,
                            label: 'Level 24',
                            color: const Color(0xFF10B981),
                            bgColor: const Color(0xFFE6F7F0),
                          ),
                          const SizedBox(width: 8),
                          _buildMiniBadge(
                            icon: Icons.local_fire_department_rounded,
                            label: '12 Day Streak',
                            color: const Color(0xFFF97316),
                            bgColor: const Color(0xFFFFF7ED),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 16),

            // 4 Stats (Weight, Body Fat, Steps, Workouts)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildProfileStatItem(Icons.scale_rounded, '82.4 kg', 'Current Weight'),
                _buildProfileStatItem(Icons.accessibility_new_rounded, '15.3%', 'Body Fat'),
                _buildProfileStatItem(Icons.directions_walk_rounded, '8,752', 'Avg Steps'),
                _buildProfileStatItem(Icons.fitness_center_rounded, '186', 'Workouts'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniBadge({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: const Color(0xFFDCFCE7),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF16A34A), size: 16),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF0F172A),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 9.5,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // 3. YOUR GOAL HERO BANNER
  // -------------------------------------------------------------
  Widget _buildGoalCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: const Color(0xFF0B0F15),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Background athlete image on right
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: 140,
              child: Image.network(
                'https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?w=400&auto=format&fit=crop&q=80',
                fit: BoxFit.cover,
              ),
            ),

            // Dark gradient overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      const Color(0xFF0B0F15),
                      const Color(0xFF0B0F15).withValues(alpha: 0.95),
                      const Color(0xFF0B0F15).withValues(alpha: 0.3),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.55, 0.8, 1.0],
                  ),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.track_changes_rounded, color: Color(0xFF22C55E), size: 14),
                      const SizedBox(width: 5),
                      Text(
                        'Your Goal',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Build Lean Muscle',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Target: 70 kg by Dec 2026',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),

                  // Progress Bar & Percentage
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: const LinearProgressIndicator(
                            value: 0.82,
                            minHeight: 5,
                            backgroundColor: Color(0xFF1E293B),
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF22C55E)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '82% Completed',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Top Right Arrow
            Positioned(
              top: 14,
              right: 14,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // 4. QUICK ACTIONS SECTION
  // -------------------------------------------------------------
  Widget _buildQuickActionsSection() {
    return Column(
      children: [
        _buildSectionHeader('Quick Actions', onSeeAll: () {}),
        const SizedBox(height: 12),
        SizedBox(
          height: 94,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildQuickActionTile(Icons.bar_chart_rounded, 'My Progress', const Color(0xFF10B981), const Color(0xFFE6F7F0)),
              _buildQuickActionTile(Icons.calendar_month_rounded, 'Workout\nHistory', const Color(0xFFF97316), const Color(0xFFFFF7ED)),
              _buildQuickActionTile(Icons.favorite_rounded, 'My Activity', const Color(0xFF8B5CF6), const Color(0xFFF3E8FF)),
              _buildQuickActionTile(Icons.bookmark_rounded, 'Saved Content', const Color(0xFF10B981), const Color(0xFFE6F7F0)),
              _buildQuickActionTile(Icons.watch_rounded, 'Connected\nDevices', const Color(0xFF3B82F6), const Color(0xFFE0F2FE)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionTile(IconData icon, String title, Color color, Color bg) {
    return Container(
      width: 86,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 5. ACHIEVEMENTS SECTION
  // -------------------------------------------------------------
  Widget _buildAchievementsSection() {
    final achievements = [
      {'title': '7 Day\nStreak', 'icon': Icons.local_fire_department_rounded, 'color': const Color(0xFFF97316), 'bg': const Color(0xFFFFF7ED)},
      {'title': '50\nWorkouts', 'icon': Icons.fitness_center_rounded, 'color': const Color(0xFF8B5CF6), 'bg': const Color(0xFFF3E8FF)},
      {'title': '10K\nSteps', 'icon': Icons.directions_walk_rounded, 'color': const Color(0xFF10B981), 'bg': const Color(0xFFE6F7F0)},
      {'title': 'Goal\nAchiever', 'icon': Icons.military_tech_rounded, 'color': const Color(0xFF3B82F6), 'bg': const Color(0xFFE0F2FE)},
      {'title': 'Mindful\n7 Days', 'icon': Icons.spa_rounded, 'color': const Color(0xFFEC4899), 'bg': const Color(0xFFFCE7F3)},
      {'title': 'Nutrition\nMaster', 'icon': Icons.eco_rounded, 'color': const Color(0xFFF59E0B), 'bg': const Color(0xFFFEF3C7)},
    ];

    return Column(
      children: [
        _buildSectionHeader('Achievements', onSeeAll: () {}),
        const SizedBox(height: 14),
        SizedBox(
          height: 98,
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: achievements.length,
            itemBuilder: (context, index) {
              final a = achievements[index];
              return Container(
                width: 68,
                margin: const EdgeInsets.symmetric(horizontal: 5),
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: a['color'] as Color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (a['color'] as Color).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(a['icon'] as IconData, color: Colors.white, size: 24),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      a['title'] as String,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                        height: 1.1,
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
  // 6. NAVIGATION LINKS 2-COLUMN GRID
  // -------------------------------------------------------------
  Widget _buildNavigationLinksGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Column
          Expanded(
            child: Column(
              children: [
                _buildLinkItem(Icons.track_changes_rounded, 'My Goals', const Color(0xFF0284C7)),
                _buildLinkItem(Icons.straighten_rounded, 'My Measurements', const Color(0xFF0284C7)),
                _buildLinkItem(Icons.workspace_premium_rounded, 'Subscription', const Color(0xFFF59E0B), badge: 'Pro'),
                _buildLinkItem(
                  Icons.card_giftcard_rounded,
                  'Rewards',
                  const Color(0xFFE11D48),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RewardsScreen()),
                    );
                  },
                ),
                _buildLinkItem(
                  Icons.people_rounded,
                  'Community',
                  const Color(0xFF3B82F6),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SocialScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Right Column
          Expanded(
            child: Column(
              children: [
                _buildLinkItem(
                  Icons.school_rounded,
                  'Trainers',
                  const Color(0xFF64748B),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const TrainersScreen()),
                    );
                  },
                ),
                _buildLinkItem(
                  Icons.emoji_events_rounded,
                  'Challenges',
                  const Color(0xFFF59E0B),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ChallengesScreen()),
                    );
                  },
                ),
                _buildLinkItem(
                  Icons.shopping_bag_rounded,
                  'Shop',
                  const Color(0xFF8B5CF6),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ShopScreen()),
                    );
                  },
                ),
                _buildLinkItem(
                  Icons.storefront_rounded,
                  'Vendor Panel',
                  const Color(0xFF16A34A),
                  badge: 'Sell',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const VendorRegistrationScreen()),
                    );
                  },
                ),
                _buildLinkItem(Icons.headset_mic_rounded, 'Help & Support', const Color(0xFF3B82F6)),
                _buildLinkItem(Icons.settings_rounded, 'Settings & Privacy', const Color(0xFF64748B)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkItem(IconData icon, String title, Color iconColor, {String? badge, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        if (onTap != null) {
          onTap();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (badge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 4),
            ],
            const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF94A3B8), size: 10),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // 7. NEUROFIT PRO BANNER
  // -------------------------------------------------------------
  Widget _buildNeuroFitProBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0E131F),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Background image right
            Positioned(
              right: -10,
              top: 0,
              bottom: 0,
              width: 130,
              child: Image.network(
                'https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?w=400&auto=format&fit=crop&q=80',
                fit: BoxFit.cover,
              ),
            ),

            // Gradient
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      const Color(0xFF0E131F),
                      const Color(0xFF0E131F).withValues(alpha: 0.95),
                      const Color(0xFF0E131F).withValues(alpha: 0.4),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.55, 0.75, 1.0],
                  ),
                ),
              ),
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF59E0B),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 14),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'NeuroFit Pro',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'PRO',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Unlock advanced features for faster results',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 12),

                // 4 Checkmarks
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProFeatureCheck('AI Coach & Personalized Plans'),
                          const SizedBox(height: 4),
                          _buildProFeatureCheck('Premium Workouts & Meal Plans'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProFeatureCheck('Live Classes'),
                          const SizedBox(height: 4),
                          _buildProFeatureCheck('Exclusive Challenges'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Upgrade Button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Upgrade Now',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 12),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProFeatureCheck(String text) {
    return Row(
      children: [
        const Icon(Icons.check_rounded, color: Color(0xFF22C55E), size: 11),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
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
                  'See All',
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
