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

  List<Widget> get pages => [
    const HomePage(),
    const DocumentsPage(),
    const SimulationPage(),
    ProfilePage(onLogout: handleLogout),
  ];

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
        children: pages,
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: currentPageIndex,
        onTap: onPageChanged,
      ),
    );
  }
}