import 'dart:convert';
import 'package:barvin/screens/signup.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

const Color _kPrimaryGreen = Color(0xFF4BCF7B);

const Color primaryColor = Color(0xFF567765);
const String apiBase = 'http://95.111.224.58:4000/api';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  bool _rememberMe = false;
  bool _isLoading = false;
  String _identifier = '';
  bool _obscure = true;
  void _togglePassword() => setState(() => _obscure = !_obscure);

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);
    try {
      final body = <String, String>{'password': _password};
      if (_identifier.contains('@')) {
        body['email'] = _identifier;
      } else {
        body['phone'] = _identifier;
      }
      final res = await http.post(
        Uri.parse('$apiBase/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data['token'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('loggedIn', true);
        await prefs.setString('userName', data['user']['name']);

        await prefs.setString('userAddress', data['user']['address']);

        await prefs.setString('userPhone', data['user']['phone']);
        await prefs.setString('userAvatar', data['user']['avatar']);
        await prefs.setBool('delivery', data['user']['delivery']);
        await prefs.setBool('debt', data['user']['debt']);
        await prefs.setString('latitude', data['user']['latitude']);

        await prefs.setString('longitude', data['user']['longitude']);
        await prefs.setInt('userId', data['user']['id']);
        await prefs.setString('token', data['token']);

        if (_rememberMe) {
          await prefs.setString('email', _email);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signed in successfully!')),
        );
        Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false);
      } else {
        final msg = data['error'] ?? 'Invalid credentials';
        print(data['error']);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error — please try again')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String? _validateIdentifier(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final t = v.trim();
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    final phoneRegex = RegExp(r'^\+?[0-9]{7,15}$');
    if (emailRegex.hasMatch(t) || phoneRegex.hasMatch(t)) return null;
    return 'Enter valid email or phone';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // extend body behind status bar
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE8F4E8),
              Color(0xFFF1FAF5),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                children: [
                  // ───────── top icon ─────────
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: const Icon(
                      Icons.local_shipping,
                      color: Colors.white,
                      size: 46,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ───────── white card ─────────
                  Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                    elevation: 6,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // identifier
                            const SizedBox(height: 46),

                            TextFormField(
                              decoration: InputDecoration(
                                hintText: 'Enter email or phone number',
                                labelText: 'Email or Phone',
                                filled: true,
                                fillColor: Colors.grey[200],
                                prefixIcon:
                                    Icon(Icons.person, color: _kPrimaryGreen),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: _validateIdentifier,
                              onSaved: (v) => _identifier = v!.trim(),
                            ),
                            const SizedBox(height: 46),

                            // password
                            TextFormField(
                              decoration: InputDecoration(
                                hintText: 'Enter your password',
                                labelText: 'Password',
                                filled: true,
                                fillColor: Colors.grey[200],
                                prefixIcon:
                                    Icon(Icons.lock, color: _kPrimaryGreen),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                      _obscure
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: Colors.grey),
                                  onPressed: _togglePassword,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              obscureText: _obscure,
                              validator: (v) => v != null && v.length >= 6
                                  ? null
                                  : 'Minimum 6 chars',
                              onSaved: (v) => _password = v!.trim(),
                            ),

                            const SizedBox(height: 8),

                            const SizedBox(height: 36),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : () => _login(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Log In',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        )),
                              ),
                            ),

                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (_) => SignUpPage())),
                              child: const Text(
                                  "Don't have an account? Sign Up",
                                  style: TextStyle(color: _kPrimaryGreen)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ───────── guest banner ─────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'You can browse as a guest, but need an account to order.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black54),
                        ),
                        TextButton(
                          onPressed: () {
                            // TODO: guest flow
                            Navigator.of(context).pop();
                          },
                          child: const Text(
                            'Continue as Guest',
                            style: TextStyle(
                              color: _kPrimaryGreen,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
