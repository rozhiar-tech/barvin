import 'package:barvin/l10n/kurdish_fallback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'generated/l10n.dart'; // ← your intl_utils output
import 'screens/home.dart';
import 'screens/orders.dart';
import 'screens/profile.dart';
import 'screens/login.dart';
import 'screens/splash.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1️⃣ Load saved locale code, default to English
  final prefs = await SharedPreferences.getInstance();
  final savedCode = prefs.getString('locale') ?? 'en';

  runApp(MyApp(initialLocale: Locale(savedCode)));
}

class MyApp extends StatefulWidget {
  final Locale initialLocale;
  const MyApp({required this.initialLocale, Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();

  /// call this to change the app-wide locale
  static void setLocale(BuildContext ctx, Locale newLocale) {
    final _MyAppState? state = ctx.findAncestorStateOfType<_MyAppState>();
    state?._updateLocale(newLocale);
  }
}

class _MyAppState extends State<MyApp> {
  late Locale _locale;

  @override
  void initState() {
    super.initState();
    _locale = widget.initialLocale;
  }

  void _updateLocale(Locale newLoc) {
    setState(() => _locale = newLoc);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Barvin',
      locale: _locale,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        KurdishMaterialFallback(),
        KurdishCupertinoFallback(),
      ],
      supportedLocales: S.delegate.supportedLocales, // [en, ku, ar]
      localeResolutionCallback: (deviceLoc, supported) {
        return supported.firstWhere(
          (l) => l.languageCode == _locale.languageCode,
          orElse: () => const Locale('en'),
        );
      },
      builder: (context, child) {
        final locale = Localizations.localeOf(context);
        final isRtl = ['ar', 'ku'].contains(locale.languageCode);
        return Directionality(
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: child!,
        );
      },
      theme: ThemeData(useMaterial3: true),
      initialRoute: '/splash',
      routes: {
        '/login': (c) => LoginPage(),
        '/main': (c) => const MainScreen(),
        '/splash': (c) => Splash(),
        '/orders': (c) => const Orders(),
        // '/signup': (c) => const SignUpPage(),
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  static const _pages = [
    HomeScreen(),
    Orders(),
    Profile(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF567765),
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
