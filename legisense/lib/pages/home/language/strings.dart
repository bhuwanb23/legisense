import '../../profile/language/language_scope.dart';
import 'strings_en.dart';
import 'strings_hi.dart';
import 'strings_ta.dart';
import 'strings_te.dart';

class HomeI18n {
  static Map<String, String> mapFor(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.hi:
        return homeStringsHi;
      case AppLanguage.ta:
        return homeStringsTa;
      case AppLanguage.te:
        return homeStringsTe;
      case AppLanguage.en:
        return homeStringsEn;
    }
  }
}


