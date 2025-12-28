// lib/screens/signup_otp.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:barvin/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:barvin/screens/home.dart' show apiBase, primaryColor;
import 'signup.dart' show SignupPayload;

class SignupOtpPage extends StatefulWidget {
  final SignupPayload payload;
  const SignupOtpPage({Key? key, required this.payload}) : super(key: key);

  @override
  State<SignupOtpPage> createState() => _SignupOtpPageState();
}

class _SignupOtpPageState extends State<SignupOtpPage> {
  final _otpCtrl = TextEditingController();
  bool _submitting = false;
  bool _resending = false;

  // Simple resend cooldown UI
  static const int _cooldownSeconds = 60;
  int _remaining = _cooldownSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final initial = widget.payload.initialResendIn;
    final start = initial > 0 ? initial : _cooldownSeconds;
    _startCooldown(start);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpCtrl.dispose();
    super.dispose();
  }

  void _startCooldown([int seconds = _cooldownSeconds]) {
    _timer?.cancel();
    _remaining = seconds;
    if (_remaining <= 0) {
      setState(() {
        _remaining = 0;
      });
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        _remaining--;
        if (_remaining <= 0) {
          _remaining = 0;
          t.cancel();
        }
      });
    });
  }

  Future<void> _resend() async {
    if (_remaining > 0) return;
    setState(() => _resending = true);
    try {
      print('🔄 [OTP RESEND] Resending OTP');
      print('🔄 Phone: ${widget.payload.phone}');

      final uri = Uri.parse('$apiBase/auth/register-start');
      final body = {
        'phone': widget.payload.phone,
      };
      print('🔄 Request body: ${jsonEncode(body)}');

      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      print('🔄 [OTP RESEND] Response status: ${resp.statusCode}');
      print('🔄 [OTP RESEND] Response body: ${resp.body}');

      if (resp.statusCode == 200) {
        print('✅ [OTP RESEND] OTP resent successfully');
        Map<String, dynamic> responseBody = {};
        try {
          responseBody = jsonDecode(resp.body) as Map<String, dynamic>;
        } catch (_) {}
        final resendIn = (responseBody['resend_in'] is num)
            ? (responseBody['resend_in'] as num).toInt()
            : 60;
        print('🔄 [OTP RESEND] Resend cooldown: ${resendIn}s');
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(S.of(context).otpResent)));
        _startCooldown(resendIn > 0 ? resendIn : _cooldownSeconds);
      } else {
        print('❌ [OTP RESEND] Failed with status ${resp.statusCode}');
        String msg = 'Failed';
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).networkErrorTryAgain)),
      );
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _completeSignup() async {
    final code = _otpCtrl.text.trim();
    if (code.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the code we emailed you')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      print('✅ [COMPLETE SIGNUP] Starting registration completion');
      print('✅ Name: ${widget.payload.name}');
      print('✅ Email: ${widget.payload.email}');
      print('✅ Phone: ${widget.payload.phone}');
      print('✅ Address: ${widget.payload.address}');
      print('✅ Location: ${widget.payload.lat}, ${widget.payload.lng}');
      print('✅ OTP Channel: ${widget.payload.otpChannel}');
      print('✅ OTP Code length: ${code.length}');

      // register-complete is multipart to optionally include avatar
      final uri = Uri.parse('$apiBase/auth/register-complete');
      final req = http.MultipartRequest('POST', uri)
        ..fields['otp_code'] = code
        ..fields['name'] = widget.payload.name
        ..fields['password'] = widget.payload.password
        ..fields['phone'] = widget.payload.phone
        ..fields['address'] = widget.payload.address
        ..fields['latitude'] = widget.payload.lat
        ..fields['longitude'] = widget.payload.lng
        ..fields['otp_channel'] = widget.payload.otpChannel;
      
      // Email is optional - only send if provided
      if (widget.payload.email.trim().isNotEmpty) {
        req.fields['email'] = widget.payload.email.trim();
      }

      // avatar: file if chosen, else default asset
      final File? file = widget.payload.avatarFile;
      if (file != null) {
        final ext = file.path.split('.').last.toLowerCase();
        req.files.add(await http.MultipartFile.fromPath(
          'avatar',
          file.path,
          contentType: MediaType('image', ext),
        ));
      } else {
        try {
          final data = await rootBundle.load(widget.payload.defaultAvatarAsset);
          req.files.add(http.MultipartFile.fromBytes(
            'avatar',
            data.buffer.asUint8List(),
            filename: 'default_avatar.png',
            contentType: MediaType('image', 'png'),
          ));
        } catch (_) {
          // If asset missing, server may set its own default avatar
        }
      }

      final streamed = await req.send();
      final bodyText = await streamed.stream.bytesToString();

      print('📥 [COMPLETE SIGNUP] Response status: ${streamed.statusCode}');
      print('📥 [COMPLETE SIGNUP] Response body: $bodyText');

      if (streamed.statusCode == 200) {
        print('✅ [COMPLETE SIGNUP] Registration successful!');
        // body: { token, user: {...} }
        // If you store token, parse it here:
        // final json = jsonDecode(bodyText);
        if (!mounted) return;
        Navigator.of(context).pop(true);
      } else {
        print(
            '❌ [COMPLETE SIGNUP] Registration failed with status ${streamed.statusCode}');
        String message = 'Failed';
        if (bodyText.isNotEmpty) {
          try {
            final j = jsonDecode(bodyText);
            if (j is Map && j['error'] != null) {
              message = j['error'].toString();
            } else {
              message = bodyText;
            }
          } catch (_) {
            message = bodyText;
          }
        }
        print('❌ [COMPLETE SIGNUP] Error message: $message');
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).networkErrorTryAgain)),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canResend = _remaining == 0 && !_resending;

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).verificationPhoneOption),
        backgroundColor: primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              S.of(context).otpSentTo(widget.payload.otpDestination),
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _otpCtrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Verification code',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton(
                  onPressed: canResend ? _resend : null,
                  child: _resending
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          canResend ? 'Resend code' : 'Resend in $_remaining s',
                        ),
                ),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _submitting ? null : _completeSignup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _submitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Create Account',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
