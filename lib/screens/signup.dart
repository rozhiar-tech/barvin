import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

const String apiBase = 'http://95.111.224.58:4000/api';
const Color primaryColor = Color(0xFF567765);

class SignUpPage extends StatefulWidget {
  const SignUpPage({Key? key}) : super(key: key);

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  File? _avatarFile;
  bool _loading = false;

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, maxWidth: 600);
    if (picked != null) {
      setState(() => _avatarFile = File(picked.path));
    }
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final uri = Uri.parse('$apiBase/users');
      final request = http.MultipartRequest('POST', uri)
        ..fields['name'] = _nameCtrl.text.trim()
        ..fields['email'] = _emailCtrl.text.trim()
        ..fields['password'] = _passwordCtrl.text
        ..fields['phone'] = _phoneCtrl.text.trim()
        ..fields['address'] = _addressCtrl.text.trim()
        ..fields['free_delivery'] = 'false'
        ..fields['debt'] = 'false';

      if (_avatarFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'avatar',
            _avatarFile!.path,
            contentType: MediaType('image', _avatarFile!.path.split('.').last),
          ),
        );
      }

      final response = await request.send();
      final respStr = await response.stream.bytesToString();
      final body = jsonDecode(respStr);

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Account created! Please sign in.')),
        );
        Navigator.of(context).pop(true);
      } else {
        final err = body['error'] ?? body;
        print(err);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: \$err')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network error — try again.')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
        backgroundColor: primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                  _buildField(_nameCtrl, 'Full Name', TextInputType.text),
                  const SizedBox(height: 12),
                  _buildField(_emailCtrl, 'Email', TextInputType.emailAddress),
                  const SizedBox(height: 12),
                  _buildField(
                    _passwordCtrl,
                    'Password',
                    TextInputType.visiblePassword,
                    obscure: true,
                  ),
                  const SizedBox(height: 12),
                  _buildField(_phoneCtrl, 'Phone', TextInputType.phone),
                  const SizedBox(height: 12),
                  _buildField(
                      _addressCtrl, 'Address', TextInputType.streetAddress),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 50,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _signup,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      child: _loading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text('Sign Up', style: TextStyle(fontSize: 16)),
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

  Widget _buildField(
      TextEditingController ctrl, String label, TextInputType type,
      {bool obscure = false}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      validator: (v) =>
          v == null || v.isEmpty ? 'Enter \$label'.toLowerCase() : null,
    );
  }
}
