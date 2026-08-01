import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/app_links.dart';
import '../../theme/app_insets.dart';
import '../../theme/app_theme.dart';
import '../../widgets/home/app_page_header.dart';

/// FAQ + email support.
class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  static const _faqs = <(String, String)>[
    (
      'How do I analyze a document?',
      'Open Upload, pick a PDF/DOCX/image or paste text, then tap Proceed. Legisense extracts the text and runs AI analysis.'
    ),
    (
      'What does the risk score mean?',
      '0–100 overall risk. Higher means more clauses that may need review. Check Flagged clauses and the Risk dashboard for details.'
    ),
    (
      'Is my document private?',
      'Documents are tied to your account and processed on the server you configure. Delete a document anytime from the Documents library.'
    ),
    (
      'How do I export a report?',
      'Open an analysis and tap Export to download a PDF or DOCX summary you can share.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AppPageHeader(
              title: 'Help & Support',
              subtitle: 'FAQ and contact',
              leading: AppHeaderIconButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => Navigator.maybePop(context),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  AppInsets.shellBottom(context),
                ),
                children: [
                  Text(
                    'Frequently asked',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ..._faqs.map(
                    (f) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadii.md),
                          boxShadow: AppShadows.soft,
                        ),
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            dividerColor: Colors.transparent,
                          ),
                          child: ExpansionTile(
                            title: Text(
                              f.$1,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            childrenPadding: const EdgeInsets.fromLTRB(
                              16,
                              0,
                              16,
                              14,
                            ),
                            children: [
                              Text(
                                f.$2,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  height: 1.45,
                                  color: AppColors.mute,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Contact',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      boxShadow: AppShadows.soft,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Email us at ${AppLinks.supportEmail}',
                          style: GoogleFonts.plusJakartaSans(fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () async {
                                  await Clipboard.setData(
                                    const ClipboardData(
                                      text: AppLinks.supportEmail,
                                    ),
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Email copied'),
                                      ),
                                    );
                                  }
                                },
                                child: const Text('Copy email'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton(
                                onPressed: () => AppLinks.openMailto(
                                  AppLinks.supportEmail,
                                  subject: 'Legisense support',
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.ink,
                                ),
                                child: const Text('Email'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
