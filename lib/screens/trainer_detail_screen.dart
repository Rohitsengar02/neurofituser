import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/staggered_slide_fade.dart';

class TrainerDetailScreen extends StatefulWidget {
  final String trainerName;
  final String specialty;
  final String rating;
  final String reviews;
  final String image;
  final String price;

  const TrainerDetailScreen({
    super.key,
    this.trainerName = 'Rohit Sharma',
    this.specialty = 'Strength & Transformation Coach',
    this.rating = '4.9',
    this.reviews = '2.4K Reviews',
    this.image = 'https://images.unsplash.com/photo-1567013127542-490d757e51fc?w=600&auto=format&fit=crop&q=80',
    this.price = '₹3,999',
  });

  @override
  State<TrainerDetailScreen> createState() => _TrainerDetailScreenState();
}

class _TrainerDetailScreenState extends State<TrainerDetailScreen> {
  int _selectedNavTab = 0;
  bool _isFavorite = false;
  bool _isBioExpanded = false;
  bool _isLoadingTab = false;
  int _selectedPlanIndex = 1; // Standard Plan by default

  void _onTabTapped(int index) async {
    if (_selectedNavTab == index) return;
    HapticFeedback.selectionClick();
    setState(() {
      _selectedNavTab = index;
      _isLoadingTab = true;
    });
    
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() {
        _isLoadingTab = false;
      });
    }
  }

  final List<String> _navTabs = [
    'About',
    'Plans & Pricing',
    'What You Get',
    'Reviews',
    'Achievements',
  ];

  final List<Map<String, dynamic>> _specializations = [
    {
      'title': 'Fat Loss',
      'desc': 'Lose weight &\nburn fat',
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
      'title': 'Body Transformation',
      'desc': 'Complete physique\ntransformation',
      'icon': Icons.accessibility_new_rounded,
      'color': const Color(0xFF16A34A),
      'bg': const Color(0xFFDCFCE7),
    },
    {
      'title': 'Strength Training',
      'desc': 'Improve strength\n& performance',
      'icon': Icons.sports_gymnastics_rounded,
      'color': const Color(0xFF2563EB),
      'bg': const Color(0xFFDBEAFE),
    },
    {
      'title': 'Nutrition Coaching',
      'desc': 'Personalized diet\n& meal plans',
      'icon': Icons.eco_rounded,
      'color': const Color(0xFFDB2777),
      'bg': const Color(0xFFFCE7F3),
    },
  ];

  final List<Map<String, dynamic>> _pricingPlans = [
    {
      'name': 'Basic Plan',
      'subtitle': 'Perfect for getting started',
      'price': '₹1,999',
      'isPopular': false,
      'features': [
        'Personalized Workout Plan',
        'Diet Plan (Basic)',
        'Weekly Progress Check',
        'Chat Support',
      ],
    },
    {
      'name': 'Standard Plan',
      'subtitle': 'Your complete transformation companion',
      'price': '₹3,999',
      'isPopular': true,
      'features': [
        'Personalized Workout Plan',
        'Diet Plan (Advanced)',
        'Weekly Check-ins',
        'Form Analysis',
        '24/7 Chat Support',
      ],
    },
    {
      'name': 'Premium Plan',
      'subtitle': 'Maximum results, 1-on-1 coaching',
      'price': '₹7,999',
      'isPopular': false,
      'features': [
        'Everything in Standard',
        '1-on-1 Video Calls',
        'Custom Supplement Guide',
        'Priority Support',
        'Monthly Body Analysis',
      ],
    },
  ];

  final List<Map<String, dynamic>> _whatYouGet = [
    {'title': 'Personalized\nWorkouts', 'icon': Icons.fitness_center_rounded, 'color': const Color(0xFF16A34A), 'bg': const Color(0xFFDCFCE7)},
    {'title': 'Custom\nNutrition Plan', 'icon': Icons.lunch_dining_rounded, 'color': const Color(0xFF16A34A), 'bg': const Color(0xFFDCFCE7)},
    {'title': 'Progress\nTracking', 'icon': Icons.trending_up_rounded, 'color': const Color(0xFF16A34A), 'bg': const Color(0xFFDCFCE7)},
    {'title': 'Habit\nGuidance', 'icon': Icons.track_changes_rounded, 'color': const Color(0xFFE11D48), 'bg': const Color(0xFFFFE4E6)},
    {'title': 'Ongoing\nSupport', 'icon': Icons.headset_mic_rounded, 'color': const Color(0xFF16A34A), 'bg': const Color(0xFFDCFCE7)},
  ];

  void _showBookingSheet() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: NetworkImage(widget.image),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Book Consultation with ${widget.trainerName}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Free 30-min Video Call Session',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Available Slots: Today 5:00 PM', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700)),
                    const Icon(Icons.calendar_month_rounded, color: Color(0xFF16A34A), size: 18),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Free consultation booked with ${widget.trainerName}! Check your calendar. 🎉',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                      ),
                      backgroundColor: const Color(0xFF16A34A),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Confirm Free Booking',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFD),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Scrollable Content
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 100), // Space for fixed bottom bar
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  // 1. Top Navigation Bar
                  StaggeredSlideFade(
                    index: 0,
                    child: _buildTopBar(),
                  ),

                  const SizedBox(height: 16),

                  // 2. Hero Trainer Profile Card
                  StaggeredSlideFade(
                    index: 1,
                    child: _buildHeroProfileCard(),
                  ),

                  const SizedBox(height: 14),

                  // 3. Bio Paragraph with Read More
                  StaggeredSlideFade(
                    index: 2,
                    child: _buildBioText(),
                  ),

                  const SizedBox(height: 16),

                  // 4. Horizontal Nav Tabs
                  StaggeredSlideFade(
                    index: 3,
                    child: _buildNavTabs(),
                  ),

                  const SizedBox(height: 20),

                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _buildDynamicTabContent(),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),

            // Fixed Bottom Action Bar (Chat + Book)
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
            'Trainers',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),

          Row(
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _isFavorite = !_isFavorite);
                },
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Icon(
                    _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: _isFavorite ? const Color(0xFFEF4444) : const Color(0xFF0F172A),
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Icon(Icons.share_outlined, color: Color(0xFF0F172A), size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 2. HERO TRAINER PROFILE CARD
  // -------------------------------------------------------------
  Widget _buildHeroProfileCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Photo with Watch Intro pill
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.network(
                        widget.image,
                        width: 125,
                        height: 165,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      left: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 12),
                            const SizedBox(width: 2),
                            Text(
                              'Watch Intro',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 14),

                // Right Profile Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified_user_rounded, color: Color(0xFF16A34A), size: 11),
                            const SizedBox(width: 3),
                            Text(
                              'Certified Trainer',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF16A34A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              widget.trainerName,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 16),
                        ],
                      ),
                      Text(
                        widget.specialty,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // Rating & Experience
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 14),
                          const SizedBox(width: 2),
                          Text(
                            widget.rating,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            ' (${widget.reviews})',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(width: 1, height: 10, color: const Color(0xFFCBD5E1)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '5+ Years Experience',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF475569),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      _buildCredentialRow(Icons.visibility_outlined, 'NASM Certified'),
                      const SizedBox(height: 3),
                      _buildCredentialRow(Icons.apple_rounded, 'Nutrition Specialist'),
                      const SizedBox(height: 3),
                      _buildCredentialRow(Icons.fitness_center_rounded, "Men's Physique Expert"),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 12),

            // Bottom 3 Metrics Capsule (Clients, Transformations, Rating)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildHeroStat(Icons.people_alt_rounded, '1,284+', 'Clients', const Color(0xFF16A34A)),
                Container(width: 1, height: 28, color: const Color(0xFFF1F5F9)),
                _buildHeroStat(Icons.emoji_events_rounded, '320+', 'Transformations', const Color(0xFF16A34A)),
                Container(width: 1, height: 28, color: const Color(0xFFF1F5F9)),
                _buildHeroStat(Icons.star_rounded, '4.9/5', 'Rating', const Color(0xFF16A34A)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCredentialRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 12, color: const Color(0xFF64748B)),
        const SizedBox(width: 5),
        Text(
          text,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF475569),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroStat(IconData icon, String value, String label, Color iconColor) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 16),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
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
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // 3. BIO TEXT
  // -------------------------------------------------------------
  Widget _buildBioText() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isBioExpanded
                ? 'I help busy professionals build lean muscle, lose fat and develop a lifestyle that lasts forever. Training should be simple, effective and enjoyable! Every plan is scientifically customized based on your body type, metabolism, and daily schedule.'
                : 'I help busy professionals build lean muscle, lose fat and develop a lifestyle that lasts forever. Training should be simple, effective and enjoyable!',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF475569),
              height: 1.35,
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _isBioExpanded = !_isBioExpanded),
            child: Text(
              _isBioExpanded ? 'Show Less' : '... Read More',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF16A34A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 4. NAV TABS
  // -------------------------------------------------------------
  Widget _buildNavTabs() {
    return SizedBox(
      height: 36,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _navTabs.length,
        itemBuilder: (context, index) {
          final bool isSelected = _selectedNavTab == index;
          return GestureDetector(
            onTap: () => _onTabTapped(index),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFDCFCE7) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Text(
                _navTabs[index],
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // -------------------------------------------------------------
  // 5. ABOUT ME & COLLAGE GALLERY SECTION
  // -------------------------------------------------------------
  Widget _buildAboutMeSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About Me',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Description & Bullet Points
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "I'm passionate about helping people become the strongest version of themselves. My approach is 100% personalized and based on science-backed training & nutrition.",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF475569),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildAboutBullet('Specialization', 'Fat Loss, Muscle Gain, Body Transformation'),
                    _buildAboutBullet('Experience', '5+ Years'),
                    _buildAboutBullet('Clients Transformed', '320+'),
                    _buildAboutBullet('Availability', 'Online Coaching'),
                    _buildAboutBullet('Languages', 'English, Hindi'),
                  ],
                ),
              ),

              const SizedBox(width: 14),

              // Right Photo Collage (1 Large + 2 Stacked)
              SizedBox(
                width: 140,
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        'https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?w=400&auto=format&fit=crop&q=80',
                        height: 110,
                        width: 140,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=200&auto=format&fit=crop&q=80',
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              widget.image,
                              height: 60,
                              fit: BoxFit.cover,
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

          const SizedBox(height: 14),

          // Response Time Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.schedule_rounded, color: Color(0xFF16A34A), size: 16),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Response Time',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF16A34A),
                      ),
                    ),
                    Text(
                      'Usually replies in 2 hrs',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
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
  }

  Widget _buildAboutBullet(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 5),
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: Color(0xFF16A34A),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: const Color(0xFF475569)),
                children: [
                  TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                  TextSpan(text: value, style: const TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 6. MY SPECIALIZATIONS SECTION
  // -------------------------------------------------------------
  Widget _buildSpecializationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            'My Specializations',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0F172A),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _specializations.length,
            itemBuilder: (context, index) {
              final s = _specializations[index];
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
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: s['bg'] as Color,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(s['icon'] as IconData, color: s['color'] as Color, size: 20),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      s['title'] as String,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s['desc'] as String,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF94A3B8),
                        height: 1.1,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
  // 7. PLANS & PRICING SECTION
  // -------------------------------------------------------------
  Widget _buildPlansAndPricingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            'Plans & Pricing',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0F172A),
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 275,
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _pricingPlans.length,
            itemBuilder: (context, index) {
              final plan = _pricingPlans[index];
              final bool isPopular = plan['isPopular'] as bool;
              final bool isSelected = _selectedPlanIndex == index;

              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedPlanIndex = index);
                },
                child: Container(
                  width: 215,
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isPopular ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0),
                      width: isPopular ? 1.8 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isPopular
                            ? const Color(0xFF16A34A).withValues(alpha: 0.12)
                            : const Color(0xFF0F172A).withValues(alpha: 0.04),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Popular Ribbon Badge
                      if (isPopular)
                        Positioned(
                          top: -10,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF16A34A),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Most Popular',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),

                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  plan['name'] as String,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  plan['subtitle'] as String,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      plan['price'] as String,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 19,
                                        fontWeight: FontWeight.w900,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                    Text(
                                      ' /month',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ...(plan['features'] as List<String>).map(
                                  (f) => Padding(
                                    padding: const EdgeInsets.only(bottom: 5.0),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 12),
                                        const SizedBox(width: 5),
                                        Expanded(
                                          child: Text(
                                            f,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF475569),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // Choose Plan Button
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: isPopular ? const Color(0xFF16A34A) : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: isPopular ? null : Border.all(color: const Color(0xFF16A34A)),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Choose Plan',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: isPopular ? Colors.white : const Color(0xFF16A34A),
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
            },
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // 8. WHAT YOU GET SECTION
  // -------------------------------------------------------------
  Widget _buildWhatYouGetSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            'What You Get',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0F172A),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 70,
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _whatYouGet.length,
            itemBuilder: (context, index) {
              final w = _whatYouGet[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: w['bg'] as Color,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(w['icon'] as IconData, color: w['color'] as Color, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      w['title'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
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
  // 9. FIXED BOTTOM ACTION BAR (Chat + Book)
  // -------------------------------------------------------------
  Widget _buildFixedBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Chat with Trainer
          Expanded(
            flex: 4,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Opening direct chat with ${widget.trainerName}...',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                    ),
                    backgroundColor: const Color(0xFF0F172A),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.chat_outlined, color: Color(0xFF0F172A), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Chat with Trainer',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Book Free Consultation Button
          Expanded(
            flex: 5,
            child: GestureDetector(
              onTap: _showBookingSheet,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF16A34A).withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'Book Free Consultation',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '30 min call',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicTabContent() {
    if (_isLoadingTab) {
      return _buildSkeletonLoader();
    }

    switch (_selectedNavTab) {
      case 0: // About
        return Column(
          key: const ValueKey('tab_0'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StaggeredSlideFade(index: 4, child: _buildAboutMeSection()),
            const SizedBox(height: 24),
            StaggeredSlideFade(index: 5, child: _buildSpecializationsSection()),
          ],
        );
      case 1: // Plans & Pricing
        return Column(
          key: const ValueKey('tab_1'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StaggeredSlideFade(index: 4, child: _buildPlansAndPricingSection()),
            const SizedBox(height: 24),
            StaggeredSlideFade(index: 5, child: _buildWhatYouGetSection()),
          ],
        );
      case 2: // What You Get
        return Container(
          key: const ValueKey('tab_2'),
          child: StaggeredSlideFade(index: 4, child: _buildWhatYouGetSection()),
        );
      case 3: // Reviews
        return _buildEmptyState(
          key: const ValueKey('tab_3'),
          title: 'No Reviews Yet',
          subtitle: 'Be the first to review Rohit Sharma!',
        );
      case 4: // Achievements
        return _buildEmptyState(
          key: const ValueKey('tab_4'),
          title: 'Achievements',
          subtitle: 'Achievements will be displayed here.',
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildSkeletonLoader() {
    return Padding(
      key: const ValueKey('skeleton'),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSkeletonContainer(width: 120, height: 24),
          const SizedBox(height: 16),
          _buildSkeletonContainer(width: double.infinity, height: 16),
          const SizedBox(height: 8),
          _buildSkeletonContainer(width: double.infinity, height: 16),
          const SizedBox(height: 8),
          _buildSkeletonContainer(width: 200, height: 16),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildSkeletonContainer(height: 120)),
              const SizedBox(width: 16),
              Expanded(child: _buildSkeletonContainer(height: 120)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonContainer({double? width, double? height}) {
    return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
    );
  }

  Widget _buildEmptyState({required Key key, required String title, required String subtitle}) {
    return StaggeredSlideFade(
      key: key,
      index: 4,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Column(
          children: [
            const Icon(Icons.hourglass_empty_rounded, color: Color(0xFF94A3B8), size: 48),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }
}
