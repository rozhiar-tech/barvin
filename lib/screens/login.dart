import 'dart:convert';
import 'package:barvin/screens/signup.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
// ignore: unused_shown_name
import 'package:barvin/screens/home.dart' show apiUrl, apiBase;
import 'package:barvin/generated/l10n.dart'; // ⬅️ i18n
// at the top with other imports
import 'package:barvin/screens/forgot_password.dart'; // NEW

const Color _kPrimaryGreen = Color(0xFF4BCF7B);
const Color primaryColor = Color(0xFF567765);

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  String _password = '';
  bool _rememberMe = false;
  bool _isLoading = false;
  String _identifier = '';
  bool _obscure = true;
  void _togglePassword() => setState(() => _obscure = !_obscure);

  String _formatPhoneForBackend(String input) {
    var digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    if (!digits.startsWith('964')) {
      digits = '964$digits';
    }
    return digits;
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);
    try {
      final body = <String, String>{'password': _password};
      if (_identifier.contains('@')) {
        body['email'] = _identifier;
      } else {
        body['phone'] = _formatPhoneForBackend(_identifier);
      }

      final res = await http.post(
        apiUrl('/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      Map<String, dynamic> data = {};
      try {
        data = jsonDecode(res.body) as Map<String, dynamic>;
      } catch (_) {}

      if (res.statusCode == 200 && data['token'] is String) {
        final token = data['token'] as String;
        final user = (data['user'] as Map<String, dynamic>?) ?? {};

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('loggedIn', true);
        await prefs.setString('token', token);
        await prefs.setInt('userId', (user['id'] ?? 0) as int);

        await prefs.setString('userName', (user['name'] ?? '').toString());
        await prefs.setString(
            'userAddress', (user['address'] ?? '').toString());
        await prefs.setString('userPhone', (user['phone'] ?? '').toString());
        if (user['avatar'] != null) {
          await prefs.setString('userAvatar', user['avatar'].toString());
        } else {
          await prefs.remove('userAvatar');
        }
        if (user['latitude'] != null) {
          await prefs.setString('latitude', user['latitude'].toString());
        } else {
          await prefs.remove('latitude');
        }
        if (user['longitude'] != null) {
          await prefs.setString('longitude', user['longitude'].toString());
        } else {
          await prefs.remove('longitude');
        }

        await prefs.setBool('delivery', (user['delivery'] ?? false) == true);
        await prefs.setBool('debt', (user['debt'] ?? false) == true);

        if (_rememberMe) {
          await prefs.setString('identifier', _identifier);
        }

        // (Optional) decode JWT expiry safely
        try {
          final parts = token.split('.');
          if (parts.length == 3) {
            final payload = jsonDecode(
              utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
            );
            if (payload is Map && payload['exp'] is int) {
              final exp =
                  DateTime.fromMillisecondsSinceEpoch(payload['exp'] * 1000);
              print('Now: ${DateTime.now()} – Token expires at: $exp');
            }
          }
        } catch (e) {
          print('JWT decode skipped: $e');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).loginSuccess)),
        );
        Navigator.pushNamedAndRemoveUntil(context, '/main', (_) => false);
      } else {
        final msg =
            (data['error'] as String?) ?? S.of(context).loginInvalidCredentials;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).networkError)),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String? _validateIdentifier(String? v) {
    if (v == null || v.trim().isEmpty) return S.of(context).loginRequired;
    final t = v.trim();
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    final phoneRegex = RegExp(r'^\+?[0-9]{7,15}$');
    if (emailRegex.hasMatch(t) || phoneRegex.hasMatch(t)) return null;
    return S.of(context).loginInvalidIdentifier;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        Container(
          decoration: const BoxDecoration(color: Color(0xffD3E4C4)),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 16.0),
                child: Column(
                  children: [
                    // top icon
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

                    // white card
                    Card(
                      color: Color(0xffFEFAE0),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24)),
                      elevation: 6,
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              const SizedBox(height: 46),

                              // identifier
                              TextFormField(
                                decoration: InputDecoration(
                                  hintText: S.of(context).loginIdentifierHint,
                                  labelText: S.of(context).loginIdentifierLabel,
                                  filled: true,
                                  fillColor: Colors.grey[200],
                                  prefixIcon: const Icon(Icons.person,
                                      color: _kPrimaryGreen),
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
                                  hintText: S.of(context).loginPasswordHint,
                                  labelText: S.of(context).loginPasswordLabel,
                                  filled: true,
                                  fillColor: Colors.grey[200],
                                  prefixIcon: const Icon(Icons.lock,
                                      color: _kPrimaryGreen),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscure
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: Colors.grey,
                                    ),
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
                                    : S.of(context).loginMinimumChars,
                                onSaved: (v) => _password = v!.trim(),
                              ),

                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _isLoading
                                      ? null
                                      : () => Navigator.of(context).push(
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                    const ForgotPasswordPage()),
                                          ),
                                  child: Text(
                                    S
                                        .of(context)
                                        .forgotPasswordLink, // e.g. "Forgot password?"
                                    style:
                                        const TextStyle(color: _kPrimaryGreen),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 36),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : () => _login(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
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
                                      : Text(
                                          S.of(context).loginButton,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),

                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (_) => SignUpPage()),
                                ),
                                child: Text(
                                  S.of(context).signUpCta,
                                  style: const TextStyle(color: _kPrimaryGreen),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // guest banner
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Color(0xffFEFAE0).withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            S.of(context).guestBannerText,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.black54),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text(
                              S.of(context).continueAsGuest,
                              style: const TextStyle(
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
        Positioned(
          top: 16,
          left: 8,
          child: SafeArea(
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black54),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ]),
    );
  }
}
