import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'data/sample_documents.dart';
import '../../theme/app_theme.dart';
import '../profile/language/language_scope.dart';
import 'language/strings.dart';
import '../../api/parsed_documents_repository.dart';

class DocumentDisplayPanel extends StatefulWidget {
  const DocumentDisplayPanel({super.key, this.document});

  final SampleDocument? document;

  @override
  State<DocumentDisplayPanel> createState() => _DocumentDisplayPanelState();
}

class _DocumentDisplayPanelState extends State<DocumentDisplayPanel>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  int _currentPageIndex = 0;
  AppLanguage _documentLanguage = AppLanguage.en; // Document-specific language (only affects document content)
  SampleDocument? _translatedDocument;
  bool _isTranslating = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: AppTheme.animationMedium,
      vsync: this,
    );
    _slideController = AnimationController(
      duration: AppTheme.animationMedium,
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void didUpdateWidget(DocumentDisplayPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset to first page when document changes
    if (oldWidget.document != widget.document) {
      _currentPageIndex = 0;
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _goToNextPage() {
    final doc = _translatedDocument ?? widget.document;
    if (doc != null && 
        _currentPageIndex < doc.textBlocks.length - 1) {
      setState(() {
        _currentPageIndex++;
      });
    }
  }

  void _goToPreviousPage() {
    if (_currentPageIndex > 0) {
      setState(() {
        _currentPageIndex--;
      });
    }
  }

  void _ensureValidPageIndex() {
    final doc = _translatedDocument ?? widget.document;
    if (doc != null && _currentPageIndex >= doc.textBlocks.length) {
      _currentPageIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use global app language for UI elements (buttons, labels, etc.)
    final globalLanguage = LanguageScope.of(context).language;
    final i18n = DocumentsI18n.mapFor(globalLanguage);
    
    // Use translated document if available, otherwise use original
    // Document content language is controlled by _documentLanguage (separate from UI language)
    final currentDocument = _translatedDocument ?? widget.document;
    return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.backgroundLight,
              AppTheme.backgroundWhite,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Enhanced Header Section
            _buildHeaderSection(i18n, currentDocument),
            
            // Document Content Area
            Expanded(
              child: _isTranslating 
                ? _buildTranslationLoader(i18n)
                : FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: _buildDocumentContent(i18n, currentDocument),
                    ),
                  ),
            ),
          ],
        ),
    );
  }


  void _showActionMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(AppTheme.spacingS),
        decoration: BoxDecoration(
          color: AppTheme.backgroundWhite,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: AppTheme.spacingS),
              width: 32,
              height: 3,
              decoration: BoxDecoration(
                color: AppTheme.borderMedium,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            const SizedBox(height: AppTheme.spacingM),
            
            // Compact Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCompactActionMenuItem(
                    icon: Icons.bookmark_border,
                    label: ((){
                      final globalLanguage = LanguageScope.of(context).language;
                      final i = DocumentsI18n.mapFor(globalLanguage);
                      return i['docs.action.bookmark'] ?? 'Bookmark';
                    })(),
                    color: AppTheme.primaryBlue,
                    onTap: () {
                      Navigator.pop(context);
                      // Handle bookmark
                    },
                  ),
                  _buildCompactActionMenuItem(
                    icon: Icons.note_add,
                    label: ((){
                      final globalLanguage = LanguageScope.of(context).language;
                      final i = DocumentsI18n.mapFor(globalLanguage);
                      return i['docs.action.note'] ?? 'Add Note';
                    })(),
                    color: AppTheme.successGreen,
                    onTap: () {
                      Navigator.pop(context);
                      // Handle add note
                    },
                  ),
                  _buildCompactActionMenuItem(
                    icon: Icons.highlight,
                    label: ((){
                      final globalLanguage = LanguageScope.of(context).language;
                      final i = DocumentsI18n.mapFor(globalLanguage);
                      return i['docs.action.highlight'] ?? 'Highlight';
                    })(),
                    color: AppTheme.warningOrange,
                    onTap: () {
                      Navigator.pop(context);
                      // Handle highlight
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppTheme.spacingM),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactActionMenuItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spacingS),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingS),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTheme.caption.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(Map<String, String> i18n, [SampleDocument? document]) {
    final currentDocument = document ?? widget.document;
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Compact Header with File Info
          Padding(
            padding: const EdgeInsets.fromLTRB(AppTheme.spacingM, AppTheme.spacingS + 2, AppTheme.spacingM, AppTheme.spacingXS + 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Document Info with Icon
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.description,
                              size: 16,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingS),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  i18n['docs.viewer.title'] ?? 'Document Viewer',
                                  style: AppTheme.heading4.copyWith(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                                if (widget.document != null) ...[
                                  const SizedBox(height: 1),
                                  Text(
                                    'tmpmzdho1yj.pdf',
                                    style: AppTheme.caption.copyWith(
                                      color: AppTheme.textSecondary,
                                      fontSize: 10.5,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Compact Document Tools Toolbar
                    _buildDocumentToolsToolbar(),
                  ],
                ),
                
                // Compact Page Progress Info with FAB
                if (currentDocument != null) ...[
                  const SizedBox(height: AppTheme.spacingXS + 2),
                  Row(
                    children: [
                      _buildCompactInfoPill(
                        'Page ${_currentPageIndex + 1}',
                        AppTheme.primaryBlue,
                        Icons.description,
                      ),
                      const SizedBox(width: 6),
                      _buildCompactInfoPill(
                        '${currentDocument.textBlocks.length} pages',
                        AppTheme.successGreen,
                        Icons.library_books,
                      ),
                      const SizedBox(width: 6),
                      _buildCompactInfoPill(
                        _getDocumentSize(currentDocument),
                        AppTheme.warningOrange,
                        Icons.data_usage,
                      ),
                      const Spacer(),
                      // Compact FAB next to page info
                      _buildCompactFAB(),
                    ],
                  ),
                ],
              ],
            ),
          ),
          
          // Progress Indicator
          if (currentDocument != null) _buildProgressIndicator(currentDocument),
          
          const Divider(height: 1, color: AppTheme.borderLight),
        ],
      ),
    );
  }

  Widget _buildCompactInfoPill(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 10,
            color: color,
          ),
          const SizedBox(width: 3),
          Text(
            text,
            style: AppTheme.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactFAB() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _showActionMenu();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.add,
            color: Colors.white,
            size: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentToolsToolbar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCompactToolbarButton(
            icon: Icons.search,
            tooltip: 'Search in document',
            onPressed: () {},
          ),
          _buildCompactToolbarButton(
            icon: Icons.share,
            tooltip: 'Share document',
            onPressed: () {},
          ),
          _buildCompactToolbarButton(
            icon: Icons.fullscreen,
            tooltip: 'Expand view',
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildCompactToolbarButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size: 14,
            color: AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }


  Widget _buildProgressIndicator([SampleDocument? document]) {
    final doc = document ?? widget.document;
    if (doc == null || doc.textBlocks.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final rawProgress = (doc.textBlocks.length > 1) 
        ? (_currentPageIndex + 1) / doc.textBlocks.length 
        : 1.0;
    
    return Container(
      height: 2.5,
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: rawProgress),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        builder: (context, value, child) {
          return LinearProgressIndicator(
            value: value,
            backgroundColor: AppTheme.borderLight,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
            borderRadius: BorderRadius.circular(2),
          );
        },
      ),
    );
  }

  Widget _buildTranslationLoader(Map<String, String> i18n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingXL),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated loader
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryBlue.withValues(alpha: 0.1),
                  AppTheme.successGreen.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Center(
              child: SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: AppTheme.spacingL),
          
          // Translation status text
          Text(
            i18n['docs.translating'] ?? 'Translating document...',
            style: AppTheme.bodyLarge.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: AppTheme.spacingS),
          
          // Language info
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingM,
              vertical: AppTheme.spacingS,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.successGreen.withValues(alpha: 0.1),
                  AppTheme.successGreen.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.successGreen.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.language,
                  size: 16,
                  color: AppTheme.successGreen,
                ),
                const SizedBox(width: 6),
                Text(
                  'Translating to ${_getLanguageDisplayCode(_documentLanguage)}',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.successGreen,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppTheme.spacingM),
          
          // Progress hint
          Text(
            i18n['docs.translation.progress'] ?? 'This may take a few moments...',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentContent(Map<String, String> i18n, [SampleDocument? document]) {
    final doc = document ?? widget.document;
    if (doc == null || doc.textBlocks.isEmpty) {
      return _buildEmptyState(i18n);
    }

    return Column(
      children: [
        // Current Page Content (more compact)
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(AppTheme.spacingM),
            child: _buildCurrentPageCard(doc),
          ),
        ),
        
        // Navigation Controls
        _buildNavigationControls(i18n),
      ],
    );
  }

  Widget _buildCurrentPageCard([SampleDocument? document]) {
    final doc = document ?? widget.document;
    if (doc == null) return const SizedBox.shrink();
    
    // Ensure page index is valid for the current document
    _ensureValidPageIndex();
    
    final currentPageText = doc.textBlocks[_currentPageIndex];
    
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        // Swipe left to go to next page
        if (details.primaryVelocity! > 0) {
          _goToPreviousPage();
        }
        // Swipe right to go to previous page
        else if (details.primaryVelocity! < 0) {
          _goToNextPage();
        }
      },
      child: AnimatedSwitcher(
        duration: AppTheme.animationMedium,
        transitionBuilder: (Widget child, Animation<double> animation) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            )),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        child: Container(
          key: ValueKey('${_currentPageIndex}_${doc.id}_${_documentLanguage.name}'),
          decoration: BoxDecoration(
            color: AppTheme.backgroundWhite,
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: AppTheme.borderLight.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Compact Page Header (smaller paddings and sizes)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingS + 2, vertical: AppTheme.spacingXS + 2),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryBlue.withValues(alpha: 0.05),
                      AppTheme.primaryBlue.withValues(alpha: 0.02),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppTheme.radiusM),
                    topRight: Radius.circular(AppTheme.radiusM),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.description,
                        size: 13,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingXS + 2),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Page ${_currentPageIndex + 1}',
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.primaryBlue,
                              fontWeight: FontWeight.w600,
                              fontSize: 12.5,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            '${currentPageText.length} characters',
                            style: AppTheme.caption.copyWith(
                              color: AppTheme.textSecondary,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Text(
                        '${_currentPageIndex + 1}',
                        style: AppTheme.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Compact Page Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(AppTheme.spacingS + 2, AppTheme.spacingXS + 2, AppTheme.spacingS + 2, AppTheme.spacingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Compact Typography
                      Text(
                        currentPageText,
                        style: AppTheme.bodyMedium.copyWith(
                          height: 1.5,
                          color: AppTheme.textPrimary,
                          letterSpacing: 0.03,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingXS + 2),
                      
                      // Compact Page Stats
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingS, vertical: AppTheme.spacingXS + 2),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.borderLight),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildCompactStatItem(
                              Icons.text_fields,
                              'Words',
                              '${currentPageText.split(' ').length}',
                              AppTheme.primaryBlue,
                            ),
                            _buildCompactStatItem(
                              Icons.format_size,
                              'Chars',
                              '${currentPageText.length}',
                              AppTheme.successGreen,
                            ),
                            _buildCompactStatItem(
                              Icons.timer,
                              'Read',
                              '${(currentPageText.split(' ').length / 200).ceil()}m',
                              AppTheme.warningOrange,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactStatItem(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            icon,
            size: 12,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTheme.caption.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 10,
          ),
        ),
        Text(
          label,
          style: AppTheme.caption.copyWith(
            color: AppTheme.textSecondary,
            fontSize: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationControls(Map<String, String> i18n) {
    final doc = _translatedDocument ?? widget.document;
    if (doc == null || doc.textBlocks.length <= 1) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingM,
        vertical: AppTheme.spacingS,
      ),
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        border: Border(
          top: BorderSide(color: AppTheme.borderLight),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous Page Button - Compact Arrow
          _buildCompactArrowButton(
            icon: Icons.arrow_back_ios,
            onPressed: _currentPageIndex > 0 ? _goToPreviousPage : null,
            isEnabled: _currentPageIndex > 0,
          ),
          
          // Center section with Page Indicator and Language Selector
          Row(
            children: [
              // Compact Page Indicator
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingM,
                  vertical: AppTheme.spacingS,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryBlue.withValues(alpha: 0.1),
                      AppTheme.primaryBlue.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '${i18n['docs.viewer.page'] ?? 'Page'} ${_currentPageIndex + 1}',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '${i18n['docs.viewer.of'] ?? 'of'} ${doc.textBlocks.length}',
                      style: AppTheme.caption.copyWith(
                        color: AppTheme.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: AppTheme.spacingS),
              
              // Language Selector
              _buildLanguageSelector(),
            ],
          ),
          
          // Next Page Button - Compact Arrow
          _buildCompactArrowButton(
            icon: Icons.arrow_forward_ios,
            onPressed: _currentPageIndex < doc.textBlocks.length - 1 
                ? _goToNextPage 
                : null,
            isEnabled: _currentPageIndex < doc.textBlocks.length - 1,
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isTranslating ? null : _showLanguageSelector,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingM,
            vertical: AppTheme.spacingS,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isTranslating 
                ? [
                    AppTheme.textSecondary.withValues(alpha: 0.1),
                    AppTheme.textSecondary.withValues(alpha: 0.05),
                  ]
                : [
                    AppTheme.successGreen.withValues(alpha: 0.1),
                    AppTheme.successGreen.withValues(alpha: 0.05),
                  ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isTranslating 
                ? AppTheme.textSecondary.withValues(alpha: 0.2)
                : AppTheme.successGreen.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.language,
                    size: 12,
                    color: _isTranslating ? AppTheme.textSecondary : AppTheme.successGreen,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _getLanguageDisplayCode(_documentLanguage),
                    style: AppTheme.bodyMedium.copyWith(
                      color: _isTranslating ? AppTheme.textSecondary : AppTheme.successGreen,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 1),
              Text(
                _isTranslating ? 'Translating...' : 'Language',
                style: AppTheme.caption.copyWith(
                  color: _isTranslating ? AppTheme.warningOrange : AppTheme.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getLanguageCode(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.en:
        return 'en';
      case AppLanguage.hi:
        return 'hi';
      case AppLanguage.ta:
        return 'ta';
      case AppLanguage.te:
        return 'te';
    }
  }

  String _getLanguageDisplayCode(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.en:
        return 'EN';
      case AppLanguage.hi:
        return 'हि';
      case AppLanguage.ta:
        return 'த';
      case AppLanguage.te:
        return 'తె';
    }
  }

  void _showLanguageSelector() {
    final globalLanguage = LanguageScope.of(context).language;
    final i18n = DocumentsI18n.mapFor(globalLanguage);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(AppTheme.spacingS),
        decoration: BoxDecoration(
          color: AppTheme.backgroundWhite,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: AppTheme.spacingS),
              width: 32,
              height: 3,
              decoration: BoxDecoration(
                color: AppTheme.borderMedium,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            const SizedBox(height: AppTheme.spacingM),
            
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
              child: Text(
                i18n['docs.language.select'] ?? 'Select Language',
                style: AppTheme.heading4.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            
            const SizedBox(height: AppTheme.spacingM),
            
            // Language Options
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
              child: Column(
                children: [
                  _buildLanguageOption(
                    AppLanguage.en,
                    i18n['docs.language.english'] ?? 'English',
                    'EN',
                    _documentLanguage == AppLanguage.en,
                  ),
                  _buildLanguageOption(
                    AppLanguage.hi,
                    i18n['docs.language.hindi'] ?? 'हिन्दी',
                    'हि',
                    _documentLanguage == AppLanguage.hi,
                  ),
                  _buildLanguageOption(
                    AppLanguage.ta,
                    i18n['docs.language.tamil'] ?? 'தமிழ்',
                    'த',
                    _documentLanguage == AppLanguage.ta,
                  ),
                  _buildLanguageOption(
                    AppLanguage.te,
                    i18n['docs.language.telugu'] ?? 'తెలుగు',
                    'తె',
                    _documentLanguage == AppLanguage.te,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppTheme.spacingM),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(
    AppLanguage language,
    String name,
    String code,
    bool isSelected,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          // Only change document-specific language, not global app language
          // This affects only the document content, UI elements remain in global language
          setState(() {
            _documentLanguage = language;
            _isTranslating = language != AppLanguage.en;
          });
          Navigator.pop(context);
          
          // If not English, fetch translated content
          if (language != AppLanguage.en && widget.document != null) {
            await _translateDocument(language);
          } else {
            // Reset to original document for English
            developer.log('Switching back to original document (English)', name: 'DocumentDisplayPanel');
            setState(() {
              _translatedDocument = null;
              _isTranslating = false;
              // Reset to first page when switching back to original
              _currentPageIndex = 0;
            });
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingM,
            vertical: AppTheme.spacingS,
          ),
          margin: const EdgeInsets.only(bottom: AppTheme.spacingXS),
          decoration: BoxDecoration(
            color: isSelected 
                ? AppTheme.primaryBlue.withValues(alpha: 0.1)
                : AppTheme.backgroundLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected 
                  ? AppTheme.primaryBlue.withValues(alpha: 0.3)
                  : AppTheme.borderLight,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isSelected 
                      ? AppTheme.primaryBlue
                      : AppTheme.backgroundLight,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected 
                        ? AppTheme.primaryBlue
                        : AppTheme.borderMedium,
                  ),
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        size: 14,
                        color: Colors.white,
                      )
                    : null,
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTheme.bodyMedium.copyWith(
                        color: isSelected 
                            ? AppTheme.primaryBlue
                            : AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      code,
                      style: AppTheme.caption.copyWith(
                        color: isSelected 
                            ? AppTheme.primaryBlue
                            : AppTheme.textSecondary,
                        fontSize: 11,
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

  Widget _buildCompactArrowButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required bool isEnabled,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled ? onPressed : null,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isEnabled 
                ? AppTheme.primaryBlue
                : AppTheme.backgroundLight,
            shape: BoxShape.circle,
            boxShadow: isEnabled ? [
              BoxShadow(
                color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ] : null,
            border: isEnabled ? null : Border.all(
              color: AppTheme.borderLight,
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            size: 14,
            color: isEnabled 
                ? Colors.white
                : AppTheme.textTertiary,
          ),
        ),
      ),
    );
  }




  Widget _buildEmptyState(Map<String, String> i18n) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(AppTheme.spacingXL),
        padding: const EdgeInsets.all(AppTheme.spacingXL),
        decoration: BoxDecoration(
          color: AppTheme.backgroundWhite,
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingXL),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryBlue.withValues(alpha: 0.1),
                    AppTheme.primaryBlue.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.description_outlined,
                size: 64,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: AppTheme.spacingXL),
            Text(
              i18n['docs.viewer.noSelection'] ?? 'No Document Selected',
              style: AppTheme.heading2.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            Text(
              i18n['docs.viewer.selectHint'] ?? 'Choose a document from the list to view its content and analysis',
              style: AppTheme.bodyLarge.copyWith(
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingXL),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingL,
                vertical: AppTheme.spacingM,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryBlue.withValues(alpha: 0.1),
                    AppTheme.primaryBlue.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusL),
                border: Border.all(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.touch_app,
                    size: 20,
                    color: AppTheme.primaryBlue,
                  ),
                  const SizedBox(width: AppTheme.spacingS),
                  Text(
                    i18n['docs.viewer.selectCta'] ?? 'Select a document to get started',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDocumentSize([SampleDocument? document]) {
    final doc = document ?? widget.document;
    if (doc == null) return '';
    final totalChars = doc.textBlocks
        .fold(0, (sum, block) => sum + block.length);
    if (totalChars < 1000) return '$totalChars characters';
    return '${(totalChars / 1000).toStringAsFixed(1)}k characters';
  }

  Future<void> _translateDocument(AppLanguage language) async {
    if (widget.document == null) return;
    
    try {
      final repo = ParsedDocumentsRepository(baseUrl: ApiConfig.baseUrl);
      final documentId = int.parse(widget.document!.id.replaceFirst('server-', ''));
      final languageCode = _getLanguageCode(language);
      
      final translatedDoc = await repo.fetchDocumentDetailWithLanguage(
        id: documentId,
        language: languageCode,
      );
      
      developer.log('Translation loaded successfully for language: ${_getLanguageCode(language)}', name: 'DocumentDisplayPanel');
      setState(() {
        _translatedDocument = translatedDoc;
        _isTranslating = false;
        // Reset to first page when translation is loaded
        _currentPageIndex = 0;
      });
    } catch (e) {
      developer.log('Translation error: $e', name: 'DocumentDisplayPanel');
      setState(() {
        _isTranslating = false;
      });
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Translation failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Removed unused _StatsGrid demo widget

