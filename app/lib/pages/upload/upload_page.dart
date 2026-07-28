import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';
import '../../widgets/home/stub_scaffold.dart';

class UploadPage extends StatelessWidget {
  const UploadPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StubScaffold(
      title: 'Upload / Scan',
      subtitle: 'Camera and file pickers land with the upload flow.',
      child: Container(
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.accentSoft,
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        child: Text(
          'Choose a document',
          style: GoogleFonts.epilogue(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryNavy.withValues(alpha: 0.55),
          ),
        ),
      ),
    );
  }
}
