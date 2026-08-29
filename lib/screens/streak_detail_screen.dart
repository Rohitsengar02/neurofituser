import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class StreakDetailScreen extends StatefulWidget {
  const StreakDetailScreen({super.key});

  @override
  State<StreakDetailScreen> createState() => _StreakDetailScreenState();
}

class _StreakDetailScreenState extends State<StreakDetailScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  int _selectedDayIndex = 5; // Saturday (Today)

  final List<Map<String, dynamic>> _weekDays = [
    {'day': 'Mon', 'date': '19', 'status': 'done'},
    {'day': 'Tue', 'date': '20', 'status': 'done'},
    {'day': 'Wed', 'date': '21', 'status': 'done'},
    {'day': 'Thu', 'date': '22', 'status': 'done'},
    {'day': 'Fri', 'date': '23', 'status': 'done'},
    {'day': 'Sat', 'date': '24', 'status': 'today'},
    {'day': 'Sun', 'date': '25', 'status': 'upcoming'},
  ];

  final List<Map<String, dynamic>> _milestones = [
    {'days': 3, 'label': 'Keep Going!', 'done': true, 'icon': Icons.local_fire_department_rounded},
    {'days': 7, 'label': 'Getting Stronger!', 'done': true, 'icon': Icons.local_fire_department_rounded},
    {'days': 14, 'label': 'On Fire!', 'done': true, 'icon': Icons.shield_rounded},
    {'days': 30, 'label': 'Unstoppable!', 'done': false, 'icon': Icons.lock_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'My Streak',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(width: 6),
            const Text('🔥', style: TextStyle(fontSize: 18)),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.info_outline_rounded, color: Color(0xFF64748B), size: 18),
            ),
            onPressed: () => _showStreakInfoDialog(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. HERO STREAK CARD
            _buildHeroStreakCard(),

            const SizedBox(height: 18),

            // 2. CALENDAR WEEKLY TRACKER
            _buildCalendarTrackerCard(),

            const SizedBox(height: 18),

            // 3. STREAK MILESTONES
            _buildStreakMilestonesCard(),

            const SizedBox(height: 18),

            // 4. STREAK REWARDS
            _buildStreakRewardsCard(),

            const SizedBox(height: 18),

            // 5. STREAK STATS (3 COLUMNS)
            _buildStreakStatsCard(),

            const SizedBox(height: 18),

            // 6. MOTIVATIONAL QUOTE BANNER
            _buildMotivationalQuoteCard(),

            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // 1. HERO STREAK CARD (LIGHT THEME WITH NEON GREEN & FLAME GLOW)
  // -------------------------------------------------------------
  Widget _buildHeroStreakCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Color(0xFFF0FDF4),
            Color(0xFFDCFCE7),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFBBF7D0), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF16A34A).withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background ambient circles
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF16A34A).withValues(alpha: 0.08),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(18.0),
            child: Row(
              children: [
                // Glowing Circular Progress Ring with Flame
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final glow = _pulseController.value * 8.0;

                    return Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF16A34A).withValues(alpha: 0.25),
                            blurRadius: 12 + glow,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 88,
                            height: 88,
                            child: CircularProgressIndicator(
                              value: 12 / 30, // 12 of 30 days
                              strokeWidth: 6.5,
                              strokeCap: StrokeCap.round,
                              backgroundColor: const Color(0xFFF1F5F9),
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF16A34A)),
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('🔥', style: TextStyle(fontSize: 18)),
                              Text(
                                '12',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF0F172A),
                                  height: 1.0,
                                ),
                              ),
                              Text(
                                'Days',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(width: 16),

                // Text & Badge Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            "You're on fire!",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF0F172A),
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text('🔥', style: TextStyle(fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Keep going, consistency is your superpower.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF475569),
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFDE68A), width: 1.0),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🏆', style: TextStyle(fontSize: 12)),
                            const SizedBox(width: 4),
                            Text(
                              'Best Streak: 21 Days',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFFB45309),
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
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 2. CALENDAR WEEKLY TRACKER
  // -------------------------------------------------------------
  Widget _buildCalendarTrackerCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Month Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'May 2025',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.chevron_left_rounded, size: 22, color: Color(0xFF64748B)),
                    onPressed: () => HapticFeedback.selectionClick(),
                  ),
                  const SizedBox(width: 14),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.chevron_right_rounded, size: 22, color: Color(0xFF64748B)),
                    onPressed: () => HapticFeedback.selectionClick(),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 7 Day Strip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_weekDays.length, (index) {
              final item = _weekDays[index];
              final isDone = item['status'] == 'done';
              final isToday = item['status'] == 'today';
              final isSelected = _selectedDayIndex == index;

              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedDayIndex = index);
                },
                child: Column(
                  children: [
                    Text(
                      item['day']!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isToday ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Status Circle Button
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDone
                            ? const Color(0xFF16A34A)
                            : isToday
                                ? const Color(0xFFF97316)
                                : const Color(0xFFF1F5F9),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF0F172A)
                              : Colors.transparent,
                          width: 2.0,
                        ),
                        boxShadow: isDone || isToday
                            ? [
                                BoxShadow(
                                  color: (isDone ? const Color(0xFF16A34A) : const Color(0xFFF97316))
                                      .withValues(alpha: 0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: isDone
                            ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                            : isToday
                                ? const Text('🔥', style: TextStyle(fontSize: 18))
                                : const Icon(Icons.remove_rounded, color: Color(0xFF94A3B8), size: 16),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item['date']!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: isToday ? FontWeight.w900 : FontWeight.w700,
                        color: isToday ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),

          const SizedBox(height: 14),

          // Consecutive text
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFDCFCE7), width: 1.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '12 days in a row! ',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF16A34A),
                  ),
                ),
                Text(
                  'Amazing! 🎉',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
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

  // -------------------------------------------------------------
  // 3. STREAK MILESTONES (STEPPER TIMELINE)
  // -------------------------------------------------------------
  Widget _buildStreakMilestonesCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Streak Milestones',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                ),
              ),
              GestureDetector(
                onTap: () => HapticFeedback.selectionClick(),
                child: Text(
                  'View All',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF16A34A),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Stepper Items
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(_milestones.length, (index) {
              final m = _milestones[index];
              final isDone = m['done'] as bool;
              final isLast = index == _milestones.length - 1;

              return Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Left connecting line
                        Expanded(
                          child: Container(
                            height: 2.5,
                            color: index == 0
                                ? Colors.transparent
                                : (isDone ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0)),
                          ),
                        ),

                        // Milestone Circle
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDone ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                            border: Border.all(
                              color: isDone ? const Color(0xFF16A34A) : const Color(0xFFCBD5E1),
                              width: 1.8,
                            ),
                            boxShadow: isDone
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF16A34A).withValues(alpha: 0.25),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                m['icon'] as IconData,
                                color: isDone ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                                size: 20,
                              ),
                              if (isDone)
                                Positioned(
                                  bottom: 2,
                                  right: 2,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF16A34A),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.check_rounded, size: 8, color: Colors.white),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Right connecting line
                        Expanded(
                          child: Container(
                            height: 2.5,
                            color: isLast
                                ? Colors.transparent
                                : (_milestones[index + 1]['done'] as bool
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFFE2E8F0)),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Days label
                    Text(
                      '${m['days']} Days',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      m['label'] as String,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: isDone ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 4. STREAK REWARDS
  // -------------------------------------------------------------
  Widget _buildStreakRewardsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Streak Rewards',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '12/30 Days',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF16A34A),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Reward Banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
            ),
            child: Row(
              children: [
                // Shaker Icon with Glow
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF86EFAC), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF16A34A).withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('🥤', style: TextStyle(fontSize: 26)),
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '30 Days Streak Reward',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Stay consistent for 30 days and unlock premium rewards',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFDE68A), width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.lock_outline_rounded, size: 12, color: Color(0xFFB45309)),
                            const SizedBox(width: 4),
                            Text(
                              '18 Days to go',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFFB45309),
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
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 5. STREAK STATS (3 COLUMNS)
  // -------------------------------------------------------------
  Widget _buildStreakStatsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Streak Stats',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0F172A),
            ),
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              // Stat 1: Current Streak
              Expanded(
                child: _buildStatItem(
                  icon: Icons.calendar_today_rounded,
                  iconColor: const Color(0xFF16A34A),
                  bgColor: const Color(0xFFDCFCE7),
                  value: '12',
                  label: 'Current Streak',
                ),
              ),
              const SizedBox(width: 10),

              // Stat 2: Best Streak
              Expanded(
                child: _buildStatItem(
                  icon: Icons.emoji_events_rounded,
                  iconColor: const Color(0xFFD97706),
                  bgColor: const Color(0xFFFEF3C7),
                  value: '21',
                  label: 'Best Streak',
                ),
              ),
              const SizedBox(width: 10),

              // Stat 3: Total Workouts
              Expanded(
                child: _buildStatItem(
                  icon: Icons.star_rounded,
                  iconColor: const Color(0xFF2563EB),
                  bgColor: const Color(0xFFDBEAFE),
                  value: '36',
                  label: 'Total Workouts',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 6. MOTIVATIONAL QUOTE BANNER
  // -------------------------------------------------------------
  Widget _buildMotivationalQuoteCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1E293B),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.15),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF16A34A).withValues(alpha: 0.25),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF16A34A), width: 1.2),
            ),
            child: const Icon(Icons.format_quote_rounded, color: Color(0xFF4ADE80), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '“Discipline today, strength tomorrow.”',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      'Keep showing up! ',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                    const Text('💪', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showStreakInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Text('🔥', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Text(
              'How Streaks Work',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w900,
                fontSize: 17,
              ),
            ),
          ],
        ),
        content: Text(
          'Complete at least one workout or reach your daily step goal to keep your streak alive. Reach 30 days to unlock exclusive fitness gear rewards!',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: const Color(0xFF475569),
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Got it',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF16A34A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
