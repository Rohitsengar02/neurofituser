import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/questionnaire/ruler_picker.dart';
import '../widgets/questionnaire/weight_scale_graphic.dart';
import '../widgets/questionnaire/vertical_ruler_picker.dart';
import '../widgets/questionnaire/height_body_graphic.dart';
import '../widgets/questionnaire/animated_goal_icon.dart';
import 'plan_generation_screen.dart';

class QuestionnaireScreen extends StatefulWidget {
  const QuestionnaireScreen({super.key});

  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0; // 0 to 7 (corresponding to 1/8 to 8/8)

  // State values
  String _selectedGender = 'Male';
  int _selectedAge = 25;
  double _currentWeight = 70.0;
  double _targetWeight = 60.0;
  double _height = 170.0;
  String _heightUnit = 'cm'; // 'cm', 'ft', 'm'
  String _selectedGoal = 'Lose Weight';
  Set<String> _selectedGoals = {'Lose Weight'};
  String _selectedActivity = 'Moderately Active';

  void _nextPage() {
    HapticFeedback.lightImpact();
    if (_currentStep < 7) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    } else {
      // Completed Flow -> Open Cinematic AI Plan Generation Screen
      _showCompletionDialog();
    }
  }

  void _previousPage() {
    HapticFeedback.lightImpact();
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  void _showCompletionDialog() {
    HapticFeedback.heavyImpact();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => PlanGenerationScreen(
          gender: _selectedGender,
          age: _selectedAge,
          currentWeight: _currentWeight,
          targetWeight: _targetWeight,
          height: _height,
          goals: _selectedGoals.toList(),
          activityLevel: _selectedActivity,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar: Back Button, Step indicator & Segmented Progress
            _buildTopBar(),

            // Swipable / Animated Content Area
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // Only navigate through button/back
                onPageChanged: (index) {
                  setState(() {
                    _currentStep = index;
                  });
                },
                children: [
                  _buildStep1(),
                  _buildStep2(),
                  _buildStep3(),
                  _buildStep4(),
                  _buildStep5(),
                  _buildStep6(),
                  _buildStep7(),
                  _buildStep8(),
                ],
              ),
            ),

            // Bottom Navigation Button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: _buildBottomButton(),
            ),
          ],
        ),
      ),
    );
  }

  // Dynamic curated colors per step
  static const List<Color> _stepColors = [
    Color(0xFF22C55E), // Step 1: Welcome (Vivid Neon Green)
    Color(0xFF3B82F6), // Step 2: Gender (Cyber Electric Blue)
    Color(0xFF8B5CF6), // Step 3: Age (Royal Purple)
    Color(0xFF06B6D4), // Step 4: Current Weight (Cyan)
    Color(0xFF10B981), // Step 5: Target Weight (Emerald)
    Color(0xFF14B8A6), // Step 6: Height (Teal Green)
    Color(0xFFF59E0B), // Step 7: Goal (Amber Gold)
    Color(0xFFF97316), // Step 8: Activity (Neon Orange)
  ];

  // -------------------------------------------------------------
  // TOP BAR
  // -------------------------------------------------------------
  Widget _buildTopBar() {
    final currentColor = _stepColors[_currentStep % _stepColors.length];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Circular Back Button
              GestureDetector(
                onTap: _previousPage,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: Color(0xFF141518),
                    size: 20,
                  ),
                ),
              ),

              // Animated Step Counter Pill with Step Color Accent
              AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: currentColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: currentColor.withValues(alpha: 0.30),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: currentColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: currentColor.withValues(alpha: 0.8),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: Text(
                        'STEP ${_currentStep + 1} / 8',
                        key: ValueKey<int>(_currentStep),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: currentColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 38), // Balance the back button
            ],
          ),
          const SizedBox(height: 12),

          // 8 Segmented Progress Indicators with Animated Colors & Glowing Active Track
          Row(
            children: List.generate(8, (index) {
              final isPassed = index < _currentStep;
              final isCurrent = index == _currentStep;
              final segColor = _stepColors[index];

              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                  height: isCurrent ? 5.5 : 4.0,
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  decoration: BoxDecoration(
                    color: isPassed
                        ? segColor
                        : (isCurrent ? currentColor : const Color(0xFFE2E8F0)),
                    gradient: (isPassed || isCurrent)
                        ? LinearGradient(
                            colors: [
                              segColor,
                              segColor.withValues(alpha: isCurrent ? 0.85 : 0.95),
                            ],
                          )
                        : null,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: isCurrent
                        ? [
                            BoxShadow(
                              color: currentColor.withValues(alpha: 0.5),
                              blurRadius: 8,
                              spreadRadius: 0.5,
                              offset: const Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // STEP 1: Let's Get Started!
  // -------------------------------------------------------------
  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Edge-to-Edge Hero Image without shadow, and top/bottom white linear gradients
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/images/questionnaire_hero.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: const Color(0xFFF3F4F6),
                  child: const Icon(
                    Icons.fitness_center_rounded,
                    size: 64,
                    color: Color(0xFF16A34A),
                  ),
                ),
              ),
              // Top White Linear Gradient
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 60,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white,
                        Color(0xB3FFFFFF),
                        Color(0x00FFFFFF),
                      ],
                      stops: [0.0, 0.4, 1.0],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              // Bottom White Linear Gradient
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 70,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0x00FFFFFF),
                        Color(0xB3FFFFFF),
                        Colors.white,
                      ],
                      stops: [0.0, 0.5, 1.0],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Bottom Left-Aligned Staggered Animated Text matching Onboarding Screen 1
        const Padding(
          padding: EdgeInsets.fromLTRB(24.0, 14.0, 24.0, 10.0),
          child: _Step1StaggeredText(),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // STEP 2: What's your gender?
  // -------------------------------------------------------------
  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildGenderCard(
                          title: 'Male',
                          symbol: '♂',
                          symbolColor: const Color(0xFF16A34A),
                          isSelected: _selectedGender == 'Male',
                          index: 0,
                          onTap: () {
                            setState(() => _selectedGender = 'Male');
                            Future.delayed(
                              const Duration(milliseconds: 400),
                              _nextPage,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildGenderCard(
                          title: 'Female',
                          symbol: '♀',
                          symbolColor: const Color(0xFF94A3B8),
                          isSelected: _selectedGender == 'Female',
                          index: 1,
                          onTap: () {
                            setState(() => _selectedGender = 'Female');
                            Future.delayed(
                              const Duration(milliseconds: 400),
                              _nextPage,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: _buildGenderCard(
                      title: 'Other',
                      symbol: '⚧',
                      symbolColor: const Color(0xFFF59E0B),
                      isSelected: _selectedGender == 'Other',
                      index: 2,
                      onTap: () {
                        setState(() => _selectedGender = 'Other');
                        Future.delayed(
                          const Duration(milliseconds: 400),
                          _nextPage,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Bottom Left-Aligned Staggered Animated Text
        const Padding(
          padding: EdgeInsets.fromLTRB(24.0, 14.0, 24.0, 10.0),
          child: _Step2StaggeredText(),
        ),
      ],
    );
  }

  Widget _buildGenderCard({
    required String title,
    required String symbol,
    required Color symbolColor,
    required bool isSelected,
    required VoidCallback onTap,
    required int index,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 700),
      curve: Interval(index * 0.15, 1.0, curve: Curves.easeOutCubic),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 40 * (1 - value)),
          child: Opacity(opacity: math.max(0.001, value), child: child),
        );
      },
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          height: 160,
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFF0FDF4)
                : const Color(0xFFFAFAFB),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF16A34A)
                  : const Color(0xFFF1F3F5),
              width: isSelected ? 2.0 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? const Color(0xFF16A34A).withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.02),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                symbol,
                style: TextStyle(
                  fontSize: 54,
                  fontWeight: FontWeight.w900,
                  color: isSelected ? const Color(0xFF16A34A) : symbolColor,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? const Color(0xFF141518)
                      : const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // STEP 3: How old are you?
  // -------------------------------------------------------------
  Widget _buildStep3() {
    final int yearsLeft = math.max(0, 85 - _selectedAge);
    final int bonusYears = 5; // Example constant

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 24),
                
                // Top Center Big Number (Years Spent)
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.0, -0.5),
                        end: Offset.zero,
                      ).animate(animation),
                      child: FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                    );
                  },
                  child: Text(
                    _selectedAge.toString(),
                    key: ValueKey<int>(_selectedAge),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 84,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF3B82F6), // Blue
                      letterSpacing: -2.0,
                      height: 1.0,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'years old',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                
                const SizedBox(height: 48),

                // Cards row (Remaining / Bonus) just above ruler with Staggered Animation
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      // Card 1: Remaining
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF94A3B8).withValues(alpha: 0.15),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.hourglass_bottom_rounded, size: 20, color: Color(0xFF64748B)),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Remaining',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: Text(
                                  '$yearsLeft yrs',
                                  key: ValueKey<int>(yearsLeft),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Card 2: Fitness Bonus
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)], // Light Blue Gradient
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.health_and_safety_rounded, size: 20, color: Color(0xFF3B82F6)),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Fitness Bonus',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF3B82F6),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '+$bonusYears yrs',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF1D4ED8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 64),

                // Horizontal Ruler for Age moved to bottom, just above title
                RulerPicker(
                  minValue: 14.0,
                  maxValue: 90.0,
                  initialValue: _selectedAge.toDouble(),
                  step: 1.0,
                  tickSpacing: 42.0, // Wider spacing so numbers like 1, 2, 3 don't overlap
                  unit: 'years',
                  pointerColor: const Color(0xFF3B82F6), // Blue Theme
                  onChanged: (val) {
                    setState(() {
                      _selectedAge = val.toInt();
                    });
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),

        // Bottom Left-Aligned Staggered Animated Text
        const Padding(
          padding: EdgeInsets.fromLTRB(24.0, 14.0, 24.0, 10.0),
          child: _Step3StaggeredText(),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // STEP 4: What's your current weight?
  // -------------------------------------------------------------
  Widget _buildStep4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Weight Scale Graphic
              Center(child: WeightScaleGraphic(weight: _currentWeight)),
              const SizedBox(height: 48),

              // Horizontal Ruler
              RulerPicker(
                minValue: 40.0,
                maxValue: 140.0,
                initialValue: _currentWeight,
                step: 0.5,
                tickSpacing: 42.0,
                unit: 'kg',
                pointerColor: const Color(0xFF3B82F6), // Blue Theme
                onChanged: (val) {
                  setState(() {
                    _currentWeight = val;
                  });
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),

        // Bottom Left-Aligned Staggered Animated Text
        const Padding(
          padding: EdgeInsets.fromLTRB(24.0, 14.0, 24.0, 10.0),
          child: _Step4StaggeredText(),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // STEP 5: What's your target weight?
  // -------------------------------------------------------------
  Widget _buildStep5() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Weight Scale Graphic
              Center(
                child: WeightScaleGraphic(
                  weight: _targetWeight,
                  isNeonGreen: true, // Neon Green Theme
                ),
              ),
              const SizedBox(height: 48),

              // Horizontal Ruler
              RulerPicker(
                minValue: 40.0,
                maxValue: 140.0,
                initialValue: _targetWeight,
                step: 0.5,
                tickSpacing: 42.0,
                unit: 'kg',
                pointerColor: const Color(0xFF22C55E), // Neon Green Theme
                onChanged: (val) {
                  setState(() {
                    _targetWeight = val;
                  });
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),

        // Bottom Left-Aligned Staggered Animated Text
        const Padding(
          padding: EdgeInsets.fromLTRB(24.0, 14.0, 24.0, 10.0),
          child: _Step5StaggeredText(),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // STEP 6: What's your height?
  // -------------------------------------------------------------
  Widget _buildStep6() {
    // Current display value and limits depending on selected unit
    double minValue = 120.0;
    double maxValue = 230.0;
    double step = 1.0;
    double rulerValue = _height;

    if (_heightUnit == 'm') {
      minValue = 1.20;
      maxValue = 2.30;
      step = 0.01;
      rulerValue = (_height / 100.0);
    } else if (_heightUnit == 'ft') {
      minValue = 4.0;
      maxValue = 7.5;
      step = 0.1;
      rulerValue = (_height / 30.48);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Top Unit Selector Bar (cm, feet, meter)
        Padding(
          padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 4.0, bottom: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildUnitOption('cm', 'cm'),
                    _buildUnitOption('ft', 'feet'),
                    _buildUnitOption('m', 'meter'),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 2. Middle Area: Body Graphic (Left) & Vertical Ruler (Right, 0 right padding)
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left: Interactive Growing Body Graphic
              Expanded(
                child: HeightBodyGraphic(
                  heightCm: _height,
                  minHeightCm: 120.0,
                  maxHeightCm: 230.0,
                  activeUnit: _heightUnit,
                  themeColor: const Color(0xFF22C55E),
                ),
              ),

              // Right: Vertical Ruler (attached to right screen edge)
              VerticalRulerPicker(
                minValue: minValue,
                maxValue: maxValue,
                initialValue: rulerValue,
                step: step,
                unit: _heightUnit,
                pointerColor: const Color(0xFF22C55E),
                tickSpacing: 16.0,
                onChanged: (val) {
                  setState(() {
                    if (_heightUnit == 'm') {
                      _height = (val * 100.0).clamp(120.0, 230.0);
                    } else if (_heightUnit == 'ft') {
                      _height = (val * 30.48).clamp(120.0, 230.0);
                    } else {
                      _height = val.clamp(120.0, 230.0);
                    }
                  });
                },
              ),
            ],
          ),
        ),

        // 3. Bottom Left-Aligned Staggered Animated Text
        const Padding(
          padding: EdgeInsets.fromLTRB(24.0, 14.0, 24.0, 10.0),
          child: _Step6StaggeredText(),
        ),
      ],
    );
  }

  Widget _buildUnitOption(String unitKey, String label) {
    final isSelected = _heightUnit == unitKey;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _heightUnit = unitKey;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? const Color(0xFF16A34A) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // STEP 7: What's your fitness goal?
  // -------------------------------------------------------------
  Widget _buildStep7() {
    final goals = [
      {
        'title': 'Lose Weight',
        'subtitle': 'Burn fat & tone body',
        'type': GoalType.loseWeight,
        'tag': 'FAT BURN',
        'color': const Color(0xFF22C55E),
      },
      {
        'title': 'Build Muscle',
        'subtitle': 'Gain strength & mass',
        'type': GoalType.buildMuscle,
        'tag': 'STRENGTH',
        'color': const Color(0xFF3B82F6),
      },
      {
        'title': 'Keep Fit',
        'subtitle': 'Boost health & cardio',
        'type': GoalType.improveFitness,
        'tag': 'VITALITY',
        'color': const Color(0xFFEC4899),
      },
      {
        'title': 'Boost Energy',
        'subtitle': 'All-day endurance',
        'type': GoalType.boostEnergy,
        'tag': 'STAMINA',
        'color': const Color(0xFFF59E0B),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Spacer(),

        // 2x2 Grid of Animated Goal Cards positioned just above bottom title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: goals.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.94,
            ),
            itemBuilder: (context, index) {
              final goal = goals[index];
              final title = goal['title'] as String;
              final subtitle = goal['subtitle'] as String;
              final tag = goal['tag'] as String;
              final type = goal['type'] as GoalType;
              final color = goal['color'] as Color;
              final isSelected = _selectedGoals.contains(title);

              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    if (_selectedGoals.contains(title)) {
                      if (_selectedGoals.length > 1) {
                        _selectedGoals.remove(title);
                      }
                    } else {
                      _selectedGoals.add(title);
                    }
                    _selectedGoal = _selectedGoals.first;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white, // Clean Pure White (No active tint or dark colors)
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isSelected ? color : const Color(0xFFF1F5F9),
                      width: isSelected ? 2.0 : 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? color.withValues(alpha: 0.14)
                            : const Color(0xFF64748B).withValues(alpha: 0.06),
                        blurRadius: isSelected ? 16 : 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Card Top Row: Tag & Selection Checkmark
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Tag Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3.5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? color.withValues(alpha: 0.3)
                                    : const Color(0xFFF1F5F9),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              tag,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                                color: isSelected ? color : const Color(0xFF64748B),
                              ),
                            ),
                          ),

                          // Selected Circle Checkmark
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected ? color : Colors.transparent,
                              border: Border.all(
                                color: isSelected ? color : const Color(0xFFCBD5E1),
                                width: 1.5,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check_rounded,
                                    size: 13,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        ],
                      ),

                      // Center: Virtual Animated Icon
                      Center(
                        child: AnimatedGoalIcon(
                          goalType: type,
                          isSelected: isSelected,
                          primaryColor: color,
                          size: 50,
                        ),
                      ),

                      // Bottom: Title & Subtitle
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 16),

        // Bottom Left-Aligned Staggered Animated Text
        const Padding(
          padding: EdgeInsets.fromLTRB(24.0, 0.0, 24.0, 10.0),
          child: _Step7StaggeredText(),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // STEP 8: How active are you?
  // -------------------------------------------------------------
  Widget _buildStep8() {
    final activityLevels = [
      {
        'title': 'Sedentary',
        'subtitle': 'Desk job / no workout',
        'tag': 'LEVEL 1',
        'icon': Icons.nightlife_rounded,
        'color': const Color(0xFF64748B),
      },
      {
        'title': 'Lightly Active',
        'subtitle': '1–2 light workouts/wk',
        'tag': 'LEVEL 2',
        'icon': Icons.directions_walk_rounded,
        'color': const Color(0xFF3B82F6),
      },
      {
        'title': 'Moderately Active',
        'subtitle': '3–5 active workouts/wk',
        'tag': 'LEVEL 3',
        'icon': Icons.directions_run_rounded,
        'color': const Color(0xFF22C55E),
      },
      {
        'title': 'Very Active',
        'subtitle': '6–7 intense sessions/wk',
        'tag': 'LEVEL 4',
        'icon': Icons.local_fire_department_rounded,
        'color': const Color(0xFFF97316),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Spacer(),

        // 2x2 Grid of Activity Cards (Single Select, Pure White, Just above bottom title)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activityLevels.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.94,
            ),
            itemBuilder: (context, index) {
              final level = activityLevels[index];
              final title = level['title'] as String;
              final subtitle = level['subtitle'] as String;
              final tag = level['tag'] as String;
              final icon = level['icon'] as IconData;
              final color = level['color'] as Color;
              final isSelected = _selectedActivity == title;

              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedActivity = title);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white, // Clean Pure White (No active tint or dark colors)
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isSelected ? color : const Color(0xFFF1F5F9),
                      width: isSelected ? 2.0 : 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? color.withValues(alpha: 0.14)
                            : const Color(0xFF64748B).withValues(alpha: 0.06),
                        blurRadius: isSelected ? 16 : 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Card Top Row: Level Tag & Radio/Checkmark
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Tag Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3.5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? color.withValues(alpha: 0.3)
                                    : const Color(0xFFF1F5F9),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              tag,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                                color: isSelected ? color : const Color(0xFF64748B),
                              ),
                            ),
                          ),

                          // Single Selection Radio Checkmark
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected ? color : Colors.transparent,
                              border: Border.all(
                                color: isSelected ? color : const Color(0xFFCBD5E1),
                                width: 1.5,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check_rounded,
                                    size: 13,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        ],
                      ),

                      // Center: Animated Activity Icon
                      Center(
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(
                              color: isSelected
                                  ? color.withValues(alpha: 0.4)
                                  : const Color(0xFFF1F5F9),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isSelected
                                    ? color.withValues(alpha: 0.18)
                                    : const Color(0xFF94A3B8).withValues(alpha: 0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Icon(
                            icon,
                            color: isSelected ? color : const Color(0xFF64748B),
                            size: 26,
                          ),
                        ),
                      ),

                      // Bottom: Title & Subtitle
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 16),

        // Bottom Left-Aligned Staggered Animated Text
        const Padding(
          padding: EdgeInsets.fromLTRB(24.0, 0.0, 24.0, 10.0),
          child: _Step8StaggeredText(),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // SHARED HEADER HELPER
  // -------------------------------------------------------------
  Widget _buildHeader({
    required String blackText,
    required String highlightText,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: blackText,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF141518),
              letterSpacing: -0.8,
              height: 1.18,
            ),
            children: [
              TextSpan(
                text: highlightText,
                style: const TextStyle(color: Color(0xFF16A34A)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.5,
            color: const Color(0xFF6B7280),
            height: 1.4,
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // BOTTOM BUTTON
  // -------------------------------------------------------------
  Widget _buildBottomButton() {
    final isLastStep = _currentStep == 7;
    return GestureDetector(
      onTap: _nextPage,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFF141518),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isLastStep ? 'Get Started' : 'Next',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            const _AnimatedArrow(),
          ],
        ),
      ),
    );
  }
}

