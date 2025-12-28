// lib/screens/edit_profile.dart

import 'dart:convert';
import 'dart:io';
import 'package:barvin/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:latlong2/latlong.dart';
import 'LocationPickerPage.dart';
import 'package:barvin/screens/home.dart' show apiBase;
import 'package:barvin/constants/app_constants.dart';
import 'package:barvin/services/token_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Color primaryColor = AppColors.primary;

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({Key? key}) : super(key: key);

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  File? _avatarFile;
  String? _lat, _lng;
  bool _loading = false;
  String? _locationError;
  String? _currentAvatarUrl;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameCtrl.text = prefs.getString('userName') ?? '';
      _emailCtrl.text = prefs.getString('userEmail') ?? '';
      _phoneCtrl.text = prefs.getString('userPhone') ?? '';
      _addressCtrl.text = prefs.getString('userAddress') ?? '';
      _lat = prefs.getString('userLatitude');
      _lng = prefs.getString('userLongitude');
      _currentAvatarUrl = prefs.getString('userAvatar');
      _userId = prefs.getInt('userId');
    });
  }

  Future<void> _pickAvatar() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 600,
    );
    if (picked != null) {
      setState(() {
        _avatarFile = File(picked.path);
      });
    }
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(builder: (_) => const LocationPickerPage()),
    );
    if (result != null) {
      setState(() {
        _lat = result.latitude.toStringAsFixed(5);
        _lng = result.longitude.toStringAsFixed(5);
        _locationError = null;
      });
    }
  }

  bool _isValidEmail(String v) =>
      RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[a-zA-Z]{2,}$').hasMatch(v);
  bool _isValidPhone(String v) =>
      RegExp(r'^\d{9,15}$').hasMatch(v.replaceAll(RegExp(r'\D'), ''));

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

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User ID not found')),
      );
      return;
    }

    setState(() {
      _loading = true;
      _locationError = null;
    });

    try {
      final token = await TokenStorage.read();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final normalizedPhone = _formatPhoneForBackend(_phoneCtrl.text.trim());
      final uri = Uri.parse('$apiBase/users/$_userId');
      
      final req = http.MultipartRequest('PUT', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..fields['name'] = _nameCtrl.text.trim()
        ..fields['phone'] = normalizedPhone
        ..fields['address'] = _addressCtrl.text.trim();

      // Add email if provided
      if (_emailCtrl.text.trim().isNotEmpty) {
        req.fields['email'] = _emailCtrl.text.trim();
      }

      // Add latitude and longitude if location is selected
      if (_lat != null && _lng != null) {
        req.fields['latitude'] = _lat!;
        req.fields['longitude'] = _lng!;
      }

      // Add avatar if a new one was picked
      if (_avatarFile != null) {
        final ext = _avatarFile!.path.split('.').last.toLowerCase();
        req.files.add(await http.MultipartFile.fromPath(
          'avatar',
          _avatarFile!.path,
          contentType: MediaType('image', ext),
        ));
      }

      print('📤 [EDIT PROFILE] Sending PUT request to: $uri');
      print('📤 [EDIT PROFILE] Fields: ${req.fields}');
      print('📤 [EDIT PROFILE] Has avatar: ${_avatarFile != null}');

      final streamed = await req.send();
      final bodyText = await streamed.stream.bytesToString();

      print('📥 [EDIT PROFILE] Response status: ${streamed.statusCode}');
      print('📥 [EDIT PROFILE] Response body: $bodyText');

      if (streamed.statusCode == 200) {
        // Parse response and update SharedPreferences
        final data = jsonDecode(bodyText) as Map<String, dynamic>;
        final user = data['user'] as Map<String, dynamic>? ?? data;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userName', user['name']?.toString() ?? _nameCtrl.text.trim());
        await prefs.setString('userEmail', user['email']?.toString() ?? _emailCtrl.text.trim());
        await prefs.setString('userPhone', user['phone']?.toString() ?? normalizedPhone);
        await prefs.setString('userAddress', user['address']?.toString() ?? _addressCtrl.text.trim());
        if (user['avatar'] != null) {
          await prefs.setString('userAvatar', user['avatar'].toString());
        }
        if (_lat != null) {
          await prefs.setString('userLatitude', _lat!);
        }
        if (_lng != null) {
          await prefs.setString('userLongitude', _lng!);
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).signUpSuccess)),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      } else {
        String message = 'Failed to update profile';
        if (bodyText.isNotEmpty) {
          try {
            final j = jsonDecode(bodyText);
            if (j is Map && j['error'] != null) {
              message = j['error'].toString();
            } else if (j is Map && j['message'] != null) {
              message = j['message'].toString();
            } else {
              message = bodyText;
            }
          } catch (_) {
            message = bodyText;
          }
        }
        print('❌ [EDIT PROFILE] Error message: $message');
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      print('💥 [EDIT PROFILE] Exception: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).networkErrorTryAgain)),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
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
    final host = apiBase.replaceAll('/api', '');
    final currentAvatarUrl = _currentAvatarUrl;
    final currentAvatarMediaUrl = currentAvatarUrl != null && currentAvatarUrl.isNotEmpty
        ? (currentAvatarUrl.startsWith('/')
            ? '$host${currentAvatarUrl}'
            : '$host/$currentAvatarUrl')
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: const Color(0xffFEFAE0),
        iconTheme: const IconThemeData(color: primaryColor),
        titleTextStyle: const TextStyle(
          color: primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(color: Color(0xffD3E4C4)),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Card(
              color: const Color(0xffFEFAE0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Avatar picker
                      GestureDetector(
                        onTap: _pickAvatar,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: _avatarFile != null
                              ? FileImage(_avatarFile!)
                              : (currentAvatarMediaUrl != null
                                  ? NetworkImage(currentAvatarMediaUrl)
                                  : null),
                          child: _avatarFile == null && currentAvatarMediaUrl == null
                              ? const Icon(
                                  Icons.camera_alt,
                                  size: 40,
                                  color: primaryColor,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 20),

                      _buildField(
                        ctrl: _nameCtrl,
                        label: S.of(context).signUpFullName,
                        type: TextInputType.name,
                        prefixIcon: const Icon(Icons.person, color: primaryColor),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? S.of(context).signUpEnterYourName
                            : null,
                      ),
                      const SizedBox(height: 12),

                      _buildField(
                        ctrl: _emailCtrl,
                        label: S.of(context).signUpEmailLabel,
                        type: TextInputType.emailAddress,
                        prefixIcon: const Icon(Icons.email, color: primaryColor),
                        validator: (v) {
                          if (v != null && v.trim().isNotEmpty) {
                            return _isValidEmail(v.trim())
                                ? null
                                : S.of(context).signUpInvalidEmail;
                          }
                          return null; // Email is optional
                        },
                      ),
                      const SizedBox(height: 12),

                      _buildField(
                        ctrl: _phoneCtrl,
                        label: S.of(context).signUpPhoneLabel,
                        type: TextInputType.phone,
                        prefixIcon: const Icon(Icons.phone, color: primaryColor),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return S.of(context).signUpEnterPhone;
                          }
                          return _isValidPhone(v.trim())
                              ? null
                              : S.of(context).signUpInvalidPhone;
                        },
                      ),
                      const SizedBox(height: 12),

                      _buildField(
                        ctrl: _addressCtrl,
                        label: S.of(context).signUpAddressLabel,
                        type: TextInputType.streetAddress,
                        prefixIcon: const Icon(Icons.home, color: primaryColor),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? S.of(context).signUpEnterAddress
                            : null,
                      ),
                      const SizedBox(height: 12),

                      // Location picker
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.map, color: primaryColor),
                            onPressed: _pickLocation,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _lat != null && _lng != null
                                  ? S.of(context).signUpLocationPicked(_lat!, _lng!)
                                  : S.of(context).signUpNoLocationSelected,
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_locationError != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 48.0, top: 4),
                          child: Text(
                            _locationError!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ),

                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _loading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : Text(
                                  S.of(context).save,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

