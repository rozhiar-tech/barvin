import 'package:barvin/screens/login.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Color primaryColor = Color(0xFF567765);

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  bool _loggedIn = false;
  String _name = 'Guest';
  String _address = '';
  String _phone = '';
  String _selectedLanguage = 'English';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool('loggedIn') ?? false;

    if (loggedIn) {
      setState(() {
        _loggedIn = true;
        _name = prefs.getString('userName') ?? 'John Doe';
        _address = prefs.getString('userAddress') ?? '123 Barvin Street, Erbil';
        _phone = prefs.getString('userPhone') ?? '+964 770 123 4567';
        _selectedLanguage = prefs.getString('language') ?? 'English';
      });
    } else {
      setState(() {
        _loggedIn = false;
        _name = 'Guest';
        _address = '';
        _phone = '';
        _selectedLanguage = prefs.getString('language') ?? 'English';
      });
    }
  }

  Future<void> _signIn() async {
    // TODO: push to your actual SignIn screen and handle login
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => LoginPage()),
    );
    if (result == true) {
      _loadProfile();
    }
  }

  Future<void> _changeLanguage(String? lang) async {
    if (lang == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', lang);
    setState(() => _selectedLanguage = lang);
    // TODO: trigger app-wide locale change
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: primaryColor),
        title: const Text(
          'Profile',
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Avatar
              Center(
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: primaryColor.withOpacity(0.1),
                  child: Icon(Icons.person, size: 64, color: primaryColor),
                ),
              ),
              const SizedBox(height: 16),

              // Name, Address, Phone (or Sign In for guests)
              if (_loggedIn) ...[
                Center(
                  child: Column(
                    children: [
                      Text(_name,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(_address),
                      const SizedBox(height: 2),
                      Text(_phone),
                    ],
                  ),
                ),
              ] else ...[
                Center(
                  child: Column(
                    children: [
                      const Text('You are browsing as Guest',
                          style: TextStyle(fontSize: 16)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _signIn,
                        child: const Text('Sign In',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Language Picker
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Language',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      DropdownButton<String>(
                        value: _selectedLanguage,
                        underline: const SizedBox(),
                        items: ['Kurdish', 'English', 'Arabic']
                            .map((lang) => DropdownMenuItem(
                                  value: lang,
                                  child: Text(lang),
                                ))
                            .toList(),
                        onChanged: _changeLanguage,
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Footer
              const Center(
                child: Text('Developed by UST Agency',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
