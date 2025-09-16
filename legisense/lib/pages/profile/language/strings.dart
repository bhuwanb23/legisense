import 'strings_en.dart';
import 'strings_hi.dart';
import 'strings_ta.dart';
import 'strings_te.dart';
import 'language_scope.dart';

class ProfileI18n {
  static Map<String, String> mapFor(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.hi:
        return profileStringsHi;
      case AppLanguage.ta:
        return profileStringsTa;
      case AppLanguage.te:
        return profileStringsTe;
      case AppLanguage.en:
        return profileStringsEn;
    }
  }
}


