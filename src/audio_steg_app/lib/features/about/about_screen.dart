import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/about_constants.dart';
import '../../app/app_strings.dart';
import '../shared/tab_scroll_body.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final scheme = Theme.of(context).colorScheme;
    return TabScrollBody(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: scheme.primaryContainer,
                      child: Icon(
                        Icons.person_outline,
                        size: 36,
                        color: scheme.onPrimaryContainer,
                      ),
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
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: s.aboutSupervisorSection,
          children: [
            _InfoTile(
              icon: Icons.school_outlined,
              title: s.aboutSupervisorName,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: s.aboutLinksSection,
          children: [
            _LinkTile(
              icon: Icons.code,
              label: s.aboutGitHubApp,
              url: AboutConstants.gitHubApp,
              errorMessage: s.aboutOpenLinkFailed,
            ),
            _LinkTile(
              icon: Icons.school_outlined,
              label: s.aboutGitHubThesis,
              url: AboutConstants.gitHubThesis,
              errorMessage: s.aboutOpenLinkFailed,
            ),
            _LinkTile(
              icon: Icons.language,
              label: s.aboutPersonalSite,
              url: AboutConstants.personalSite,
              errorMessage: s.aboutOpenLinkFailed,
            ),
            _LinkTile(
              icon: Icons.business_outlined,
              label: s.aboutCompanySite,
              url: AboutConstants.companySite,
              errorMessage: s.aboutOpenLinkFailed,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: s.aboutContactSection,
          children: [
            _LinkTile(
              icon: Icons.phone_in_talk_outlined,
              label: s.aboutPhoneLandline,
              subtitle: AboutConstants.phoneLandline,
              url: 'tel:${AboutConstants.phoneLandline}',
              errorMessage: s.aboutOpenLinkFailed,
            ),
            _LinkTile(
              icon: Icons.smartphone_outlined,
              label: s.aboutPhoneMobile,
              subtitle: AboutConstants.phoneMobile,
              url: 'tel:${AboutConstants.phoneMobile}',
              errorMessage: s.aboutOpenLinkFailed,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
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
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
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
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;

  const _InfoTile({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: scheme.primary),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final String url;
  final String errorMessage;

  const _LinkTile({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.url,
    required this.errorMessage,
  });

  Future<void> _open(BuildContext context) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: scheme.primary),
      title: Text(label),
      subtitle: subtitle != null
          ? Text(subtitle!, style: TextStyle(color: scheme.primary))
          : Text(
              url,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
      trailing: Icon(Icons.open_in_new, color: scheme.onSurfaceVariant),
      onTap: () => _open(context),
    );
  }
}
