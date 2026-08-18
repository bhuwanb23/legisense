import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../repositories/meta_repository.dart';
import '../../services/api_exception.dart';
import '../../theme/app_theme.dart';

/// Visual country → state picker. Returns `(countryCode, stateCode?)` where
/// state is a plain-text state name for the selected country.
class JurisdictionPickerSheet extends StatefulWidget {
  const JurisdictionPickerSheet({super.key});

  @override
  State<JurisdictionPickerSheet> createState() => _JurisdictionPickerSheetState();
}

class _JurisdictionPickerSheetState extends State<JurisdictionPickerSheet> {
  final _repo = MetaRepository();
  List<Map<String, dynamic>> _countries = [];
  List<Map<String, dynamic>> _states = [];
  String? _countryCode;
  String? _stateName;
  bool _loading = true;
  bool _loadingStates = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCountries();
  }

  Future<void> _loadCountries() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final countries = await _repo.countries();
      if (!mounted) return;
      setState(() {
        _countries = countries;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _selectCountry(String code) async {
    setState(() {
      _countryCode = code;
      _stateName = null;
      _states = [];
      _loadingStates = true;
    });
    try {
      final states = await _repo.states(code);
      if (!mounted) return;
      setState(() {
        _states = states;
        _loadingStates = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingStates = false);
    }
  }

  void _confirm() {
    final code = _countryCode;
    if (code == null) return;
    Navigator.of(context).pop((country: code, state: _stateName));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.chip,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Jurisdiction',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Choose the country whose laws apply.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.mute,
              ),
            ),
            const SizedBox(height: 14),
            Flexible(
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _error != null
                      ? Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.error,
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: _countries.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 6),
                          itemBuilder: (context, i) {
                            final c = _countries[i];
                            final code = (c['country_code'] ??
                                    c['code'] ??
                                    c['countryCode'] ??
                                    '')
                                .toString();
                            final name = (c['country_name'] ??
                                    c['name'] ??
                                    c['country'] ??
                                    code)
                                .toString();
                            final selected = _countryCode == code;
                            return _CountryTile(
                              name: name,
                              code: code,
                              selected: selected,
                              expanded: selected,
                              states: _states,
                              loadingStates: _loadingStates,
                              onTap: () => _selectCountry(code),
                              onState: (s) => setState(() => _stateName = s),
                              stateName: _stateName,
                            );
                          },
                        ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _countryCode == null ? null : _confirm,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.ink,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(46),
              ),
              child: Text(
                'Use this jurisdiction',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountryTile extends StatelessWidget {
  const _CountryTile({
    required this.name,
    required this.code,
    required this.selected,
    required this.expanded,
    required this.states,
    required this.loadingStates,
    required this.onTap,
    required this.onState,
    required this.stateName,
  });

  final String name;
  final String code;
  final bool selected;
  final bool expanded;
  final List<Map<String, dynamic>> states;
  final bool loadingStates;
  final VoidCallback onTap;
  final ValueChanged<String> onState;
  final String? stateName;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: selected ? AppColors.chip : AppColors.bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ListTile(
            dense: true,
            leading: const Icon(Icons.public_rounded, size: 20),
            title: Text(
              name,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
            trailing: Icon(
              expanded
                  ? Icons.expand_less_rounded
                  : Icons.expand_more_rounded,
              color: AppColors.mute,
            ),
            onTap: onTap,
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: loadingStates
                  ? const Padding(
                      padding: EdgeInsets.all(8),
                      child: Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  : states.isEmpty
                      ? Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'No states listed — using country only.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppColors.mute,
                            ),
                          ),
                        )
                      : Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: states.map((s) {
                            final v = (s['state_code'] ??
                                    s['code'] ??
                                    s['stateCode'] ??
                                    '')
                                .toString();
                            final label = (s['state_name'] ??
                                    s['name'] ??
                                    s['state'] ??
                                    v)
                                .toString();
                            final sel = stateName == v;
                            return ChoiceChip(
                              label: Text(label),
                              selected: sel,
                              onSelected: (_) => onState(sel ? '' : v),
                              selectedColor: AppColors.ink,
                              labelStyle: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: sel
                                    ? AppColors.cloud
                                    : AppColors.ink,
                              ),
                              backgroundColor: AppColors.surface,
                              visualDensity: VisualDensity.compact,
                            );
                          }).toList(),
                        ),
            ),
        ],
      ),
    );
  }
}
