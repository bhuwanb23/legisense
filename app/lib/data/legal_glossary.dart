/// Instant definitions for tappable legalese terms (demo glossary).
abstract final class LegalGlossary {
  static const terms = <String, String>{
    'lessee': 'The person who rents or leases property (the tenant).',
    'lessor': 'The owner who grants the lease (the landlord).',
    'indemnify':
        'To promise to cover someone else’s losses, damages, or legal costs.',
    'hold harmless':
        'An agreement that one party will not hold the other responsible for certain claims.',
    'herein': 'In this document.',
    'thereof': 'Of the thing just mentioned.',
    'notwithstanding': 'Even if something else in the contract says otherwise.',
    'force majeure':
        'Events beyond anyone’s control (like disasters) that excuse delays.',
    'sublet': 'To rent out property you are already renting to someone else.',
    'waiver': 'Giving up a legal right, often permanently for that situation.',
    'jurisdiction': 'Which court or region’s laws apply to the dispute.',
    'consideration': 'Something of value exchanged to make a contract binding.',
    'covenant': 'A formal promise in a contract to do or not do something.',
    'default': 'Failing to meet a required obligation under the contract.',
    'terminate': 'To end the contract before or at its natural end.',
    'notice': 'A formal written message required by the contract.',
    'deposit': 'Money held as security, often returned if terms are met.',
    'landlord': 'The property owner in a rental agreement.',
    'tenant': 'The person renting the property.',
  };

  /// Longest-first so multi-word phrases match before single words.
  static List<MapEntry<String, String>> get sortedEntries {
    final list = terms.entries.toList()
      ..sort((a, b) => b.key.length.compareTo(a.key.length));
    return list;
  }
}
