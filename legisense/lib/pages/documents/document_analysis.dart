import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'components/components.dart';
import 'data/sample_documents.dart';

class AnalysisPanel extends StatelessWidget {
  const AnalysisPanel({super.key, this.document});

  final SampleDocument? document;

  @override
  Widget build(BuildContext context) {
    final sampleBullets = <String>[
      'This agreement covers a 12-month rental.',
      'Rent due on the 1st of each month.',
      '30-day termination notice by landlord.',
      'Tenant responsible for late fees.',
    ];

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Analysis & Insights',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6B7280),
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              children: [
                // 1. TL;DR Bullets
                TldrBullets(bullets: sampleBullets),
                const SizedBox(height: 16),

                // 2. Clause Breakdown
                const ListHeader(title: 'Clause Breakdown'),
                const SizedBox(height: 12),
                const ClauseBreakdownCard(
                  title: 'Payment Terms',
                  icon: Icons.payments_rounded,
                  originalSnippet: 'Rent must be paid by the 1st of each month via bank transfer.',
                  explanation: 'You need to pay rent on the 1st every month. Other methods may not be accepted.',
                  risk: ClauseRisk.medium,
                ),
                const SizedBox(height: 10),
                const ClauseBreakdownCard(
                  title: 'Termination / Exit',
                  icon: Icons.logout_rounded,
                  originalSnippet: 'Landlord may terminate the lease with 30 days notice.',
                  explanation: 'The landlord can end the agreement with a 30-day notice period.',
                  risk: ClauseRisk.high,
                ),
                const SizedBox(height: 10),
                const ClauseBreakdownCard(
                  title: 'Liability & Damages',
                  icon: Icons.gavel_rounded,
                  originalSnippet: 'Tenant is responsible for all repairs during tenancy.',
                  explanation: 'Repairs are on you, which is unusual. Typically the landlord pays for structural fixes.',
                  risk: ClauseRisk.high,
                ),
                const SizedBox(height: 10),
                const ClauseBreakdownCard(
                  title: 'Confidentiality',
                  icon: Icons.lock_rounded,
                  originalSnippet: 'Tenant shall not disclose any information pertaining to property security systems.',
                  explanation: 'Do not share alarm codes or security details with others.',
                  risk: ClauseRisk.low,
                ),
                const SizedBox(height: 10),
                const ClauseBreakdownCard(
                  title: 'Dispute Resolution',
                  icon: Icons.balance_rounded,
                  originalSnippet: 'Any disputes shall be resolved through arbitration.',
                  explanation: 'Conflicts go to arbitration rather than court. This can limit appeal options.',
                  risk: ClauseRisk.medium,
                ),
                const SizedBox(height: 10),
                const ClauseBreakdownCard(
                  title: 'Renewal / Extension',
                  icon: Icons.autorenew_rounded,
                  originalSnippet: 'Lease may be renewed upon mutual agreement 30 days before expiration.',
                  explanation: 'You and the landlord must agree at least 30 days before the end to renew.',
                  risk: ClauseRisk.low,
                ),

                const SizedBox(height: 16),
                const ListHeader(title: 'Risk Flags & Warnings'),
                const SizedBox(height: 12),
                const RiskFlagsList(items: [
                  RiskFlagItem(
                    text: 'Tenant is responsible for all repairs (High Risk – usually landlord’s duty).',
                    level: 'high',
                    why: 'Industry norms place structural and major repairs on the landlord. This can be costly for tenants.',
                  ),
                  RiskFlagItem(
                    text: 'Early termination penalty is very high compared to standard (Medium Risk).',
                    level: 'medium',
                    why: 'Typical penalties are 1–2 months rent. Excessive penalties can be negotiated down.',
                  ),
                ]),

                const SizedBox(height: 16),
                const ListHeader(title: 'Comparative Context'),
                const SizedBox(height: 12),
                const ComparativeContextCard(
                  label: 'Notice Period',
                  standard: '60 days',
                  contract: '15 days',
                  assessment: 'Risky',
                ),

                const SizedBox(height: 16),
                const ListHeader(title: 'Suggested Questions'),
                const SizedBox(height: 12),
                const SuggestedQuestions(questions: [
                  'What happens if I pay late?',
                  'Can the landlord increase rent?',
                  'What are my exit options?',
                ]),

                const SizedBox(height: 20),
                const SimulationCta(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

