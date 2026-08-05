import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'screens/splash_screen.dart';
import 'services/ads_service.dart';
import 'services/app_state.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  final appState = AppState();
  final ads = AdsService();
  await appState.init();
  // Ads init non-blocking so offline review still works.
  ads.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appState),
        ChangeNotifierProvider.value(value: ads),
      ],
      child: const CasharkApp(),
    ),
  );
}

class CasharkApp extends StatelessWidget {
  const CasharkApp({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppState>().lang;
    return MaterialApp(
      title: 'Cashark',
      debugShowCheckedModeBanner: false,
      theme: buildCasharkTheme(),
      locale: lang.locale,
      home: const SplashScreen(),
    );
  }
}
