import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/session_prefs.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth/auth_or_divider.dart';
import '../../widgets/auth/auth_primary_button.dart';
import '../../widgets/auth/auth_scaffold.dart';
import '../../widgets/auth/auth_social_button.dart';
import '../../widgets/auth/auth_text_field.dart';
import 'login_page.dart';
import 'otp_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  String? get _passwordHint {
    final v = _password.text;
    if (v.isEmpty) return null;
    if (v.length >= 10) return 'Strong';
    if (v.length >= 8) return 'Good';
    return 'Weak';
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);
    await SessionPrefs.setOnboardingSeen();
    await SessionPrefs.setUserEmail(_email.text.trim());
    if (!mounted) return;
    setState(() => _loading = false);

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OtpPage(
          contact: _email.text.trim(),
          isNewUser: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Create Account',
      subtitle: 'Join Legisense in under a minute.',
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthTextField(
              label: 'Email',
              icon: Icons.mail_outline_rounded,
              controller: _email,
              hint: 'you@email.com',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              validator: (v) {
                final value = v?.trim() ?? '';
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            AuthTextField(
              label: 'Mobile Number',
              icon: Icons.phone_outlined,
              controller: _phone,
              hint: '+91 XXXXX XXXXX',
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.telephoneNumber],
              validator: (v) {
                final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
                if (digits.length < 10) return 'Enter a valid number';
                return null;
              },
            ),
            const SizedBox(height: 16),
            AuthTextField(
              label: 'Password',
              icon: Icons.lock_outline_rounded,
              controller: _password,
              obscureText: true,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              onChanged: (_) => setState(() {}),
              trailing: _passwordHint == null
                  ? null
                  : Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Center(
                        child: Text(
                          _passwordHint!,
                          style: GoogleFonts.epilogue(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accentSky,
                          ),
                        ),
                      ),
                    ),
              validator: (v) {
                if (v == null || v.length < 8) {
                  return 'At least 8 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 28),
            AuthPrimaryButton(
              label: 'Sign up',
              loading: _loading,
              onPressed: _submit,
            ),
            const SizedBox(height: 28),
            const AuthOrDivider(label: 'or sign up with'),
            const SizedBox(height: 20),
            AuthSocialRow(
              onGoogle: () => showAuthComingSoon(context, 'Google'),
              onGithub: () => showAuthComingSoon(context, 'GitHub'),
              onApple: () => showAuthComingSoon(context, 'Apple'),
            ),
            const SizedBox(height: 32),
            Center(
              child: Text.rich(
                TextSpan(
                  style: GoogleFonts.epilogue(
                    fontSize: 14,
                    color: AppColors.inkSoft,
                  ),
                  children: [
                    const TextSpan(text: 'Already have an account? '),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.baseline,
                      baseline: TextBaseline.alphabetic,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute<void>(
                              builder: (_) => const LoginPage(),
                            ),
                          );
                        },
                        child: Text(
                          'Sign in',
                          style: GoogleFonts.epilogue(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryNavy,
                          ),
                        ),
                      ),
                    ),
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
