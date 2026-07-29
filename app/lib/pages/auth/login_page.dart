import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/session_prefs.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth/auth_card.dart';
import '../../widgets/auth/auth_illustration.dart';
import '../../widgets/auth/auth_or_divider.dart';
import '../../widgets/auth/auth_primary_button.dart';
import '../../widgets/auth/auth_scaffold.dart';
import '../../widgets/auth/auth_social_button.dart';
import '../../widgets/auth/auth_text_field.dart';
import '../shell/main_shell.dart';
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
    if (remember && email != null) {
      setState(() => _contact.text = email);
    }
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
    await SessionPrefs.setRememberMe(true);
    await SessionPrefs.setUserEmail(_contact.text.trim());
    await SessionPrefs.setLoggedIn(true);

    final profileDone = await SessionPrefs.isProfileComplete();
    if (!mounted) return;
    setState(() => _loading = false);

    final next = profileDone ? const MainShell() : const ProfileSetupPage();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => next),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      showBack: false,
      trailing: TextButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const ForgotPasswordPage(),
            ),
          );
        },
        child: Text(
          'Forgot?',
          style: GoogleFonts.epilogue(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
      ),
      body: AuthCard(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const AuthIllustration(type: AuthIllustrationType.login),
              const SizedBox(height: 24),
              Text(
                'Sign In',
                style: GoogleFonts.epilogue(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryNavy,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter valid user name & password to continue',
                style: GoogleFonts.epilogue(
                  fontSize: 13,
                  color: AppColors.inkSoft,
                ),
              ),
              const SizedBox(height: 28),
              AuthTextField(
                label: 'User name',
                icon: Icons.person_outline_rounded,
                controller: _contact,
                hint: 'User name',
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
              const SizedBox(height: 16),
              AuthTextField(
                label: 'Password',
                icon: Icons.lock_outline_rounded,
                controller: _password,
                hint: 'Password',
                obscureText: true,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter your password';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ForgotPasswordPage(),
                      ),
                    );
                  },
                  child: Text(
                    'Forget password',
                    style: GoogleFonts.epilogue(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AuthPrimaryButton(
                label: 'Login',
                loading: _loading,
                onPressed: _submit,
              ),
              const SizedBox(height: 24),
              const AuthOrDivider(label: 'Or Continue with'),
              const SizedBox(height: 20),
              AuthSocialRow(
                onGoogle: () => showAuthComingSoon(context, 'Google'),
                onFacebook: () => showAuthComingSoon(context, 'Facebook'),
              ),
              const SizedBox(height: 24),
              Text.rich(
                TextSpan(
                  style: GoogleFonts.epilogue(
                    fontSize: 14,
                    color: AppColors.inkSoft,
                  ),
                  children: [
                    const TextSpan(text: "Haven't any account? "),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.baseline,
                      baseline: TextBaseline.alphabetic,
                      child: GestureDetector(
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
                            color: AppColors.ink,
                          ),
                        ),
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
}
