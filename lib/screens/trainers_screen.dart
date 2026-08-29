import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/staggered_slide_fade.dart';
import 'trainer_detail_screen.dart';

class TrainersScreen extends StatefulWidget {
  const TrainersScreen({super.key});

  @override
  State<TrainersScreen> createState() => _TrainersScreenState();
}

class _TrainersScreenState extends State<TrainersScreen> with TickerProviderStateMixin {
  int _selectedSpecialtyIndex = 0;

  int _badgeIconIndex = 0;
  Timer? _badgeIconTimer;

  final List<IconData> _badgeIcons = [
    Icons.fitness_center_rounded,
    Icons.sports_gymnastics_rounded,
    Icons.bolt_rounded,
    Icons.verified_rounded,
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

  final List<Map<String, dynamic>> _specialties = [
    {'title': 'Strength', 'icon': Icons.fitness_center_rounded, 'color': const Color(0xFF22C55E)},
    {'title': 'Weight Loss', 'icon': Icons.local_fire_department_rounded, 'color': const Color(0xFFF97316)},
    {'title': 'Muscle Gain', 'icon': Icons.sports_gymnastics_rounded, 'color': const Color(0xFF06B6D4)},
    {'title': 'Yoga', 'icon': Icons.self_improvement_rounded, 'color': const Color(0xFFA855F7)},
    {'title': 'Nutrition', 'icon': Icons.eco_rounded, 'color': const Color(0xFF10B981)},
    {'title': 'HIIT', 'icon': Icons.bolt_rounded, 'color': const Color(0xFFEAB308)},
    {'title': 'Rehab & Mobility', 'icon': Icons.accessibility_new_rounded, 'color': const Color(0xFF3B82F6)},
  ];

  final List<Map<String, dynamic>> _trainers = [
    {
      'name': 'Rahul Sharma',
      'role': 'Strength & Muscle Coach',
      'exp': '8 Yrs Exp • 1.2K Clients',
      'price': '₹999',
      'rating': '4.9',
      'image': 'https://images.unsplash.com/photo-1567013127542-490d757e51fc?w=600&auto=format&fit=crop&q=80',
    },
    {
      'name': 'Anjali Mehta',
      'role': 'Weight Loss Specialist',
      'exp': '6 Yrs Exp • 980 Clients',
      'price': '₹899',
      'rating': '4.8',
      'image': 'https://images.unsplash.com/photo-1548690312-e3b507d8c110?w=600&auto=format&fit=crop&q=80',
    },
    {
      'name': 'Vikram Singh',
      'role': 'Muscle Gain Coach',
      'exp': '7 Yrs Exp • 1.5K Clients',
      'price': '₹1,099',
      'rating': '4.9',
      'image': 'https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?w=600&auto=format&fit=crop&q=80',
    },
    {
      'name': 'Neha Patel',
      'role': 'Yoga & Wellness Coach',
      'exp': '5 Yrs Exp • 760 Clients',
      'price': '₹799',
      'rating': '4.7',
      'image': 'https://images.unsplash.com/photo-1518611012118-696072aa579a?w=600&auto=format&fit=crop&q=80',
    },
  ];

  final List<Map<String, dynamic>> _challenges = [
    {
      'title': 'Push-Up Challenge',
      'subtitle': 'Build upper body strength',
      'days': '21 Days',
      'joined': '12.5K Joined',
      'image': 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=600&auto=format&fit=crop&q=80',
    },
    {
      'title': '30 Day Fitness Challenge',
      'subtitle': 'Complete daily workouts',
      'days': '30 Days',
      'joined': '28.4K Joined',
      'image': 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=600&auto=format&fit=crop&q=80',
    },
    {
      'title': '10K Steps Challenge',
      'subtitle': 'Walk more. Live better.',
      'days': '14 Days',
      'joined': '18.7K Joined',
      'image': 'https://images.unsplash.com/photo-1476480862126-209bfaa8edc8?w=600&auto=format&fit=crop&q=80',
    },
    {
      'title': 'HIIT Burn Challenge',
      'subtitle': 'Burn fat. Get fit.',
      'days': '7 Days',
      'joined': '9.3K Joined',
      'image': 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=600&auto=format&fit=crop&q=80',
    },
  ];

  final List<Map<String, dynamic>> _successStories = [
    {
      'badge': '-12 KG',
      'title': 'Weight Loss',
      'weeks': '12 Weeks',
      'beforeImg': 'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?w=400&auto=format&fit=crop&q=80',
      'afterImg': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&auto=format&fit=crop&q=80',
    },
    {
      'badge': '-8 KG',
      'title': 'Fat Loss',
      'weeks': '10 Weeks',
      'beforeImg': 'https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?w=400&auto=format&fit=crop&q=80',
      'afterImg': 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400&auto=format&fit=crop&q=80',
    },
    {
      'badge': '+6 KG',
      'title': 'Muscle Gain',
      'weeks': '16 Weeks',
      'beforeImg': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&auto=format&fit=crop&q=80',
      'afterImg': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400&auto=format&fit=crop&q=80',
    },
    {
      'badge': '+Strength',
      'title': '& Confidence',
      'weeks': '8 Weeks',
      'beforeImg': 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=400&auto=format&fit=crop&q=80',
      'afterImg': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400&auto=format&fit=crop&q=80',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFBFBFD),
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 110), // Padding for floating nav
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              StaggeredSlideFade(
                index: 0,
                child: _buildHeader(),
              ),
              const SizedBox(height: 18),
              StaggeredSlideFade(
                index: 1,
                child: _buildHeroBanner(),
              ),
              const SizedBox(height: 20),
              StaggeredSlideFade(
                index: 2,
                child: _buildSpecialtiesList(),
              ),
              const SizedBox(height: 26),
              StaggeredSlideFade(
                index: 3,
                child: _buildTopRatedTrainersSection(),
              ),
              const SizedBox(height: 26),
              StaggeredSlideFade(
                index: 4,
                child: _buildPopularChallengesSection(),
              ),
              const SizedBox(height: 26),
              StaggeredSlideFade(
                index: 5,
                child: _buildWhyTrainWithUsSection(),
              ),
              const SizedBox(height: 26),
              StaggeredSlideFade(
                index: 6,
                child: _buildSuccessStoriesSection(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // 1. TOP HEADER (WITH ANIMATED BADGE & ZERO OVERFLOW)
  // -------------------------------------------------------------
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Title, Animated Badge & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Trainers',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 26,
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
                  'Find the perfect trainer to achieve your goals 💪',
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

          // Action Buttons (Search & Filter)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeaderActionButton(Icons.search_rounded),
              const SizedBox(width: 8),
              _buildHeaderActionButton(Icons.tune_rounded),
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
          colors: [Color(0xFFDCFCE7), Color(0xFFBBF7D0)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF22C55E).withValues(alpha: 0.18),
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
          color: const Color(0xFF16A34A),
          size: 16,
        ),
      ),
    );
  }

