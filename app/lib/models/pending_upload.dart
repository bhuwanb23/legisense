/// User-selected document awaiting processing.
enum UploadSource { file, scan, paste, url }

class PendingUpload {
  const PendingUpload({
    required this.source,
    required this.title,
    this.detail,
    this.localPath,
    this.bytes,
    this.text,
    this.url,
    this.documentId,
  });

  final UploadSource source;
  final String title;
  final String? detail;
  final String? localPath;
  final List<int>? bytes;
  final String? text;
  final String? url;
  /// Set after successful API upload.
  final int? documentId;

  String get sourceLabel => switch (source) {
        UploadSource.file => 'File upload',
        UploadSource.scan => 'Camera scan',
        UploadSource.paste => 'Pasted text',
        UploadSource.url => 'URL import',
      };

  PendingUpload copyWith({int? documentId}) {
    return PendingUpload(
      source: source,
      title: title,
      detail: detail,
      localPath: localPath,
      bytes: bytes,
      text: text,
      url: url,
      documentId: documentId ?? this.documentId,
    );
  }
}
