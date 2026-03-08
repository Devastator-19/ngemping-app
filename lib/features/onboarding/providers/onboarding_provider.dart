import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/onboarding_item.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_strings.dart';

const String _kOnboardingSeenKey = 'onboarding_seen';

class OnboardingProvider extends ChangeNotifier {
  int _currentPage = 0;
  bool _isLoading = false;

  int get currentPage => _currentPage;
  bool get isLoading => _isLoading;
  bool get isLastPage => _currentPage == items.length - 1;

  static final List<OnboardingItem> items = [
    OnboardingItem(
      title: AppStrings.onboardingTitles[0],
      description: AppStrings.onboardingDescriptions[0],
      icon: Icons.people_alt_rounded,
      backgroundColor: AppColors.primarySurface,
      iconColor: AppColors.primary,
    ),
    OnboardingItem(
      title: AppStrings.onboardingTitles[1],
      description: AppStrings.onboardingDescriptions[1],
      icon: Icons.event_available_rounded,
      backgroundColor: AppColors.secondarySurface,
      iconColor: AppColors.secondary,
    ),
    OnboardingItem(
      title: AppStrings.onboardingTitles[2],
      description: AppStrings.onboardingDescriptions[2],
      icon: Icons.cabin_rounded,
      backgroundColor: AppColors.primarySurface,
      iconColor: AppColors.primaryDark,
    ),
  ];

  void setPage(int page) {
    _currentPage = page;
    notifyListeners();
  }

  void nextPage(PageController controller) {
    if (_currentPage < items.length - 1) {
      controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> completeOnboarding() async {
    _isLoading = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboardingSeenKey, true);
    _isLoading = false;
    notifyListeners();
  }

  static Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kOnboardingSeenKey) ?? false;
  }
}
