/// User-selected document awaiting mock processing.
enum UploadSource { file, scan, paste, url }

class PendingUpload {
  const PendingUpload({
    required this.source,
    required this.title,
    this.detail,
    this.localPath,
  });

  final UploadSource source;
  final String title;
  final String? detail;
  final String? localPath;

  String get sourceLabel => switch (source) {
        UploadSource.file => 'File upload',
        UploadSource.scan => 'Camera scan',
        UploadSource.paste => 'Pasted text',
        UploadSource.url => 'URL import',
      };
}
