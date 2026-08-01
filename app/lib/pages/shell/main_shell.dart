import 'package:flutter/material.dart';

import '../../data/analysis_mock.dart';
import '../../theme/app_theme.dart';
import '../../widgets/home/app_bottom_nav.dart';
import '../analysis/analysis_results_page.dart';
import '../documents/documents_page.dart';
import '../home/home_page.dart';
import '../notifications/notifications_page.dart';
import '../profile/profile_page.dart';
import '../upload/upload_page.dart';

/// Access shell tab navigation from nested routes (Upload → Analysis, etc.).
class ShellScope extends InheritedWidget {
  const ShellScope({
    super.key,
    required this.goToTab,
    required this.openAnalysisOnDocuments,
    required this.openDocuments,
    required super.child,
  });

  final void Function(int index) goToTab;
  final void Function(AnalysisResult result) openAnalysisOnDocuments;
  final void Function({String? query, String? filter}) openDocuments;

  static ShellScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ShellScope>();
  }

  static ShellScope of(BuildContext context) {
    final scope = maybeOf(context);
    assert(scope != null, 'ShellScope not found');
    return scope!;
  }

  @override
  bool updateShouldNotify(ShellScope oldWidget) => false;
}

/// Post-auth root — floating dock + per-tab nested navigators
/// so Analysis / Edit Profile / Processing keep the navbar.
class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _index = widget.initialIndex;
  String? _docsQuery;
  String? _docsFilter;

  final _navKeys = List<GlobalKey<NavigatorState>>.generate(
    5,
    (_) => GlobalKey<NavigatorState>(),
  );

  void goToTab(int index) {
    if (index < 0 || index > 4) return;
    if (index == _index) {
      _navKeys[index].currentState?.popUntil((route) => route.isFirst);
      return;
    }
    setState(() => _index = index);
  }

  void openDocuments({String? query, String? filter}) {
    setState(() {
      _docsQuery = query;
      _docsFilter = filter;
      _index = 1;
    });
    _navKeys[1].currentState?.popUntil((route) => route.isFirst);
  }

  /// Clear upload stack, switch to Documents, open analysis there.
  /// Back from analysis returns to the Documents list — never the loader.
  void openAnalysisOnDocuments(AnalysisResult result) {
    _navKeys[2].currentState?.popUntil((route) => route.isFirst);
    _navKeys[1].currentState?.popUntil((route) => route.isFirst);
    setState(() => _index = 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navKeys[1].currentState?.push(
        MaterialPageRoute<void>(
          builder: (_) => AnalysisResultsPage(result: result),
        ),
      );
    });
  }

  Future<bool> _onWillPop() async {
    final nav = _navKeys[_index].currentState;
    if (nav != null && nav.canPop()) {
      nav.pop();
      return false;
    }
    return true;
  }

  Widget _tabNavigator({
    required int tabIndex,
    required Widget root,
  }) {
    return Navigator(
      key: _navKeys[tabIndex],
      onGenerateRoute: (settings) {
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => root,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ShellScope(
      goToTab: goToTab,
      openAnalysisOnDocuments: openAnalysisOnDocuments,
      openDocuments: openDocuments,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          final shouldLeave = await _onWillPop();
          if (shouldLeave && context.mounted) {
            Navigator.of(context).maybePop();
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.bg,
          extendBody: true,
          body: IndexedStack(
            index: _index,
            children: [
              _tabNavigator(
                tabIndex: 0,
                root: HomePage(
                  onOpenUpload: () => goToTab(2),
                  onOpenDocuments: () => openDocuments(),
                  onOpenNotifications: () => goToTab(3),
                ),
              ),
              _tabNavigator(
                tabIndex: 1,
                root: DocumentsPage(
                  onOpenUpload: () => goToTab(2),
                  initialQuery: _docsQuery,
                  initialFilter: _docsFilter,
                  onInitialApplied: () {
                    if (_docsQuery != null || _docsFilter != null) {
                      setState(() {
                        _docsQuery = null;
                        _docsFilter = null;
                      });
                    }
                  },
                ),
              ),
              _tabNavigator(
                tabIndex: 2,
                root: const UploadPage(),
              ),
              _tabNavigator(
                tabIndex: 3,
                root: const NotificationsPage(),
              ),
              _tabNavigator(
                tabIndex: 4,
                root: const ProfilePage(),
              ),
            ],
          ),
          bottomNavigationBar: AppBottomNav(
            currentIndex: _index,
            onChanged: goToTab,
          ),
        ),
      ),
    );
  }
}