class _Step1StaggeredText extends StatefulWidget {
  const _Step1StaggeredText();

  @override
  State<_Step1StaggeredText> createState() => _Step1StaggeredTextState();
}

class _Step1StaggeredTextState extends State<_Step1StaggeredText>
    with TickerProviderStateMixin {
  late AnimationController _revealController;
  late AnimationController _badgePulseController;

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _badgePulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _revealController.dispose();
    _badgePulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final headingFontSize = (screenWidth * 0.088).clamp(28.0, 36.0);

    return AnimatedBuilder(
      animation: Listenable.merge([_revealController, _badgePulseController]),
      builder: (context, child) {
        final progress = _revealController.value;

        // Line 1: 0.0 -> 0.45
        final l1 = ((progress - 0.0) / 0.45).clamp(0.0, 1.0);
        final l1Slide = (1.0 - l1) * 20.0;
        final l1Blur = math.max(0.001, (1.0 - l1) * 12.0);

        // Line 2: 0.25 -> 0.70
        final l2 = ((progress - 0.25) / 0.45).clamp(0.0, 1.0);
        final l2Slide = (1.0 - l2) * 20.0;
        final l2Blur = math.max(0.001, (1.0 - l2) * 12.0);

        // Line 3: 0.50 -> 0.95
        final l3 = ((progress - 0.50) / 0.45).clamp(0.0, 1.0);
        final l3Slide = (1.0 - l3) * 20.0;
        final l3Blur = math.max(0.001, (1.0 - l3) * 12.0);

        // Subtitle: 0.65 -> 1.0
        final l4 = ((progress - 0.65) / 0.35).clamp(0.0, 1.0);
        final l4Slide = (1.0 - l4) * 16.0;
        final l4Blur = math.max(0.001, (1.0 - l4) * 10.0);

        final double pulseScale = 1.0 + (_badgePulseController.value * 0.08);
        final double wobbleAngle =
            math.sin(_badgePulseController.value * math.pi) * 0.08;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Line 1: "Let's get"
            Transform.translate(
              offset: Offset(0, l1Slide),
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: l1Blur, sigmaY: l1Blur),
                child: Opacity(
                  opacity: l1,
                  child: Text(
                    "Let's get",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: headingFontSize,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF6B7280),
                      letterSpacing: -1.2,
                      height: 1.15,
                    ),
                  ),
                ),
              ),
            ),

            // Line 2: "fitness [Dumbbell Badge] started"
            Transform.translate(
              offset: Offset(0, l2Slide),
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: l2Blur, sigmaY: l2Blur),
                child: Opacity(
                  opacity: l2,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'fitness',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: headingFontSize,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF141518),
                            letterSpacing: -1.2,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Animated Dumbbell Badge
                        Transform.scale(
                          scale: pulseScale,
                          child: Transform.rotate(
                            angle: wobbleAngle,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF22C55E),
                                    Color(0xFF16A34A),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.fitness_center_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),
                        Text(
                          'started',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: headingFontSize,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF141518),
                            letterSpacing: -1.2,
                            height: 1.15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Line 3: "for your goals"
            Transform.translate(
              offset: Offset(0, l3Slide),
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: l3Blur, sigmaY: l3Blur),
                child: Opacity(
                  opacity: l3,
                  child: Text(
                    'for your goals',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: headingFontSize,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF6B7280),
                      letterSpacing: -1.2,
                      height: 1.15,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Subtitle
            Transform.translate(
              offset: Offset(0, l4Slide),
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: l4Blur, sigmaY: l4Blur),
                child: Opacity(
                  opacity: l4,
                  child: Text(
                    "Your fitness journey begins here.\nWe'll personalize everything for you.",
                    textAlign: TextAlign.left,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      color: const Color(0xFF6B7280),
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Step2StaggeredText extends StatefulWidget {
  const _Step2StaggeredText({Key? key}) : super(key: key);

  @override
  State<_Step2StaggeredText> createState() => _Step2StaggeredTextState();
}

class _Step2StaggeredTextState extends State<_Step2StaggeredText>
    with TickerProviderStateMixin {
  late AnimationController _revealController;
  late AnimationController _badgePulseController;

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _badgePulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _revealController.dispose();
    _badgePulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final headingFontSize = (screenWidth * 0.088).clamp(28.0, 36.0);

    return AnimatedBuilder(
      animation: Listenable.merge([_revealController, _badgePulseController]),
      builder: (context, child) {
        final progress = _revealController.value;

        // Line 1: 0.0 -> 0.45
        final l1 = ((progress - 0.0) / 0.45).clamp(0.0, 1.0);
        final l1Slide = (1.0 - l1) * 20.0;
        final l1Blur = math.max(0.001, (1.0 - l1) * 12.0);

        // Line 2: 0.25 -> 0.70
        final l2 = ((progress - 0.25) / 0.45).clamp(0.0, 1.0);
        final l2Slide = (1.0 - l2) * 20.0;
        final l2Blur = math.max(0.001, (1.0 - l2) * 12.0);

        final double pulseScale = 1.0 + (_badgePulseController.value * 0.08);
        final double wobbleAngle =
            math.sin(_badgePulseController.value * math.pi) * 0.08;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Line 1: "What's your"
            Transform.translate(
              offset: Offset(0, l1Slide),
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: l1Blur, sigmaY: l1Blur),
                child: Opacity(
                  opacity: l1,
                  child: Text(
                    "What's your",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: headingFontSize,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF6B7280),
                      letterSpacing: -1.2,
                      height: 1.15,
                    ),
                  ),
                ),
              ),
            ),

            // Line 2: "gender [Icon] ?"
            Transform.translate(
              offset: Offset(0, l2Slide),
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: l2Blur, sigmaY: l2Blur),
                child: Opacity(
                  opacity: l2,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'gender',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: headingFontSize,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF141518),
                            letterSpacing: -1.2,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Animated Badge
                        Transform.scale(
                          scale: pulseScale,
                          child: Transform.rotate(
                            angle: wobbleAngle,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFF59E0B),
                                    Color(0xFFD97706),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.person_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),
                        Text(
                          '?',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: headingFontSize,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF141518),
                            letterSpacing: -1.2,
                            height: 1.15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AnimatedArrow extends StatefulWidget {
  const _AnimatedArrow({Key? key}) : super(key: key);

  @override
  State<_AnimatedArrow> createState() => _AnimatedArrowState();
}

class _AnimatedArrowState extends State<_AnimatedArrow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_controller.value * 6, 0),
          child: child,
        );
      },
      child: const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
    );
  }
}

