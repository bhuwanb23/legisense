import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/dashboard_mock.dart';
import '../../theme/app_theme.dart';

/// Hero feature card — TripGlide destination card grammar for a document.
class FeaturedDocCard extends StatelessWidget {
  const FeaturedDocCard({
    super.key,
    required this.document,
    required this.onTap,
  });

  final MockDocument document;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final risk = switch (document.risk) {
      DocRisk.low => ('Low risk', AppColors.riskLow),
      DocRisk.medium => ('Medium risk', AppColors.riskMedium),
      DocRisk.high => ('High risk', AppColors.riskHigh),
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        onTap: onTap,
        child: Ink(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF2C2C2C),
                Color(0xFF1A1A1A),
                Color(0xFF3A3A3A),
              ],
            ),
            boxShadow: AppShadows.card,
          ),
          child: Stack(
            children: [
              Positioned(
                top: -30,
                right: -20,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
              ),
              Positioned(
                top: 14,
                right: 14,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.55)),
                  ),
                  child: const Icon(
                    Icons.bookmark_border_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
              Positioned(
                top: 36,
                left: 20,
                child: Icon(
                  Icons.description_outlined,
                  size: 48,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
              Positioned(
                left: 18,
                right: 18,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      document.typeLabel,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      document.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.shield_outlined, size: 14, color: risk.$2),
                        const SizedBox(width: 5),
                        Text(
                          '${document.riskScore} · ${risk.$1}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '· ${document.relativeDate}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 44,
                      padding: const EdgeInsets.only(left: 16, right: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Open analysis',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              color: AppColors.ink,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
