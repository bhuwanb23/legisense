import 'package:flutter/material.dart';
import 'pages/login/login.dart';
import 'pages/home/home_page.dart';
import 'pages/documents/documents_page.dart';
import 'pages/simulation/simulation_page.dart';
import 'pages/profile/profile_page.dart';
import 'components/bottom_nav_bar.dart';

// Global navigation key to access the main app state
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Global reference to the AppWrapper state
_AppWrapperState? _appWrapperState;

void main() {
  runApp(const LegisenseApp());
}

class LegisenseApp extends StatelessWidget {
  const LegisenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Legisense',
      navigatorKey: navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E3A8A)),
        useMaterial3: true,
      ),
      home: const AppWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AppWrapper extends StatefulWidget {
  const AppWrapper({super.key});

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  bool isLoggedIn = false;
  int currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _appWrapperState = this;
  }

  @override
  void dispose() {
    _appWrapperState = null;
    super.dispose();
  }

  void handleLoginSuccess() {
    setState(() {
      isLoggedIn = true;
    });
  }

  void handleLogout() {
    setState(() {
      isLoggedIn = false;
      currentPageIndex = 0;
    });
  }

  void onPageChanged(int index) {
    setState(() {
      currentPageIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!isLoggedIn) {
      return LoginPage(
        onLoginSuccess: handleLoginSuccess,
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: currentPageIndex,
        children: [
          const HomePage(),
          const DocumentsPage(),
          const SimulationPage(),
          ProfilePage(onLogout: handleLogout),
        ],
      ),
        bottomNavigationBar: BottomNavBar(
        currentIndex: currentPageIndex,
        onTap: onPageChanged,
      ),
    );
  }
}

// Global function to navigate to a specific page from anywhere in the app
void navigateToPage(int pageIndex) {
  // Try to change the page index first
  if (_appWrapperState != null) {
    _appWrapperState!.onPageChanged(pageIndex);
  } else {
    // Alternative approach: use the navigator key to access the context
    final context = navigatorKey.currentContext;
    if (context != null) {
      // Find the AppWrapper in the widget tree
      final appWrapperState = context.findAncestorStateOfType<_AppWrapperState>();
      if (appWrapperState != null) {
        appWrapperState.onPageChanged(pageIndex);
      }
    }
  }
}
