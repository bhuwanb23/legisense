import 'package:flutter/material.dart';
import 'data/sample_documents.dart';
import '../../theme/app_theme.dart';

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
    if (widget.document != null && 
        _currentPageIndex < widget.document!.textBlocks.length - 1) {
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

  @override
  Widget build(BuildContext context) {
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
            _buildHeaderSection(),
            
            // Document Content Area
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _buildDocumentContent(),
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
                    label: 'Bookmark',
                    color: AppTheme.primaryBlue,
                    onTap: () {
                      Navigator.pop(context);
                      // Handle bookmark
                    },
                  ),
                  _buildCompactActionMenuItem(
                    icon: Icons.note_add,
                    label: 'Add Note',
                    color: AppTheme.successGreen,
                    onTap: () {
                      Navigator.pop(context);
                      // Handle add note
                    },
                  ),
                  _buildCompactActionMenuItem(
                    icon: Icons.highlight,
                    label: 'Highlight',
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

  Widget _buildHeaderSection() {
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
            padding: const EdgeInsets.fromLTRB(AppTheme.spacingM, AppTheme.spacingM, AppTheme.spacingM, AppTheme.spacingS),
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
                                  'Document Viewer',
                                  style: AppTheme.heading4.copyWith(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                if (widget.document != null) ...[
                                  const SizedBox(height: 1),
                                  Text(
                                    'tmpmzdho1yj.pdf',
                                    style: AppTheme.caption.copyWith(
                                      color: AppTheme.textSecondary,
                                      fontSize: 11,
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
                if (widget.document != null) ...[
                  const SizedBox(height: AppTheme.spacingS),
                  Row(
                    children: [
                      _buildCompactInfoPill(
                        'Page ${_currentPageIndex + 1}',
                        AppTheme.primaryBlue,
                        Icons.description,
                      ),
                      const SizedBox(width: 6),
                      _buildCompactInfoPill(
                        '${widget.document!.textBlocks.length} pages',
                        AppTheme.successGreen,
                        Icons.library_books,
                      ),
                      const SizedBox(width: 6),
                      _buildCompactInfoPill(
                        _getDocumentSize(),
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
          if (widget.document != null) _buildProgressIndicator(),
          
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


  Widget _buildProgressIndicator() {
    if (widget.document == null || widget.document!.textBlocks.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final progress = (widget.document!.textBlocks.length > 1) 
        ? (_currentPageIndex + 1) / widget.document!.textBlocks.length 
        : 1.0;
    
    return Container(
      height: 3,
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
      child: LinearProgressIndicator(
        value: progress,
        backgroundColor: AppTheme.borderLight,
        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildDocumentContent() {
    if (widget.document == null || widget.document!.textBlocks.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        // Current Page Content
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(AppTheme.spacingL),
            child: _buildCurrentPageCard(),
          ),
        ),
        
        // Navigation Controls
        _buildNavigationControls(),
      ],
    );
  }

  Widget _buildCurrentPageCard() {
    final currentPageText = widget.document!.textBlocks[_currentPageIndex];
    
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
          key: ValueKey(_currentPageIndex),
          decoration: BoxDecoration(
            color: AppTheme.backgroundWhite,
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: AppTheme.borderLight.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Compact Page Header
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingM),
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
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.description,
                        size: 14,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingS),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Page ${_currentPageIndex + 1}',
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.primaryBlue,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            '${currentPageText.length} characters',
                            style: AppTheme.caption.copyWith(
                              color: AppTheme.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
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
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Compact Page Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Compact Typography
                      Text(
                        currentPageText,
                        style: AppTheme.bodyMedium.copyWith(
                          height: 1.6,
                          color: AppTheme.textPrimary,
                          letterSpacing: 0.1,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingM),
                      
                      // Compact Page Stats
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacingS),
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

  Widget _buildNavigationControls() {
    if (widget.document == null || widget.document!.textBlocks.length <= 1) {
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
                  'Page ${_currentPageIndex + 1}',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'of ${widget.document!.textBlocks.length}',
                  style: AppTheme.caption.copyWith(
                    color: AppTheme.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          
          // Next Page Button - Compact Arrow
          _buildCompactArrowButton(
            icon: Icons.arrow_forward_ios,
            onPressed: _currentPageIndex < widget.document!.textBlocks.length - 1 
                ? _goToNextPage 
                : null,
            isEnabled: _currentPageIndex < widget.document!.textBlocks.length - 1,
          ),
        ],
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




  Widget _buildEmptyState() {
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
              'No Document Selected',
              style: AppTheme.heading2.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            Text(
              'Choose a document from the list to view its content and analysis',
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
                    'Select a document to get started',
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

  String _getDocumentSize() {
    if (widget.document == null) return '';
    final totalChars = widget.document!.textBlocks
        .fold(0, (sum, block) => sum + block.length);
    if (totalChars < 1000) return '$totalChars characters';
    return '${(totalChars / 1000).toStringAsFixed(1)}k characters';
  }
}

// Removed unused _StatsGrid demo widget

