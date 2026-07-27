import '../../profile/language/language_scope.dart';
import 'strings_en.dart' as en;
import 'strings_hi.dart' as hi;
import 'strings_ta.dart' as ta;
import 'strings_te.dart' as te;

class SimulationI18n {
  static Map<String, String> mapFor(AppLanguage language) {
    switch (language) {
      case AppLanguage.hi:
        return hi.strings;
      case AppLanguage.ta:
        return ta.strings;
      case AppLanguage.te:
        return te.strings;
      case AppLanguage.en:
        return en.strings;
    }
  }
}


