import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'LocationPickerPage.dart'; // <-- your map picker

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
  LatLng? _pickedLocation;
  File? _avatarFile;
  bool _loading = false;

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
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 600,
    );
    if (picked != null) {
      setState(() => _avatarFile = File(picked.path));
    }
  }

  Future<void> _pickLocation() async {
    // pushes to your map picker and returns a LatLng
    final result = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(builder: (_) => const LocationPickerPage()),
    );
    if (result != null) {
      setState(() {
        _pickedLocation = result;
        // you can also reverse-geocode here if you want a human address
        _addressCtrl.text =
            '${result.latitude.toStringAsFixed(5)}, ${result.longitude.toStringAsFixed(5)}';
      });
    }
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final uri = Uri.parse('$apiBase/users');
      final req = http.MultipartRequest('POST', uri)
        ..fields['name'] = _nameCtrl.text.trim()
        ..fields['email'] = _emailCtrl.text.trim()
        ..fields['password'] = _passwordCtrl.text
        ..fields['phone'] = _phoneCtrl.text.trim()
        ..fields['address'] = _addressCtrl.text.trim();

      // attach lat/long if selected
      if (_pickedLocation != null) {
        req.fields['latitude'] = _pickedLocation!.latitude.toString();
        req.fields['longitude'] = _pickedLocation!.longitude.toString();
      }

      // avatar upload
      if (_avatarFile != null) {
        final ext = _avatarFile!.path.split('.').last;
        req.files.add(await http.MultipartFile.fromPath(
          'avatar',
          _avatarFile!.path,
          contentType: MediaType('image', ext),
        ));
      }

      final streamed = await req.send();
      final respStr = await streamed.stream.bytesToString();
      final body = jsonDecode(respStr);

      if (streamed.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created! Please sign in.')),
        );
        Navigator.of(context).pop(true);
      } else {
        final err = body['error'] ?? body;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $err')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error — try again.')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget _buildField(
      {required TextEditingController ctrl,
      required String label,
      required TextInputType type,
      bool obscure = false,
      VoidCallback? onTap,
      Widget? suffixIcon,
      bool readOnly = false}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      obscureText: obscure,
      readOnly: readOnly,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      validator: (v) => (v == null || v.isEmpty) ? 'Enter $label' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sign Up',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Avatar picker
            GestureDetector(
              onTap: _pickAvatar,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[200],
                backgroundImage:
                    _avatarFile != null ? FileImage(_avatarFile!) : null,
                child: _avatarFile == null
                    ? Icon(Icons.camera_alt, size: 40, color: primaryColor)
                    : null,
              ),
            ),
            const SizedBox(height: 20),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildField(
                      ctrl: _nameCtrl,
                      label: 'Full Name',
                      type: TextInputType.text),
                  const SizedBox(height: 12),
                  _buildField(
                      ctrl: _emailCtrl,
                      label: 'Email',
                      type: TextInputType.emailAddress),
                  const SizedBox(height: 12),
                  _buildField(
                      ctrl: _passwordCtrl,
                      label: 'Password',
                      type: TextInputType.visiblePassword,
                      obscure: true),
                  const SizedBox(height: 12),
                  _buildField(
                      ctrl: _phoneCtrl,
                      label: 'Phone',
                      type: TextInputType.phone),
                  const SizedBox(height: 12),
                  // Address + map picker
                  _buildField(
                    ctrl: _addressCtrl,
                    label: 'Address',
                    type: TextInputType.streetAddress,
                    readOnly: false, // allow typing
                    onTap: null, // don't override tap
                    suffixIcon: const SizedBox.shrink(),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _pickedLocation != null
                              ? 'Lat: ${_pickedLocation!.latitude.toStringAsFixed(5)}\n'
                                  'Lng: ${_pickedLocation!.longitude.toStringAsFixed(5)}'
                              : 'No location selected',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.map, color: primaryColor),
                        tooltip: 'Pick on map',
                        onPressed: _pickLocation,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _signup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Sign Up',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              )),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
