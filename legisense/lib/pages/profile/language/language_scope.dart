import 'package:flutter/widgets.dart';

enum AppLanguage { en, hi, ta, te }

class LanguageController extends ChangeNotifier {
  LanguageController(this._language);

  AppLanguage _language;
  AppLanguage get language => _language;

  void setLanguage(AppLanguage lang) {
    if (_language == lang) return;
    _language = lang;
    notifyListeners();
  }
}

class LanguageScope extends InheritedNotifier<LanguageController> {
  const LanguageScope({
    super.key,
    required LanguageController controller,
    required super.child,
  }) : super(notifier: controller);

  static LanguageController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LanguageScope>();
    assert(scope != null, 'LanguageScope not found in context');
    return scope!.notifier!;
  }

  static LanguageController? maybeOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LanguageScope>();
    return scope?.notifier;
  }
}


