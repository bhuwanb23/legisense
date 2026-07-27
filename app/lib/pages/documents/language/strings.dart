import '../../profile/language/language_scope.dart';

import 'strings_en.dart';
import 'strings_hi.dart';
import 'strings_ta.dart';
import 'strings_te.dart';

class DocumentsI18n {
  static Map<String, String> mapFor(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.hi:
        return documentsStringsHi;
      case AppLanguage.ta:
        return documentsStringsTa;
      case AppLanguage.te:
        return documentsStringsTe;
      case AppLanguage.en:
        return documentsStringsEn;
    }
  }
}