class _Step3StaggeredText extends StatefulWidget {
  const _Step3StaggeredText({Key? key}) : super(key: key);

  @override
  State<_Step3StaggeredText> createState() => _Step3StaggeredTextState();
}

class _Step3StaggeredTextState extends State<_Step3StaggeredText>
    with TickerProviderStateMixin {
  late AnimationController _revealController;
  late AnimationController _badgePulseController;

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _badgePulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _revealController.dispose();
    _badgePulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final headingFontSize = (screenWidth * 0.088).clamp(28.0, 36.0);

    return AnimatedBuilder(
      animation: Listenable.merge([_revealController, _badgePulseController]),
      builder: (context, child) {
        final progress = _revealController.value;

        // Line 1: 0.0 -> 0.45
        final l1 = ((progress - 0.0) / 0.45).clamp(0.0, 1.0);
        final l1Slide = (1.0 - l1) * 20.0;
        final l1Blur = math.max(0.001, (1.0 - l1) * 12.0);

        // Line 2: 0.25 -> 0.70
        final l2 = ((progress - 0.25) / 0.45).clamp(0.0, 1.0);
        final l2Slide = (1.0 - l2) * 20.0;
        final l2Blur = math.max(0.001, (1.0 - l2) * 12.0);

        final double pulseScale = 1.0 + (_badgePulseController.value * 0.08);
        final double wobbleAngle =
            math.sin(_badgePulseController.value * math.pi) * 0.08;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Line 1: "How old"
            Transform.translate(
              offset: Offset(0, l1Slide),
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: l1Blur, sigmaY: l1Blur),
                child: Opacity(
                  opacity: l1,
                  child: Text(
                    "How old",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: headingFontSize,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF6B7280),
                      letterSpacing: -1.2,
                      height: 1.15,
                    ),
                  ),
                ),
              ),
            ),

            // Line 2: "are [Icon] you?"
            Transform.translate(
              offset: Offset(0, l2Slide),
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: l2Blur, sigmaY: l2Blur),
                child: Opacity(
                  opacity: l2,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'are',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: headingFontSize,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF141518),
                            letterSpacing: -1.2,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Animated Badge
                        Transform.scale(
                          scale: pulseScale,
                          child: Transform.rotate(
                            angle: wobbleAngle,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF8B5CF6),
                                    Color(0xFF6D28D9),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.cake_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),
                        Text(
                          'you?',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: headingFontSize,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF141518),
                            letterSpacing: -1.2,
                            height: 1.15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Step4StaggeredText extends StatefulWidget {
  const _Step4StaggeredText({super.key});

  @override
  State<_Step4StaggeredText> createState() => _Step4StaggeredTextState();
}

