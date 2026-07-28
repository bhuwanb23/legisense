/// Static lists for profile setup (India-first).
abstract final class IndiaRegions {
  static const states = <String>[
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chhattisgarh',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
    'Delhi',
    'Jammu and Kashmir',
    'Ladakh',
    'Puducherry',
    'Chandigarh',
  ];
}

abstract final class ProfileOptions {
  static const professions = <String>[
    'Lawyer',
    'Student',
    'Business Owner',
    'Individual',
  ];

  static const languages = <({String code, String label})>[
    (code: 'en', label: 'English'),
    (code: 'hi', label: 'Hindi'),
    (code: 'ta', label: 'Tamil'),
    (code: 'te', label: 'Telugu'),
  ];

  static const documentTypes = <String>[
    'Rent',
    'Loan',
    'Employment',
    'Insurance',
    'Other',
  ];
}

/// Mock auth helpers.
abstract final class AuthMock {
  static const demoOtp = '123456';

  static String maskContact(String contact) {
    final trimmed = contact.trim();
    if (trimmed.contains('@')) {
      final parts = trimmed.split('@');
      if (parts.length != 2) return trimmed;
      final name = parts[0];
      final masked = name.length <= 2
          ? '*' * name.length
          : '${name.substring(0, 2)}${'*' * (name.length - 2)}';
      return '$masked@${parts[1]}';
    }
    if (trimmed.length >= 4) {
      return '${'*' * (trimmed.length - 4)}${trimmed.substring(trimmed.length - 4)}';
    }
    return trimmed;
  }
}
