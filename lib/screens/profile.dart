import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:barvin/generated/l10n.dart';
import '../main.dart'; // for MyApp.setLocale
import 'login.dart';

const Color primaryColor = Color(0xFF567765);

class Profile extends StatefulWidget {
  const Profile({super.key});
  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  String? avatarUrl;
  final host = apiBase.replaceAll('/api', '');

  String? get rawPath {
    if (avatarUrl == null) return null;
    return avatarUrl!.startsWith('/') ? avatarUrl!.substring(1) : avatarUrl!;
  }

  String? get mediaUrl {
    if (rawPath == null) return null;
    // Make sure 'host' is defined somewhere in your code.
    return '$host/$rawPath';
  }

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
    final langCode = prefs.getString('locale') ?? 'en';
    // reverse map code → label
    final langLabel = {
      'en': 'English',
      'ku': 'Kurdish',
      'ar': 'Arabic',
    }[langCode]!;

    setState(() {
      _loggedIn = loggedIn;
      _selectedLanguage = langLabel;
      if (loggedIn) {
        _name = prefs.getString('userName') ?? 'John Doe';
        _address = prefs.getString('userAddress') ?? '';
        _phone = prefs.getString('userPhone') ?? '';
        avatarUrl = prefs.getString('userAvatar');
      } else {
        _name = 'Guest';
        _address = '';
        _phone = '';
        avatarUrl = null;
      }
    });
  }

  Future<void> _signIn() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => LoginPage()),
    );
    if (result == true) _loadProfile();
  }

  Future<void> _logOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    setState(() {
      _loggedIn = false;
      _name = 'Guest';
      _address = '';
      _phone = '';
      _selectedLanguage = 'English';
      avatarUrl = null;
    });
  }

  /// called when user picks a new language
  Future<void> _changeLanguage(String? lang) async {
    if (lang == null) return;

    // map label → code
    final code = {
      'English': 'en',
      'Kurdish': 'ku',
      'Arabic': 'ar',
    }[lang]!;

    // persist
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', code);

    // tell MyApp to rebuild
    MyApp.setLocale(context, Locale(code));

    // update dropdown
    setState(() => _selectedLanguage = lang);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: primaryColor),
        title: Text(S.of(context).profileTitle,
            style: const TextStyle(
                color: primaryColor, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            // ───── Avatar ─────
            Center(
              child: CircleAvatar(
                radius: 48,
                backgroundColor: primaryColor.withOpacity(0.1),
                backgroundImage: (avatarUrl?.isNotEmpty ?? false)
                    ? NetworkImage(mediaUrl!)
                    : null,
                child: (mediaUrl == null || mediaUrl!.isEmpty)
                    ? Icon(Icons.person, size: 64, color: primaryColor)
                    : null,
              ),
            ),
            const SizedBox(height: 16),

            // ───── User Info or Guest Sign-in ─────
            if (_loggedIn) ...[
              Center(
                child: Column(children: [
                  Text(_name,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(_address),
                  const SizedBox(height: 2),
                  Text(_phone),
                ]),
              ),
            ] else ...[
              Center(
                child: Column(children: [
                  Text(S.of(context).guestModeMessage,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _signIn,
                    child: Text(S.of(context).login,
                        style: const TextStyle(color: Colors.white)),
                  ),
                ]),
              ),
            ],
            const SizedBox(height: 24),

            // ───── Language Picker ─────
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(S.of(context).language,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      DropdownButton<String>(
                        value: _selectedLanguage,
                        underline: const SizedBox(),
                        items: ['Kurdish', 'English', 'Arabic']
                            .map((l) =>
                                DropdownMenuItem(value: l, child: Text(l)))
                            .toList(),
                        onChanged: _changeLanguage,
                      ),
                    ]),
              ),
            ),
            const Spacer(),

            // ───── Logout ─────
            if (_loggedIn)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _logOut,
                child: Text(S.of(context).logout,
                    style: const TextStyle(color: Colors.white)),
              ),

            const SizedBox(height: 16),
            Center(
                child: Text(S.of(context).footerCredit,
                    style: const TextStyle(fontSize: 12))),
          ]),
        ),
      ),
    );
  }
}
