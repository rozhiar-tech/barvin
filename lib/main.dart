import 'package:barvin/l10n/kurdish_fallback.dart';
import 'package:barvin/screens/basket.dart';
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
        '/orders': (c) => Orders(),
        '/basket': (c) => BasketPage(),
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
  final GlobalKey<BasketPageState> _basketKey = GlobalKey<BasketPageState>();

  // avoid `const` here if your pages aren’t const widgets

  // Build pages in initState so you can pass the key:
  late final List<Widget> _pages;
  @override
  void initState() {
    super.initState();
    _pages = [
      const HomeScreen(),
      Orders(),
      Profile(),
      BasketPage(key: _basketKey), // <- with key, not const
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // <-- important for 4+ items
        selectedFontSize: 11, // <-- make labels smaller
        unselectedFontSize: 11,
        iconSize: 22, // <-- slightly smaller icons
        showUnselectedLabels: true, // (optional) keep labels visible
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF567765),
        unselectedItemColor: const Color(0xFF567765).withOpacity(0.6),
        currentIndex: _currentIndex,
        onTap: (i) {
          setState(() => _currentIndex = i);
          if (i == 3) {
            // Ask Basket to refresh when tab is shown
            _basketKey.currentState?.reload();
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_basket), label: 'Basket'),
        ],
      ),
    );
  }
}
