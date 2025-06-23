import 'package:barvin/screens/orders.dart';
import 'package:barvin/screens/profile.dart';
import 'package:barvin/screens/splash.dart';
import 'package:flutter/material.dart';
import 'package:barvin/screens/login.dart';
import 'package:barvin/screens/home.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Barvin',
      theme: ThemeData(useMaterial3: true),
      initialRoute: '/splash',
      routes: {
        '/login': (context) => LoginPage(),
        '/main': (context) => const MainScreen(),
        '/splash': (context) => Splash(),
        '/orders': (context) => Orders(),
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
  final List<Widget> _pages = const [
    HomeScreen(),
    Orders(), // OrdersScreen()
    Profile(), // ProfileScreen()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        // fixedColor: Colors.grey[600],
        backgroundColor: Colors.white,
        selectedItemColor: Color(0xFF10B981),
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
