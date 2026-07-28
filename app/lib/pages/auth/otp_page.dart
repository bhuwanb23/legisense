import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/auth_constants.dart';
import '../../services/session_prefs.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth/auth_primary_button.dart';
import '../../widgets/auth/auth_scaffold.dart';
import '../home/home_page.dart';
import 'profile_setup_page.dart';

class OtpPage extends StatefulWidget {
  const OtpPage({
    super.key,
    required this.contact,
    required this.isNewUser,
  });

  final String contact;
  final bool isNewUser;

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  static const _length = 6;

  final _controllers = List.generate(_length, (_) => TextEditingController());
  final _focusNodes = List.generate(_length, (_) => FocusNode());
  Timer? _timer;
  int _secondsLeft = 30;
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 1) {
        t.cancel();
        if (mounted) setState(() => _secondsLeft = 0);
      } else if (mounted) {
        setState(() => _secondsLeft -= 1);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  Future<void> _verify() async {
    final code = _code;
    if (code.length != _length) {
      setState(() => _error = 'Enter the $_length-digit code');
      return;
    }
    if (code != AuthMock.demoOtp) {
      setState(() => _error = 'Invalid OTP. Use ${AuthMock.demoOtp} for demo.');
      return;
    }

    setState(() {
      _error = null;
      _loading = true;
    });

    await SessionPrefs.setLoggedIn(true);
    if (!mounted) return;
    setState(() => _loading = false);

    final next = widget.isNewUser
        ? const ProfileSetupPage()
        : const HomePage();

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => next),
      (_) => false,
    );
  }

  void _onChanged(int index, String value) {
    setState(() => _error = null);
    if (value.length == 1 && index < _length - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    if (_code.length == _length) {
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final masked = AuthMock.maskContact(widget.contact);

    return AuthScaffold(
      title: 'Enter code',
      subtitle: 'Sent to $masked',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_length, (i) {
              return SizedBox(
                width: AppSizes.otpBox,
                height: AppSizes.otpBox,
                child: TextField(
                  controller: _controllers[i],
                  focusNode: _focusNodes[i],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  style: GoogleFonts.epilogue(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryNavy,
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    counterText: '',
                    contentPadding: EdgeInsets.zero,
                    filled: true,
                    fillColor: const Color(0xFFF3F7FC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: AppColors.primaryNavy,
                        width: 1.4,
                      ),
                    ),
                  ),
                  onChanged: (v) => _onChanged(i, v),
                ),
              );
            }),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: GoogleFonts.epilogue(
                fontSize: 13,
                color: AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 28),
          AuthPrimaryButton(
            label: 'Verify',
            loading: _loading,
            onPressed: _verify,
          ),
          const SizedBox(height: 20),
          Center(
            child: _secondsLeft > 0
                ? Text(
                    'Resend in ${_secondsLeft}s',
                    style: GoogleFonts.epilogue(
                      fontSize: 14,
                      color: AppColors.inkSoft,
                    ),
                  )
                : TextButton(
                    onPressed: () {
                      for (final c in _controllers) {
                        c.clear();
                      }
                      _focusNodes.first.requestFocus();
                      _startTimer();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'OTP resent. Demo: ${AuthMock.demoOtp}',
                          ),
                          backgroundColor: AppColors.primaryNavy,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      );
                    },
                    child: Text(
                      'Resend OTP',
                      style: GoogleFonts.epilogue(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          Text(
            'Demo: ${AuthMock.demoOtp}',
            textAlign: TextAlign.center,
            style: GoogleFonts.epilogue(
              fontSize: 12,
              color: AppColors.inkSoft.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}
