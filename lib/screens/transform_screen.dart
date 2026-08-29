import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/staggered_slide_fade.dart';

class TransformScreen extends StatefulWidget {
  const TransformScreen({super.key});

  @override
  State<TransformScreen> createState() => _TransformScreenState();
}

class _TransformScreenState extends State<TransformScreen> {
  int _currentInspirationIndex = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  final List<Map<String, dynamic>> _focusAreas = [
    {
      'title': 'Fat Loss',
      'desc': 'Burn calories &\nreduce body fat',
      'icon': Icons.local_fire_department_rounded,
      'color': const Color(0xFFEA580C),
      'bg': const Color(0xFFFFF7ED),
    },
    {
      'title': 'Muscle Gain',
      'desc': 'Build lean muscle\n& strength',
      'icon': Icons.fitness_center_rounded,
      'color': const Color(0xFF8B5CF6),
      'bg': const Color(0xFFF3E8FF),
    },
    {
      'title': 'Nutrition',
      'desc': 'Eat right, fuel\nyour body',
      'icon': Icons.apple_rounded,
      'color': const Color(0xFF16A34A),
      'bg': const Color(0xFFDCFCE7),
    },
    {
      'title': 'Cardio',
      'desc': 'Improve endurance\n& heart health',
      'icon': Icons.monitor_heart_rounded,
      'color': const Color(0xFFE11D48),
      'bg': const Color(0xFFFFE4E6),
    },
    {
      'title': 'Mindset',
      'desc': 'Stay motivated\n& stress-free',
      'icon': Icons.psychology_rounded,
      'color': const Color(0xFF2563EB),
      'bg': const Color(0xFFDBEAFE),
    },
    {
      'title': 'Recovery',
      'desc': 'Sleep better,\nrecover faster',
      'icon': Icons.nights_stay_rounded,
      'color': const Color(0xFF4F46E5),
      'bg': const Color(0xFFE0E7FF),
    },
  ];

  final List<Map<String, dynamic>> _whatsIncluded = [
    {
      'title': 'Personalized\nWorkouts',
      'desc': 'Tailored to your\nfitness level & goal',
      'icon': Icons.accessibility_new_rounded,
      'image': 'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?w=400&auto=format&fit=crop&q=80',
    },
    {
      'title': 'Custom\nDiet Plan',
      'desc': 'Nutrition plan designed\njust for you',
      'icon': Icons.restaurant_menu_rounded,
      'image': 'https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=400&auto=format&fit=crop&q=80',
    },
    {
      'title': 'Progress\nTracking',
      'desc': 'Track your workouts,\nweight & progress',
      'icon': Icons.show_chart_rounded,
      'image': 'https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=400&auto=format&fit=crop&q=80',
    },
    {
      'title': '1-on-1\nSupport',
      'desc': 'Chat with your\ntrainer anytime',
      'icon': Icons.forum_rounded,
      'image': 'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?w=400&auto=format&fit=crop&q=80',
    },
    {
      'title': 'Expert\nGuidance',
      'desc': 'Get guidance from\ncertified trainers',
      'icon': Icons.verified_rounded,
      'image': 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=400&auto=format&fit=crop&q=80',
    },
  ];

