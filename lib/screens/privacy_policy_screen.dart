import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
          'Privacy Policy',
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
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.security_rounded, color: Color(0xFF059669), size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Last Updated: August 2026',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF059669),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Your privacy and health data security are our highest priorities.',
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
              'At NeuroFit, we are committed to safeguarding your personal and biometric fitness information. This Privacy Policy details the types of data we collect and how we ensure its utmost security.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: const Color(0xFF6B7280),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),

            // Policy Section Cards
            _buildSectionCard(
              icon: Icons.fitness_center_rounded,
              iconBgColor: const Color(0xFF39FF14).withValues(alpha: 0.18),
              iconColor: const Color(0xFF15803D),
              title: '1. Health & Fitness Data Collection',
              content:
                  'We collect biometric workout metrics, exercise frequencies, workout durations, heart rate logs, and goals you enter into NeuroFit. This data is solely utilized to tailor your personalized training algorithms.',
            ),
            const SizedBox(height: 14),

            _buildSectionCard(
              icon: Icons.lock_outline_rounded,
              iconBgColor: const Color(0xFFFF5F1F).withValues(alpha: 0.15),
              iconColor: const Color(0xFFC2410C),
              title: '2. End-to-End Encryption',
              content:
                  'All personal data transmitted between your device and our cloud servers is encrypted using industry-standard AES-256 protocols. Your biometric records are never stored in unencrypted plain text.',
            ),
            const SizedBox(height: 14),

            _buildSectionCard(
              icon: Icons.share_location_rounded,
              iconBgColor: const Color(0xFF3B82F6).withValues(alpha: 0.15),
              iconColor: const Color(0xFF1D4ED8),
              title: '3. Third-Party Sharing',
              content:
                  'NeuroFit does not sell, rent, or monetize your personal information to third-party data brokers or advertisers. We only integrate with Apple Health and Google Fit with your explicit consent.',
            ),
            const SizedBox(height: 14),

            _buildSectionCard(
              icon: Icons.delete_outline_rounded,
              iconBgColor: const Color(0xFFEF4444).withValues(alpha: 0.15),
              iconColor: const Color(0xFFB91C1C),
              title: '4. Account & Data Deletion Rights',
              content:
                  'You have the complete right to request the deletion of your account and associated workout logs at any time via your account settings. All associated data will be permanently purged within 30 days.',
            ),
            const SizedBox(height: 28),

            // Support Contact Card
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
                    'Questions about your privacy?',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Reach out to our Data Protection Officer at privacy@neurofit.app for any concerns.',
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
