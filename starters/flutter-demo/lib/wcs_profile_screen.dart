import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class WcsProfileScreen extends StatelessWidget {
  const WcsProfileScreen({super.key});

  static const _services = <String>[
    'Digital storytelling and workshop facilitation',
    'Training and learning content for care professionals',
    'Care-tech product strategy and implementation',
    'Public advocacy campaigns and inclusive communications',
  ];

  static const _reasons = <String>[
    'Domain expertise in dementia care and social justice',
    'Human-centered UX for elders, families, and care teams',
    'Cross-platform delivery across web and mobile',
    'AI-ready architecture with practical rollout support',
  ];

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('World Class Scholars')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Powering Digital Innovation in Care Tech',
              style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(
              'Founded by Dr. Christopher Appiah-Thompson, World Class Scholars advances equity in disability, mental health, dementia care, education, and digital storytelling.',
              style: textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            _SectionCard(
              title: 'Why Choose Us for Your App?',
              items: _reasons,
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Services',
              items: _services,
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contact',
                      style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton(
                          onPressed: () => _openUrl('mailto:Christopher.appiahthompson@myworldclass.org'),
                          child: const Text('Email'),
                        ),
                        OutlinedButton(
                          onPressed: () => _openUrl('https://www.linkedin.com/in/christopher-appiah-thompson-a2014045'),
                          child: const Text('LinkedIn'),
                        ),
                        OutlinedButton(
                          onPressed: () => _openUrl('https://worldclassscholars.org'),
                          child: const Text('Website'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('- $item', style: textTheme.bodyMedium),
              ),
            )
          ],
        ),
      ),
    );
  }
}
