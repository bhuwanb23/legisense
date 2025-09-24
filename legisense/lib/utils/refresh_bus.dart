import 'package:flutter/foundation.dart';

class GlobalRefreshBus {
  GlobalRefreshBus._();
  static final ValueNotifier<int> notifier = ValueNotifier<int>(0);

  static void ping() {
    notifier.value = notifier.value + 1;
  }
}