  final List<Map<String, dynamic>> _inspirations = [
    {
      'name': 'Rohit S.',
      'duration': '12 Weeks',
      'result': '-12 KG',
      'quote': '"Consistency is the key!"',
      'image1': 'https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?w=400&auto=format&fit=crop&q=80',
      'image2': 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=400&auto=format&fit=crop&q=80',
    },
    {
      'name': 'Neha P.',
      'duration': '10 Weeks',
      'result': '-8 KG',
      'quote': '"I feel stronger & happier"',
      'image1': 'https://images.unsplash.com/photo-1518611012118-696072aa579a?w=400&auto=format&fit=crop&q=80',
      'image2': 'https://images.unsplash.com/photo-1607962837311-b583f6c8d76f?w=400&auto=format&fit=crop&q=80',
    },
    {
      'name': 'Aman K.',
      'duration': '14 Weeks',
      'result': '+5 KG',
      'quote': '"From skinny to strong!"',
      'image1': 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400&auto=format&fit=crop&q=80',
      'image2': 'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?w=400&auto=format&fit=crop&q=80',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFD),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  // Top Bar
                  StaggeredSlideFade(index: 0, child: _buildTopBar()),

                  const SizedBox(height: 16),
                  
                  // Hero Section
                  StaggeredSlideFade(index: 1, child: _buildHeroSection()),

                  const SizedBox(height: 24),
                  
                  // Your Transformation Plan
                  StaggeredSlideFade(index: 2, child: _buildTransformationPlanSection()),

                  const SizedBox(height: 24),

                  // Key Focus Areas
                  StaggeredSlideFade(index: 3, child: _buildKeyFocusAreasSection()),

                  const SizedBox(height: 24),

                  // What's Included
                  StaggeredSlideFade(index: 4, child: _buildWhatsIncludedSection()),

                  const SizedBox(height: 24),

                  // Your Transformation Journey (Timeline)
                  StaggeredSlideFade(index: 5, child: _buildTransformationJourneySection()),

                  const SizedBox(height: 24),

                  // Transformation Inspiration
                  StaggeredSlideFade(index: 6, child: _buildTransformationInspirationSection()),

                  const SizedBox(height: 40),
                ],
              ),
            ),

            // Fixed Bottom Action Bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildFixedBottomBar(),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // 1. TOP BAR
  // -------------------------------------------------------------
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              if (Navigator.canPop(context)) Navigator.pop(context);
            },
            child: Container(
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
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Color(0xFF0F172A),
                size: 16,
              ),
            ),
          ),
          Text(
            'Transform Yourself',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
            },
            child: Container(
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
              child: const Icon(Icons.share_outlined, color: Color(0xFF0F172A), size: 18),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 2. HERO SECTION
  // -------------------------------------------------------------
  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 0, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'A Better You,',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0F172A),
                        height: 1.1,
                      ),
                    ),
                    Text(
                      'Starts Today.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF6D28D9),
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Personalized programs, expert guidance and smart tracking to help you become the best version of yourself.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF475569),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 6,
                child: SizedBox(
                  height: 200,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        right: -10,
                        top: -10,
                        bottom: -20,
                        child: Container(
                          width: 220,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                const Color(0xFF6D28D9).withValues(alpha: 0.15),
                                Colors.transparent,
                              ],
                              radius: 0.6,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: -20,
                        bottom: -40,
                        top: 0,
                        child: Image.asset(
                          'assets/images/transform_hero.jpg',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const SizedBox(),
                        ),
                      ),
                      // Floating Icons
                      Positioned(
                        top: 20,
                        left: 0,
                        child: _buildFloatingIcon(Icons.bar_chart_rounded),
                      ),
                      Positioned(
                        bottom: 60,
                        left: -10,
                        child: _buildFloatingIcon(Icons.favorite_rounded, isSolid: true),
                      ),
                      Positioned(
                        top: 60,
                        right: 10,
                        child: _buildFloatingIcon(Icons.fitness_center_rounded),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F3FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEDE9FE)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded, color: Color(0xFF6D28D9), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'You + Consistency + Right Plan = Transformation',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF5B21B6),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "We'll guide you at every step!",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF7C3AED),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingIcon(IconData icon, {bool isSolid = false}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6D28D9).withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: const Color(0xFF7C3AED),
        size: 16,
      ),
    );
  }

  // -------------------------------------------------------------
  // 3. YOUR TRANSFORMATION PLAN SECTION
  // -------------------------------------------------------------
  Widget _buildTransformationPlanSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Transformation Plan',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 14),
          // Scrollable stats row
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              children: [
                _buildPlanStat(Icons.ads_click_rounded, 'Goal', 'Lose Fat &\nBuild Muscle', const Color(0xFFE11D48)),
                const SizedBox(width: 16),
                _buildPlanStat(Icons.calendar_month_rounded, 'Duration', '12 Weeks', const Color(0xFF8B5CF6)),
                const SizedBox(width: 16),
                _buildPlanStat(Icons.play_arrow_rounded, 'Start Date', '20 May 2026', const Color(0xFF2563EB), isCircle: true),
                const SizedBox(width: 16),
                _buildPlanStat(Icons.emoji_events_rounded, 'Target', '74 KG', const Color(0xFFD97706)),
                const SizedBox(width: 16),
                _buildPlanStat(Icons.monitor_weight_rounded, 'Current Weight', '82 KG', const Color(0xFF6D28D9)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Progress Cards Row
          Row(
            children: [
              // Progress Bar Card
              Expanded(
                flex: 6,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Progress',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            'Week 4',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            ' of 12',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '33%',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF6D28D9),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Progress Bar
                      Container(
                        height: 6,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: 0.33,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF7C3AED),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Stay consistent! You're doing great.",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Next Milestone Card
              Expanded(
                flex: 4,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.workspace_premium_rounded, color: const Color(0xFF3B82F6), size: 24),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Next Milestone',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Lose 5 KG',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: const Color(0xFF475569)),
                          children: [
                            TextSpan(
                              text: '2.1 KG ',
                              style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF6D28D9)),
                            ),
                            const TextSpan(text: 'to go', style: TextStyle(fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 4,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: 0.58, // (5-2.1)/5 = 0.58
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF6D28D9),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlanStat(IconData icon, String label, String value, Color color, {bool isCircle = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(isCircle ? 6 : 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: isCircle ? null : BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
            ),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
                height: 1.2,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // 4. KEY FOCUS AREAS SECTION
  // -------------------------------------------------------------
  Widget _buildKeyFocusAreasSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Key Focus Areas',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Text(
                'View All >',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF6D28D9),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 135,
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _focusAreas.length,
            itemBuilder: (context, index) {
              final area = _focusAreas[index];
              return Container(
                width: 115,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: area['bg'] as Color,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(area['icon'] as IconData, color: area['color'] as Color, size: 22),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      area['title'] as String,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        area['desc'] as String,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
  // 5. WHAT'S INCLUDED SECTION
  // -------------------------------------------------------------
  Widget _buildWhatsIncludedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            "What's Included in Your Plan",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0F172A),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 155,
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _whatsIncluded.length,
            itemBuilder: (context, index) {
              final item = _whatsIncluded[index];
              return Container(
                width: 140,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        image: DecorationImage(
                          image: NetworkImage(item['image'] as String),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.6),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(item['icon'] as IconData, color: const Color(0xFF16A34A), size: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item['title'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['desc'] as String,
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
            },
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // 6. YOUR TRANSFORMATION JOURNEY
  // -------------------------------------------------------------
  Widget _buildTransformationJourneySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Transformation Journey',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Text(
                'View Timeline >',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF6D28D9),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 80,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _buildJourneyStep(
                icon: Icons.check_circle_rounded,
                title: 'Start',
                subtitle: 'Week 1',
                status: 'Completed',
                color: const Color(0xFF16A34A),
                isCompleted: true,
                isCurrent: false,
              ),
              _buildJourneyDashedLine(color: const Color(0xFF22C55E)),
              _buildJourneyStep(
                icon: Icons.directions_run_rounded,
                title: 'Build Momentum',
                subtitle: 'Week 2-4',
                status: 'In Progress',
                color: const Color(0xFF7C3AED),
                isCompleted: false,
                isCurrent: true,
              ),
              _buildJourneyDashedLine(color: const Color(0xFFCBD5E1)),
              _buildJourneyStep(
                icon: Icons.visibility_rounded,
                title: 'See Changes',
                subtitle: 'Week 5-8',
                status: 'Upcoming',
                color: const Color(0xFF64748B),
                isCompleted: false,
                isCurrent: false,
              ),
              _buildJourneyDashedLine(color: const Color(0xFFCBD5E1)),
              _buildJourneyStep(
                icon: Icons.star_rounded,
                title: 'Final Transformation',
                subtitle: 'Week 9-12',
                status: 'Upcoming',
                color: const Color(0xFF64748B),
                isCompleted: false,
                isCurrent: false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildJourneyStep({
    required IconData icon,
    required String title,
    required String subtitle,
    required String status,
    required Color color,
    required bool isCompleted,
    required bool isCurrent,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(isCurrent ? 12 : 10),
          decoration: BoxDecoration(
            color: isCurrent ? color.withValues(alpha: 0.1) : (isCompleted ? color.withValues(alpha: 0.1) : Colors.white),
            shape: BoxShape.circle,
            border: Border.all(
              color: isCurrent ? color : (isCompleted ? color : const Color(0xFFE2E8F0)),
              width: isCurrent ? 1.5 : 1,
            ),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              status,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildJourneyDashedLine({required Color color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(
          5,
          (index) => Container(
            width: 4,
            height: 1.5,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            color: color,
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // 7. TRANSFORMATION INSPIRATION SECTION
  // -------------------------------------------------------------
  Widget _buildTransformationInspirationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            'Transformation Inspiration',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0F172A),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 240,
          child: PageView.builder(
            physics: const BouncingScrollPhysics(),
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentInspirationIndex = index);
            },
            itemCount: _inspirations.length + 1,
            itemBuilder: (context, index) {
              if (index == _inspirations.length) {
                // Last Card (Call to Action)
                return _buildInspirationCTACard();
              }
              final insp = _inspirations[index];
              return _buildInspirationCard(insp);
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _inspirations.length + 1,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentInspirationIndex == index ? 16 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _currentInspirationIndex == index ? const Color(0xFF6D28D9) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInspirationCard(Map<String, dynamic> insp) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
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
          // Split Image (Before / After)
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Row(
                      children: [
                        Expanded(
                          child: Image.network(
                            insp['image1'] as String,
                            fit: BoxFit.cover,
                            height: double.infinity,
                          ),
                        ),
                        Container(width: 1.5, color: Colors.white),
                        Expanded(
                          child: Image.network(
                            insp['image2'] as String,
                            fit: BoxFit.cover,
                            height: double.infinity,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Separator arrow icon in center
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Color(0xFF0F172A)),
                    ),
                  ),
                  // Result Badge
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        insp['result'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Details Bottom
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      insp['name'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      insp['duration'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  insp['quote'] as String,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.italic,
                    color: const Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInspirationCTACard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEDE9FE)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.emoji_events_rounded, color: Color(0xFF7C3AED), size: 36),
          ),
          const SizedBox(height: 16),
          Text(
            'You Could Be Next!',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Start your journey today.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
          const Spacer(),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              'Get Started',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 8. FIXED BOTTOM ACTION BAR
  // -------------------------------------------------------------
  Widget _buildFixedBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6D28D9).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.emoji_events_rounded, color: Color(0xFFFBBF24), size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Ready to Transform?',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                Text(
                  "Let's build the best version of YOU!",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Text(
                  'Start My Plan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF6D28D9),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF6D28D9), size: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
