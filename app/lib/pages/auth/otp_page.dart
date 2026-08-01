import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../repositories/auth_repository.dart';
import '../../services/api_exception.dart';
import '../../services/session_prefs.dart';
import '../../services/socket_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth/auth_card.dart';
import '../../widgets/auth/auth_illustration.dart';
import '../../widgets/auth/auth_primary_button.dart';
import '../../widgets/auth/auth_scaffold.dart';
import '../shell/main_shell.dart';
import 'profile_setup_page.dart';

class OtpPage extends StatefulWidget {
  const OtpPage({
    super.key,
    required this.contact,
    this.isNewUser = false,
    this.devOtpHint,
  });

  final String contact;
  final bool isNewUser;
  final String? devOtpHint;

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
  String? _devHint;

  @override
  void initState() {
    super.initState();
    _devHint = widget.devOtpHint;
    _startTimer();
    _requestIfNeeded();
  }

  Future<void> _requestIfNeeded() async {
    if (widget.devOtpHint != null) return;
    try {
      final res = await AuthRepository().requestOtp(widget.contact);
      final hint = res['devOtp']?.toString();
      if (hint != null && mounted) setState(() => _devHint = hint);
    } catch (_) {}
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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthRepository().verifyOtp(email: widget.contact, otp: code);
      await SocketService.instance.connect();
      final complete = await SessionPrefs.isProfileComplete();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => complete || !widget.isNewUser
              ? const MainShell()
              : const ProfileSetupPage(),
        ),
        (_) => false,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    if (_secondsLeft > 0) return;
    try {
      final res = await AuthRepository().requestOtp(widget.contact);
      final hint = res['devOtp']?.toString();
      if (!mounted) return;
      setState(() {
        _devHint = hint;
        _error = null;
      });
      _startTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            hint != null ? 'OTP resent. Dev: $hint' : 'OTP resent.',
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      body: AuthCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AuthIllustration(type: AuthIllustrationType.otp),
            const SizedBox(height: 12),
            Text(
              'Verify email',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Code sent to ${widget.contact}',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppColors.inkSoft,
              ),
            ),
            if (_devHint != null) ...[
              const SizedBox(height: 8),
              Text(
                'Dev OTP: $_devHint',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppColors.mute,
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(_length, (i) {
                return SizedBox(
                  width: 44,
                  child: TextField(
                    controller: _controllers[i],
                    focusNode: _focusNodes[i],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(counterText: ''),
                    onChanged: (v) {
                      if (v.isNotEmpty && i < _length - 1) {
                        _focusNodes[i + 1].requestFocus();
                      }
                      if (v.isEmpty && i > 0) {
                        _focusNodes[i - 1].requestFocus();
                      }
                    },
                  ),
                );
              }),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.error,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 18),
            AuthPrimaryButton(
              label: 'Verify',
              loading: _loading,
              onPressed: _verify,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _secondsLeft == 0 ? _resend : null,
              child: Text(
                _secondsLeft == 0
                    ? 'Resend code'
                    : 'Resend in ${_secondsLeft}s',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
