import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/staggered_slide_fade.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> with TickerProviderStateMixin {
  int _badgeIconIndex = 0;
  Timer? _badgeIconTimer;
  int _selectedFilterIndex = 0;

  final List<IconData> _badgeIcons = [
    Icons.emoji_events_rounded,
    Icons.military_tech_rounded,
    Icons.bolt_rounded,
    Icons.stars_rounded,
  ];

  final List<String> _filters = [
    'Active',
    'Upcoming',
    'Completed',
    'My Challenges',
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
              // 1. Header with Back Button & Animated Badge
              StaggeredSlideFade(
                index: 0,
                child: _buildHeader(),
              ),

              const SizedBox(height: 16),

              // 2. Filter Pills Bar
              StaggeredSlideFade(
                index: 1,
                child: _buildFilterPills(),
              ),

              const SizedBox(height: 22),

              // 3. Active Challenges Carousel
              StaggeredSlideFade(
                index: 2,
                child: _buildActiveChallengesSection(),
              ),

              const SizedBox(height: 24),

              // 4. Upcoming Challenges Section
              StaggeredSlideFade(
                index: 3,
                child: _buildUpcomingChallengesSection(),
              ),

              const SizedBox(height: 24),

              // 5. Leaderboard Section
              StaggeredSlideFade(
                index: 4,
                child: _buildLeaderboardSection(),
              ),

              const SizedBox(height: 24),

              // 6. Complete Challenges Unlock Rewards Banner
              StaggeredSlideFade(
                index: 5,
                child: _buildPromoBanner(),
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
                      'Challenges',
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
                  'Push your limits. Earn rewards. Become your best. 💚',
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

          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeaderIcon(Icons.emoji_events_outlined),
              const SizedBox(width: 8),
              _buildHeaderIcon(Icons.access_time_rounded),
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
  // 2. FILTER PILLS
  // -------------------------------------------------------------
  Widget _buildFilterPills() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(_filters.length, (index) {
          final bool isSelected = _selectedFilterIndex == index;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedFilterIndex = index);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7.5),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFDCFCE7) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Text(
                _filters[index],
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // -------------------------------------------------------------
  // 3. ACTIVE CHALLENGES CAROUSEL
  // -------------------------------------------------------------
  Widget _buildActiveChallengesSection() {
    final activeChallenges = [
      {
        'tag': 'Popular',
        'tagIcon': Icons.eco_rounded,
        'tagColor': const Color(0xFF16A34A),
        'tagBg': const Color(0xFFDCFCE7),
        'badgeIcon': Icons.directions_walk_rounded,
        'badgeColor': const Color(0xFF16A34A),
        'title': '10K Steps\nChallenge',
        'desc': 'Walk 10,000 steps\nevery day',
        'currentDays': 7,
        'totalDays': 10,
        'progress': 0.7,
        'barColor': const Color(0xFF16A34A),
        'giftBg': const Color(0xFFDCFCE7),
        'image': 'https://images.unsplash.com/photo-1502680390469-be75c86b636f?w=400&auto=format&fit=crop&q=80',
      },
      {
        'tag': 'Trending',
        'tagIcon': Icons.bolt_rounded,
        'tagColor': const Color(0xFF2563EB),
        'tagBg': const Color(0xFFDBEAFE),
        'badgeIcon': Icons.sports_gymnastics_rounded,
        'badgeColor': const Color(0xFF2563EB),
        'title': '30 Day\nPush-up Challenge',
        'desc': 'Complete 100 push-ups\nevery day',
        'currentDays': 18,
        'totalDays': 30,
        'progress': 0.6,
        'barColor': const Color(0xFF2563EB),
        'giftBg': const Color(0xFFDBEAFE),
        'image': 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400&auto=format&fit=crop&q=80',
      },
      {
        'tag': 'Hot',
        'tagIcon': Icons.local_fire_department_rounded,
        'tagColor': const Color(0xFFEA580C),
        'tagBg': const Color(0xFFFFF7ED),
        'badgeIcon': Icons.lunch_dining_rounded,
        'badgeColor': const Color(0xFFEA580C),
        'title': 'Clean Eating\nChallenge',
        'desc': 'Eat clean for 21 days\nstraight',
        'currentDays': 12,
        'totalDays': 21,
        'progress': 0.57,
        'barColor': const Color(0xFFEA580C),
        'giftBg': const Color(0xFFFEF3C7),
        'image': 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400&auto=format&fit=crop&q=80',
      },
      {
        'tag': 'New',
        'tagIcon': Icons.stars_rounded,
        'tagColor': const Color(0xFF9333EA),
        'tagBg': const Color(0xFFF3E8FF),
        'badgeIcon': Icons.spa_rounded,
        'badgeColor': const Color(0xFF9333EA),
        'title': 'Mindful\n21 Days',
        'desc': 'Meditate for 10 min\nevery day',
        'currentDays': 5,
        'totalDays': 21,
        'progress': 0.24,
        'barColor': const Color(0xFF9333EA),
        'giftBg': const Color(0xFFF3E8FF),
        'image': 'https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=400&auto=format&fit=crop&q=80',
      },
    ];

    return Column(
      children: [
        _buildSectionHeader('Active Challenges', onSeeAll: () {}),
        const SizedBox(height: 14),
        SizedBox(
          height: 250,
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: activeChallenges.length,
            itemBuilder: (context, index) {
              final c = activeChallenges[index];
              return Container(
                width: 155,
                margin: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Image with Tag & Badge
                    Stack(
                      children: [
                        Image.network(
                          c['image'] as String,
                          height: 105,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                        // Pill Tag
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: c['tagBg'] as Color,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(c['tagIcon'] as IconData, size: 10, color: c['tagColor'] as Color),
                                const SizedBox(width: 3),
                                Text(
                                  c['tag'] as String,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: c['tagColor'] as Color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Hexagon / Badge Icon Overlap
                        Positioned(
                          bottom: 6,
                          left: 8,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: c['badgeColor'] as Color,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Icon(c['badgeIcon'] as IconData, color: Colors.white, size: 16),
                          ),
                        ),
                      ],
                    ),

                    // Details
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c['title'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                              height: 1.15,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            c['desc'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF94A3B8),
                              height: 1.1,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),

                          // Progress Bar & Days Ratio
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: c['progress'] as double,
                              minHeight: 4,
                              backgroundColor: const Color(0xFFE2E8F0),
                              valueColor: AlwaysStoppedAnimation<Color>(c['barColor'] as Color),
                            ),
                          ),
                          const SizedBox(height: 6),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              RichText(
                                text: TextSpan(
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF0F172A),
                                  ),
                                  children: [
                                    TextSpan(text: '${c['currentDays']} '),
                                    TextSpan(
                                      text: '/ ${c['totalDays']} Days',
                                      style: TextStyle(
                                        color: c['barColor'] as Color,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 9.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: c['giftBg'] as Color,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.card_giftcard_rounded,
                                  size: 13,
                                  color: c['barColor'] as Color,
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
    );
  }

  // -------------------------------------------------------------
  // 4. UPCOMING CHALLENGES SECTION
  // -------------------------------------------------------------
  Widget _buildUpcomingChallengesSection() {
    final upcoming = [
      {
        'title': 'Muscle Gain\nChallenge',
        'badgeIcon': Icons.fitness_center_rounded,
        'badgeColor': const Color(0xFFEC4899),
        'badgeBg': const Color(0xFFFCE7F3),
        'date': 'Start on 1 Jun 2025',
        'startsIn': 'Starts in 5 days',
        'participants': '12.4K',
        'image': 'https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?w=400&auto=format&fit=crop&q=80',
      },
      {
        'title': 'Yoga Flexibility\nChallenge',
        'badgeIcon': Icons.self_improvement_rounded,
        'badgeColor': const Color(0xFF16A34A),
        'badgeBg': const Color(0xFFDCFCE7),
        'date': 'Start on 5 Jun 2025',
        'startsIn': 'Starts in 9 days',
        'participants': '8.7K',
        'image': 'https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=400&auto=format&fit=crop&q=80',
      },
      {
        'title': 'Better Sleep\nChallenge',
        'badgeIcon': Icons.bedtime_rounded,
        'badgeColor': const Color(0xFF7C3AED),
        'badgeBg': const Color(0xFFF3E8FF),
        'date': 'Start on 10 Jun 2025',
        'startsIn': 'Starts in 14 days',
        'participants': '6.2K',
        'image': 'https://images.unsplash.com/photo-1541781774459-bb2af2f05b55?w=400&auto=format&fit=crop&q=80',
      },
    ];

    return Column(
      children: [
        _buildSectionHeader('Upcoming Challenges', onSeeAll: () {}),
        const SizedBox(height: 14),
        SizedBox(
          height: 175,
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: upcoming.length,
            itemBuilder: (context, index) {
              final up = upcoming[index];
              return Container(
                width: 220,
                margin: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Top Split (Image Left, Details Right)
                    Expanded(
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.only(topLeft: Radius.circular(22)),
                            child: Image.network(
                              up['image'] as String,
                              width: 90,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: up['badgeBg'] as Color,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(up['badgeIcon'] as IconData, color: up['badgeColor'] as Color, size: 14),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    up['title'] as String,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF0F172A),
                                      height: 1.15,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    up['date'] as String,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF94A3B8),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      up['startsIn'] as String,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF475569),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1, color: Color(0xFFF1F5F9)),

                    // Bottom Bar (Participants + Avatars)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Participants: ',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                              Text(
                                up['participants'] as String,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              _buildMiniAvatar('https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100'),
                              _buildMiniAvatar('https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100'),
                              _buildMiniAvatar('https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100'),
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
    );
  }

  Widget _buildMiniAvatar(String url) {
    return Container(
      margin: const EdgeInsets.only(left: 2),
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1),
        image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
      ),
    );
  }

  // -------------------------------------------------------------
  // 5. LEADERBOARD SECTION
  // -------------------------------------------------------------
  Widget _buildLeaderboardSection() {
    final leaders = [
      {
        'rank': '1',
        'medalColor': const Color(0xFFEAB308),
        'name': 'Aman Verma',
        'streak': '12 Day Streak',
        'xp': '28,450 XP',
        'avatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
      },
      {
        'rank': '2',
        'medalColor': const Color(0xFF94A3B8),
        'name': 'Neha Sharma',
        'streak': '9 Day Streak',
        'xp': '24,780 XP',
        'avatar': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
      },
      {
        'rank': '3',
        'medalColor': const Color(0xFFD97706),
        'name': 'Rohit Singh',
        'streak': '7 Day Streak',
        'xp': '21,890 XP',
        'avatar': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200',
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Leaderboard',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Row(
                children: [
                  Text(
                    'This Week',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF16A34A),
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF16A34A), size: 16),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: leaders.length,
            itemBuilder: (context, index) {
              final leader = leaders[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Row(
                  children: [
                    // Rank Medal
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: (leader['medalColor'] as Color).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        leader['rank'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: leader['medalColor'] as Color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Avatar
                    CircleAvatar(
                      radius: 18,
                      backgroundImage: NetworkImage(leader['avatar'] as String),
                    ),
                    const SizedBox(width: 10),
                    // Name & Streak
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            leader['name'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.local_fire_department_rounded, color: Color(0xFFF97316), size: 11),
                              const SizedBox(width: 2),
                              Text(
                                leader['streak'] as String,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // XP & Gift Button
                    Text(
                      leader['xp'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFFF97316),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFF7ED),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.card_giftcard_rounded, color: Color(0xFFF97316), size: 14),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 6. PROMO UNLOCK REWARDS BANNER
  // -------------------------------------------------------------
  Widget _buildPromoBanner() {
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
            // Gold Trophy
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                'assets/images/rewards_gold_trophy_3d.jpg',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.emoji_events_rounded,
                  color: Color(0xFFF59E0B),
                  size: 36,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Complete challenges,\nearn XP and unlock rewards!',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
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
                          'How It Works',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9.5,
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
