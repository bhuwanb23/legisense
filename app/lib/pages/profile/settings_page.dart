import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/session_prefs.dart';
import '../../theme/app_insets.dart';
import '../../theme/app_theme.dart';
import '../../widgets/home/app_page_header.dart';
import 'edit_profile_page.dart';

/// App settings — notifications, shortcuts, about.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _deadlines = true;
  bool _analysis = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final d = await SessionPrefs.notifyDeadlines();
    final a = await SessionPrefs.notifyAnalysis();
    if (!mounted) return;
    setState(() {
      _deadlines = d;
      _analysis = a;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AppPageHeader(
              title: 'Settings',
              subtitle: 'Preferences',
              leading: AppHeaderIconButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => Navigator.maybePop(context),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  AppInsets.shellBottom(context),
                ),
                children: [
                  _sectionTitle('Notifications'),
                  _card(
                    children: [
                      SwitchListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                        title: Text(
                          'Deadline reminders',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        value: _deadlines,
                        activeThumbColor: AppColors.ink,
                        onChanged: (v) async {
                          setState(() => _deadlines = v);
                          await SessionPrefs.setNotifyDeadlines(v);
                        },
                      ),
                      SwitchListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                        title: Text(
                          'Analysis ready',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        value: _analysis,
                        activeThumbColor: AppColors.ink,
                        onChanged: (v) async {
                          setState(() => _analysis = v);
                          await SessionPrefs.setNotifyAnalysis(v);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _sectionTitle('Account'),
                  _card(
                    children: [
                      ListTile(
                        title: Text(
                          'Region & language',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const EditProfilePage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _sectionTitle('About'),
                  _card(
                    children: [
                      ListTile(
                        title: Text(
                          'Version',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        trailing: Text(
                          '1.0.0',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.mute,
                          ),
                        ),
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

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          t,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.mute,
          ),
        ),
      );

  Widget _card({required List<Widget> children}) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.md),
          boxShadow: AppShadows.soft,
        ),
        child: Column(children: children),
      );
}
