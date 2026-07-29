import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';
import '../../widgets/auth/auth_card.dart';
import '../../widgets/auth/auth_illustration.dart';
import '../../widgets/auth/auth_primary_button.dart';
import '../../widgets/auth/auth_scaffold.dart';
import '../../widgets/auth/auth_text_field.dart';
import 'login_page.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key, required this.email});

  final String email;

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    setState(() => _loading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Password updated. Please log in.'),
        backgroundColor: AppColors.primaryNavy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginPage()),
      (_) => false,
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
              const AuthIllustration(type: AuthIllustrationType.resetPassword),
              const SizedBox(height: 24),
              Text(
                'New Password',
                style: GoogleFonts.epilogue(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryNavy,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'For ${widget.email}',
                style: GoogleFonts.epilogue(
                  fontSize: 13,
                  color: AppColors.inkSoft,
                ),
              ),
              const SizedBox(height: 28),
              AuthTextField(
                label: 'New Password',
                icon: Icons.lock_outline_rounded,
                controller: _password,
                hint: 'New Password',
                obscureText: true,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                validator: (v) {
                  if (v == null || v.length < 8) {
                    return 'At least 8 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AuthTextField(
                label: 'Confirm Password',
                icon: Icons.lock_outline_rounded,
                controller: _confirm,
                hint: 'Confirm Password',
                obscureText: true,
                textInputAction: TextInputAction.done,
                validator: (v) {
                  if (v != _password.text) return 'Passwords do not match';
                  return null;
                },
              ),
              const SizedBox(height: 28),
              AuthPrimaryButton(
                label: 'Reset Password',
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
                    const TextSpan(text: 'Remember your password? '),
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
