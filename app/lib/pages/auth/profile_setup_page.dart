import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/auth_constants.dart';
import '../../services/session_prefs.dart';
import '../../theme/app_theme.dart';
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
      title: 'Your profile',
      subtitle: 'A few details so explanations fit your context.',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: GestureDetector(
              onTap: _pickPhoto,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: AppColors.accentSoft,
                    backgroundImage: _photo != null
                        ? FileImage(File(_photo!.path))
                        : null,
                    child: _photo == null
                        ? Image.asset(
                            'assets/images/legisense_mark.png',
                            width: 54,
                            height: 54,
                          )
                        : null,
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryNavy,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 16,
                      color: AppColors.cloud,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _sectionLabel('Profession'),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ProfileOptions.professions.map((p) {
              final selected = _profession == p;
              return ChoiceChip(
                label: Text(p),
                selected: selected,
                onSelected: (_) => setState(() => _profession = p),
                selectedColor: AppColors.primaryNavy,
                labelStyle: GoogleFonts.epilogue(
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.cloud : AppColors.primaryNavy,
                ),
                backgroundColor: AppColors.cloud,
                side: const BorderSide(color: AppColors.accentSoft),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.lg),
          _sectionLabel('Primary language'),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ProfileOptions.languages.map((lang) {
              final selected = _language == lang.code;
              return ChoiceChip(
                label: Text(lang.label),
                selected: selected,
                onSelected: (_) => setState(() => _language = lang.code),
                selectedColor: AppColors.accentSky,
                labelStyle: GoogleFonts.epilogue(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryNavy,
                ),
                backgroundColor: AppColors.cloud,
                side: const BorderSide(color: AppColors.accentSoft),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.lg),
          _sectionLabel('State / Region'),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<String>(
            initialValue: _state,
            decoration: const InputDecoration(
              hintText: 'Select jurisdiction default',
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
          const SizedBox(height: AppSpacing.lg),
          _sectionLabel('Preferred document types'),
          const SizedBox(height: AppSpacing.sm),
          ...ProfileOptions.documentTypes.map((type) {
            final checked = _docTypes.contains(type);
            return CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(
                type,
                style: GoogleFonts.epilogue(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primaryNavy,
                ),
              ),
              value: checked,
              activeColor: AppColors.primaryNavy,
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
          const SizedBox(height: AppSpacing.xl),
          AuthPrimaryButton(
            label: 'Save & Continue',
            loading: _loading,
            onPressed: _save,
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.epilogue(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.primaryNavy,
      ),
    );
  }
}
