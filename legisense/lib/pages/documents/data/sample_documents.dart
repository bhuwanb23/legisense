import 'package:flutter/material.dart';

class SampleDocInsight {
  const SampleDocInsight({required this.icon, required this.title, required this.description, required this.level});
  final IconData icon;
  final String title;
  final String description;
  final String level; // 'low' | 'medium' | 'high'
}

class SampleDocument {
  const SampleDocument({
    required this.id,
    required this.title,
    required this.meta,
    required this.ext,
    required this.tldr,
    required this.textBlocks,
    required this.imageUrls,
    required this.insights,
  });

  final String id;
  final String title;
  final String meta; // size • time
  final String ext;
  final String tldr;
  final List<String> textBlocks; // paragraphs for viewer
  final List<String> imageUrls; // optional images for viewer
  final List<SampleDocInsight> insights;
}

final List<SampleDocument> kSampleDocuments = [
  SampleDocument(
    id: 'doc-1',
    title: 'Employment Contract.pdf',
    meta: 'PDF • 2.3 MB • 2h ago',
    ext: 'pdf',
    tldr:
        'This contract contains moderate risk clauses. Payment terms are standard with 30-day periods. Termination clause favors the employer with limited employee protections. Liability is capped but exclusions are broad.',
    textBlocks: [
      'EMPLOYMENT AGREEMENT\nThis Employment Agreement (the "Agreement") is made effective as of the Effective Date between Company and Employee.',
      '1. Term and Termination\nEither party may terminate this Agreement with written notice as specified herein.',
      '2. Compensation\nEmployee will receive salary and benefits as set forth in attached Schedule A.',
    ],
    imageUrls: [
      // leave empty or add sample assets/urls
    ],
    insights: [
      SampleDocInsight(
        icon: Icons.credit_card,
        title: 'Payment Terms',
        description: 'Standard 30-day payment terms with on-time bonus provision.',
        level: 'low',
      ),
      SampleDocInsight(
        icon: Icons.meeting_room,
        title: 'Termination Clause',
        description: 'Employer can terminate with 15-day notice; employee requires 60 days.',
        level: 'medium',
      ),
      SampleDocInsight(
        icon: Icons.shield,
        title: 'Liability Limitations',
        description: 'Broad exclusions; cap at 12 months of compensation.',
        level: 'high',
      ),
    ],
  ),
  SampleDocument(
    id: 'doc-2',
    title: 'Service Agreement.docx',
    meta: 'DOCX • 456 KB • yesterday',
    ext: 'docx',
    tldr:
        'This agreement presents low risk for payment and data protection, with a few medium risks around intellectual property ownership and termination.',
    textBlocks: [
      'SERVICE AGREEMENT\nThis Service Agreement is entered into between Client and Vendor...',
      'Scope of Services\nVendor agrees to provide the services described in Schedule 1.',
    ],
    imageUrls: [],
    insights: [
      SampleDocInsight(
        icon: Icons.storage,
        title: 'Data Protection',
        description: 'GDPR aligned; retention and deletion clearly defined.',
        level: 'low',
      ),
      SampleDocInsight(
        icon: Icons.lightbulb,
        title: 'Intellectual Property',
        description: 'Work-for-hire ambiguous; derivative work ownership needs clarity.',
        level: 'medium',
      ),
    ],
  ),
  SampleDocument(
    id: 'doc-3',
    title: 'NDA Template.pdf',
    meta: 'PDF • 1.1 MB • 3 days ago',
    ext: 'pdf',
    tldr: 'Low risk standard NDA with mutual confidentiality obligations and reasonable term.',
    textBlocks: [
      'NON-DISCLOSURE AGREEMENT\nThis NDA is made between Discloser and Recipient...',
    ],
    imageUrls: [],
    insights: [
      SampleDocInsight(
        icon: Icons.verified_user,
        title: 'Confidentiality',
        description: 'Standard mutual obligations; reasonable exclusions.',
        level: 'low',
      ),
    ],
  ),
];

/// A global, mutable collection that can be appended to at runtime for
/// uploaded/parsed documents. The UI can show `kSampleDocuments + uploaded`.
final List<SampleDocument> kUploadedDocuments = [];


