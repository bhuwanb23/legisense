import 'package:flutter/material.dart';
import 'components/gradient_background.dart';
import 'components/logo_section.dart';
import 'components/hero_illustration.dart';
import 'components/welcome_text.dart';
import 'components/sign_in_buttons.dart';
import 'components/email_login_form.dart';
import 'components/footer.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool showEmailForm = false;

  void toggleEmailForm() {
    setState(() {
      showEmailForm = !showEmailForm;
    });
  }

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
                
                // Sign In Buttons or Email Form
                if (showEmailForm)
                  EmailLoginForm(
                    onBack: toggleEmailForm,
                    onLoginSuccess: () {
                      // TODO: Navigate to home page
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Login successful!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                  )
                else
                  SignInButtons(
                    onEmailPressed: toggleEmailForm,
                  ),
                
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