class _Step4StaggeredTextState extends State<_Step4StaggeredText>
    with TickerProviderStateMixin {
  late AnimationController _revealController;
  late AnimationController _badgePulseController;
  late AnimationController _badgeWobbleController;

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _badgePulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _badgeWobbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    // Initial delay before starting the text reveal
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _revealController.forward();
    });
  }

  @override
  void dispose() {
    _revealController.dispose();
    _badgePulseController.dispose();
    _badgeWobbleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double headingFontSize = 42.0;

    return AnimatedBuilder(
      animation: _revealController,
      builder: (context, child) {
        // Line 1: "What's your"
        final l1 = CurvedAnimation(
          parent: _revealController,
          curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
        ).value;
        final l1Slide = 30 * (1 - l1);
        final l1Blur = 8 * (1 - l1);

        // Line 2: "current [Icon] weight?"
        final l2 = CurvedAnimation(
          parent: _revealController,
          curve: const Interval(0.15, 0.55, curve: Curves.easeOutCubic),
        ).value;
        final l2Slide = 30 * (1 - l2);
        final l2Blur = 8 * (1 - l2);

        // Badge Animations
        final pulseScale = Tween<double>(begin: 1.0, end: 1.05).evaluate(
          CurvedAnimation(
            parent: _badgePulseController,
            curve: Curves.easeInOutSine,
          ),
        );
        final wobbleAngle = Tween<double>(begin: -0.05, end: 0.05).evaluate(
          CurvedAnimation(
            parent: _badgeWobbleController,
            curve: Curves.easeInOutSine,
          ),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Line 1: "What's your"
            Transform.translate(
              offset: Offset(0, l1Slide),
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: l1Blur, sigmaY: l1Blur),
                child: Opacity(
                  opacity: l1,
                  child: Text(
                    "What's your",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: headingFontSize,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF6B7280),
                      letterSpacing: -1.2,
                      height: 1.15,
                    ),
                  ),
                ),
              ),
            ),

            // Line 2: "current [Icon] weight?"
            Transform.translate(
              offset: Offset(0, l2Slide),
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: l2Blur, sigmaY: l2Blur),
                child: Opacity(
                  opacity: l2,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'current',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: headingFontSize,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF141518),
                            letterSpacing: -1.2,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Animated Badge
                        Transform.scale(
                          scale: pulseScale,
                          child: Transform.rotate(
                            angle: wobbleAngle,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF3B82F6),
                                    Color(0xFF2563EB),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.monitor_weight_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),
                        Text(
                          'weight?',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: headingFontSize,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF141518),
                            letterSpacing: -1.2,
                            height: 1.15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Step5StaggeredText extends StatefulWidget {
  const _Step5StaggeredText({super.key});

  @override
  State<_Step5StaggeredText> createState() => _Step5StaggeredTextState();
}

