import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_strings.dart';
import 'models/onboarding_item.dart';
import 'providers/onboarding_provider.dart';
import '../home/home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToHome(BuildContext context) async {
    final provider = context.read<OnboardingProvider>();
    await provider.completeOnboarding();
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => const HomeScreen(),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OnboardingProvider(),
      child: _OnboardingBody(
        pageController: _pageController,
        onFinish: _goToHome,
      ),
    );
  }
}

class _OnboardingBody extends StatelessWidget {
  final PageController pageController;
  final void Function(BuildContext) onFinish;

  const _OnboardingBody({
    required this.pageController,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OnboardingProvider>();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 12, right: 16),
                child: AnimatedOpacity(
                  opacity: provider.isLastPage ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: TextButton(
                    onPressed:
                        provider.isLastPage ? null : () => onFinish(context),
                    child: Text(
                      AppStrings.skip,
                      style: GoogleFonts.nunito(
                        color: AppColors.textLight,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Page view
            Expanded(
              child: PageView.builder(
                controller: pageController,
                itemCount: OnboardingProvider.items.length,
                onPageChanged: provider.setPage,
                itemBuilder: (context, index) {
                  return _OnboardingPage(
                    item: OnboardingProvider.items[index],
                    screenHeight: size.height,
                  );
                },
              ),
            ),

            // Bottom controls
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 40),
              child: Column(
                children: [
                  // Page indicator
                  SmoothPageIndicator(
                    controller: pageController,
                    count: OnboardingProvider.items.length,
                    effect: ExpandingDotsEffect(
                      activeDotColor: AppColors.primary,
                      dotColor: AppColors.primaryPastel,
                      dotHeight: 8,
                      dotWidth: 8,
                      expansionFactor: 3.5,
                      spacing: 6,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Action button
                  SizedBox(
                    width: double.infinity,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: provider.isLastPage
                          ? ElevatedButton(
                              key: const ValueKey('start'),
                              onPressed: provider.isLoading
                                  ? null
                                  : () => onFinish(context),
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: provider.isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.white,
                                      ),
                                    )
                                  : Text(AppStrings.getStarted),
                            )
                          : ElevatedButton(
                              key: const ValueKey('next'),
                              onPressed: () =>
                                  provider.nextPage(pageController),
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(AppStrings.next),
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
}

class _OnboardingPage extends StatelessWidget {
  final OnboardingItem item;
  final double screenHeight;

  const _OnboardingPage({
    required this.item,
    required this.screenHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration area
          Container(
            width: double.infinity,
            height: screenHeight * 0.35,
            decoration: BoxDecoration(
              color: item.backgroundColor,
              borderRadius: BorderRadius.circular(32),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background pattern circles
                Positioned(
                  top: 20,
                  right: 24,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: item.iconColor.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 24,
                  left: 20,
                  child: Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: item.iconColor.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                // Main icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: item.iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Icon(
                    item.icon,
                    size: 52,
                    color: item.iconColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 44),

          // Title
          Text(
            item.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.comfortaa(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            item.description,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 15,
              color: AppColors.textMedium,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
