/// Mock notification feed until the backend exists.
abstract final class NotificationsMock {
  static const items = <AppNotification>[
    AppNotification(
      id: 'n1',
      type: NotificationType.deadline,
      title: 'Rent due in 3 days',
      body: 'Apartment Lease — Andheri: payment window closes on the 5th.',
      timeLabel: '2h ago',
      docId: '2',
      unread: true,
    ),
    AppNotification(
      id: 'n2',
      type: NotificationType.analysisReady,
      title: 'Analysis ready',
      body: 'Vendor NDA — Acme Labs scored 28 (low risk).',
      timeLabel: '5h ago',
      docId: '1',
      unread: true,
    ),
    AppNotification(
      id: 'n3',
      type: NotificationType.tip,
      title: 'Tip: lock-in clauses',
      body: 'Early-exit penalties above 1 month rent deserve a second look.',
      timeLabel: 'Yesterday',
      unread: false,
    ),
    AppNotification(
      id: 'n4',
      type: NotificationType.deadline,
      title: 'Renewal window opens',
      body: 'Offer Letter — Product Co: notice period starts in 10 days.',
      timeLabel: 'Yesterday',
      docId: '3',
      unread: false,
    ),
    AppNotification(
      id: 'n5',
      type: NotificationType.analysisReady,
      title: 'High-risk flags found',
      body: 'RentAgreement_2024.pdf — 4 high-risk clauses need review.',
      timeLabel: '2 days ago',
      docId: '6',
      unread: false,
    ),
    AppNotification(
      id: 'n6',
      type: NotificationType.tip,
      title: 'Tip: indemnity language',
      body: 'Broad “all claims” indemnity often shifts too much liability to you.',
      timeLabel: '3 days ago',
      unread: false,
    ),
    AppNotification(
      id: 'n7',
      type: NotificationType.analysisReady,
      title: 'Insurance policy reviewed',
      body: 'Health Insurance Policy scored 22 — coverage gaps noted.',
      timeLabel: '1 week ago',
      docId: '5',
      unread: false,
    ),
    AppNotification(
      id: 'n8',
      type: NotificationType.deadline,
      title: 'Loan EMI reminder',
      body: 'Personal Loan Agreement: next installment due Friday.',
      timeLabel: '1 week ago',
      docId: '4',
      unread: false,
    ),
  ];
}

enum NotificationType { deadline, analysisReady, tip }

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.timeLabel,
    this.docId,
    this.unread = false,
  });

  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final String timeLabel;
  final String? docId;
  final bool unread;
}
