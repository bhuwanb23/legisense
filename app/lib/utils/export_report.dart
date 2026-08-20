import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../repositories/documents_repository.dart';
import '../../services/api_exception.dart';

/// Shared export/share helper for analysis reports.
Future<void> exportAndShareReport(
  BuildContext context, {
  required int? documentId,
  required String title,
  String format = 'pdf',
}) async {
  if (documentId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export needs a saved document.')),
    );
    return;
  }
  final messenger = ScaffoldMessenger.of(context);
  messenger.showSnackBar(
    SnackBar(content: Text('Preparing $format…')),
  );
  try {
    final file = await DocumentsRepository().exportReport(
      documentId,
      format: format,
    );
    if (kIsWeb) {
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              file.bytes,
              mimeType: file.mime,
              name: file.filename,
            ),
          ],
          subject: title,
        ),
      );
    } else {
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/${file.filename}';
      await File(path).writeAsBytes(file.bytes);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(path, mimeType: file.mime)],
          subject: title,
        ),
      );
    }
  } on ApiException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.message)));
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.toString())));
  }
}

Future<String?> pickExportFormat(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    useRootNavigator: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: Text(
                'Export PDF',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
              ),
              onTap: () => Navigator.pop(context, 'pdf'),
            ),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: Text(
                'Export DOCX',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
              ),
              onTap: () => Navigator.pop(context, 'docx'),
            ),
          ],
        ),
      );
    },
  );
}
