// lib/screens/forgot_password.dart
import 'dart:async';
import 'dart:convert';
import 'package:barvin/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:barvin/screens/home.dart' show apiUrl;

const Color primaryColor = Color(0xFF567765);

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _loading = false;
  bool _usePhone = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  bool _isValidEmail(String v) =>
      RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[a-zA-Z]{2,}$').hasMatch(v);
  bool _isValidPhone(String v) => RegExp(r'^\d{9,15}$').hasMatch(v.replaceAll(RegExp(r'\D'), ''));

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

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final identifier = _usePhone
          ? _formatPhoneForBackend(_phoneCtrl.text.trim())
          : _emailCtrl.text.trim();
      final body = <String, String>{
        if (_usePhone) 'phone': identifier else 'email': identifier,
      };
      final res = await http.post(
        apiUrl('/auth/request-reset-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      Map<String, dynamic> data = {};
      try {
        data = jsonDecode(res.body) as Map<String, dynamic>;
      } catch (_) {}

      // Backend always replies vague on success; optionally includes resend_in
      if (res.statusCode == 200) {
        final resendIn =
            (data['resend_in'] is int) ? data['resend_in'] as int : 0;

        if (!mounted) return;
        final channel = _usePhone ? 'phone' : 'email';
        final successMsg = _usePhone
            ? S.of(context).otpSentTo(identifier)
            : S.of(context).forgotSentCheckEmail;

        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(successMsg)));

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ResetPasswordOtpPage(
              identifier: identifier,
              channel: channel,
              initialResendIn: resendIn,
            ),
          ),
        );
      } else {
        final msg = (data['error'] as String?) ??
            S.of(context).genericError; // “Something went wrong”
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(S.of(context).networkError)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
                  borderRadius: BorderRadius.circular(24)),
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        S.of(context).forgotTitle, // "Reset your password"
                        style: const TextStyle(
                          color: primaryColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        S.of(context).forgotChooseMethod,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        children: [
                          ChoiceChip(
                            label: Text(S.of(context).verificationPhoneOption),
                            selected: _usePhone,
                            onSelected: (sel) {
                              if (!sel) return;
                              setState(() => _usePhone = true);
                            },
                          ),
                          ChoiceChip(
                            label: Text(S.of(context).verificationEmailOption),
                            selected: !_usePhone,
                            onSelected: (sel) {
                              if (!sel) return;
                              setState(() => _usePhone = false);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_usePhone)
                        TextFormField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: S.of(context).signUpPhoneLabel,
                            prefixIcon:
                                const Icon(Icons.phone, color: primaryColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (v) => (v != null && _isValidPhone(v.trim()))
                              ? null
                              : S.of(context).signUpInvalidPhone,
                        )
                      else
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText:
                                S.of(context).forgotEmailLabel, // "Email"
                            prefixIcon:
                                const Icon(Icons.email, color: primaryColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (v) => (v != null && _isValidEmail(v.trim()))
                              ? null
                              : S.of(context).loginInvalidIdentifier,
                        ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _sendCode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _loading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : Text(
                                  S.of(context).forgotSendCode, // "Send code"
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 16),
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(S.of(context).backToLogin),
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

class ResetPasswordOtpPage extends StatefulWidget {
  final String identifier;
  final String channel;
  final int initialResendIn;
  const ResetPasswordOtpPage({
    Key? key,
    required this.identifier,
    required this.channel,
    this.initialResendIn = 0,
  }) : super(key: key);

  @override
  State<ResetPasswordOtpPage> createState() => _ResetPasswordOtpPageState();
}

class _ResetPasswordOtpPageState extends State<ResetPasswordOtpPage> {
  final _formKey = GlobalKey<FormState>();
  final _otpCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _loading = false;
  int _resendIn = 0;
  Timer? _timer;
  bool get _isPhone => widget.channel == 'phone';

  @override
  void initState() {
    super.initState();
    _resendIn = widget.initialResendIn;
    if (_resendIn > 0) _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    if (_resendIn <= 0) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        _resendIn = (_resendIn - 1).clamp(0, 1 << 30);
        if (_resendIn == 0) {
          t.cancel();
        }
      });
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passCtrl.text != _confirmCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).otpPasswordMismatch)),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final body = {
        'otp': _otpCtrl.text.trim(),
        'new_password': _passCtrl.text,
        if (_isPhone) 'phone': widget.identifier else 'email': widget.identifier,
      };
      final res = await http.post(
        apiUrl('/auth/reset-with-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (res.statusCode == 204) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).passwordUpdatedSuccess)),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        String msg = S.of(context).otpInvalidCode;
        try {
          final data = jsonDecode(res.body);
          if (data is Map && data['error'] is String) {
            msg = data['error'] as String;
          }
        } catch (_) {}
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(S.of(context).networkError)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _loading = true);
    try {
      final body = {
        if (_isPhone) 'phone': widget.identifier else 'email': widget.identifier,
      };
      final res = await http.post(
        apiUrl('/auth/request-reset-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      int cooldown = 60;
      String successMsg = _isPhone
          ? S.of(context).otpSentTo(widget.identifier)
          : S.of(context).forgotSentCheckEmail;
      try {
        final data = jsonDecode(res.body);
        if (data is Map && data['resend_in'] is int) {
          cooldown = data['resend_in'] as int;
        }
        if (data is Map && data['message'] is String) {
          successMsg = data['message'] as String;
        }
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _resendIn = cooldown;
        _startTimer();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMsg)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(S.of(context).networkError)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _validateOtp(String? v) {
    final t = (v ?? '').trim();
    if (t.length != 6 || !RegExp(r'^\d{6}$').hasMatch(t)) {
      return S.of(context).otpInvalidFormat; // "Enter the 6-digit code"
    }
    return null;
  }

  String? _validatePassword(String? v) {
    final t = v ?? '';
    if (t.length < 8) return S.of(context).signUpPasswordMin8;
    if (!RegExp(r'^[A-Za-z0-9.]+$').hasMatch(t)) {
      return S.of(context).signUpPasswordAllowedChars;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final canResend = _resendIn == 0 && !_loading;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(color: Color(0xffD3E4C4)),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Card(
              color: const Color(0xffFEFAE0),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isPhone
                            ? S.of(context).otpTitlePhone
                            : S.of(context).otpTitle,
                        style: const TextStyle(
                          color: primaryColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        S.of(context).otpSentTo(widget.identifier),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),

                      // OTP
                      TextFormField(
                        controller: _otpCtrl,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: InputDecoration(
                          labelText:
                              S.of(context).otpCodeLabel, // "6-digit code"
                          prefixIcon:
                              const Icon(Icons.pin, color: primaryColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          counterText: '',
                        ),
                        validator: _validateOtp,
                      ),
                      const SizedBox(height: 12),

                      // New password
                      TextFormField(
                        controller: _passCtrl,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: S
                              .of(context)
                              .otpNewPasswordLabel, // "New password"
                          prefixIcon:
                              const Icon(Icons.lock, color: primaryColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: _validatePassword,
                      ),
                      const SizedBox(height: 12),

                      // Confirm password
                      TextFormField(
                        controller: _confirmCtrl,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: S
                              .of(context)
                              .otpConfirmPasswordLabel, // "Confirm password"
                          prefixIcon: const Icon(Icons.lock_outline,
                              color: primaryColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: _validatePassword,
                      ),
                      const SizedBox(height: 16),

                      // Resend
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _resendIn > 0
                                ? S
                                    .of(context)
                                    .otpResendIn(_resendIn) // "Resend in 34s"
                                : S
                                    .of(context)
                                    .otpYouCanResend, // "You can resend a new code"
                            style: const TextStyle(color: Colors.black54),
                          ),
                          TextButton(
                            onPressed: canResend ? _resend : null,
                            child: Text(S.of(context).otpResend),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _loading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : Text(
                                  S.of(context).otpSubmit, // "Reset password"
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 16),
                                ),
                        ),
                      ),

                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(S.of(context).backToLogin),
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
