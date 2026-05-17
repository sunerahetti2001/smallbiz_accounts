import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/language_provider.dart';
import '../../utils/colors.dart';
import 'basic_info_screen.dart';
import 'email_auth_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final localizations = AppLocalizations.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1A4D8C),
                Color(0xFF1E3A8A),
                Color(0xFF1E1B4B),
              ],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: _buildLanguageSelector(context, localizations, isSmallScreen),
                ),
                const Spacer(flex: 1),
                Center(
                  child: Container(
                    width: isSmallScreen ? 80 : 100,
                    height: isSmallScreen ? 80 : 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.account_balance,
                      size: isSmallScreen ? 40 : 50,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: isSmallScreen ? 20 : 32),
                Text(
                  localizations.appName,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 26 : 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 10 : 16),
                Text(
                  localizations.welcomeMessage,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    color: Colors.white.withOpacity(0.8),
                    height: 1.5,
                  ),
                ),
                const Spacer(flex: 1),
                if (userProvider.isLoading)
                  const Center(child: CircularProgressIndicator(color: Colors.white))
                else ...[
                  _buildButton(
                    text: localizations.login,
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const EmailAuthScreen(isLogin: true))
                      );
                    },
                    color: Colors.white,
                    textColor: AppColors.primary,
                    isSmallScreen: isSmallScreen,
                  ),
                  SizedBox(height: isSmallScreen ? 10 : 16),
                  _buildButton(
                    text: localizations.signUp,
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const EmailAuthScreen(isLogin: false))
                      );
                    },
                    color: Colors.transparent,
                    textColor: Colors.white,
                    isOutlined: true,
                    isSmallScreen: isSmallScreen,
                  ),
                  SizedBox(height: isSmallScreen ? 16 : 24),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const BasicInfoScreen(),
                          ),
                        );
                      },
                      child: Text(
                        localizations.guestMode,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontWeight: FontWeight.normal,
                          fontSize: isSmallScreen ? 12 : 14,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
                SizedBox(height: isSmallScreen ? 12 : 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSelector(BuildContext context, AppLocalizations localizations, bool isSmallScreen) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(25),
      ),
      child: InkWell(
        onTap: () => _showLanguageDialog(context, localizations, languageProvider),
        borderRadius: BorderRadius.circular(25),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 10 : 16,
            vertical: isSmallScreen ? 6 : 10,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.language, color: Colors.white, size: isSmallScreen ? 16 : 20),
              SizedBox(width: isSmallScreen ? 4 : 8),
              Text(
                languageProvider.isSinhala ? 'සිංහල' : 'English',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isSmallScreen ? 12 : 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: isSmallScreen ? 2 : 4),
              Icon(Icons.arrow_drop_down, color: Colors.white, size: isSmallScreen ? 16 : 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, AppLocalizations localizations, LanguageProvider languageProvider) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(localizations.selectLanguage),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Text('🇬🇧', style: TextStyle(fontSize: 24)),
                title: Text(localizations.english),
                trailing: !languageProvider.isSinhala
                    ? const Icon(Icons.check_circle, color: AppColors.primary)
                    : null,
                onTap: () {
                  languageProvider.changeLanguage('en');
                  Navigator.pop(dialogContext);
                  _showLanguageChangedSnackBar(context, localizations);
                },
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Text('🇱🇰', style: TextStyle(fontSize: 24)),
                title: Text(localizations.sinhala),
                trailing: languageProvider.isSinhala
                    ? const Icon(Icons.check_circle, color: AppColors.primary)
                    : null,
                onTap: () {
                  languageProvider.changeLanguage('si');
                  Navigator.pop(dialogContext);
                  _showLanguageChangedSnackBar(context, localizations);
                },
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLanguageChangedSnackBar(BuildContext context, AppLocalizations localizations) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(localizations.languageChanged),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildButton({
    required String text,
    required VoidCallback onPressed,
    required Color color,
    required Color textColor,
    bool isOutlined = false,
    required bool isSmallScreen,
  }) {
    return SizedBox(
      width: double.infinity,
      height: isSmallScreen ? 48 : 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          elevation: isOutlined ? 0 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: isOutlined ? const BorderSide(color: Colors.white) : BorderSide.none,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(fontSize: isSmallScreen ? 14 : 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}