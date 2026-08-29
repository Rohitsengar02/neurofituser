import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'vendor_dashboard_screen.dart';

class VendorRegistrationScreen extends StatefulWidget {
  const VendorRegistrationScreen({super.key});

  @override
  State<VendorRegistrationScreen> createState() => _VendorRegistrationScreenState();
}

class _VendorRegistrationScreenState extends State<VendorRegistrationScreen> with TickerProviderStateMixin {
  int _currentStep = 0;
  final int _totalSteps = 6;

  // Step 1: Store Basics
  final TextEditingController _storeNameController = TextEditingController(text: 'Apex Fitness Gear');
  final TextEditingController _cityController = TextEditingController(text: 'Mumbai');
  final TextEditingController _pincodeController = TextEditingController(text: '400001');
  int _selectedCategoryIndex = 0;
  final List<Map<String, dynamic>> _categories = [
    {'name': 'Supplements & Protein', 'icon': Icons.local_drink_rounded, 'color': Color(0xFF16A34A), 'bg': Color(0xFFDCFCE7)},
    {'name': 'Gym & Fitness Gear', 'icon': Icons.fitness_center_rounded, 'color': Color(0xFF2563EB), 'bg': Color(0xFFDBEAFE)},
    {'name': 'Athletic Apparel', 'icon': Icons.checkroom_rounded, 'color': Color(0xFF8B5CF6), 'bg': Color(0xFFF3E8FF)},
    {'name': 'Healthy Nutrition', 'icon': Icons.spa_rounded, 'color': Color(0xFFEA580C), 'bg': Color(0xFFFFEDD5)},
    {'name': 'Recovery & Tech', 'icon': Icons.smart_toy_rounded, 'color': Color(0xFF0D9488), 'bg': Color(0xFFCCFBF1)},
  ];

  // Step 2: Business Type
  int _selectedEntityTypeIndex = 0;
  final List<Map<String, dynamic>> _entityTypes = [
    {
      'title': 'Individual Seller / Freelancer',
      'desc': 'Sell directly without GST (Annual turnover < ₹20 Lakhs)',
      'icon': Icons.person_outline_rounded,
      'badge': 'Quick Setup',
      'color': Color(0xFF16A34A),
    },
    {
      'title': 'Sole Proprietorship',
      'desc': 'Single business owner operating under a trade name',
      'icon': Icons.storefront_rounded,
      'badge': 'Most Popular',
      'color': Color(0xFF2563EB),
    },
    {
      'title': 'Partnership / LLP Firm',
      'desc': 'Registered partnership deed with 2 or more partners',
      'icon': Icons.groups_rounded,
      'badge': 'Registered',
      'color': Color(0xFF8B5CF6),
    },
    {
      'title': 'Private Limited Company',
      'desc': 'Incorporated corporate entity with MCA registration',
      'icon': Icons.domain_rounded,
      'badge': 'Enterprise',
      'color': Color(0xFFEA580C),
    },
  ];

  // Step 3: Aadhaar Verification
  final TextEditingController _aadhaarController = TextEditingController(text: '5489 2145 9823');
  bool _isAadhaarVerified = false;
  bool _isAadhaarLoading = false;

  // Step 4: PAN & Tax Verification
  final TextEditingController _panController = TextEditingController(text: 'ABCDE1234F');
  final TextEditingController _panNameController = TextEditingController(text: 'ROHIT SHARMA');
  final TextEditingController _gstinController = TextEditingController(text: '27ABCDE1234F1Z5');
  bool _isPanVerified = false;
  bool _isPanLoading = false;

  // Step 5: Bank Settlement
  final TextEditingController _accHolderController = TextEditingController(text: 'ROHIT SHARMA');
  final TextEditingController _accNumberController = TextEditingController(text: '50100428912345');
  final TextEditingController _ifscController = TextEditingController(text: 'HDFC0001234');
  final TextEditingController _bankNameController = TextEditingController(text: 'HDFC Bank Ltd');
  bool _isBankVerified = false;
  bool _isBankLoading = false;

  // Step 6: Fulfillment & Dispatch
  int _shippingModeIndex = 0; // 0: NeuroFit Express, 1: Self Ship
  int _dispatchTurnaroundIndex = 0; // 0: Same Day, 1: 24h, 2: 48h
  int _returnPolicyIndex = 0; // 0: 7 Days, 1: 14 Days, 2: No returns

