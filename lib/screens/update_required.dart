import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../generated/l10n.dart';
import '../services/app_version_service.dart';

class UpdateRequiredScreen extends StatelessWidget {
  final AppVersionStatus status;
  const UpdateRequiredScreen({super.key, required this.status});

  Future<void> _openStore(BuildContext context) async {
    final url = status.storeUrl;
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (!await canLaunchUrl(uri)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).networkErrorTryAgain)),
      );
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final hasUrl = status.storeUrl != null && status.storeUrl!.isNotEmpty;
    final body = (status.message?.isNotEmpty ?? false)
        ? status.message!
        : s.updateRequiredBody;

    return Scaffold(
      backgroundColor: const Color(0xFFD3E4C4),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.system_update_alt,
                size: 96,
                color: Color(0xFF567765),
              ),
              const SizedBox(height: 24),
              Text(
                s.updateRequiredTitle,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2C1F),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                body,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              if (status.minVersion?.isNotEmpty ?? false)
                Text(
                  s.updateVersionLabel(status.minVersion!),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: hasUrl ? () => _openStore(context) : null,
                  icon: const Icon(Icons.open_in_new),
                  label: Text(s.updateButton),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF567765),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    disabledBackgroundColor: Colors.grey.shade400,
                    disabledForegroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                s.updateStoreLinkHint,
                style: TextStyle(
                  color: Colors.black.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
