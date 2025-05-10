import 'package:chatmcp/page/layout/widgets/llm_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:chatmcp/widgets/ink_icon.dart';
import 'package:chatmcp/utils/color.dart';
import 'package:flutter/services.dart';
import 'package:chatmcp/utils/platform.dart';
import 'package:chatmcp/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:chatmcp/widgets/upgradge.dart';
import 'package:url_launcher/url_launcher.dart';

class AppInfo extends StatelessWidget {
  final String? appVersion;
  final String? appWebsite;
  final String? githubUrl;
  final String? licenseInfo;

  const AppInfo({
    super.key,
    this.appVersion,
    this.appWebsite,
    this.githubUrl = 'https://github.com/daodao97/chatmcp',
    this.licenseInfo = 'Apache License 2.0',
  });

  Future<String> _getAppVersion() async {
    // 如果已提供版本号，则使用提供的版本号
    if (appVersion != null) {
      return appVersion!;
    }

    try {
      // 获取本地存储
      final prefs = await SharedPreferences.getInstance();

      // 获取存储的版本号，如果没有则从PackageInfo获取
      final storedVersion = prefs.getString('app_version');
      if (storedVersion != null) {
        return storedVersion;
      }

      // 获取当前应用版本
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      debugPrint('当前应用版本: $currentVersion');

      // 存储版本号以供下次使用
      await prefs.setString('app_version', currentVersion);

      return currentVersion;
    } catch (e) {
      debugPrint('获取版本号时出错: $e');
      return '1.0.0'; // 默认版本号
    }
  }

  void _showAboutDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final version = await _getAppVersion();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Container(
          width: kIsMobile ? null : 450,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.asset(
                  'assets/logo.png',
                  width: 80,
                  height: 80,
                ),
              ),
              const SizedBox(height: 16),

              // App Name
              Text(
                'ChatMCP',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getThemeTextColor(context),
                ),
              ),

              // Version
              Text(
                'v$version',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.getThemeTextColor(context).withAlpha(120),
                ),
              ),
              const SizedBox(height: 16),

              // Description
              Text(
                l10n.appDescription,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.getThemeTextColor(context),
                ),
              ),
              const SizedBox(height: 24),

              // Links
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (appWebsite != null)
                    _buildLinkButton(
                      context,
                      LlmIcon(icon: "github"),
                      l10n.visitWebsite,
                      appWebsite!,
                    ),
                  if (appWebsite != null && githubUrl != null)
                    const SizedBox(width: 12),
                  if (githubUrl != null)
                    _buildLinkButton(
                      context,
                      LlmIcon(icon: "github"),
                      'GitHub',
                      githubUrl!,
                    ),
                  const SizedBox(width: 12),
                  UpgradeNotice(
                    owner: 'daodao97',
                    repo: 'chatmcp',
                    showCheckUpdate: true,
                    autoCheck: true,
                  ),
                ],
              ),

              if (licenseInfo != null) ...[
                const SizedBox(height: 16),
                Text(
                  licenseInfo!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        AppColors.getThemeTextColor(context).withOpacity(0.5),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLinkButton(
      BuildContext context, LlmIcon icon, String label, String url) {
    return InkWell(
      onTap: () {
        launchUrl(Uri.parse(url));
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.getInkIconHoverColor(context),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: AppColors.getThemeTextColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showAboutDialog(context),
      child: LlmIcon(icon: "github"),
    );
  }
}
