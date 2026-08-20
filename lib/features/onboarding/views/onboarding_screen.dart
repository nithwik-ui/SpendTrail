import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../../../config/constants.dart';
import '../../../core/providers/settings_provider.dart';
import '../../dashboard/views/home_navigation_parent.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _budgetController = TextEditingController(text: '12000');
  String _selectedCurrency = 'INR';
  String? _pickedImagePath;

  Future<void> _pickImage() async {
    HapticFeedback.lightImpact();
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
      );
      if (image != null) {
        // Open crop tool with 1:1 square ratio
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: image.path,
          aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Profile Photo',
              toolbarColor: AppColors.primary,
              toolbarWidgetColor: Colors.white,
              activeControlsWidgetColor: AppColors.primary,
              lockAspectRatio: true,
              hideBottomControls: false,
            ),
            IOSUiSettings(
              title: 'Crop Profile Photo',
              aspectRatioLockEnabled: true,
              resetAspectRatioEnabled: false,
            ),
          ],
        );
        if (croppedFile != null) {
          setState(() {
            _pickedImagePath = croppedFile.path;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to pick profile photo')),
        );
      }
    }
  }

  void _submit() {
    HapticFeedback.lightImpact();
    final name = _nameController.text.trim();
    final double budget = double.tryParse(_budgetController.text.trim()) ?? 12000.0;

    ref.read(settingsProvider.notifier).completeOnboarding(
          name: name.isEmpty ? '' : name,
          budget: budget,
          currency: _selectedCurrency,
          profilePath: _pickedImagePath,
        );

    // Direct transition to navigation coordinator
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const HomeNavigationParent(),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final cardBgColor = isDark ? AppColors.darkCard : AppColors.surfaceContainerLowest;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.surfaceContainer;
    final inputBgColor = isDark ? AppColors.darkBg : AppColors.surfaceContainerLow;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom -
                  48.0,
            ),
            child: IntrinsicHeight(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24.0),
                    // 1. APP LOGO & SUBTITLE
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20.0),
                        child: Image.asset(
                          'assets/icon.png',
                          height: 80.0,
                          width: 80.0,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    Text(
                      "Let's set up your personal notebook for tracking expenses",
                      style: AppConstants.getBodyMdStyle(color: secondaryTextColor),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32.0),

                    // 2. CIRCULAR AVATAR WITH BADGE
                    Center(
                      child: Stack(
                        children: [
                          GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              width: 100.0,
                              height: 100.0,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: cardBgColor,
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: ClipOval(
                                child: _pickedImagePath != null
                                    ? (kIsWeb
                                        ? Image.network(_pickedImagePath!, fit: BoxFit.cover)
                                        : Image.file(File(_pickedImagePath!), fit: BoxFit.cover))
                                    : Container(
                                        color: AppColors.primary.withOpacity(0.08),
                                        child: Icon(
                                          Icons.person_rounded,
                                          size: 48.0,
                                          color: AppColors.primary.withOpacity(0.6),
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                padding: const EdgeInsets.all(6.0),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.add_rounded,
                                  color: Colors.white,
                                  size: 16.0,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 36.0),

                    // 3. CARD CONTAINER WITH INPUT FIELDS
                    Container(
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        color: cardBgColor,
                        borderRadius: BorderRadius.circular(16.0), // 16px corner radius audit
                        border: Border.all(color: borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: isDark ? Colors.transparent : Colors.black.withOpacity(0.03),
                            blurRadius: 10.0,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Field 1: Name Input
                          Text(
                            'What should we call you?',
                            style: AppConstants.getLabelSmStyle(color: secondaryTextColor).copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6.0),
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              hintText: 'Your Name',
                              hintStyle: AppConstants.getBodyMdStyle(color: secondaryTextColor.withOpacity(0.5)),
                              filled: true,
                              fillColor: inputBgColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                            ),
                            style: AppConstants.getBodyMdStyle(color: primaryTextColor),
                          ),
                          const SizedBox(height: 20.0),

                          // Field 2: Default Currency Dropdown
                          Text(
                            'Default Currency',
                            style: AppConstants.getLabelSmStyle(color: secondaryTextColor).copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6.0),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            decoration: BoxDecoration(
                              color: inputBgColor,
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedCurrency,
                                isExpanded: true,
                                dropdownColor: cardBgColor,
                                items: const [
                                  DropdownMenuItem(value: 'INR', child: Text('₹ INR (Indian Rupee)')),
                                  DropdownMenuItem(value: 'USD', child: Text('\$ USD (US Dollar)')),
                                  DropdownMenuItem(value: 'EUR', child: Text('€ EUR (Euro)')),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _selectedCurrency = val;
                                    });
                                  }
                                },
                                style: AppConstants.getBodyMdStyle(color: primaryTextColor).copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20.0),

                          // Field 3: Monthly Budget Target
                          Text(
                            'Monthly Budget Target',
                            style: AppConstants.getLabelSmStyle(color: secondaryTextColor).copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6.0),
                          TextFormField(
                            controller: _budgetController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              prefixText: '${AppConstants.defaultCurrencySymbol} ',
                              prefixStyle: AppConstants.getHeadlineSmStyle(color: primaryTextColor).copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              filled: true,
                              fillColor: inputBgColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                            ),
                            style: AppConstants.getHeadlineSmStyle(color: primaryTextColor).copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 22.0,
                            ),
                          ),
                          const SizedBox(height: 12.0),
                          
                          // Helper text
                          Center(
                            child: Text(
                              'You can always adjust this later.',
                              style: AppConstants.getLabelSmStyle(color: secondaryTextColor.withOpacity(0.7)),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 500.ms, curve: Curves.easeOutCubic).slideY(begin: 0.08, end: 0),

                    const Spacer(),
                    const SizedBox(height: 24.0),

                    // 4. GET STARTED BUTTON (Teal, Arrow Icon, Rounded 16px, Soft Shadow)
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 4.0,
                        shadowColor: AppColors.primary.withOpacity(0.2),
                        minimumSize: const Size(double.infinity, 54.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.0), // 16px corner radius audit
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Get Started',
                            style: AppConstants.getHeadlineSmStyle(color: Colors.white).copyWith(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          const Icon(Icons.arrow_forward_rounded, size: 20.0),
                        ],
                      ),
                    ).animate().fadeIn(delay: 200.ms, duration: 400.ms, curve: Curves.easeOutCubic),
                    const SizedBox(height: 8.0),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