class _Step5StaggeredTextState extends State<_Step5StaggeredText>
    with TickerProviderStateMixin {
  late AnimationController _revealController;
  late AnimationController _badgePulseController;
  late AnimationController _badgeWobbleController;

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _badgePulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _badgeWobbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    // Initial delay before starting the text reveal
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _revealController.forward();
    });
  }

  @override
  void dispose() {
    _revealController.dispose();
    _badgePulseController.dispose();
    _badgeWobbleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double headingFontSize = 42.0;

    return AnimatedBuilder(
      animation: _revealController,
      builder: (context, child) {
        // Line 1: "What's your"
        final l1 = CurvedAnimation(
          parent: _revealController,
          curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
        ).value;
        final l1Slide = 30 * (1 - l1);
        final l1Blur = 8 * (1 - l1);

        // Line 2: "target [Icon] weight?"
        final l2 = CurvedAnimation(
          parent: _revealController,
          curve: const Interval(0.15, 0.55, curve: Curves.easeOutCubic),
        ).value;
        final l2Slide = 30 * (1 - l2);
        final l2Blur = 8 * (1 - l2);

        // Badge Animations
        final pulseScale = Tween<double>(begin: 1.0, end: 1.05).evaluate(
          CurvedAnimation(
            parent: _badgePulseController,
            curve: Curves.easeInOutSine,
          ),
        );
        final wobbleAngle = Tween<double>(begin: -0.05, end: 0.05).evaluate(
          CurvedAnimation(
            parent: _badgeWobbleController,
            curve: Curves.easeInOutSine,
          ),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Line 1: "What's your"
            Transform.translate(
              offset: Offset(0, l1Slide),
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: l1Blur, sigmaY: l1Blur),
                child: Opacity(
                  opacity: l1,
                  child: Text(
                    "What's your",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: headingFontSize,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF6B7280),
                      letterSpacing: -1.2,
                      height: 1.15,
                    ),
                  ),
                ),
              ),
            ),

            // Line 2: "target [Icon] weight?"
            Transform.translate(
              offset: Offset(0, l2Slide),
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: l2Blur, sigmaY: l2Blur),
                child: Opacity(
                  opacity: l2,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'target',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: headingFontSize,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF141518),
                            letterSpacing: -1.2,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Animated Badge
                        Transform.scale(
                          scale: pulseScale,
                          child: Transform.rotate(
                            angle: wobbleAngle,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF22C55E),
                                    Color(0xFF16A34A),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.ads_click_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),
                        Text(
                          'weight?',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: headingFontSize,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF141518),
                            letterSpacing: -1.2,
                            height: 1.15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Step6StaggeredText extends StatefulWidget {
  const _Step6StaggeredText({super.key});

  @override
  State<_Step6StaggeredText> createState() => _Step6StaggeredTextState();
}

