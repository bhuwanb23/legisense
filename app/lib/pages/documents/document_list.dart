import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'components/components.dart';
import '../profile/language/language_scope.dart';
import 'language/strings.dart';
import '../../theme/app_theme.dart';

class DocumentListPanel extends StatefulWidget {
  const DocumentListPanel({super.key});

  @override
  State<DocumentListPanel> createState() => _DocumentListPanelState();
}

class DocumentListController {
  void refreshDocuments() {}
  void forceUIUpdate() {}
}

class _DocumentListPanelState extends State<DocumentListPanel> {
  @override
  Widget build(BuildContext context) {
    final i18n = DocumentsI18n.mapFor(
      LanguageScope.maybeOf(context)?.language ?? AppLanguage.en,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SearchField(
          onChanged: (_) {},
        ),
        ListHeader(title: i18n['docs.list.header'] ?? 'Your documents'),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    FontAwesomeIcons.fileCirclePlus,
                    size: 40,
                    color: AppTheme.textSecondary.withValues(alpha: 0.45),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    i18n['docs.empty.title'] ?? 'No documents',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    i18n['docs.empty.subtitle'] ??
                        'Your library will fill up once uploads are connected to the new backend.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
