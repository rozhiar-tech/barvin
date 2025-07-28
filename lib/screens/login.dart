import 'dart:convert';
import 'package:barvin/generated/l10n.dart';
import 'package:barvin/screens/signup.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

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
      backgroundColor: const Color(0xFFF5F5F5),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            elevation: 6,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo & Title omitted for brevity...

                    // Email Field
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Email or Phone',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: Icon(Icons.person, color: primaryColor),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      onSaved: (v) => _identifier = v!.trim(),
                      validator: _validateIdentifier,
                    ),
                    const SizedBox(height: 16),

                    // Password Field
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: Icon(Icons.lock, color: primaryColor),
                      ),
                      obscureText: true,
                      onSaved: (v) => _password = v!.trim(),
                      validator: (v) =>
                          v != null && v.length >= 6 ? null : 'Minimum 6 chars',
                    ),
                    const SizedBox(height: 8),

                    // Remember Me
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          activeColor: primaryColor,
                          onChanged: (v) => setState(() => _rememberMe = v!),
                        ),
                        const Text('Remember me'),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Sign In Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isLoading ? null : _login,
                        child: _isLoading
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Sign In',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    // Sign Up link...
                    TextButton(
                      onPressed: () {
                        // if you’ve registered a named route:

                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SignUpPage()),
                        );
                      },
                      child: Text(
                        S
                            .of(context)
                            .dontHaveAnAccount, // or just "Don't have an account?"
                        style: TextStyle(color: primaryColor),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