  Widget _buildHeaderActionButton(IconData icon) {
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
  // 2. HERO BANNER CAROUSEL
  // -------------------------------------------------------------
  Widget _buildHeroBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 190,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                // Background Image
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/trainers_hero_banner.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Image.network(
                      'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=1000&auto=format&fit=crop&q=80',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                // Subtle Left Gradient for Text readability
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.94),
                          Colors.white.withValues(alpha: 0.85),
                          Colors.white.withValues(alpha: 0.2),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.45, 0.75, 1.0],
                      ),
                    ),
                  ),
                ),

                // Content Left
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'ACHIEVE TOGETHER',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF16A34A),
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF0F172A),
                            height: 1.15,
                            letterSpacing: -0.5,
                          ),
                          children: const [
                            TextSpan(text: 'Train with\nExpert '),
                            TextSpan(
                              text: 'Trainers',
                              style: TextStyle(color: Color(0xFF16A34A)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Personalized guidance.\nReal results.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TrainerDetailScreen(
                                trainerName: 'Rohit Sharma',
                                specialty: 'Strength & Transformation Coach',
                                rating: '4.9',
                                reviews: '2.4K Reviews',
                                image: 'https://images.unsplash.com/photo-1567013127542-490d757e51fc?w=600&auto=format&fit=crop&q=80',
                                price: '₹3,999',
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16A34A),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF16A34A).withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Book Session',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 12),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Carousel Dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              bool isActive = index == 0;
              return Container(
                width: isActive ? 16 : 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFF16A34A) : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 3. SPECIALTIES CATEGORIES LIST
  // -------------------------------------------------------------
  Widget _buildSpecialtiesList() {
    return SizedBox(
      height: 84,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _specialties.length,
        itemBuilder: (context, index) {
          final item = _specialties[index];
          final bool isSelected = _selectedSpecialtyIndex == index;
          final Color color = item['color'] as Color;

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _selectedSpecialtyIndex = index;
              });
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 5),
              child: Column(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: isSelected ? color.withValues(alpha: 0.15) : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? color : const Color(0xFFF1F5F9),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected ? color.withValues(alpha: 0.2) : const Color(0xFF0F172A).withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      item['icon'] as IconData,
                      color: color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item['title'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // -------------------------------------------------------------
  // 4. TOP RATED TRAINERS SECTION
  // -------------------------------------------------------------
  Widget _buildTopRatedTrainersSection() {
    return Column(
      children: [
        _buildSectionHeader('Top Rated Trainers', onSeeAll: () {}),
        const SizedBox(height: 14),
        SizedBox(
          height: 245,
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _trainers.length,
            itemBuilder: (context, index) {
              final trainer = _trainers[index];
              return _buildTrainerCard(trainer);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTrainerCard(Map<String, dynamic> trainer) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TrainerDetailScreen(
              trainerName: trainer['name'] as String,
              specialty: trainer['role'] as String,
              rating: trainer['rating'] as String,
              reviews: '1.8K Reviews',
              image: trainer['image'] as String,
              price: trainer['price'] as String,
            ),
          ),
        );
      },
      child: Container(
        width: 170,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trainer Image with Rating Badge
          Stack(
            children: [
              Container(
                height: 110,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  image: DecorationImage(
                    image: NetworkImage(trainer['image'] as String),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 12),
                      const SizedBox(width: 3),
                      Text(
                        trainer['rating'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Details
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trainer['name'] as String,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  trainer['role'] as String,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  trainer['exp'] as String,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF94A3B8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      trainer['price'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF16A34A),
                      ),
                    ),
                    Text(
                      ' /month',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'View Profile',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
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
  // 5. POPULAR CHALLENGES SECTION
  // -------------------------------------------------------------
  Widget _buildPopularChallengesSection() {
    return Column(
      children: [
        _buildSectionHeader('Popular Challenges', onSeeAll: () {}),
        const SizedBox(height: 14),
        SizedBox(
          height: 205,
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _challenges.length,
            itemBuilder: (context, index) {
              final challenge = _challenges[index];
              return _buildChallengeCard(challenge);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChallengeCard(Map<String, dynamic> challenge) {
    return Container(
      width: 180,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Challenge Image with Duration Tag
          Stack(
            children: [
              Container(
                height: 95,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  image: DecorationImage(
                    image: NetworkImage(challenge['image'] as String),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    challenge['days'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  challenge['title'] as String,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  challenge['subtitle'] as String,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.people_alt_rounded, color: Color(0xFF64748B), size: 12),
                    const SizedBox(width: 4),
                    Text(
                      challenge['joined'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Join Challenge',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF16A34A),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 6. WHY TRAIN WITH US? SECTION
  // -------------------------------------------------------------
  Widget _buildWhyTrainWithUsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Why Train With Us?',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildBenefitCard(
                  icon: Icons.verified_rounded,
                  iconColor: const Color(0xFF22C55E),
                  title: 'Certified Trainers',
                  desc: 'All trainers are certified and experienced.',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildBenefitCard(
                  icon: Icons.emoji_events_rounded,
                  iconColor: const Color(0xFFF59E0B),
                  title: 'Personalized Plans',
                  desc: 'Custom workout and nutrition plans.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildBenefitCard(
                  icon: Icons.chat_bubble_outline_rounded,
                  iconColor: const Color(0xFFA855F7),
                  title: '1:1 Support',
                  desc: 'Get guidance and support whenever you need.',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildBenefitCard(
                  icon: Icons.trending_up_rounded,
                  iconColor: const Color(0xFF38BDF8),
                  title: 'Real Results',
                  desc: 'Proven methods that deliver real results.',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            desc,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 7. SUCCESS STORIES (TRANSFORMATIONS) SECTION
  // -------------------------------------------------------------
  Widget _buildSuccessStoriesSection() {
    return Column(
      children: [
        _buildSectionHeader('Success Stories', onSeeAll: () {}),
        const SizedBox(height: 14),
        SizedBox(
          height: 185,
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _successStories.length,
            itemBuilder: (context, index) {
              final story = _successStories[index];
              return _buildSuccessStoryCard(story);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessStoryCard(Map<String, dynamic> story) {
    return Container(
      width: 175,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Before / After side by side images
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: SizedBox(
              height: 105,
              child: Row(
                children: [
                  Expanded(
                    child: Image.network(
                      story['beforeImg'] as String,
                      fit: BoxFit.cover,
                      height: 105,
                    ),
                  ),
                  Container(width: 1.5, color: Colors.white),
                  Expanded(
                    child: Image.network(
                      story['afterImg'] as String,
                      fit: BoxFit.cover,
                      height: 105,
                    ),
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  story['badge'] as String,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF16A34A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  story['title'] as String,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  story['weeks'] as String,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // REUSABLE SECTION HEADER
  // -------------------------------------------------------------
  Widget _buildSectionHeader(String title, {required VoidCallback onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
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
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF16A34A),
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF16A34A), size: 11),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
