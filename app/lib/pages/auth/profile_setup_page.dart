import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/auth_constants.dart';
import '../../services/session_prefs.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth/auth_card.dart';
import '../../widgets/auth/auth_illustration.dart';
import '../../widgets/auth/auth_primary_button.dart';
import '../../widgets/auth/auth_scaffold.dart';
import '../shell/main_shell.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _picker = ImagePicker();
  XFile? _photo;
  String? _profession;
  String _language = 'en';
  String? _state;
  final Set<String> _docTypes = {};
  bool _loading = false;

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.cloud,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        );
      },
    );
    if (source == null) return;
    final file = await _picker.pickImage(source: source, imageQuality: 85);
    if (file != null && mounted) setState(() => _photo = file);
  }

  Future<void> _save() async {
    if (_profession == null) {
      _toast('Select your profession');
      return;
    }
    if (_state == null) {
      _toast('Select your state / region');
      return;
    }
    if (_docTypes.isEmpty) {
      _toast('Pick at least one document type');
      return;
    }

    setState(() => _loading = true);
    await SessionPrefs.setLoggedIn(true);
    await SessionPrefs.setProfileComplete(true);
    await SessionPrefs.setProfession(_profession);
    await SessionPrefs.setLanguage(_language);
    await SessionPrefs.setStateRegion(_state);
    final email = await SessionPrefs.userEmail();
    final existingName = await SessionPrefs.displayName();
    if (existingName == null || existingName.isEmpty) {
      if (email != null && email.contains('@')) {
        final local = email.split('@').first.trim();
        if (local.isNotEmpty) {
          final pretty = local[0].toUpperCase() + local.substring(1);
          await SessionPrefs.setDisplayName(pretty);
        }
      }
    }
    if (!mounted) return;
    setState(() => _loading = false);

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const MainShell()),
      (_) => false,
    );
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.primaryNavy),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      showBack: false,
      body: AuthCard(
        maxWidth: 480,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            const AuthIllustration(
              type: AuthIllustrationType.profile,
              size: 120,
            ),
            const SizedBox(height: 20),
            Text(
              'Your Profile',
              style: GoogleFonts.epilogue(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryNavy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'A few details so explanations fit your context.',
              textAlign: TextAlign.center,
              style: GoogleFonts.epilogue(
                fontSize: 13,
                color: AppColors.inkSoft,
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: GestureDetector(
                onTap: _pickPhoto,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: AppColors.accentSoft,
                      backgroundImage: _photo != null
                          ? FileImage(File(_photo!.path))
                          : null,
                      child: _photo == null
                          ? Image.asset(
                              'assets/images/legisense_mark.png',
                              width: 50,
                              height: 50,
                            )
                          : null,
                    ),
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: AppColors.ink,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        size: 14,
                        color: AppColors.cloud,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _sectionLabel('Profession'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ProfileOptions.professions.map((p) {
                final selected = _profession == p;
                return ChoiceChip(
                  label: Text(p),
                  selected: selected,
                  onSelected: (_) => setState(() => _profession = p),
                  selectedColor: AppColors.ink,
                  labelStyle: GoogleFonts.epilogue(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? AppColors.cloud : AppColors.primaryNavy,
                  ),
                  backgroundColor: AppColors.cloud,
                  side: BorderSide(
                    color: selected
                        ? AppColors.ink
                        : AppColors.borderMuted,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            _sectionLabel('Primary language'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ProfileOptions.languages.map((lang) {
                final selected = _language == lang.code;
                return ChoiceChip(
                  label: Text(lang.label),
                  selected: selected,
                  onSelected: (_) => setState(() => _language = lang.code),
                  selectedColor: AppColors.ink,
                  labelStyle: GoogleFonts.epilogue(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? AppColors.cloud : AppColors.primaryNavy,
                  ),
                  backgroundColor: AppColors.cloud,
                  side: BorderSide(
                    color: selected
                        ? AppColors.ink
                        : AppColors.borderMuted,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            _sectionLabel('State / Region'),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _state,
              decoration: InputDecoration(
                hintText: 'Select jurisdiction default',
                hintStyle: GoogleFonts.epilogue(
                  fontSize: 14,
                  color: AppColors.inkSoft.withValues(alpha: 0.5),
                ),
              ),
              items: IndiaRegions.states
                  .map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Text(s, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _state = v),
            ),
            const SizedBox(height: 20),
            _sectionLabel('Preferred document types'),
            const SizedBox(height: 10),
            ...ProfileOptions.documentTypes.map((type) {
              final checked = _docTypes.contains(type);
              return CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(
                  type,
                  style: GoogleFonts.epilogue(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryNavy,
                  ),
                ),
                value: checked,
                activeColor: AppColors.ink,
                onChanged: (v) {
                  setState(() {
                    if (v == true) {
                      _docTypes.add(type);
                    } else {
                      _docTypes.remove(type);
                    }
                  });
                },
              );
            }),
            const SizedBox(height: 24),
            AuthPrimaryButton(
              label: 'Save & Continue',
              loading: _loading,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: GoogleFonts.epilogue(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryNavy,
        ),
      ),
    );
  }
}
