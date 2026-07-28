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
import 'login_page.dart';
import 'otp_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _phone = TextEditingController();
  bool _agreed = false;
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to Terms & Privacy Policy.'),
          backgroundColor: AppColors.primaryNavy,
        ),
      );
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);
    await SessionPrefs.setOnboardingSeen();
    await SessionPrefs.setDisplayName(_name.text.trim());
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
      title: "Let's Get Started",
      subtitle: 'Create your Legisense account to continue.',
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthTextField(
              label: 'Full Name',
              controller: _name,
              hint: 'Your full name',
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              validator: (v) {
                if (v == null || v.trim().length < 2) {
                  return 'Enter your full name';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            AuthTextField(
              label: 'Email',
              controller: _email,
              hint: 'you@example.com',
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
            const SizedBox(height: AppSpacing.md),
            AuthTextField(
              label: 'Password',
              controller: _password,
              obscureText: true,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              validator: (v) {
                if (v == null || v.length < 8) {
                  return 'Use at least 8 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            AuthTextField(
              label: 'Confirm Password',
              controller: _confirm,
              obscureText: true,
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v != _password.text) return 'Passwords do not match';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            AuthTextField(
              label: 'Phone Number',
              controller: _phone,
              hint: '+91 XXXXX XXXXX',
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.telephoneNumber],
              validator: (v) {
                final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
                if (digits.length < 10) return 'Enter a valid phone number';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            AuthToggleRow(
              label: 'I agree to Terms & Privacy Policy',
              value: _agreed,
              onChanged: (v) => setState(() => _agreed = v),
            ),
            const SizedBox(height: AppSpacing.lg),
            AuthPrimaryButton(
              label: 'Sign Up',
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
                    'Already have an account? ',
                    style: GoogleFonts.epilogue(
                      fontSize: 14,
                      color: AppColors.inkSoft,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute<void>(
                          builder: (_) => const LoginPage(),
                        ),
                      );
                    },
                    child: Text(
                      'Login',
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
