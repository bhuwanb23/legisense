import 'package:flutter/material.dart';

/// Demo dashboard content until the backend exists.
abstract final class DashboardMock {
  static const stats = DashboardStats(
    totalAnalyzed: 32,
    highRisk: 7,
    pendingDeadlines: 4,
  );

  static const filters = <DocTypeFilter>[
    DocTypeFilter(id: 'all', label: 'All', icon: Icons.apps_rounded),
    DocTypeFilter(id: 'nda', label: 'NDA', icon: Icons.lock_outline_rounded),
    DocTypeFilter(
      id: 'lease',
      label: 'Lease',
      icon: Icons.home_work_outlined,
    ),
    DocTypeFilter(
      id: 'employment',
      label: 'Employment',
      icon: Icons.badge_outlined,
    ),
    DocTypeFilter(
      id: 'loan',
      label: 'Loan',
      icon: Icons.account_balance_outlined,
    ),
    DocTypeFilter(
      id: 'insurance',
      label: 'Insurance',
      icon: Icons.health_and_safety_outlined,
    ),
  ];

  static const recentDocuments = <MockDocument>[
    MockDocument(
      id: '1',
      title: 'Vendor NDA — Acme Labs',
      typeId: 'nda',
      typeLabel: 'NDA',
      risk: DocRisk.low,
      relativeDate: '2h ago',
      riskScore: 28,
      daysAgo: 0,
    ),
    MockDocument(
      id: '2',
      title: 'Apartment Lease — Andheri',
      typeId: 'lease',
      typeLabel: 'Lease',
      risk: DocRisk.medium,
      relativeDate: 'Yesterday',
      riskScore: 58,
      daysAgo: 1,
    ),
    MockDocument(
      id: '3',
      title: 'Offer Letter — Product Co',
      typeId: 'employment',
      typeLabel: 'Employment',
      risk: DocRisk.high,
      relativeDate: '3 days ago',
      riskScore: 74,
      daysAgo: 3,
    ),
    MockDocument(
      id: '4',
      title: 'Personal Loan Agreement',
      typeId: 'loan',
      typeLabel: 'Loan',
      risk: DocRisk.medium,
      relativeDate: '1 week ago',
      riskScore: 61,
      daysAgo: 7,
    ),
    MockDocument(
      id: '5',
      title: 'Health Insurance Policy',
      typeId: 'insurance',
      typeLabel: 'Insurance',
      risk: DocRisk.low,
      relativeDate: '2 weeks ago',
      riskScore: 22,
      daysAgo: 14,
    ),
    MockDocument(
      id: '6',
      title: 'RentAgreement_2024.pdf',
      typeId: 'lease',
      typeLabel: 'Rental Agreement',
      risk: DocRisk.high,
      relativeDate: '2 days ago',
      riskScore: 72,
      daysAgo: 2,
    ),
    MockDocument(
      id: '7',
      title: 'Freelance MSA — Pixel Studio',
      typeId: 'employment',
      typeLabel: 'Employment',
      risk: DocRisk.medium,
      relativeDate: '4 days ago',
      riskScore: 49,
      daysAgo: 4,
    ),
    MockDocument(
      id: '8',
      title: 'Mutual NDA — Northwind',
      typeId: 'nda',
      typeLabel: 'NDA',
      risk: DocRisk.low,
      relativeDate: '5 days ago',
      riskScore: 18,
      daysAgo: 5,
    ),
  ];

  static List<MockDocument> filtered(String typeId) {
    if (typeId == 'all') return recentDocuments;
    return recentDocuments.where((d) => d.typeId == typeId).toList();
  }

  /// History chips: All / Lease / NDA / Employment / Others
  static List<MockDocument> historyFiltered(String chipId) {
    return switch (chipId) {
      'lease' => recentDocuments
          .where((d) => d.typeId == 'lease' || d.typeLabel.contains('Rent'))
          .toList(),
      'nda' => recentDocuments.where((d) => d.typeId == 'nda').toList(),
      'employment' =>
        recentDocuments.where((d) => d.typeId == 'employment').toList(),
      'others' => recentDocuments
          .where(
            (d) =>
                d.typeId != 'lease' &&
                d.typeId != 'nda' &&
                d.typeId != 'employment' &&
                !d.typeLabel.contains('Rent'),
          )
          .toList(),
      _ => List<MockDocument>.from(recentDocuments),
    };
  }
}

class DashboardStats {
  const DashboardStats({
    required this.totalAnalyzed,
    required this.highRisk,
    required this.pendingDeadlines,
  });

  final int totalAnalyzed;
  final int highRisk;
  final int pendingDeadlines;
}

class DocTypeFilter {
  const DocTypeFilter({
    required this.id,
    required this.label,
    required this.icon,
  });

  final String id;
  final String label;
  final IconData icon;
}

enum DocRisk { low, medium, high }

class MockDocument {
  const MockDocument({
    required this.id,
    required this.title,
    required this.typeId,
    required this.typeLabel,
    required this.risk,
    required this.relativeDate,
    this.riskScore = 50,
    this.daysAgo = 0,
  });

  final String id;
  final String title;
  final String typeId;
  final String typeLabel;
  final DocRisk risk;
  final String relativeDate;
  final int riskScore;
  final int daysAgo;
}
