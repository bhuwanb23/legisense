import 'package:flutter/material.dart';
import 'components/gradient_background.dart';
import 'components/logo_section.dart';
import 'components/hero_illustration.dart';
import 'components/welcome_text.dart';
import 'components/sign_in_buttons.dart';
import 'components/demo_section.dart';
import 'components/footer.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              children: [
                const SizedBox(height: 40),
                
                // Logo Section
                const LogoSection(),
                
                const SizedBox(height: 32),
                
                // Hero Illustration
                const HeroIllustration(),
                
                const SizedBox(height: 32),
                
                // Welcome Text
                const WelcomeText(),
                
                const SizedBox(height: 32),
                
                // Sign In Buttons
                const SignInButtons(),
                
                const SizedBox(height: 24),
                
                // Demo Section
                const DemoSection(),
                
                const SizedBox(height: 32),
                
                // Footer
                const Footer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}