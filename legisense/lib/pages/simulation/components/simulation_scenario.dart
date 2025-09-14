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
