import 'package:flutter/material.dart';
import '../../../shared/utils/auth_helper.dart';
import '../../../shared/widgets/meditrack_logo.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingSlideData> _slides = [
    OnboardingSlideData(
      title: "Track Vitals Instantly",
      description: "Log blood pressure, glucose, oxygen, and heart rate with smart color-coded warning indicators.",
      icon: Icons.monitor_heart_rounded,
      color: const Color(0xFF6366F1), // Indigo
      accentColor: const Color(0xFF818CF8),
    ),
    OnboardingSlideData(
      title: "Pill Reminder & Stock Alerts",
      description: "Set personalized medication schedules and receive auto warnings when your medicine stock is running low.",
      icon: Icons.medication_rounded,
      color: const Color(0xFF1D9E75), // Teal
      accentColor: const Color(0xFF34D399),
    ),
    OnboardingSlideData(
      title: "Instant SOS & Emergency Contact",
      description: "Trigger emergency distress signals with one tap to send automated WhatsApp, SMS alerts, and call your close ones.",
      icon: Icons.sos_rounded,
      color: const Color(0xFFF43F5E), // Rose
      accentColor: const Color(0xFFFB7185),
    ),
    OnboardingSlideData(
      title: "Auto Sync & Health Reports",
      description: "Securely backup your logs to the database cloud and export beautiful PDF medical summaries for your next doctor visit.",
      icon: Icons.cloud_done_rounded,
      color: const Color(0xFF6366F1), // Indigo
      accentColor: const Color(0xFF818CF8),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onSkip() {
    AuthHelper().completeOnboarding();
  }

  void _onNext() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      AuthHelper().completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Stack(
          children: [
            // Top Bar: Skip Option
            Positioned(
              top: 8,
              right: 16,
              child: TextButton(
                onPressed: _onSkip,
                child: const Text(
                  'Skip',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),

            // Main Slide Contents
            Positioned.fill(
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  // App branding headers
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const MediTrackLogo(size: 32),
                      const SizedBox(width: 8),
                      Text(
                        'MediTrack',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF0F172A),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  
                  // Interactive Feature Slides PageView
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _slides.length,
                      onPageChanged: (idx) => setState(() => _currentPage = idx),
                      itemBuilder: (context, index) {
                        final slide = _slides[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Unique feature visual card
                              Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  color: slide.color.withValues(alpha: 0.08),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: slide.color.withValues(alpha: 0.15),
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  slide.icon,
                                  size: 64,
                                  color: slide.color,
                                ),
                              ),
                              const SizedBox(height: 40),
                              
                              // Feature Title
                              Text(
                                slide.title,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Feature Description
                              Text(
                                slide.description,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 15,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // Bottom Navigation controls
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Page Dots Indicator
                        Row(
                          children: List.generate(
                            _slides.length,
                            (index) => AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              height: 6,
                              width: _currentPage == index ? 20 : 6,
                              decoration: BoxDecoration(
                                color: _currentPage == index
                                    ? _slides[_currentPage].color
                                    : const Color(0xFFCBD5E1),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),

                        // Next / Start Button with beautiful feedback animation
                        ElevatedButton(
                          onPressed: _onNext,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _slides[_currentPage].color,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                            shadowColor: _slides[_currentPage].color.withValues(alpha: 0.3),
                          ),
                          child: Text(
                            _currentPage == _slides.length - 1 ? 'GET STARTED' : 'NEXT',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              letterSpacing: 0.5,
                            ),
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
    );
  }
}

class OnboardingSlideData {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final Color accentColor;

  OnboardingSlideData({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.accentColor,
  });
}
