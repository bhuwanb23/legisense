import 'package:flutter/material.dart';
import 'pages/login/login.dart';
import 'pages/home/home_page.dart';
import 'pages/documents/documents_page.dart';
import 'pages/simulation/simulation_page.dart';
import 'pages/profile/profile_page.dart';
import 'components/bottom_nav_bar.dart';

void main() {
  runApp(const LegisenseApp());
}

class LegisenseApp extends StatelessWidget {
  const LegisenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Legisense',
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

  final List<GlobalKey<NavigatorState>> _navigatorKeys = List.generate(4, (_) => GlobalKey<NavigatorState>());

  Widget _buildTabNavigator(int index) {
    late final Widget rootPage;
    switch (index) {
      case 0:
        rootPage = const HomePage();
        break;
      case 1:
        rootPage = const DocumentsPage();
        break;
      case 2:
        rootPage = const SimulationPage();
        break;
      case 3:
        rootPage = ProfilePage(onLogout: handleLogout);
        break;
      default:
        rootPage = const HomePage();
    }

    return Navigator(
      key: _navigatorKeys[index],
      onGenerateRoute: (settings) {
        return MaterialPageRoute(builder: (_) => rootPage, settings: settings);
      },
    );
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

    final NavigatorState? currentNavigator = _navigatorKeys[currentPageIndex].currentState;
    final bool nestedCanPop = currentNavigator?.canPop() ?? false;

    return PopScope(
      canPop: !nestedCanPop,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (nestedCanPop) {
          currentNavigator!.pop();
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: currentPageIndex,
          children: List.generate(4, _buildTabNavigator),
        ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: currentPageIndex,
          onTap: onPageChanged,
        ),
      ),
    );
  }
}