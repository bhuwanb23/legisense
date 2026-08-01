import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/api_config.dart';
import '../../data/auth_constants.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/meta_repository.dart';
import '../../services/session_prefs.dart';
import '../../theme/app_insets.dart';
import '../../theme/app_theme.dart';

/// Edit Profile — label / value / trailing icon rows + Discard / Save.
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _name = TextEditingController();
  final _nickname = TextEditingController();
  final _email = TextEditingController();
  String _profession = ProfileOptions.professions.first;
  String _language = 'en';
  String _state = IndiaRegions.states.first;
  bool _loading = false;
  bool _hydrated = false;
  String? _photoUrl;
  Uint8List? _localPhotoBytes;
  List<String> _languageLabels = [
    for (final l in ProfileOptions.languages) l.label,
  ];
  List<String> _stateOptions = List.from(IndiaRegions.states);
  final Map<String, String> _langCodeByLabel = {
    for (final l in ProfileOptions.languages) l.label: l.code,
  };

  @override
  void initState() {
    super.initState();
    _hydrate();
    _loadMeta();
  }

  Future<void> _loadMeta() async {
    try {
      final langs = await MetaRepository().languages();
      if (langs.isNotEmpty && mounted) {
        setState(() {
          _languageLabels = [
            for (final l in langs)
              (l['name'] ?? l['label'] ?? l['code']).toString(),
          ];
          for (final l in langs) {
            final label = (l['name'] ?? l['label'] ?? l['code']).toString();
            final code = (l['code'] ?? l['id'] ?? label).toString();
            _langCodeByLabel[label] = code;
          }
        });
      }
      final states = await MetaRepository().states('IN');
      if (states.isNotEmpty && mounted) {
        setState(() {
          _stateOptions = [
            for (final s in states)
              (s['name'] ?? s['code'] ?? s['id']).toString(),
          ];
        });
      }
    } catch (_) {
      // Keep static fallbacks.
    }
  }

  Future<void> _hydrate() async {
    final name = await SessionPrefs.displayName() ?? '';
    final email = await SessionPrefs.userEmail() ?? '';
    final profession = await SessionPrefs.profession();
    final language = await SessionPrefs.language();
    final state = await SessionPrefs.stateRegion();
    final nick = await SessionPrefs.nickname();
    if (!mounted) return;
    setState(() {
      _name.text = name.isNotEmpty ? name : _nameFromEmail(email);
      _nickname.text =
          (nick != null && nick.isNotEmpty) ? nick : _name.text.split(' ').first;
      _email.text = email;
      if (profession != null &&
          ProfileOptions.professions.contains(profession)) {
        _profession = profession;
      }
      if (language != null) _language = language;
      if (state != null && state.isNotEmpty) {
        _state = state.split(',').first;
      }
      _hydrated = true;
    });
  }

  String _nameFromEmail(String email) {
    if (email.isEmpty || !email.contains('@')) return 'Member';
    final local = email.split('@').first;
    if (local.isEmpty) return 'Member';
    return local[0].toUpperCase() + local.substring(1);
  }

  Future<void> _pickPhoto() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1024,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _localPhotoBytes = bytes;
      _loading = true;
    });
    try {
      final url = await AuthRepository().uploadAvatar(
        filePath: file.path,
        bytes: bytes,
        filename: file.name,
      );
      if (!mounted) return;
      setState(() {
        _photoUrl = url.startsWith('http')
            ? url
            : '${ApiConfig.baseUrl}$url';
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _nickname.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Full name is required.',
            style: GoogleFonts.plusJakartaSans(),
          ),
          backgroundColor: AppColors.ink,
        ),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final auth = AuthRepository();
      await auth.updateProfile(
        fullName: name,
        profession: _profession,
      );
      await auth.updatePreferences(
        preferredLanguage: _language,
        defaultJurisdiction: _state,
        nickname: _nickname.text.trim(),
      );
      await SessionPrefs.setDisplayName(name);
      await SessionPrefs.setUserEmail(_email.text.trim());
      await SessionPrefs.setNickname(_nickname.text.trim());
      await SessionPrefs.setUserEmail(_email.text.trim());
      await SessionPrefs.setProfession(_profession);
      await SessionPrefs.setLanguage(_language);
      await SessionPrefs.setStateRegion(_state);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _discard() => Navigator.of(context).pop(false);

  @override
  Widget build(BuildContext context) {
    final initial =
        _name.text.isNotEmpty ? _name.text[0].toUpperCase() : 'L';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.ink,
        centerTitle: true,
        title: Text(
          'Edit Profile',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
      ),
      body: !_hydrated
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      Center(
                        child: Stack(
                          children: [
                            Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.chip,
                                border: Border.all(
                                  color: AppColors.rule,
                                  width: 2,
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              alignment: Alignment.center,
                              child: _localPhotoBytes != null
                                  ? Image.memory(
                                      _localPhotoBytes!,
                                      fit: BoxFit.cover,
                                      width: 110,
                                      height: 110,
                                    )
                                  : (_photoUrl != null
                                      ? Image.network(
                                          _photoUrl!,
                                          fit: BoxFit.cover,
                                          width: 110,
                                          height: 110,
                                          errorBuilder: (_, __, ___) => Text(
                                            initial,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 40,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.ink,
                                            ),
                                          ),
                                        )
                                      : Text(
                                          initial,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 40,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.ink,
                                          ),
                                        )),
                            ),
                            Positioned(
                              right: 2,
                              bottom: 2,
                              child: Material(
                                color: AppColors.ink,
                                shape: const CircleBorder(),
                                child: InkWell(
                                  customBorder: const CircleBorder(),
                                  onTap: _loading ? null : _pickPhoto,
                                  child: const SizedBox(
                                    width: 32,
                                    height: 32,
                                    child: Icon(
                                      Icons.add_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      _FieldRow(
                        label: 'Full Name',
                        controller: _name,
                        icon: Icons.edit_outlined,
                      ),
                      _FieldRow(
                        label: 'Nickname',
                        controller: _nickname,
                        icon: Icons.edit_outlined,
                      ),
                      _FieldRow(
                        label: 'Email',
                        controller: _email,
                        icon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                        readOnly: true,
                      ),
                      _SelectRow(
                        label: 'Occupation',
                        value: _profession,
                        icon: Icons.work_outline_rounded,
                        options: ProfileOptions.professions,
                        onChanged: (v) => setState(() => _profession = v),
                      ),
                      _SelectRow(
                        label: 'Language',
                        value: _langCodeByLabel.entries
                            .firstWhere(
                              (e) => e.value == _language,
                              orElse: () => MapEntry(
                                _languageLabels.isNotEmpty
                                    ? _languageLabels.first
                                    : 'English',
                                _language,
                              ),
                            )
                            .key,
                        icon: Icons.translate_rounded,
                        options: _languageLabels,
                        onChanged: (label) {
                          setState(() {
                            _language = _langCodeByLabel[label] ?? _language;
                          });
                        },
                      ),
                      _SelectRow(
                        label: 'State / region',
                        value: _stateOptions.contains(_state)
                            ? _state
                            : (_stateOptions.isNotEmpty
                                ? _stateOptions.first
                                : _state),
                        icon: Icons.location_on_outlined,
                        options: _stateOptions,
                        onChanged: (v) => setState(() => _state = v),
                      ),
                    ],
                  ),
                ),
                SafeArea(
                  top: false,
                  bottom: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      8,
                      20,
                      AppInsets.footerAboveDock(context),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _loading ? null : _discard,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.ink,
                              side: const BorderSide(color: AppColors.ink),
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadii.pill),
                              ),
                            ),
                            child: Text(
                              'Discard',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: _loading ? null : _save,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.ink,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadii.pill),
                              ),
                            ),
                            child: _loading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'Save',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({
    required this.label,
    required this.controller,
    required this.icon,
    this.keyboardType,
    this.readOnly = false,
  });

  final String label;
  final TextEditingController controller;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.mute,
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              Icon(icon, size: 20, color: AppColors.mute),
            ],
          ),
          const Divider(height: 1, color: AppColors.rule),
        ],
      ),
    );
  }
}

class _SelectRow extends StatelessWidget {
  const _SelectRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final IconData icon;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.mute,
            ),
          ),
          InkWell(
            onTap: () async {
              final picked = await showModalBottomSheet<String>(
                context: context,
                backgroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder: (context) {
                  return SafeArea(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final o in options)
                          ListTile(
                            title: Text(o),
                            trailing: o == value
                                ? const Icon(Icons.check_rounded)
                                : null,
                            onTap: () => Navigator.pop(context, o),
                          ),
                      ],
                    ),
                  );
                },
              );
              if (picked != null) onChanged(picked);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  Icon(icon, size: 20, color: AppColors.mute),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.rule),
        ],
      ),
    );
  }
}
