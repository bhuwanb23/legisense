// i18n helpers
import 'package:flutter/widgets.dart';
import '../../profile/language/language_scope.dart';
import '../language/strings.dart';

enum SimulationScenario {
  normal,
  missedPayment,
  earlyTermination,
}

extension SimulationScenarioExtension on SimulationScenario {
  String get displayName {
    switch (this) {
      case SimulationScenario.normal:
        return 'Normal';
      case SimulationScenario.missedPayment:
        return 'Missed Payment';
      case SimulationScenario.earlyTermination:
        return 'Early Termination';
    }
  }

  String get description {
    switch (this) {
      case SimulationScenario.normal:
        return 'Standard contract execution with no issues';
      case SimulationScenario.missedPayment:
        return 'Contractor misses payment deadlines';
      case SimulationScenario.earlyTermination:
        return 'Contract is terminated before completion';
    }
  }

  String get icon {
    switch (this) {
      case SimulationScenario.normal:
        return '✓';
      case SimulationScenario.missedPayment:
        return '⚠';
      case SimulationScenario.earlyTermination:
        return '✗';
    }
  }
}

extension SimulationScenarioI18n on SimulationScenario {
  /// Returns the i18n key for this scenario's name
  String get i18nKeyName {
    switch (this) {
      case SimulationScenario.normal:
        return 'scenario.normal';
      case SimulationScenario.missedPayment:
        return 'scenario.missed';
      case SimulationScenario.earlyTermination:
        return 'scenario.early';
    }
  }

  /// Returns the i18n key for this scenario's description
  String get i18nKeyDescription {
    switch (this) {
      case SimulationScenario.normal:
        return 'scenario.normal.desc';
      case SimulationScenario.missedPayment:
        return 'scenario.missed.desc';
      case SimulationScenario.earlyTermination:
        return 'scenario.early.desc';
    }
  }

  /// Localized display name using provided i18n map
  String localizedName(Map<String, String> i18n) =>
      i18n[i18nKeyName] ?? displayName;

  /// Localized description using provided i18n map
  String localizedDescription(Map<String, String> i18n) =>
      i18n[i18nKeyDescription] ?? description;

  /// Localized display name using BuildContext
  String localizedNameFromContext(BuildContext context) {
    final scope = LanguageScope.maybeOf(context);
    final i18n = SimulationI18n.mapFor(scope?.language ?? AppLanguage.en);
    return localizedName(i18n);
  }

  /// Localized description using BuildContext
  String localizedDescriptionFromContext(BuildContext context) {
    final scope = LanguageScope.maybeOf(context);
    final i18n = SimulationI18n.mapFor(scope?.language ?? AppLanguage.en);
    return localizedDescription(i18n);
  }
}