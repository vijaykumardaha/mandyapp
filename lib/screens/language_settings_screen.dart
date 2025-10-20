import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mandyapp/helpers/localizations/language.dart';
import 'package:mandyapp/helpers/theme/app_notifier.dart';
import 'package:mandyapp/helpers/theme/app_theme.dart';
import 'package:mandyapp/helpers/widgets/my_spacing.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';
import 'package:provider/provider.dart';

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  late ThemeData theme;
  Language? selectedLanguage;

  @override
  void initState() {
    super.initState();
    theme = AppTheme.shoppingManagerTheme;
    selectedLanguage = Language.currentLanguage;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: MyText.titleMedium('Language Settings', fontWeight: 600),
      ),
      body: Consumer<AppNotifier>(
        builder: (context, appNotifier, child) {
          return ListView(
            padding: MySpacing.all(20),
            children: [
              MySpacing.height(8),
              
              // Header
              MyText.bodyMedium(
                'Choose your preferred language',
                color: theme.colorScheme.onBackground.withOpacity(0.6),
              ),
              
              MySpacing.height(24),
              
              // Language Options
              ...Language.languages.map((language) {
                return Padding(
                  padding: MySpacing.bottom(12),
                  child: _buildLanguageOption(
                    context: context,
                    language: language,
                    isSelected: selectedLanguage?.locale.languageCode == 
                        language.locale.languageCode,
                    onTap: () async {
                      setState(() {
                        selectedLanguage = language;
                      });
                      
                      // Change language
                      await appNotifier.changeLanguage(language);
                      
                      // Show success message
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
                            content: Text('Language changed to ${language.languageName}'),
                            backgroundColor: Colors.green,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),
                );
              }).toList(),
              
              MySpacing.height(20),
              
              // Info Card
              Container(
                padding: MySpacing.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    MySpacing.width(12),
                    Expanded(
                      child: MyText.bodySmall(
                        'Your language preference will be saved and applied across the entire app. Some features may require app restart.',
                        color: theme.colorScheme.onBackground.withOpacity(0.8),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              
              MySpacing.height(24),
              
              // Available Languages Info
              Container(
                padding: MySpacing.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.translate,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                        MySpacing.width(8),
                        MyText.bodyMedium(
                          'Available Languages',
                          fontWeight: 600,
                        ),
                      ],
                    ),
                    MySpacing.height(12),
                    ...Language.languages.map((lang) {
                      return Padding(
                        padding: MySpacing.bottom(6),
                        child: Row(
                          children: [
                            Icon(
                              Icons.circle,
                              size: 6,
                              color: theme.colorScheme.onBackground.withOpacity(0.4),
                            ),
                            MySpacing.width(8),
                            MyText.bodySmall(
                              lang.languageName,
                              color: theme.colorScheme.onBackground.withOpacity(0.7),
                            ),
                            if (lang.supportRTL) ...[
                              MySpacing.width(8),
                              Container(
                                padding: MySpacing.xy(6, 2),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: MyText.bodySmall(
                                  'RTL',
                                  fontSize: 10,
                                  color: theme.colorScheme.primary,
                                  fontWeight: 600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLanguageOption({
    required BuildContext context,
    required Language language,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    // Language flag emojis (you can replace with actual flag images)
    String getFlagEmoji(String languageCode) {
      switch (languageCode) {
        case 'en':
          return '🇬🇧';
        case 'hi':
          return '🇮🇳';
        case 'ar':
          return '🇸🇦';
        case 'fr':
          return '🇫🇷';
        case 'zh':
          return '🇨🇳';
        default:
          return '🌐';
      }
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: MySpacing.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? theme.colorScheme.primary.withOpacity(0.05)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            // Flag/Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary.withOpacity(0.2)
                    : theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  getFlagEmoji(language.locale.languageCode),
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            
            MySpacing.width(16),
            
            // Language Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MyText.bodyLarge(
                    language.languageName,
                    fontWeight: 600,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onBackground,
                  ),
                  MySpacing.height(4),
                  Row(
                    children: [
                      MyText.bodySmall(
                        language.locale.languageCode.toUpperCase(),
                        color: theme.colorScheme.onBackground.withOpacity(0.6),
                      ),
                      if (language.supportRTL) ...[
                        MySpacing.width(8),
                        Container(
                          padding: MySpacing.xy(6, 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: MyText.bodySmall(
                            'RTL Support',
                            fontSize: 10,
                            color: theme.colorScheme.primary,
                            fontWeight: 600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            
            // Selection Indicator
            if (isSelected)
              Container(
                padding: MySpacing.all(4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  size: 16,
                  color: theme.colorScheme.onPrimary,
                ),
              )
            else
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: theme.dividerColor,
                    width: 2,
                  ),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
