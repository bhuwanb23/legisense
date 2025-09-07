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

final List<SampleDocument> kSampleDocuments = [];

/// A global, mutable collection that can be appended to at runtime for
/// uploaded/parsed documents. The UI can show `kSampleDocuments + uploaded`.
final List<SampleDocument> kUploadedDocuments = [];


