import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'pages/splash/splash_page.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );
  runApp(const LegisenseApp());
}

class LegisenseApp extends StatelessWidget {
  const LegisenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Legisense',
      debugShowCheckedModeBanner: false,
      theme: buildLegisenseTheme(),
      // Flutter web: Material tooltips use SingleTickerProvider but create
      // multiple tickers on hover → mouse_tracker assertion storms.
      builder: (context, child) {
        final content = child ?? const SizedBox.shrink();
        if (!kIsWeb) return content;
        return TooltipVisibility(
          visible: false,
          child: content,
        );
      },
      home: const SplashPage(),
    );
  }
}