class _Step6StaggeredTextState extends State<_Step6StaggeredText>
    with TickerProviderStateMixin {
  late AnimationController _revealController;
  late AnimationController _badgePulseController;
  late AnimationController _badgeWobbleController;

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _badgePulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _badgeWobbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _revealController.forward();
    });
  }

  @override
  void dispose() {
    _revealController.dispose();
    _badgePulseController.dispose();
    _badgeWobbleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double headingFontSize = 42.0;

    return AnimatedBuilder(
      animation: _revealController,
      builder: (context, child) {
        // Line 1: "What's your"
        final l1 = CurvedAnimation(
          parent: _revealController,
          curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
        ).value;
        final l1Slide = 30 * (1 - l1);
        final l1Blur = 8 * (1 - l1);

        // Line 2: "[Icon] height?"
        final l2 = CurvedAnimation(
          parent: _revealController,
          curve: const Interval(0.15, 0.55, curve: Curves.easeOutCubic),
        ).value;
        final l2Slide = 30 * (1 - l2);
        final l2Blur = 8 * (1 - l2);

        // Badge Animations
        final pulseScale = Tween<double>(begin: 1.0, end: 1.05).evaluate(
          CurvedAnimation(
            parent: _badgePulseController,
            curve: Curves.easeInOutSine,
          ),
        );
        final wobbleAngle = Tween<double>(begin: -0.05, end: 0.05).evaluate(
          CurvedAnimation(
            parent: _badgeWobbleController,
            curve: Curves.easeInOutSine,
          ),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Line 1: "What's your"
            Transform.translate(
              offset: Offset(0, l1Slide),
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: l1Blur, sigmaY: l1Blur),
                child: Opacity(
                  opacity: l1,
                  child: Text(
                    "What's your",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: headingFontSize,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF6B7280),
                      letterSpacing: -1.2,
                      height: 1.15,
                    ),
                  ),
                ),
              ),
            ),

            // Line 2: "[Icon] height?"
            Transform.translate(
              offset: Offset(0, l2Slide),
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: l2Blur, sigmaY: l2Blur),
                child: Opacity(
                  opacity: l2,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Animated Badge
                        Transform.scale(
                          scale: pulseScale,
                          child: Transform.rotate(
                            angle: wobbleAngle,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF22C55E),
                                    Color(0xFF16A34A),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.height_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        Text(
                          'height?',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: headingFontSize,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF141518),
                            letterSpacing: -1.2,
                            height: 1.15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Step7StaggeredText extends StatefulWidget {
  const _Step7StaggeredText({super.key});

  @override
  State<_Step7StaggeredText> createState() => _Step7StaggeredTextState();
}

class _Step7StaggeredTextState extends State<_Step7StaggeredText>
    with TickerProviderStateMixin {
  late AnimationController _revealController;
  late AnimationController _badgePulseController;
  late AnimationController _badgeWobbleController;

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _badgePulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _badgeWobbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _revealController.forward();
    });
  }

  @override
  void dispose() {
    _revealController.dispose();
    _badgePulseController.dispose();
    _badgeWobbleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double headingFontSize = 42.0;

    return AnimatedBuilder(
      animation: _revealController,
      builder: (context, child) {
        // Line 1: "What's your"
        final l1 = CurvedAnimation(
          parent: _revealController,
          curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
        ).value;
        final l1Slide = 30 * (1 - l1);
        final l1Blur = 8 * (1 - l1);

        // Line 2: "fitness [Icon] goal?"
        final l2 = CurvedAnimation(
          parent: _revealController,
          curve: const Interval(0.15, 0.55, curve: Curves.easeOutCubic),
        ).value;
        final l2Slide = 30 * (1 - l2);
        final l2Blur = 8 * (1 - l2);

        // Badge Animations
        final pulseScale = Tween<double>(begin: 1.0, end: 1.05).evaluate(
          CurvedAnimation(
            parent: _badgePulseController,
            curve: Curves.easeInOutSine,
          ),
        );
        final wobbleAngle = Tween<double>(begin: -0.05, end: 0.05).evaluate(
          CurvedAnimation(
            parent: _badgeWobbleController,
            curve: Curves.easeInOutSine,
          ),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Line 1: "What's your"
            Transform.translate(
              offset: Offset(0, l1Slide),
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: l1Blur, sigmaY: l1Blur),
                child: Opacity(
                  opacity: l1,
                  child: Text(
                    "What's your",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: headingFontSize,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF6B7280),
                      letterSpacing: -1.2,
                      height: 1.15,
                    ),
                  ),
                ),
              ),
            ),

            // Line 2: "fitness [Icon] goal?"
            Transform.translate(
              offset: Offset(0, l2Slide),
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: l2Blur, sigmaY: l2Blur),
                child: Opacity(
                  opacity: l2,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'fitness',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: headingFontSize,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF141518),
                            letterSpacing: -1.2,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Animated Badge
                        Transform.scale(
                          scale: pulseScale,
                          child: Transform.rotate(
                            angle: wobbleAngle,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF22C55E),
                                    Color(0xFF16A34A),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.emoji_events_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        Text(
                          'goal?',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: headingFontSize,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF141518),
                            letterSpacing: -1.2,
                            height: 1.15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Step8StaggeredText extends StatefulWidget {
  const _Step8StaggeredText({super.key});

  @override
  State<_Step8StaggeredText> createState() => _Step8StaggeredTextState();
}

class _Step8StaggeredTextState extends State<_Step8StaggeredText>
    with TickerProviderStateMixin {
  late AnimationController _revealController;
  late AnimationController _badgePulseController;
  late AnimationController _badgeWobbleController;

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _badgePulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _badgeWobbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _revealController.forward();
    });
  }

  @override
  void dispose() {
    _revealController.dispose();
    _badgePulseController.dispose();
    _badgeWobbleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double headingFontSize = 42.0;

    return AnimatedBuilder(
      animation: _revealController,
      builder: (context, child) {
        // Line 1: "How active"
        final l1 = CurvedAnimation(
          parent: _revealController,
          curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
        ).value;
        final l1Slide = 30 * (1 - l1);
        final l1Blur = 8 * (1 - l1);

        // Line 2: "are [Icon] you?"
        final l2 = CurvedAnimation(
          parent: _revealController,
          curve: const Interval(0.15, 0.55, curve: Curves.easeOutCubic),
        ).value;
        final l2Slide = 30 * (1 - l2);
        final l2Blur = 8 * (1 - l2);

        // Badge Animations
        final pulseScale = Tween<double>(begin: 1.0, end: 1.05).evaluate(
          CurvedAnimation(
            parent: _badgePulseController,
            curve: Curves.easeInOutSine,
          ),
        );
        final wobbleAngle = Tween<double>(begin: -0.05, end: 0.05).evaluate(
          CurvedAnimation(
            parent: _badgeWobbleController,
            curve: Curves.easeInOutSine,
          ),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Line 1: "How active"
            Transform.translate(
              offset: Offset(0, l1Slide),
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: l1Blur, sigmaY: l1Blur),
                child: Opacity(
                  opacity: l1,
                  child: Text(
                    "How active",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: headingFontSize,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF6B7280),
                      letterSpacing: -1.2,
                      height: 1.15,
                    ),
                  ),
                ),
              ),
            ),

            // Line 2: "are [Icon] you?"
            Transform.translate(
              offset: Offset(0, l2Slide),
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: l2Blur, sigmaY: l2Blur),
                child: Opacity(
                  opacity: l2,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'are',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: headingFontSize,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF141518),
                            letterSpacing: -1.2,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Animated Badge
                        Transform.scale(
                          scale: pulseScale,
                          child: Transform.rotate(
                            angle: wobbleAngle,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF22C55E),
                                    Color(0xFF16A34A),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.directions_run_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        Text(
                          'you?',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: headingFontSize,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF141518),
                            letterSpacing: -1.2,
                            height: 1.15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}



