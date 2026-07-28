import 'package:flutter/material.dart';

/// Demo dashboard content until the backend exists.
abstract final class DashboardMock {
  static const stats = DashboardStats(
    totalAnalyzed: 24,
    highRisk: 5,
    pendingDeadlines: 3,
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
    ),
    MockDocument(
      id: '2',
      title: 'Apartment Lease — Andheri',
      typeId: 'lease',
      typeLabel: 'Lease',
      risk: DocRisk.medium,
      relativeDate: 'Yesterday',
    ),
    MockDocument(
      id: '3',
      title: 'Offer Letter — Product Co',
      typeId: 'employment',
      typeLabel: 'Employment',
      risk: DocRisk.high,
      relativeDate: '3 days ago',
    ),
    MockDocument(
      id: '4',
      title: 'Personal Loan Agreement',
      typeId: 'loan',
      typeLabel: 'Loan',
      risk: DocRisk.medium,
      relativeDate: '1 week ago',
    ),
    MockDocument(
      id: '5',
      title: 'Health Insurance Policy',
      typeId: 'insurance',
      typeLabel: 'Insurance',
      risk: DocRisk.low,
      relativeDate: '2 weeks ago',
    ),
  ];

  static List<MockDocument> filtered(String typeId) {
    if (typeId == 'all') return recentDocuments;
    return recentDocuments.where((d) => d.typeId == typeId).toList();
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
  });

  final String id;
  final String title;
  final String typeId;
  final String typeLabel;
  final DocRisk risk;
  final String relativeDate;
}
