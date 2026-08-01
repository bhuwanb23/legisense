import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../repositories/auth_repository.dart';
import '../../services/api_exception.dart';
import '../../services/auth_social_actions.dart';
import '../../services/session_prefs.dart';
import '../../services/socket_service.dart';
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
import 'otp_page.dart';
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
  final _auth = AuthRepository();
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

    try {
      await _auth.login(
        email: _contact.text.trim(),
        password: _password.text,
      );
      await SessionPrefs.setOnboardingSeen();
      await SessionPrefs.setRememberMe(true);

      try {
        final profile = await _auth.getProfile();
        if (profile.fullName != null && profile.fullName!.isNotEmpty) {
          await SessionPrefs.setDisplayName(profile.fullName);
        }
        if (profile.profession != null) {
          await SessionPrefs.setProfession(profile.profession);
        }
      } catch (_) {}

      await SessionPrefs.setProfileComplete(true);
      await SocketService.instance.connect();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const MainShell()),
        (_) => false,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
          style: GoogleFonts.plusJakartaSans(
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
              const AuthIllustration(
                type: AuthIllustrationType.login,
                size: 112,
              ),
              const SizedBox(height: 16),
              Text(
                'Sign In',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryNavy,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Enter your email & password to continue',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppColors.inkSoft,
                ),
              ),
              const SizedBox(height: 20),
              AuthTextField(
                label: 'Email',
                icon: Icons.mail_outline_rounded,
                controller: _contact,
                hint: 'Email',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter email';
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 12),
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
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ForgotPasswordPage(),
                      ),
                    );
                  },
                  child: Text(
                    'Forget password',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              AuthPrimaryButton(
                label: 'Login',
                showArrow: true,
                loading: _loading,
                onPressed: _submit,
              ),
              const SizedBox(height: 18),
              const AuthOrDivider(label: 'Or Continue with'),
              const SizedBox(height: 14),
              AuthSocialRow(
                onGoogle: () => AuthSocialActions.signInWithGoogle(context),
                onFacebook: () => AuthSocialActions.signInWithFacebook(context),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () async {
                  final email = _contact.text.trim();
                  if (email.isEmpty || !email.contains('@')) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Enter your email above first'),
                      ),
                    );
                    return;
                  }
                  try {
                    final res = await _auth.requestOtp(email);
                    if (!mounted) return;
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => OtpPage(
                          contact: email,
                          devOtpHint: res['devOtp']?.toString(),
                        ),
                      ),
                    );
                  } on ApiException catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.message)),
                    );
                  }
                },
                child: Text(
                  'Sign in with email code',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text.rich(
                textAlign: TextAlign.center,
                TextSpan(
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
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
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
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
