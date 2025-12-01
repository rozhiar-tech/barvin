// lib/screens/signup.dart

import 'dart:convert';
import 'dart:io';
import 'package:barvin/generated/l10n.dart';
import 'package:flutter/material.dart';
// import 'package:flutter/services.dart' show rootBundle;
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'LocationPickerPage.dart';
import 'package:barvin/screens/home.dart' show apiBase;
import 'signup_otp.dart';
import 'package:barvin/constants/app_constants.dart';

const Color primaryColor = AppColors.primary;

// 👇 update path & ensure it's in pubspec.yaml: assets:
//   - assets/appicon.png
const String DEFAULT_AVATAR_ASSET = 'assets/appicon.png';

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
  String? _lat, _lng;
  bool _loading = false;
  String? _locationError;
  bool _usePhoneOtp = true;

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

  /// Step 1: start signup → request OTP to email
  Future<void> _startSignup() async {
    if (!_formKey.currentState!.validate()) return;

    // Still require location (as in your previous logic)
    if (_lat == null || _lng == null) {
      setState(() => _locationError = S.of(context).signUpSelectLocationError);
      return;
    }
    setState(() {
      _locationError = null;
      _loading = true;
    });

    try {
      final selectedChannel = _usePhoneOtp ? 'phone' : 'email';
      final normalizedPhone = _formatPhoneForBackend(_phoneCtrl.text.trim());
      final uri = Uri.parse('$apiBase/auth/register-start');
      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailCtrl.text.trim(),
          'channel': selectedChannel,
          if (selectedChannel == 'phone') 'phone': normalizedPhone,
        }),
      );

      if (resp.statusCode == 200) {
        Map<String, dynamic> payloadJson = {};
        try {
          payloadJson = jsonDecode(resp.body) as Map<String, dynamic>;
        } catch (_) {}

        final serverChannel =
            (payloadJson['channel'] as String?) ?? selectedChannel;
        final resendIn = (payloadJson['resend_in'] is num)
            ? (payloadJson['resend_in'] as num).toInt()
            : 0;

        // Go to OTP screen with all data needed for /register-complete
        final payload = SignupPayload(
          name: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          phone: _phoneCtrl.text.trim(),
          address: _addressCtrl.text.trim(),
          lat: _lat!,
          lng: _lng!,
          avatarFile: _avatarFile,
          defaultAvatarAsset: DEFAULT_AVATAR_ASSET,
          otpChannel: serverChannel,
          otpDestination: serverChannel == 'phone'
              ? normalizedPhone
              : _emailCtrl.text.trim(),
          initialResendIn: resendIn,
        );
        final ok = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => SignupOtpPage(payload: payload),
          ),
        );
        if (ok == true) {
          // success
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(S.of(context).signUpSuccess)),
            );
            Navigator.of(context).pop(true);
          }
        }
      } else {
        String msg = 'Unexpected error';
        if (resp.body.isNotEmpty) {
          try {
            final data = jsonDecode(resp.body);
            if (data is Map && data['error'] != null) {
              msg = data['error'].toString();
            } else {
              msg = resp.body;
            }
          } catch (_) {
            msg = resp.body;
          }
        }
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
        print(msg);
      }
    } catch (_) {
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
    return Scaffold(
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      S.of(context).signUpTitle,
                      style: const TextStyle(
                        color: primaryColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Avatar picker (optional)
                    GestureDetector(
                      onTap: _pickAvatar,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: _avatarFile != null
                            ? FileImage(_avatarFile!)
                            : null,
                        child: _avatarFile == null
                            ? const Icon(
                                Icons.camera_alt,
                                size: 40,
                                color: primaryColor,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 20),

                    Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        children: [
                          _buildField(
                            ctrl: _nameCtrl,
                            label: S.of(context).signUpFullName,
                            type: TextInputType.name,
                            prefixIcon:
                                const Icon(Icons.person, color: primaryColor),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? S.of(context).signUpEnterYourName
                                : null,
                          ),
                          const SizedBox(height: 12),

                          _buildField(
                            ctrl: _emailCtrl,
                            label: S.of(context).signUpEmailLabel,
                            type: TextInputType.emailAddress,
                            prefixIcon:
                                const Icon(Icons.email, color: primaryColor),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return S.of(context).signUpEnterEmail;
                              }
                              return _isValidEmail(v.trim())
                                  ? null
                                  : S.of(context).signUpInvalidEmail;
                            },
                          ),
                          const SizedBox(height: 12),

                          _buildField(
                            ctrl: _passwordCtrl,
                            label: S.of(context).signUpPasswordLabel,
                            type: TextInputType.visiblePassword,
                            obscure: true,
                            prefixIcon:
                                const Icon(Icons.lock, color: primaryColor),
                            validator: (v) {
                              if (v == null || v.length < 8) {
                                return S.of(context).signUpPasswordMin8;
                              }
                              if (!RegExp(r'^[A-Za-z0-9.]+$').hasMatch(v)) {
                                return S.of(context).signUpPasswordAllowedChars;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          _buildField(
                            ctrl: _phoneCtrl,
                            label: S.of(context).signUpPhoneLabel,
                            type: TextInputType.phone,
                            prefixIcon:
                                const Icon(Icons.phone, color: primaryColor),
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

                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              S.of(context).verificationMethodLabel,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 12,
                            children: [
                              ChoiceChip(
                                label:
                                    Text(S.of(context).verificationPhoneOption),
                                selected: _usePhoneOtp,
                                onSelected: (sel) {
                                  if (!sel) return;
                                  setState(() => _usePhoneOtp = true);
                                },
                              ),
                              ChoiceChip(
                                label:
                                    Text(S.of(context).verificationEmailOption),
                                selected: !_usePhoneOtp,
                                onSelected: (sel) {
                                  if (!sel) return;
                                  setState(() => _usePhoneOtp = false);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          _buildField(
                            ctrl: _addressCtrl,
                            label: S.of(context).signUpAddressLabel,
                            type: TextInputType.streetAddress,
                            prefixIcon:
                                const Icon(Icons.home, color: primaryColor),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? S.of(context).signUpEnterAddress
                                : null,
                          ),
                          const SizedBox(height: 12),

                          // Location picker (required)
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
                                      ? S
                                          .of(context)
                                          .signUpLocationPicked(_lat!, _lng!)
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
                              padding:
                                  const EdgeInsets.only(left: 48.0, top: 4),
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
                              onPressed: _loading ? null : _startSignup,
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
                                      // This now says "Continue" logically,
                                      // but you can keep your localized label.
                                      S.of(context).signUpButton,
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

/// Data we pass to the OTP screen to complete registration
class SignupPayload {
  final String name;
  final String email;
  final String password;
  final String phone;
  final String address;
  final String lat;
  final String lng;
  final File? avatarFile;
  final String defaultAvatarAsset;
  final String otpChannel;
  final String otpDestination;
  final int initialResendIn;

  SignupPayload({
    required this.name,
    required this.email,
    required this.password,
    required this.phone,
    required this.address,
    required this.lat,
    required this.lng,
    required this.avatarFile,
    required this.defaultAvatarAsset,
    required this.otpChannel,
    required this.otpDestination,
    required this.initialResendIn,
  });
}
