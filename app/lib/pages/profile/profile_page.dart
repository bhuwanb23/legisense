import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/auth_constants.dart';
import '../../services/session_prefs.dart';
import '../../theme/app_theme.dart';
import '../../widgets/home/stub_scaffold.dart';
import '../auth/login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _name = 'Member';
  String _email = '—';
  String _profession = '—';
  String _language = 'en';
  String _state = '—';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final name = await SessionPrefs.displayName();
    final email = await SessionPrefs.userEmail();
    final profession = await SessionPrefs.profession();
    final language = await SessionPrefs.language();
    final state = await SessionPrefs.stateRegion();
    if (!mounted) return;
    setState(() {
      _name = (name == null || name.isEmpty) ? _nameFromEmail(email) : name;
      _email = email ?? '—';
      _profession = profession ?? '—';
      _language = language ?? 'en';
      _state = state ?? '—';
    });
  }

  String _nameFromEmail(String? email) {
    if (email == null || email.isEmpty) return 'Member';
    final local = email.split('@').first;
    if (local.isEmpty) return 'Member';
    return local[0].toUpperCase() + local.substring(1);
  }

  String _languageLabel(String code) {
    for (final lang in ProfileOptions.languages) {
      if (lang.code == code) return lang.label;
    }
    return code;
  }

  Future<void> _editPrefs() async {
    var profession = ProfileOptions.professions.contains(_profession)
        ? _profession
        : ProfileOptions.professions.first;
    var language = ProfileOptions.languages.any((l) => l.code == _language)
        ? _language
        : 'en';
    var state = IndiaRegions.states.contains(_state)
        ? _state
        : IndiaRegions.states.first;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cloud,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModal) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                20,
                24,
                24 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Edit preferences',
                    style: GoogleFonts.spectral(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                      fontStyle: FontStyle.normal,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: profession,
                    decoration: const InputDecoration(labelText: 'Profession'),
                    items: [
                      for (final p in ProfileOptions.professions)
                        DropdownMenuItem(value: p, child: Text(p)),
                    ],
                    onChanged: (v) =>
                        setModal(() => profession = v ?? profession),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: language,
                    decoration: const InputDecoration(labelText: 'Language'),
                    items: [
                      for (final lang in ProfileOptions.languages)
                        DropdownMenuItem(
                          value: lang.code,
                          child: Text(lang.label),
                        ),
                    ],
                    onChanged: (v) => setModal(() => language = v ?? language),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: state,
                    decoration: const InputDecoration(labelText: 'State'),
                    items: [
                      for (final s in IndiaRegions.states)
                        DropdownMenuItem(value: s, child: Text(s)),
                    ],
                    onChanged: (v) => setModal(() => state = v ?? state),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () async {
                      await SessionPrefs.setProfession(profession);
                      await SessionPrefs.setLanguage(language);
                      await SessionPrefs.setStateRegion(state);
                      if (context.mounted) Navigator.pop(context, true);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.ink,
                      foregroundColor: AppColors.cloud,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'Save',
                      style: GoogleFonts.spectral(
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.normal,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (saved == true) await _load();
  }

  Future<void> _logout() async {
    await SessionPrefs.setLoggedIn(false);
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final initial = _name.isNotEmpty ? _name[0].toUpperCase() : 'L';

    return StubScaffold(
      title: 'Profile',
      subtitle: 'Account and counsel preferences.',
      child: ListView(
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.paper2,
                  child: Text(
                    initial,
                    style: GoogleFonts.spectral(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                      fontStyle: FontStyle.normal,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _name,
                  style: GoogleFonts.spectral(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                    fontStyle: FontStyle.normal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _email,
                  style: GoogleFonts.epilogue(
                    fontSize: 13,
                    color: AppColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _InfoRow(label: 'Profession', value: _profession),
          const SizedBox(height: 10),
          _InfoRow(label: 'Language', value: _languageLabel(_language)),
          const SizedBox(height: 10),
          _InfoRow(label: 'State / region', value: _state),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: _editPrefs,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.ink,
              side: const BorderSide(color: AppColors.rule),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(
              'Edit preferences',
              style: GoogleFonts.epilogue(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _logout,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(
              'Log out',
              style: GoogleFonts.epilogue(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cloud,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.rule),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.epilogue(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.inkSoft,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.epilogue(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
