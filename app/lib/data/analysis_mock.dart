import '../data/dashboard_mock.dart';

enum AnalysisRiskLevel { low, medium, high, missing }

class AnalysisParty {
  const AnalysisParty({
    required this.name,
    required this.role,
    required this.obligations,
  });

  final String name;
  final String role;
  final List<String> obligations;
}

class AnalysisDateRow {
  const AnalysisDateRow({required this.label, required this.value});

  final String label;
  final String value;
}

class AnalysisClause {
  const AnalysisClause({
    required this.id,
    required this.number,
    required this.title,
    required this.risk,
    required this.originalText,
    required this.plainEnglish,
    required this.categories,
  });

  final String id;
  final int number;
  final String title;
  final AnalysisRiskLevel risk;
  final String originalText;
  final String plainEnglish;
  final List<String> categories;
}

class RiskCategory {
  const RiskCategory({
    required this.id,
    required this.title,
    required this.level,
    required this.summary,
    required this.clauseIds,
  });

  final String id;
  final String title;
  final AnalysisRiskLevel level;
  final String summary;
  final List<String> clauseIds;
}

class AnalysisResult {
  const AnalysisResult({
    required this.documentTitle,
    required this.documentType,
    required this.typeEmoji,
    required this.pageCount,
    required this.partyCount,
    required this.analyzedLabel,
    required this.riskScore,
    required this.biasSummary,
    required this.overview,
    required this.parties,
    required this.durationLabel,
    required this.keyDatesCount,
    required this.criticalDates,
    required this.breachScenarios,
    required this.clauses,
    required this.riskCategories,
    required this.highRiskCount,
    required this.mediumRiskCount,
    required this.lowRiskCount,
    required this.missingCount,
  });

  final String documentTitle;
  final String documentType;
  final String typeEmoji;
  final int pageCount;
  final int partyCount;
  final String analyzedLabel;
  final int riskScore;
  final String biasSummary;
  final String overview;
  final List<AnalysisParty> parties;
  final String durationLabel;
  final int keyDatesCount;
  final List<AnalysisDateRow> criticalDates;
  final List<String> breachScenarios;
  final List<AnalysisClause> clauses;
  final List<RiskCategory> riskCategories;
  final int highRiskCount;
  final int mediumRiskCount;
  final int lowRiskCount;
  final int missingCount;

  AnalysisRiskLevel get scoreBand {
    if (riskScore <= 33) return AnalysisRiskLevel.low;
    if (riskScore <= 66) return AnalysisRiskLevel.medium;
    return AnalysisRiskLevel.high;
  }

  static AnalysisResult fromMockDocument(MockDocument doc) {
    return AnalysisMock.forTitle(
      title: doc.title,
      typeLabel: doc.typeLabel,
      analyzedLabel: doc.relativeDate,
    );
  }
}

