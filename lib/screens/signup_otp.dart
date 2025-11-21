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

  bool get _isPhoneChannel => widget.payload.otpChannel == 'phone';

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
      final uri = Uri.parse('$apiBase/auth/register-start');
      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.payload.email,
          'channel': widget.payload.otpChannel,
          if (_isPhoneChannel) 'phone': widget.payload.phone,
        }),
      );
      if (resp.statusCode == 200) {
        Map<String, dynamic> body = {};
        try {
          body = jsonDecode(resp.body) as Map<String, dynamic>;
        } catch (_) {}
        final resendIn =
            (body['resend_in'] is num) ? (body['resend_in'] as num).toInt() : 0;
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(S.of(context).otpResent)));
        _startCooldown(resendIn > 0 ? resendIn : _cooldownSeconds);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${resp.statusCode}')),
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
      // register-complete is multipart to optionally include avatar
      final uri = Uri.parse('$apiBase/auth/register-complete');
      final req = http.MultipartRequest('POST', uri)
        ..fields['email'] = widget.payload.email
        ..fields['otp_code'] = code
        ..fields['name'] = widget.payload.name
        ..fields['password'] = widget.payload.password
        ..fields['phone'] = widget.payload.phone
        ..fields['address'] = widget.payload.address
        ..fields['latitude'] = widget.payload.lat
        ..fields['longitude'] = widget.payload.lng
        ..fields['otp_channel'] = widget.payload.otpChannel;

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

      if (streamed.statusCode == 201) {
        // body: { token, user: {...} }
        // If you store token, parse it here:
        // final json = jsonDecode(bodyText);
        if (!mounted) return;
        Navigator.of(context).pop(true);
      } else {
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
        title: Text(_isPhoneChannel
            ? S.of(context).verificationPhoneOption
            : S.of(context).verificationEmailOption),
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
