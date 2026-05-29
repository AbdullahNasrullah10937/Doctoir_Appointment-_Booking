import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const List<Map<String, String>> _faqs = <Map<String, String>>[
    {'q': 'How do I cancel an appointment?', 'a': 'Go to the Appointments tab, find your upcoming booking, and tap the Cancel button. Cancellations must be made at least 2 hours in advance.'},
    {'q': 'How does live queue tracking work?', 'a': 'After confirming a booking, your Queue Tracker shows real-time token updates. You\'ll receive push alerts when 2 patients are ahead of you.'},
    {'q': 'How do I share my health records?', 'a': 'Open the Records tab, select any record, and use the Share button to send via WhatsApp, email, or download as PDF.'},
    {'q': 'Can I book a video consultation?', 'a': 'Yes! During the booking flow, toggle the "Video Consultation" switch. You\'ll receive a meeting link when your token is close.'},
    {'q': 'Is my health data secure?', 'a': 'All health data is encrypted with AES-256 before being stored. We comply with healthcare data privacy standards.'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(4, 8, 16, 14),
              decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
              child: Row(
                children: <Widget>[
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  ),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Help & Support', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                        Text('We\'re here for you 24/7', style: TextStyle(color: Colors.white60, fontSize: 11)),
                      ],
                    ),
                  ),
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                    child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppTheme.space4),
                children: <Widget>[
                  // Search bar
                  const TextField(
                    decoration: InputDecoration(
                      hintText: 'Search FAQs...',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const SectionHeading(title: 'Frequently Asked Questions'),
                  // FAQs
                  ...List<Widget>.generate(_faqs.length, (index) {
                    final faq = _faqs[index];
                    return MediQCard(
                      padding: EdgeInsets.zero,
                      child: Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(horizontal: AppTheme.space3, vertical: 4),
                          childrenPadding: EdgeInsets.zero,
                          leading: Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(color: AppTheme.primarySoft, shape: BoxShape.circle),
                            child: const Icon(Icons.help_outline_rounded, color: AppTheme.accentBlue, size: 16),
                          ),
                          title: Text(faq['q']!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          children: <Widget>[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(AppTheme.space4, 0, AppTheme.space4, AppTheme.space3),
                              child: Text(faq['a']!, style: const TextStyle(color: AppTheme.textSecondary, height: 1.5, fontSize: 13)),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  const SectionHeading(title: 'Contact Us'),
                  // Contact cards
                  _ContactCard(icon: Icons.chat_rounded, color: AppTheme.accentBlue, title: 'Live Chat', subtitle: 'Average response in 2 minutes', onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Live chat opened (mock).')))),
                  _ContactCard(icon: Icons.email_rounded, color: AppTheme.success, title: 'Email Support', subtitle: 'support@mediq.pk', onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email client opened (mock).')))),
                  _ContactCard(icon: Icons.phone_rounded, color: AppTheme.warning, title: 'Call Helpline', subtitle: '+92-311-MEDIQ-PK', onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dialing helpline (mock).')))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.icon, required this.color, required this.title, required this.subtitle, required this.onTap});
  final IconData icon;
  final Color color;
  final String title, subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MediQCard(
      onTap: onTap,
      child: Row(
        children: <Widget>[
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                Text(subtitle, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: color),
        ],
      ),
    );
  }
}
