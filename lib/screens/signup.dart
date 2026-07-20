// lib/screens/signup.dart

import 'dart:convert';
import 'dart:io';
import 'package:barvin/generated/l10n.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'LocationPickerPage.dart';
import 'signup_otp.dart';
import 'package:barvin/constants/app_constants.dart';
import 'package:barvin/services/api_client.dart';

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
  final _accountFormKey = GlobalKey<FormState>();
  final _detailsFormKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  File? _avatarFile;
  String? _lat, _lng;
  bool _loading = false;

  int _step = 0; // 0 = account essentials, 1 = optional delivery details

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
    // API accepts with or without + prefix, we'll send without + to match docs
    return digits;
  }

  void _goToDetailsStep() {
    if (!_accountFormKey.currentState!.validate()) return;
    setState(() => _step = 1);
  }

  void _goBackToAccountStep() {
    setState(() => _step = 0);
  }

  /// Step 2: start signup → request OTP via phone.
  /// [skipDetails] short-circuits the details-form validation for the
  /// "Skip for now" path — address/location are optional server-side.
  Future<void> _startSignup({bool skipDetails = false}) async {
    if (!skipDetails && !_detailsFormKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
    });

    try {
      final normalizedPhone = _formatPhoneForBackend(_phoneCtrl.text.trim());

      // Routed through ApiClient (like login.dart) instead of a raw
      // http.post — that gives this call a real 30s timeout and lets us
      // tell an actual connectivity failure apart from a backend error
      // response (e.g. rate limiting), instead of bucketing everything
      // into one generic "network error".
      final resp = await ApiClient.instance.post(
        '/auth/register-start',
        body: jsonEncode({'phone': normalizedPhone}),
        requiresAuth: false,
      );

      Map<String, dynamic> payloadJson = {};
      try {
        payloadJson = jsonDecode(resp.body) as Map<String, dynamic>;
      } catch (_) {}

      final resendIn = (payloadJson['resend_in'] is num)
          ? (payloadJson['resend_in'] as num).toInt()
          : 60;
      final expiresIn = (payloadJson['expires_in'] is num)
          ? (payloadJson['expires_in'] as num).toInt()
          : 300;

      final payload = SignupPayload(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(), // Optional email field
        password: _passwordCtrl.text,
        // Store normalized phone so all subsequent OTP calls use the same value
        phone: normalizedPhone,
        address: _addressCtrl.text.trim(),
        lat: _lat ?? '',
        lng: _lng ?? '',
        avatarFile: _avatarFile,
        defaultAvatarAsset: DEFAULT_AVATAR_ASSET,
        otpChannel: 'phone', // Always phone now
        otpDestination: normalizedPhone,
        initialResendIn: resendIn,
      );
      if (kDebugMode) {
        print('[SIGNUP] OTP requested, expires in ${expiresIn}s');
      }

      // signup_otp.dart handles the rest: on success it signs the user in
      // and resets the nav stack straight into the app, so there's nothing
      // to do here once this push returns.
      await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => SignupOtpPage(payload: payload),
        ),
      );
    } on ApiException catch (e) {
      // Backend responded (e.g. rate-limited, invalid phone, already
      // registered) — show its actual message, not a generic one.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? S.of(context).networkErrorTryAgain)),
      );
    } catch (e) {
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
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      validator: validator,
    );
  }

  Widget _stepProgress(S s) {
    final label = _step == 0 ? s.signUpStepAccount : s.signUpStepProfile;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _stepDot(active: true),
            _stepConnector(filled: _step > 0),
            _stepDot(active: _step > 0),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: primaryColor.withValues(alpha: 0.85),
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _stepDot({required bool active}) => AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? primaryColor : primaryColor.withValues(alpha: 0.25),
        ),
      );

  Widget _stepConnector({required bool filled}) => Expanded(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          height: 2,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          color: filled ? primaryColor : primaryColor.withValues(alpha: 0.25),
        ),
      );

  Widget _buildAccountStep(S s) {
    return Form(
      key: _accountFormKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        key: const ValueKey('step-account'),
        children: [
          _buildField(
            ctrl: _nameCtrl,
            label: s.signUpFullName,
            type: TextInputType.name,
            prefixIcon: const Icon(Icons.person, color: primaryColor),
            validator: (v) =>
                v == null || v.trim().isEmpty ? s.signUpEnterYourName : null,
          ),
          const SizedBox(height: 12),
          _buildField(
            ctrl: _phoneCtrl,
            label: s.signUpPhoneLabel,
            type: TextInputType.phone,
            prefixIcon: const Icon(Icons.phone, color: primaryColor),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return s.signUpEnterPhone;
              return _isValidPhone(v.trim()) ? null : s.signUpInvalidPhone;
            },
          ),
          const SizedBox(height: 12),
          _buildField(
            ctrl: _passwordCtrl,
            label: s.signUpPasswordLabel,
            type: TextInputType.visiblePassword,
            obscure: true,
            prefixIcon: const Icon(Icons.lock, color: primaryColor),
            validator: (v) {
              if (v == null || v.length < 8) return s.signUpPasswordMin8;
              if (!RegExp(r'^[A-Za-z0-9.]+$').hasMatch(v)) {
                return s.signUpPasswordAllowedChars;
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _goToDetailsStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                s.signUpContinue,
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsStep(S s) {
    return Form(
      key: _detailsFormKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        key: const ValueKey('step-details'),
        children: [
          GestureDetector(
            onTap: _pickAvatar,
            child: CircleAvatar(
              radius: 44,
              backgroundColor: Colors.grey[200],
              backgroundImage:
                  _avatarFile != null ? FileImage(_avatarFile!) : null,
              child: _avatarFile == null
                  ? const Icon(Icons.camera_alt, size: 34, color: primaryColor)
                  : null,
            ),
          ),
          const SizedBox(height: 20),
          _buildField(
            ctrl: _emailCtrl,
            label: s.signUpEmailLabel,
            type: TextInputType.emailAddress,
            prefixIcon: const Icon(Icons.email, color: primaryColor),
            validator: (v) {
              if (v != null && v.trim().isNotEmpty) {
                return _isValidEmail(v.trim()) ? null : s.signUpInvalidEmail;
              }
              return null; // Email is optional
            },
          ),
          const SizedBox(height: 12),
          _buildField(
            ctrl: _addressCtrl,
            label: s.signUpAddressLabel,
            type: TextInputType.streetAddress,
            prefixIcon: const Icon(Icons.home, color: primaryColor),
          ),
          const SizedBox(height: 12),
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
                      ? s.signUpLocationPicked(_lat!, _lng!)
                      : s.signUpNoLocationSelected,
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            s.signUpSkipHint,
            style: TextStyle(color: Colors.grey[600], fontSize: 12.5),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _loading ? null : _goBackToAccountStep,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(s.signUpBack,
                      style: const TextStyle(color: primaryColor)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _loading ? null : () => _startSignup(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            s.signUpButton,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed:
                _loading ? null : () => _startSignup(skipDetails: true),
            child: Text(
              s.signUpSkipForNow,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      backgroundColor: const Color(0xffD3E4C4),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: primaryColor),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
                    s.signUpTitle,
                    style: const TextStyle(
                      color: primaryColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _stepProgress(s),
                  const SizedBox(height: 22),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.04, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: _step == 0
                        ? _buildAccountStep(s)
                        : _buildDetailsStep(s),
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
