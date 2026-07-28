import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/session_prefs.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth/auth_or_divider.dart';
import '../../widgets/auth/auth_primary_button.dart';
import '../../widgets/auth/auth_scaffold.dart';
import '../../widgets/auth/auth_social_button.dart';
import '../../widgets/auth/auth_text_field.dart';
import '../../widgets/auth/auth_toggle_row.dart';
import '../home/home_page.dart';
import 'forgot_password_page.dart';
import 'profile_setup_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _contact = TextEditingController();
  final _password = TextEditingController();
  bool _rememberMe = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _hydrate();
  }

  Future<void> _hydrate() async {
    final remember = await SessionPrefs.rememberMe();
    final email = await SessionPrefs.userEmail();
    if (!mounted) return;
    setState(() {
      _rememberMe = remember;
      if (remember && email != null) _contact.text = email;
    });
  }

  @override
  void dispose() {
    _contact.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);

    await SessionPrefs.setOnboardingSeen();
    await SessionPrefs.setRememberMe(_rememberMe);
    await SessionPrefs.setUserEmail(_contact.text.trim());
    await SessionPrefs.setLoggedIn(true);

    final profileDone = await SessionPrefs.isProfileComplete();
    if (!mounted) return;
    setState(() => _loading = false);

    final next = profileDone ? const HomePage() : const ProfileSetupPage();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => next),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Welcome back',
      subtitle: 'Log in to continue to Legisense.',
      trailing: TextButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const ForgotPasswordPage(),
            ),
          );
        },
        child: Text(
          'Forgot password?',
          style: GoogleFonts.epilogue(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.inkSoft,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthTextField(
              label: 'Email / Phone',
              controller: _contact,
              hint: 'you@example.com or phone',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.username],
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Enter email or phone';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            AuthTextField(
              label: 'Password',
              controller: _password,
              obscureText: true,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter your password';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            AuthToggleRow(
              label: 'Remember me next time',
              value: _rememberMe,
              onChanged: (v) => setState(() => _rememberMe = v),
            ),
            const SizedBox(height: AppSpacing.lg),
            AuthPrimaryButton(
              label: 'Login',
              loading: _loading,
              onPressed: _submit,
            ),
            const SizedBox(height: AppSpacing.lg),
            const AuthOrDivider(),
            const SizedBox(height: AppSpacing.lg),
            AuthSocialButton(
              provider: AuthSocialProvider.google,
              onPressed: () => showAuthComingSoon(context, 'Google'),
            ),
            const SizedBox(height: AppSpacing.sm),
            AuthSocialButton(
              provider: AuthSocialProvider.github,
              onPressed: () => showAuthComingSoon(context, 'GitHub'),
            ),
            const SizedBox(height: AppSpacing.xl),
            Center(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: GoogleFonts.epilogue(
                      fontSize: 14,
                      color: AppColors.inkSoft,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute<void>(
                          builder: (_) => const RegisterPage(),
                        ),
                      );
                    },
                    child: Text(
                      'Sign up',
                      style: GoogleFonts.epilogue(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryNavy,
                      ),
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
}
