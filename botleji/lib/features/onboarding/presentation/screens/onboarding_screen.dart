import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:botleji/l10n/app_localizations.dart';

const appGreenColor = Color(0xFF00695C);

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<OnboardingPage> _getPages(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return [
      OnboardingPage(
        title: l10n.welcomeToBottleji,
        subtitle: l10n.yourSustainableWasteManagementSolution,
        description: l10n.joinThousandsOfUsersMakingDifference,
        imagePath: 'assets/onboarding/welcome_to_bottleji.png',
      ),
      OnboardingPage(
        title: l10n.createAndTrackDrops,
        subtitle: l10n.forHouseholdUsers,
        description: l10n.easilyCreateDropRequests,
        imagePath: 'assets/onboarding/create_and_track_drops.png',
      ),
      OnboardingPage(
        title: l10n.collectAndEarn,
        subtitle: l10n.forCollectors,
        description: l10n.findNearbyDropsCollectRecyclables,
        imagePath: 'assets/onboarding/collect_and_earn.png',
      ),
      OnboardingPage(
        title: l10n.realTimeUpdates,
        subtitle: l10n.stayConnected,
        description: l10n.getInstantNotificationsAboutDrops,
        imagePath: 'assets/onboarding/real_time_update.png',
      ),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage(BuildContext context) {
    final pages = _getPages(context);
    if (_currentPage < pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_first_time', false);
    
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/permissions');
  }

  void _skipOnboarding() {
    _completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage > 0)
                    TextButton.icon(
                      onPressed: _previousPage,
                      icon: const Icon(Icons.arrow_back, color: appGreenColor),
                      label: Text(
                        AppLocalizations.of(context).back,
                        style: const TextStyle(color: appGreenColor),
                      ),
                    )
                  else
                    const SizedBox(width: 80),
                  TextButton(
                    onPressed: _skipOnboarding,
                    child: Text(
                      AppLocalizations.of(context).skip,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Page content
            Expanded(
              child: Builder(
                builder: (context) {
                  final pages = _getPages(context);
                  return PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemCount: pages.length,
                    itemBuilder: (context, index) {
                      return _buildPage(pages[index]);
                    },
                  );
                },
              ),
            ),
            
            // Bottom section
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Page indicators
                  Builder(
                    builder: (context) {
                      final pages = _getPages(context);
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          pages.length,
                          (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index 
                              ? appGreenColor 
                              : appGreenColor.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Next/Get Started button
                  Builder(
                    builder: (context) {
                      final pages = _getPages(context);
                      return SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () => _nextPage(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: appGreenColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            _currentPage == pages.length - 1 
                                ? AppLocalizations.of(context).getStarted 
                                : AppLocalizations.of(context).next,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration Image
          Expanded(
            flex: 3,
            child: Center(
              child: Image.asset(
                page.imagePath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback to icon if image fails to load
                  return Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: appGreenColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(
                      page.icon ?? Icons.image_not_supported,
                      size: 80,
                      color: appGreenColor,
                    ),
                  );
                },
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Description only (title and subtitle are in the illustration)
          Text(
            page.description,
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String subtitle;
  final String description;
  final String imagePath;
  final IconData? icon; // Optional, used as fallback if image fails to load

  OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.imagePath,
    this.icon,
  });
}
