import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF141518), size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Terms of Service',
          style: GoogleFonts.plusJakartaSans(
            color: const Color(0xFF141518),
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: const Color(0xFFF1F3F5),
            height: 1.0,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFED7AA)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.gavel_rounded, color: Color(0xFFC2410C), size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Effective Date: August 2026',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFC2410C),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Please read these terms carefully before starting your fitness journey.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF141518),
                letterSpacing: -0.5,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),

            Text(
              'By accessing or using the NeuroFit mobile application, you agree to comply with and be bound by the terms, conditions, and notices contained herein.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: const Color(0xFF6B7280),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),

            // Terms Section Cards
            _buildSectionCard(
              icon: Icons.health_and_safety_rounded,
              iconBgColor: const Color(0xFF39FF14).withValues(alpha: 0.18),
              iconColor: const Color(0xFF15803D),
              title: '1. Medical & Fitness Disclaimer',
              content:
                  'NeuroFit is designed for general physical conditioning and informational purposes. Consult your physician or licensed healthcare provider before beginning any new training, nutrition, or workout program.',
            ),
            const SizedBox(height: 14),

            _buildSectionCard(
              icon: Icons.person_outline_rounded,
              iconBgColor: const Color(0xFFFF5F1F).withValues(alpha: 0.15),
              iconColor: const Color(0xFFC2410C),
              title: '2. User Accounts & Integrity',
              content:
                  'You are solely responsible for maintaining the confidentiality of your account credentials. You agree to provide accurate, up-to-date information regarding your physical health metrics.',
            ),
            const SizedBox(height: 14),

            _buildSectionCard(
              icon: Icons.workspace_premium_rounded,
              iconBgColor: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
              iconColor: const Color(0xFF6D28D9),
              title: '3. Memberships & Subscriptions',
              content:
                  'NeuroFit Premium features may auto-renew according to your App Store or Google Play subscription preferences. Subscriptions can be managed or canceled directly via your device store settings at any time.',
            ),
            const SizedBox(height: 14),

            _buildSectionCard(
              icon: Icons.copyright_rounded,
              iconBgColor: const Color(0xFF3B82F6).withValues(alpha: 0.15),
              iconColor: const Color(0xFF1D4ED8),
              title: '4. Intellectual Property Rights',
              content:
                  'All training programs, interactive algorithms, animations, visual layouts, and content published in NeuroFit are proprietary and protected under global intellectual property laws.',
            ),
            const SizedBox(height: 28),

            // Acceptance Note
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF141518),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Need assistance with our terms?',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'For any questions or legal inquiries, please contact legal@neurofit.app.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: const Color(0xFF9CA3AF),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String content,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEEF0F3), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF141518),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              color: const Color(0xFF4B5563),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
