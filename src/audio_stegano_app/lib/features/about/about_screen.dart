import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/about_constants.dart';
import '../../app/app_icon_accents.dart';
import '../../app/app_strings.dart';
import '../../app/app_ui_tokens.dart';
import '../../app/app_version.dart';
import '../shared/accent_icon.dart';
import '../shared/app_section_card.dart';
import '../shared/directional_latin_text.dart';
import '../shared/page_app_bar.dart';
import '../shared/tab_scroll_body.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: PageAppBar(title: s.aboutUsTab),
      body: TabScrollBody(
      children: [
        AppSectionCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: scheme.primaryContainer,
                    foregroundColor: scheme.onPrimaryContainer,
                    backgroundImage: const AssetImage(
                      AboutConstants.profilePhotoAsset,
                    ),
                    onBackgroundImageError: (_, _) {},
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.aboutProfileTitle,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          s.aboutThesis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${s.aboutVersion}: ${AppVersion.display}',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: scheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(s.aboutBio, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
        const SizedBox(height: AppUiTokens.sectionGap),
        _SectionCard(
          title: s.aboutSupervisorSection,
          children: [
            _InfoTile(
              icon: Icons.school_outlined,
              accent: AppIconAccent.thesis,
              title: s.aboutSupervisorName,
            ),
          ],
        ),
        const SizedBox(height: AppUiTokens.sectionGap),
        _SectionCard(
          title: s.aboutLinksSection,
          children: [
            _LinkTile(
              icon: Icons.code,
              accent: AppIconAccent.github,
              label: s.aboutGitHubApp,
              url: AboutConstants.gitHubApp,
              errorMessage: s.aboutOpenLinkFailed,
            ),
            _LinkTile(
              icon: Icons.school_outlined,
              accent: AppIconAccent.thesis,
              label: s.aboutGitHubThesis,
              url: AboutConstants.gitHubThesis,
              errorMessage: s.aboutOpenLinkFailed,
            ),
            _LinkTile(
              icon: Icons.language,
              accent: AppIconAccent.web,
              label: s.aboutPersonalSite,
              url: AboutConstants.personalSite,
              errorMessage: s.aboutOpenLinkFailed,
            ),
            _LinkTile(
              icon: Icons.business_outlined,
              accent: AppIconAccent.company,
              label: s.aboutCompanySite,
              url: AboutConstants.companySite,
              errorMessage: s.aboutOpenLinkFailed,
            ),
          ],
        ),
        const SizedBox(height: AppUiTokens.sectionGap),
        _SectionCard(
          title: s.aboutContactSection,
          children: [
            _LinkTile(
              icon: Icons.phone_in_talk_outlined,
              accent: AppIconAccent.phone,
              label: s.aboutCall,
              subtitle: AboutConstants.phoneNumber,
              url: 'tel:${AboutConstants.phoneNumber}',
              errorMessage: s.aboutOpenLinkFailed,
            ),
            _LinkTile(
              icon: Icons.email_outlined,
              accent: AppIconAccent.email,
              label: s.aboutEmail,
              subtitle: AboutConstants.email,
              url: 'mailto:${AboutConstants.email}',
              errorMessage: s.aboutOpenLinkFailed,
            ),
          ],
        ),
        const SizedBox(height: AppUiTokens.sectionGap),
        AppSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.aboutAlgo,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                s.aboutAlgoBody,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final AppIconAccent accent;
  final String title;

  const _InfoTile({
    required this.icon,
    required this.accent,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return ListTile(
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: AppIconAccents.container(accent, brightness),
        child: AccentIcon(icon, accent: accent, size: 20),
      ),
      title: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  final IconData icon;
  final AppIconAccent accent;
  final String label;
  final String? subtitle;
  final String url;
  final String errorMessage;

  const _LinkTile({
    required this.icon,
    required this.accent,
    required this.label,
    this.subtitle,
    required this.url,
    required this.errorMessage,
  });

  Future<void> _open(BuildContext context) async {
    final uri = Uri.parse(url);
    final mode = uri.scheme == 'http' || uri.scheme == 'https'
        ? LaunchMode.externalApplication
        : LaunchMode.platformDefault;
    if (!await launchUrl(uri, mode: mode)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    return ListTile(
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: AppIconAccents.container(accent, brightness),
        child: AccentIcon(icon, accent: accent, size: 20),
      ),
      title: Text(label),
      subtitle: subtitle != null
          ? DirectionalLatinText(
              subtitle!,
              style: TextStyle(color: scheme.primary),
            )
          : DirectionalLatinText(
              url,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
      trailing: AccentIcon(
        Icons.open_in_new,
        accent: accent,
        size: 18,
        selected: false,
      ),
      onTap: () => _open(context),
    );
  }
}