  @override
  void dispose() {
    _storeNameController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    _aadhaarController.dispose();
    _panController.dispose();
    _panNameController.dispose();
    _gstinController.dispose();
    _accHolderController.dispose();
    _accNumberController.dispose();
    _ifscController.dispose();
    _bankNameController.dispose();
    super.dispose();
  }

  void _nextStep() {
    HapticFeedback.lightImpact();
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
    } else {
      _showCompletionCelebration();
    }
  }

  void _prevStep() {
    HapticFeedback.lightImpact();
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  void _verifyAadhaar() {
    HapticFeedback.selectionClick();
    setState(() => _isAadhaarLoading = true);
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) {
        setState(() {
          _isAadhaarLoading = false;
          _isAadhaarVerified = true;
        });
      }
    });
  }

  void _verifyPan() {
    HapticFeedback.selectionClick();
    setState(() => _isPanLoading = true);
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) {
        setState(() {
          _isPanLoading = false;
          _isPanVerified = true;
        });
      }
    });
  }

  void _verifyBank() {
    HapticFeedback.selectionClick();
    setState(() => _isBankLoading = true);
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _isBankLoading = false;
          _isBankVerified = true;
        });
      }
    });
  }

  void _showCompletionCelebration() {
    HapticFeedback.heavyImpact();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => VendorDashboardScreen(
          storeName: _storeNameController.text.isNotEmpty ? _storeNameController.text : 'Apex Fitness Gear',
          category: _categories[_selectedCategoryIndex]['name'] as String,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_currentStep + 1) / _totalSteps;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Bar with Back, Progress and Step counter
            _buildTopProgressHeader(progress),

            // 2. Animated Step Content (Headers pinned to absolute top)
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.03, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey('step_content_$_currentStep'),
                  child: _buildCurrentStepContent(),
                ),
              ),
            ),

            // 3. Bottom Next / Continue Button
            _buildBottomActionBar(),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // 1. TOP PROGRESS HEADER
  // -------------------------------------------------------------
  Widget _buildTopProgressHeader(double progress) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 6.0, 20.0, 6.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: _prevStep,
                behavior: HitTestBehavior.opaque,
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
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Color(0xFF0F172A),
                    size: 15,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.storefront_rounded, size: 14, color: Color(0xFF16A34A)),
                    const SizedBox(width: 6),
                    Text(
                      'STEP ${_currentStep + 1} OF $_totalSteps',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF15803D),
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF64748B)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Linear Animated Progress Bar
          Container(
            height: 4.5,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 2. STEP ROUTER
  // -------------------------------------------------------------
  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1StoreBasics();
      case 1:
        return _buildStep2EntityType();
      case 2:
        return _buildStep3AadhaarVerification();
      case 3:
        return _buildStep4PanVerification();
      case 4:
        return _buildStep5BankSettlement();
      case 5:
        return _buildStep6Fulfillment();
      default:
        return const SizedBox();
    }
  }

  // -------------------------------------------------------------
  // STEP 1: STORE BASICS (HEADING ON ABSOLUTE TOP)
  // -------------------------------------------------------------
  Widget _buildStep1StoreBasics() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20.0, 6.0, 20.0, 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Absolute Top Staggered Heading
          _VendorStaggeredStepHeader(
            key: const ValueKey('header_step_1'),
            line1: "Let's set up your",
            line2: "store profile",
            highlightWord: "profile",
            badgeIcon: Icons.storefront_rounded,
            badgeColor: const Color(0xFF16A34A),
            subtitle: "Start selling fitness gear & supplements to over 250,000+ active athletes across India.",
          ),
          const SizedBox(height: 18),

          // Store Name Field
          _buildInputLabel('Store / Brand Name', icon: Icons.storefront_rounded),
          const SizedBox(height: 6),
          _buildInputField(
            controller: _storeNameController,
            hint: 'e.g. Apex Nutrition Hub',
            prefixIcon: Icons.store_rounded,
          ),
          const SizedBox(height: 16),

          // Category Select
          _buildInputLabel('Primary Product Category', icon: Icons.category_rounded),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.asMap().entries.map((entry) {
              final idx = entry.key;
              final cat = entry.value;
              final isSel = _selectedCategoryIndex == idx;
              final color = cat['color'] as Color;
              final bg = cat['bg'] as Color;

              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedCategoryIndex = idx);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSel ? color : bg.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSel ? color : const Color(0xFFE2E8F0),
                      width: isSel ? 1.5 : 1.0,
                    ),
                    boxShadow: isSel
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : [],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(cat['icon'] as IconData, size: 16, color: isSel ? Colors.white : color),
                      const SizedBox(width: 8),
                      Text(
                        cat['name'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: isSel ? FontWeight.w800 : FontWeight.w700,
                          color: isSel ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Location details (City & Pincode)
          Row(
            children: [
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputLabel('Store City', icon: Icons.location_city_rounded),
                    const SizedBox(height: 6),
                    _buildInputField(
                      controller: _cityController,
                      hint: 'Mumbai',
                      prefixIcon: Icons.location_city_rounded,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputLabel('Dispatch Pincode', icon: Icons.pin_drop_rounded),
                    const SizedBox(height: 6),
                    _buildInputField(
                      controller: _pincodeController,
                      hint: '400001',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.pin_drop_rounded,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // STEP 2: BUSINESS ENTITY TYPE (HEADING ON ABSOLUTE TOP)
  // -------------------------------------------------------------
  Widget _buildStep2EntityType() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20.0, 6.0, 20.0, 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Absolute Top Staggered Heading
          _VendorStaggeredStepHeader(
            key: const ValueKey('header_step_2'),
            line1: "Select your registered",
            line2: "business structure",
            highlightWord: "structure",
            badgeIcon: Icons.domain_rounded,
            badgeColor: const Color(0xFF2563EB),
            subtitle: "Choose how your store is registered legally for invoice and payout compliance.",
          ),
          const SizedBox(height: 18),

          ..._entityTypes.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            final isSel = _selectedEntityTypeIndex == idx;
            final color = item['color'] as Color;

            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedEntityTypeIndex = idx);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSel ? const Color(0xFFF0FDF4) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSel ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0),
                    width: isSel ? 1.8 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: isSel ? 0.06 : 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSel ? const Color(0xFF16A34A) : color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        item['icon'] as IconData,
                        color: isSel ? Colors.white : color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                item['title'] as String,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: isSel ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  item['badge'] as String,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: isSel ? const Color(0xFF15803D) : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item['desc'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF64748B),
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // STEP 3: AADHAAR KYC VERIFICATION (HEADING ON ABSOLUTE TOP)
  // -------------------------------------------------------------
  Widget _buildStep3AadhaarVerification() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20.0, 6.0, 20.0, 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Absolute Top Staggered Heading
          _VendorStaggeredStepHeader(
            key: const ValueKey('header_step_3'),
            line1: "Fast identity & government",
            line2: "Aadhaar KYC",
            highlightWord: "KYC",
            badgeIcon: Icons.fingerprint_rounded,
            badgeColor: const Color(0xFF06B6D4),
            subtitle: "Instant government KYC via DigiLocker OTP for 10-second paperless merchant onboarding.",
          ),
          const SizedBox(height: 18),

          // Aadhaar Number Input
          _buildInputLabel('12-Digit Aadhaar Number', icon: Icons.fingerprint_rounded),
          const SizedBox(height: 6),
          _buildInputField(
            controller: _aadhaarController,
            hint: 'XXXX XXXX XXXX',
            keyboardType: TextInputType.number,
            prefixIcon: Icons.fingerprint_rounded,
          ),
          const SizedBox(height: 14),

          // Instant OTP / DigiLocker Verification Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _isAadhaarVerified ? const Color(0xFFF0FDF4) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _isAadhaarVerified ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _isAadhaarVerified ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isAadhaarVerified ? Icons.verified_user_rounded : Icons.security_rounded,
                    color: _isAadhaarVerified ? const Color(0xFF16A34A) : const Color(0xFF475569),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isAadhaarVerified ? 'UIDAI KYC Verified' : 'DigiLocker Paperless KYC',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: _isAadhaarVerified ? const Color(0xFF15803D) : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        _isAadhaarVerified ? 'UID: •••• •••• 9823 (Active)' : 'Fast 10-second instant authentication',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _isAadhaarVerified ? null : _verifyAadhaar,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: _isAadhaarVerified ? const Color(0xFFDCFCE7) : const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _isAadhaarLoading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            _isAadhaarVerified ? 'Verified ✓' : 'Verify OTP',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: _isAadhaarVerified ? const Color(0xFF16A34A) : Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Upload Aadhaar Card Mock
          _buildInputLabel('Aadhaar Card Document Preview', icon: Icons.cloud_done_rounded),
          const SizedBox(height: 6),
          Container(
            height: 90,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_done_rounded, color: Color(0xFF16A34A), size: 24),
                const SizedBox(width: 10),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'aadhaar_card_front_back.pdf',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Auto-imported from DigiLocker • 1.2 MB',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
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

  // -------------------------------------------------------------
  // STEP 4: PAN & TAX VERIFICATION (HEADING ON ABSOLUTE TOP)
  // -------------------------------------------------------------
  Widget _buildStep4PanVerification() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20.0, 6.0, 20.0, 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Absolute Top Staggered Heading
          _VendorStaggeredStepHeader(
            key: const ValueKey('header_step_4'),
            line1: "Verify tax & legal",
            line2: "PAN details",
            highlightWord: "details",
            badgeIcon: Icons.badge_rounded,
            badgeColor: const Color(0xFF8B5CF6),
            subtitle: "Income Tax Department PAN verification to process and authenticate your settlement payouts.",
          ),
          const SizedBox(height: 18),

          // PAN Number Field
          _buildInputLabel('10-Character Permanent Account Number (PAN)', icon: Icons.badge_rounded),
          const SizedBox(height: 6),
          _buildInputField(
            controller: _panController,
            hint: 'ABCDE1234F',
            prefixIcon: Icons.badge_rounded,
          ),
          const SizedBox(height: 14),

          // Name on PAN
          _buildInputLabel('Full Legal Name on PAN Card', icon: Icons.person_outline_rounded),
          const SizedBox(height: 6),
          _buildInputField(
            controller: _panNameController,
            hint: 'e.g. ROHIT SHARMA',
            prefixIcon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 14),

          // Instant ITD Verification Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _isPanVerified ? const Color(0xFFF0FDF4) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _isPanVerified ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _isPanVerified ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isPanVerified ? Icons.check_circle_rounded : Icons.credit_card_rounded,
                    color: _isPanVerified ? const Color(0xFF16A34A) : const Color(0xFF475569),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isPanVerified ? 'PAN Authenticated ✓' : 'Direct ITD Database Validation',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: _isPanVerified ? const Color(0xFF15803D) : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        _isPanVerified ? 'Matched: ROHIT SHARMA' : 'Validates name match against PAN records',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _isPanVerified ? null : _verifyPan,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: _isPanVerified ? const Color(0xFFDCFCE7) : const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _isPanLoading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            _isPanVerified ? 'Verified ✓' : 'Verify PAN',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: _isPanVerified ? const Color(0xFF16A34A) : Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // GSTIN Optional Field
          _buildInputLabel('GSTIN Number (Optional for < ₹20L turnover)', icon: Icons.receipt_long_rounded),
          const SizedBox(height: 6),
          _buildInputField(
            controller: _gstinController,
            hint: '27ABCDE1234F1Z5',
            prefixIcon: Icons.receipt_long_rounded,
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // STEP 5: BANK SETTLEMENT DETAILS (HEADING ON ABSOLUTE TOP)
  // -------------------------------------------------------------
  Widget _buildStep5BankSettlement() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20.0, 6.0, 20.0, 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Absolute Top Staggered Heading
          _VendorStaggeredStepHeader(
            key: const ValueKey('header_step_5'),
            line1: "Link your merchant",
            line2: "settlement account",
            highlightWord: "account",
            badgeIcon: Icons.account_balance_rounded,
            badgeColor: const Color(0xFF10B981),
            subtitle: "Where you will receive your automated daily & weekly customer sales payments directly.",
          ),
          const SizedBox(height: 18),

          // Account Holder Name
          _buildInputLabel('Account Holder Legal Name', icon: Icons.person_rounded),
          const SizedBox(height: 6),
          _buildInputField(
            controller: _accHolderController,
            hint: 'ROHIT SHARMA',
            prefixIcon: Icons.person_rounded,
          ),
          const SizedBox(height: 14),

          // Bank Account Number
          _buildInputLabel('Bank Account Number', icon: Icons.account_balance_rounded),
          const SizedBox(height: 6),
          _buildInputField(
            controller: _accNumberController,
            hint: '50100428912345',
            keyboardType: TextInputType.number,
            prefixIcon: Icons.account_balance_rounded,
          ),
          const SizedBox(height: 14),

          // IFSC Code & Bank Name
          Row(
            children: [
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputLabel('IFSC Code', icon: Icons.qr_code_rounded),
                    const SizedBox(height: 6),
                    _buildInputField(
                      controller: _ifscController,
                      hint: 'HDFC0001234',
                      prefixIcon: Icons.qr_code_rounded,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputLabel('Bank Name', icon: Icons.account_balance_wallet_rounded),
                    const SizedBox(height: 6),
                    _buildInputField(
                      controller: _bankNameController,
                      hint: 'HDFC Bank',
                      prefixIcon: Icons.account_balance_wallet_rounded,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Penny Drop Bank Verification Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _isBankVerified ? const Color(0xFFF0FDF4) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _isBankVerified ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _isBankVerified ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isBankVerified ? Icons.currency_rupee_rounded : Icons.account_balance_rounded,
                    color: _isBankVerified ? const Color(0xFF16A34A) : const Color(0xFF475569),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isBankVerified ? 'Penny Drop Verified ✓' : 'Instant ₹1 Penny-Drop Validation',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: _isBankVerified ? const Color(0xFF15803D) : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        _isBankVerified ? 'Account active for auto-payouts' : 'Deposits ₹1 to verify active status',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _isBankVerified ? null : _verifyBank,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: _isBankVerified ? const Color(0xFFDCFCE7) : const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _isBankLoading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            _isBankVerified ? 'Verified ✓' : 'Validate',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: _isBankVerified ? const Color(0xFF16A34A) : Colors.white,
                            ),
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
  // STEP 6: FULFILLMENT & DISPATCH (HEADING ON ABSOLUTE TOP)
  // -------------------------------------------------------------
  Widget _buildStep6Fulfillment() {
    final shippingModes = [
      {
        'title': 'NeuroFit Express Logistics',
        'desc': 'Our courier partners pick up parcels from your doorstep with automated label printing.',
        'icon': Icons.local_shipping_rounded,
        'badge': 'Recommended',
      },
      {
        'title': 'Self-Ship / Merchant Delivery',
        'desc': 'You handle packing and ship via your own preferred local delivery network.',
        'icon': Icons.delivery_dining_rounded,
        'badge': 'Custom',
      },
    ];

    final turnaroundTimes = ['Same Day (Under 12h)', '24 Hours', '48 Hours'];
    final returnPolicies = ['7 Days Replacement', '14 Days Return', 'No Returns (Final Sale)'];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20.0, 6.0, 20.0, 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Absolute Top Staggered Heading
          _VendorStaggeredStepHeader(
            key: const ValueKey('header_step_6'),
            line1: "Configure store delivery &",
            line2: "fast operations",
            highlightWord: "operations",
            badgeIcon: Icons.local_shipping_rounded,
            badgeColor: const Color(0xFFEA580C),
            subtitle: "Configure order fulfillment, doorstep pickup, parcel turnaround, and customer returns.",
          ),
          const SizedBox(height: 18),

          // Shipping Mode Selector
          _buildInputLabel('Fulfillment Model', icon: Icons.local_shipping_rounded),
          const SizedBox(height: 8),
          ...shippingModes.asMap().entries.map((entry) {
            final idx = entry.key;
            final mode = entry.value;
            final isSel = _shippingModeIndex == idx;

            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _shippingModeIndex = idx);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSel ? const Color(0xFFF0FDF4) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSel ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0),
                    width: isSel ? 1.8 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSel ? const Color(0xFF16A34A) : const Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        mode['icon'] as IconData,
                        color: isSel ? Colors.white : const Color(0xFF475569),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                mode['title'] as String,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isSel ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  mode['badge'] as String,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: isSel ? const Color(0xFF15803D) : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            mode['desc'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 14),

          // Dispatch Turnaround Time
          _buildInputLabel('Dispatch Turnaround Time', icon: Icons.timer_outlined),
          const SizedBox(height: 6),
          Row(
            children: turnaroundTimes.asMap().entries.map((entry) {
              final idx = entry.key;
              final time = entry.value;
              final isSel = _dispatchTurnaroundIndex == idx;

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _dispatchTurnaroundIndex = idx);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.only(right: idx < turnaroundTimes.length - 1 ? 8 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSel ? const Color(0xFF16A34A) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSel ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      time,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                        color: isSel ? Colors.white : const Color(0xFF475569),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // Customer Return Policy
          _buildInputLabel('Customer Return & Replacement Window', icon: Icons.assignment_return_rounded),
          const SizedBox(height: 6),
          Row(
            children: returnPolicies.asMap().entries.map((entry) {
              final idx = entry.key;
              final policy = entry.value;
              final isSel = _returnPolicyIndex == idx;

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _returnPolicyIndex = idx);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.only(right: idx < returnPolicies.length - 1 ? 8 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSel ? const Color(0xFF0F172A) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSel ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      policy,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                        color: isSel ? Colors.white : const Color(0xFF475569),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // HELPER WIDGETS
  // -------------------------------------------------------------
  Widget _buildInputLabel(String label, {IconData? icon}) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: const Color(0xFF16A34A)),
          const SizedBox(width: 6),
        ],
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF334155),
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(prefixIcon, color: const Color(0xFF94A3B8), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF94A3B8),
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // BOTTOM ACTION BAR
  // -------------------------------------------------------------
  Widget _buildBottomActionBar() {
    final isLastStep = _currentStep == _totalSteps - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            GestureDetector(
              onTap: _prevStep,
              child: Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(25),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Back',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF475569),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: GestureDetector(
              onTap: _nextStep,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF141518),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.16),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isLastStep ? 'Complete & Launch Store' : 'Continue to Step ${_currentStep + 2}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isLastStep ? Icons.rocket_launch_rounded : Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 16,
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
}

// -------------------------------------------------------------
// QUESTIONNAIRE-STYLE STAGGERED STEP HEADER COMPONENT
// -------------------------------------------------------------
class _VendorStaggeredStepHeader extends StatefulWidget {
  final String line1;
  final String line2;
  final String highlightWord;
  final IconData badgeIcon;
  final Color badgeColor;
  final String subtitle;

  const _VendorStaggeredStepHeader({
    super.key,
    required this.line1,
    required this.line2,
    required this.highlightWord,
    required this.badgeIcon,
    required this.badgeColor,
    required this.subtitle,
  });

  @override
  State<_VendorStaggeredStepHeader> createState() => _VendorStaggeredStepHeaderState();
}

class _VendorStaggeredStepHeaderState extends State<_VendorStaggeredStepHeader> with TickerProviderStateMixin {
  late AnimationController _revealController;
  late AnimationController _badgePulseController;

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
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
    final headingFontSize = (screenWidth * 0.068).clamp(22.0, 27.0);

    return AnimatedBuilder(
      animation: Listenable.merge([_revealController, _badgePulseController]),
      builder: (context, child) {
        final progress = _revealController.value;

        // Line 1: 0.0 -> 0.45
        final l1 = ((progress - 0.0) / 0.45).clamp(0.0, 1.0);
        final l1Slide = (1.0 - l1) * 16.0;
        final l1Blur = math.max(0.001, (1.0 - l1) * 10.0);

        // Line 2: 0.25 -> 0.70
        final l2 = ((progress - 0.25) / 0.45).clamp(0.0, 1.0);
        final l2Slide = (1.0 - l2) * 16.0;
        final l2Blur = math.max(0.001, (1.0 - l2) * 10.0);

        // Subtitle: 0.50 -> 0.95
        final l3 = ((progress - 0.50) / 0.45).clamp(0.0, 1.0);
        final l3Slide = (1.0 - l3) * 12.0;
        final l3Blur = math.max(0.001, (1.0 - l3) * 8.0);

        final double pulseScale = 1.0 + (_badgePulseController.value * 0.08);
        final double wobbleAngle = math.sin(_badgePulseController.value * math.pi) * 0.08;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Line 1 (Grey/Slate Question Intro)
            Transform.translate(
              offset: Offset(0, l1Slide),
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: l1Blur, sigmaY: l1Blur),
                child: Opacity(
                  opacity: l1,
                  child: Text(
                    widget.line1,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: headingFontSize,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF64748B),
                      letterSpacing: -0.8,
                      height: 1.15,
                    ),
                  ),
                ),
              ),
            ),

            // Line 2 (Bold Charcoal + Animated Badge)
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
                          widget.line2,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: headingFontSize,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                            letterSpacing: -0.8,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Animated Pulse & Wobble Badge
                        Transform.scale(
                          scale: pulseScale,
                          child: Transform.rotate(
                            angle: wobbleAngle,
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: widget.badgeColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(9),
                                border: Border.all(
                                  color: widget.badgeColor.withValues(alpha: 0.35),
                                  width: 1.2,
                                ),
                              ),
                              child: Icon(
                                widget.badgeIcon,
                                color: widget.badgeColor,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 6),

            // Subtitle Description (Staggered blur fade)
            Transform.translate(
              offset: Offset(0, l3Slide),
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: l3Blur, sigmaY: l3Blur),
                child: Opacity(
                  opacity: l3,
                  child: Text(
                    widget.subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                      height: 1.35,
                      letterSpacing: -0.1,
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
