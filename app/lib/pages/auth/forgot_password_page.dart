import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';
import '../../widgets/auth/auth_card.dart';
import '../../widgets/auth/auth_illustration.dart';
import '../../widgets/auth/auth_primary_button.dart';
import '../../widgets/auth/auth_scaffold.dart';
import '../../widgets/auth/auth_text_field.dart';
import 'login_page.dart';
import 'reset_password_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    setState(() => _loading = false);

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ResetPasswordPage(email: _email.text.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      body: AuthCard(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const AuthIllustration(type: AuthIllustrationType.forgotPassword),
              const SizedBox(height: 24),
              Text(
                'Forget Password',
                style: GoogleFonts.epilogue(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryNavy,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Don't worry it happens. Please enter the address\nassociate with your account",
                textAlign: TextAlign.center,
                style: GoogleFonts.epilogue(
                  fontSize: 13,
                  color: AppColors.inkSoft,
                ),
              ),
              const SizedBox(height: 28),
              AuthTextField(
                label: 'Email address',
                icon: Icons.mail_outline_rounded,
                controller: _email,
                hint: 'Email address',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.email],
                validator: (v) {
                  final value = v?.trim() ?? '';
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 28),
              AuthPrimaryButton(
                label: 'Send OTP',
                loading: _loading,
                onPressed: _submit,
              ),
              const SizedBox(height: 24),
              Text.rich(
                TextSpan(
                  style: GoogleFonts.epilogue(
                    fontSize: 14,
                    color: AppColors.inkSoft,
                  ),
                  children: [
                    const TextSpan(text: 'You remember you password? '),
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
                            color: AppColors.brightBlue,
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
