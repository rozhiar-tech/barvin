// lib/screens/signup.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'LocationPickerPage.dart';

const String apiBase = 'http://95.111.224.58:4000/api';
const Color primaryColor = Color(0xFF567765);

class SignUpPage extends StatefulWidget {
  const SignUpPage({Key? key}) : super(key: key);
  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  File? _avatarFile;
  String? _avatarError;
  String? _lat, _lng;
  bool _loading = false;
  String? _locationError;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, maxWidth: 600);
    if (picked != null) {
      setState(() {
        _avatarFile = File(picked.path);
        _avatarError = null;
      });
    }
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.of(context).push<LatLng>(
        MaterialPageRoute(builder: (_) => const LocationPickerPage()));
    if (result != null) {
      setState(() {
        _lat = result.latitude.toStringAsFixed(5);
        _lng = result.longitude.toStringAsFixed(5);
      });
    }
  }

  bool _isValidEmail(String v) =>
      RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[a-zA-Z]{2,}$').hasMatch(v);
  bool _isValidPhone(String v) => RegExp(r'^\+?\d{7,15}$').hasMatch(v);

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    if (_avatarFile == null) {
      setState(() => _avatarError = 'Please pick a photo');
      return;
    }

    setState(() => _loading = true);
    try {
      final uri = Uri.parse('$apiBase/users');
      final req = http.MultipartRequest('POST', uri)
        ..fields['name'] = _nameCtrl.text.trim()
        ..fields['email'] = _emailCtrl.text.trim()
        ..fields['password'] = _passwordCtrl.text
        ..fields['phone'] = _phoneCtrl.text.trim()
        ..fields['address'] = _addressCtrl.text.trim();
      if (_lat != null && _lng != null) {
        req.fields['latitude'] = _lat!;
        req.fields['longitude'] = _lng!;
      }
      final ext = _avatarFile!.path.split('.').last;
      req.files.add(await http.MultipartFile.fromPath(
        'avatar',
        _avatarFile!.path,
        contentType: MediaType('image', ext),
      ));

      final streamed = await req.send();
      final body = jsonDecode(await streamed.stream.bytesToString());
      if (streamed.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account created! Please sign in.')));
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${body['error'] ?? body}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Network error — try again.')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget _buildField({
    required TextEditingController ctrl,
    required String label,
    required TextInputType type,
    bool obscure = false,
    String? Function(String?)? validator,
    Widget? prefixIcon,
    VoidCallback? onTap,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      obscureText: obscure,
      readOnly: readOnly,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: prefixIcon,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // full‐screen gradient bg:
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE8F4E8), Color(0xFFF1FAF5)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Create Account',
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // avatar picker
                    GestureDetector(
                      onTap: _pickAvatar,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: _avatarFile != null
                            ? FileImage(_avatarFile!)
                            : null,
                        child: _avatarFile == null
                            ? Icon(Icons.camera_alt,
                                size: 40, color: primaryColor)
                            : null,
                      ),
                    ),
                    if (_avatarError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(_avatarError!,
                            style: const TextStyle(
                                color: Colors.red, fontSize: 12)),
                      ),
                    const SizedBox(height: 20),

                    Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        children: [
                          _buildField(
                            ctrl: _nameCtrl,
                            label: 'Full Name',
                            type: TextInputType.name,
                            prefixIcon:
                                const Icon(Icons.person, color: primaryColor),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Enter your name'
                                : null,
                          ),
                          const SizedBox(height: 12),

                          _buildField(
                            ctrl: _emailCtrl,
                            label: 'Email',
                            type: TextInputType.emailAddress,
                            prefixIcon:
                                const Icon(Icons.email, color: primaryColor),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty)
                                return 'Enter your email';
                              return _isValidEmail(v.trim())
                                  ? null
                                  : 'Invalid email';
                            },
                          ),
                          const SizedBox(height: 12),

                          _buildField(
                            ctrl: _passwordCtrl,
                            label: 'Password',
                            type: TextInputType.visiblePassword,
                            obscure: true,
                            prefixIcon:
                                const Icon(Icons.lock, color: primaryColor),
                            validator: (v) {
                              if (v == null || v.length < 8)
                                return 'Password must be ≥8 chars';
                              // only letters, numbers and dot
                              if (!RegExp(r'^[A-Za-z0-9.]+$').hasMatch(v))
                                return 'Password may only contain letters, numbers, and “.”';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          _buildField(
                            ctrl: _phoneCtrl,
                            label: 'Phone',
                            type: TextInputType.phone,
                            prefixIcon:
                                const Icon(Icons.phone, color: primaryColor),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty)
                                return 'Enter phone';
                              return _isValidPhone(v.trim())
                                  ? null
                                  : 'Invalid phone';
                            },
                          ),
                          const SizedBox(height: 12),

                          // free‐text address
                          _buildField(
                            ctrl: _addressCtrl,
                            label: 'Address',
                            type: TextInputType.streetAddress,
                            prefixIcon:
                                const Icon(Icons.home, color: primaryColor),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Enter your address'
                                : null,
                          ),
                          const SizedBox(height: 12),

                          // separate lat/lng picker
                          Row(
                            children: [
                              IconButton(
                                icon:
                                    const Icon(Icons.map, color: primaryColor),
                                onPressed: _pickLocation,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _lat != null && _lng != null
                                      ? 'Location: ($_lat, $_lng)'
                                      : 'No location selected',
                                  style: TextStyle(
                                      color: Colors.grey[700], fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                          if (_locationError != null)
                            Padding(
                              padding:
                                  const EdgeInsets.only(left: 48.0, top: 4),
                              child: Text(
                                _locationError!,
                                style: const TextStyle(
                                    color: Colors.red, fontSize: 12),
                              ),
                            ),

                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _loading
                                  ? null
                                  : () {
                                      // first, validate all text fields:
                                      if (!_formKey.currentState!.validate())
                                        return;

                                      // avatar required
                                      if (_avatarFile == null) {
                                        setState(() => _avatarError =
                                            'Please pick a photo');
                                        return;
                                      }

                                      // location required
                                      if (_lat == null || _lng == null) {
                                        setState(() => _locationError =
                                            'Please select your location on map');
                                        return;
                                      }

                                      // all good, clear errors & submit
                                      setState(() {
                                        _avatarError = null;
                                        _locationError = null;
                                        _loading = true;
                                      });
                                      _signup();
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _loading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white)
                                  : const Text(
                                      'Sign Up',
                                      style: TextStyle(
                                          fontSize: 16, color: Colors.white),
                                    ),
                            ),
                          ),
                        ],
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
