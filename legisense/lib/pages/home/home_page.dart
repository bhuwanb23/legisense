import 'package:flutter/material.dart';
import 'components/components.dart';
import '../../components/main_header.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFEFF6FF), // from-blue-50
              Color(0xFFEEF2FF), // via-indigo-50
              Color(0xFFFAF5FF), // to-purple-50
            ],
          ),
        ),
        child: Stack(
          children: [
            // Background floating icons
            const BackgroundIcons(),
            
            // Main content
            SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Global Main Header
                    const MainHeader(title: 'Legisense'),
                    
                    // Welcome Section
                    const WelcomeSection(),
                    
                    // Upload Zone
                    const UploadZone(),
                    
                    // Recent Files
                    const RecentFiles(),
                    
                    // Quick Actions
                    const QuickActions(),
                    
                    // Bottom padding for better scrolling
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
