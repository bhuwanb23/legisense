import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/session_prefs.dart';
import '../../theme/app_insets.dart';
import '../../theme/app_theme.dart';
import '../../widgets/home/app_page_header.dart';
import '../../repositories/auth_repository.dart';
import '../auth/login_page.dart';
import 'edit_profile_page.dart';

/// Profile — TripGlide Operate (Home theme).
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _name = 'Member';
  String _email = '—';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final name = await SessionPrefs.displayName();
    final email = await SessionPrefs.userEmail();
    if (!mounted) return;
    setState(() {
      _name = (name == null || name.isEmpty) ? _nameFromEmail(email) : name;
      _email = email ?? '—';
    });
  }

  String _nameFromEmail(String? email) {
    if (email == null || email.isEmpty) return 'Member';
    final local = email.split('@').first;
    if (local.isEmpty) return 'Member';
    return local[0].toUpperCase() + local.substring(1);
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.plusJakartaSans()),
        backgroundColor: AppColors.ink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Future<void> _openEdit() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const EditProfilePage()),
    );
    if (changed == true) await _load();
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Log out?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'You’ll need to sign in again to access your documents.',
          style: GoogleFonts.plusJakartaSans(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Log out',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await AuthRepository().logout();
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final initial = _name.isNotEmpty ? _name[0].toUpperCase() : 'L';

    return ColoredBox(
      color: AppColors.bg,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AppPageHeader(
              title: 'Profile',
              subtitle: 'Account & preferences',
              trailing: AppHeaderIconButton(
                icon: Icons.edit_outlined,
                onTap: _openEdit,
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  AppInsets.shellBottom(context),
                ),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.ink,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      boxShadow: AppShadows.card,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            initial,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _name,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _email,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.65),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _MenuCard(
                    children: [
                      _MenuTile(
                        icon: Icons.person_outline_rounded,
                        label: 'Edit Profile',
                        onTap: _openEdit,
                      ),
                      _MenuTile(
                        icon: Icons.language_rounded,
                        label: 'Region & language',
                        onTap: _openEdit,
                      ),
                      _MenuTile(
                        icon: Icons.headset_mic_outlined,
                        label: 'Help & Support',
                        onTap: () =>
                            _toast('Support chat comes with the backend.'),
                      ),
                      _MenuTile(
                        icon: Icons.settings_outlined,
                        label: 'Settings',
                        onTap: () =>
                            _toast('Settings come with the backend.'),
                        showDivider: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _MenuCard(
                    children: [
                      _MenuTile(
                        icon: Icons.logout_rounded,
                        label: 'Log out',
                        danger: true,
                        showChevron: false,
                        showDivider: false,
                        onTap: _logout,
                      ),
                    ],
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

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        boxShadow: AppShadows.soft,
      ),
      child: Column(children: children),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
    this.showChevron = true,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;
  final bool showChevron;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.error : AppColors.ink;

    return Column(
      children: [
        ListTile(
          onTap: onTap,
          leading: Icon(icon, color: color, size: 22),
          title: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          trailing: showChevron
              ? Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.mute.withValues(alpha: 0.7),
                )
              : null,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
        ),
        if (showDivider)
          const Divider(height: 1, indent: 56, color: AppColors.rule),
      ],
    );
  }
}