/// Demo analysis payload until the backend exists.
abstract final class AnalysisMock {
  static AnalysisResult forTitle({
    required String title,
    String typeLabel = 'Rental Agreement',
    String analyzedLabel = 'Just now',
  }) {
    final clauses = <AnalysisClause>[
      const AnalysisClause(
        id: 'c1',
        number: 1,
        title: 'Parties',
        risk: AnalysisRiskLevel.low,
        originalText:
            'This Agreement is entered into between the Landlord and the Tenant named herein.',
        plainEnglish:
            'This contract is between the property owner (Landlord) and the person renting (Tenant).',
        categories: ['Legal Liability Risk'],
      ),
      const AnalysisClause(
        id: 'c2',
        number: 2,
        title: 'Rent & Payment',
        risk: AnalysisRiskLevel.medium,
        originalText:
            'Tenant shall pay rent on or before the 5th of each month without demand.',
        plainEnglish:
            'You must pay rent by the 5th every month, even if the landlord does not send a reminder.',
        categories: ['Financial Risk'],
      ),
      const AnalysisClause(
        id: 'c3',
        number: 3,
        title: 'Security Deposit',
        risk: AnalysisRiskLevel.medium,
        originalText:
            'Landlord may retain the deposit for any damage beyond normal wear and tear.',
        plainEnglish:
            'Your deposit can be kept for damage that is more than everyday use. Vague wording can be disputed.',
        categories: ['Financial Risk'],
      ),
      const AnalysisClause(
        id: 'c4',
        number: 4,
        title: 'Termination',
        risk: AnalysisRiskLevel.high,
        originalText:
            'Landlord may terminate with 7 days notice at any time without cause.',
        plainEnglish:
            'The landlord can end the lease in 7 days for any reason. This heavily favors the landlord.',
        categories: ['Termination Risk', 'Legal Liability Risk'],
      ),
      const AnalysisClause(
        id: 'c5',
        number: 5,
        title: 'Lock-in Period',
        risk: AnalysisRiskLevel.high,
        originalText:
            'Early exit by Tenant within 11 months attracts 2 months rent as penalty.',
        plainEnglish:
            'Leaving early in the first 11 months can cost you two months of rent.',
        categories: ['Financial Risk', 'Termination Risk'],
      ),
      const AnalysisClause(
        id: 'c6',
        number: 6,
        title: 'Maintenance',
        risk: AnalysisRiskLevel.low,
        originalText:
            'Landlord shall maintain structural integrity; Tenant maintains interiors.',
        plainEnglish:
            'Landlord handles major structure; you handle day-to-day interior upkeep.',
        categories: ['Legal Liability Risk'],
      ),
      const AnalysisClause(
        id: 'c7',
        number: 7,
        title: 'Subletting',
        risk: AnalysisRiskLevel.medium,
        originalText:
            'Tenant shall not sublet without prior written consent of Landlord.',
        plainEnglish:
            'You cannot rent the place to someone else unless the landlord agrees in writing.',
        categories: ['Legal Liability Risk'],
      ),
      const AnalysisClause(
        id: 'c8',
        number: 8,
        title: 'Data & Access',
        risk: AnalysisRiskLevel.high,
        originalText:
            'Landlord may enter with 24 hours notice and may install monitoring devices.',
        plainEnglish:
            'Landlord can enter with a day’s notice and may install cameras/sensors — privacy risk.',
        categories: ['Privacy Risk'],
      ),
      const AnalysisClause(
        id: 'c9',
        number: 9,
        title: 'Indemnity',
        risk: AnalysisRiskLevel.high,
        originalText:
            'Tenant indemnifies Landlord against all claims arising from occupancy.',
        plainEnglish:
            'You may have to cover the landlord’s losses from almost anything that happens while you live there.',
        categories: ['Legal Liability Risk', 'Financial Risk'],
      ),
      const AnalysisClause(
        id: 'c10',
        number: 10,
        title: 'Renewal',
        risk: AnalysisRiskLevel.medium,
        originalText:
            'Renewal is at Landlord’s sole discretion with revised rent.',
        plainEnglish:
            'Renewal is not guaranteed and rent can change at the landlord’s choice.',
        categories: ['Termination Risk', 'Financial Risk'],
      ),
      const AnalysisClause(
        id: 'c11',
        number: 11,
        title: 'Dispute Resolution',
        risk: AnalysisRiskLevel.low,
        originalText:
            'Disputes shall first be referred to mediation in the local jurisdiction.',
        plainEnglish:
            'If there is a fight over the contract, try mediation locally before court.',
        categories: ['Legal Liability Risk'],
      ),
      const AnalysisClause(
        id: 'c12',
        number: 12,
        title: 'Force Majeure',
        risk: AnalysisRiskLevel.low,
        originalText:
            'Neither party is liable for delays caused by events beyond reasonable control.',
        plainEnglish:
            'Neither side is blamed for delays from disasters or events they cannot control.',
        categories: ['Legal Liability Risk'],
      ),
      const AnalysisClause(
        id: 'c13',
        number: 13,
        title: 'Notice Address',
        risk: AnalysisRiskLevel.low,
        originalText:
            'Notices are valid when delivered to the addresses listed in Schedule A.',
        plainEnglish:
            'Official messages count when sent to the addresses listed in the schedule.',
        categories: ['Legal Liability Risk'],
      ),
      const AnalysisClause(
        id: 'c14',
        number: 14,
        title: 'Insurance (Missing)',
        risk: AnalysisRiskLevel.missing,
        originalText: 'No insurance requirement clause detected.',
        plainEnglish:
            'The contract does not say who must insure the property or belongings.',
        categories: ['Financial Risk'],
      ),
      const AnalysisClause(
        id: 'c15',
        number: 15,
        title: 'Inventory Schedule (Missing)',
        risk: AnalysisRiskLevel.missing,
        originalText: 'No furnished inventory annex found.',
        plainEnglish:
            'There is no list of furniture/fixtures — deposit disputes become harder to prove.',
        categories: ['Financial Risk'],
      ),
    ];

    final high = clauses.where((c) => c.risk == AnalysisRiskLevel.high).length;
    final medium =
        clauses.where((c) => c.risk == AnalysisRiskLevel.medium).length;
    final low = clauses.where((c) => c.risk == AnalysisRiskLevel.low).length;
    final missing =
        clauses.where((c) => c.risk == AnalysisRiskLevel.missing).length;

    return AnalysisResult(
      documentTitle: title,
      documentType: typeLabel.contains('Lease') || typeLabel.contains('Rent')
          ? 'Rental Agreement'
          : typeLabel,
      typeEmoji: '🏠',
      pageCount: 8,
      partyCount: 2,
      analyzedLabel: analyzedLabel,
      riskScore: 72,
      biasSummary: 'This contract heavily favors the Landlord',
      overview:
          'This is an 11-month residential rental agreement between the Landlord and Tenant. '
          'Rent is due monthly with a lock-in and a short landlord termination window. '
          'Several clauses shift financial and privacy risk toward the Tenant.',
      parties: const [
        AnalysisParty(
          name: 'Rajesh Kumar',
          role: 'Landlord',
          obligations: [
            'Maintain structural integrity of the premises',
            'Provide peaceful possession',
            'Return eligible deposit within 30 days of exit',
          ],
        ),
        AnalysisParty(
          name: 'Anita Sharma',
          role: 'Tenant',
          obligations: [
            'Pay rent by the 5th of each month',
            'Maintain interiors and fixtures',
            'Provide 30 days notice before vacating (after lock-in)',
          ],
        ),
      ],
      durationLabel: '11 months',
      keyDatesCount: 5,
      criticalDates: const [
        AnalysisDateRow(label: 'Start Date', value: '01 Jan 2025'),
        AnalysisDateRow(label: 'End Date', value: '30 Nov 2025'),
        AnalysisDateRow(label: 'Rent Due', value: 'Every 5th of month'),
        AnalysisDateRow(label: 'Notice Period', value: '30 days'),
        AnalysisDateRow(label: 'Renewal Deadline', value: '01 Oct 2025'),
      ],
      breachScenarios: const [
        'Late rent beyond grace may trigger notice and eventual eviction process.',
        'Early exit during lock-in can cost up to 2 months’ rent.',
        'Unauthorized subletting can allow immediate termination.',
      ],
      clauses: clauses,
      riskCategories: const [
        RiskCategory(
          id: 'fin',
          title: 'Financial Risk',
          level: AnalysisRiskLevel.high,
          summary: 'Deposit retention, early-exit penalty, and indemnity exposure.',
          clauseIds: ['c3', 'c5', 'c9'],
        ),
        RiskCategory(
          id: 'leg',
          title: 'Legal Liability Risk',
          level: AnalysisRiskLevel.high,
          summary: 'Broad indemnity and landlord-friendly termination.',
          clauseIds: ['c4', 'c9'],
        ),
        RiskCategory(
          id: 'priv',
          title: 'Privacy Risk',
          level: AnalysisRiskLevel.high,
          summary: 'Entry rights and monitoring devices language.',
          clauseIds: ['c8'],
        ),
        RiskCategory(
          id: 'term',
          title: 'Termination Risk',
          level: AnalysisRiskLevel.high,
          summary: '7-day landlord exit and discretionary renewal.',
          clauseIds: ['c4', 'c5', 'c10'],
        ),
      ],
      highRiskCount: high,
      mediumRiskCount: medium,
      lowRiskCount: low,
      missingCount: missing,
    );
  }

  static AnalysisResult sample() => forTitle(
        title: 'RentAgreement_2024.pdf',
        typeLabel: 'Rental Agreement',
      );
}
