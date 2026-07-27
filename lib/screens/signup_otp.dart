// lib/screens/signup_otp.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:barvin/generated/l10n.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show KeyDownEvent, LogicalKeyboardKey, rootBundle;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:barvin/screens/home.dart' show apiBase, primaryColor;
import 'package:barvin/services/api_client.dart';
import 'package:barvin/services/token_storage.dart';
import 'signup.dart' show SignupPayload;

class SignupOtpPage extends StatefulWidget {
  final SignupPayload payload;
  const SignupOtpPage({Key? key, required this.payload}) : super(key: key);

  @override
  State<SignupOtpPage> createState() => _SignupOtpPageState();
}

class _SignupOtpPageState extends State<SignupOtpPage> {
  static const int _digitCount = 6;
  final List<TextEditingController> _digitControllers =
      List.generate(_digitCount, (_) => TextEditingController());
  final List<FocusNode> _digitFocusNodes =
      List.generate(_digitCount, (_) => FocusNode());

  bool _submitting = false;
  bool _resending = false;

  // Simple resend cooldown UI
  static const int _cooldownSeconds = 60;
  int _remaining = _cooldownSeconds;
  Timer? _timer;

  String get _code => _digitControllers.map((c) => c.text).join();

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
    for (final c in _digitControllers) {
      c.dispose();
    }
    for (final f in _digitFocusNodes) {
      f.dispose();
    }
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

  /// Handles both normal single-digit typing and pasting a full code into
  /// one box (common on iOS when tapping the SMS autofill suggestion or a
  /// manual paste).
  void _handleDigitChange(int index, String value) {
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (var i = 0; i < _digitControllers.length; i++) {
        _digitControllers[i].text = i < digits.length ? digits[i] : '';
      }
      setState(() {});
      if (digits.length >= _digitCount) {
        _digitFocusNodes[_digitCount - 1].unfocus();
        _maybeAutoSubmit();
      } else {
        _digitFocusNodes[digits.length].requestFocus();
      }
      return;
    }

    setState(() {});
    if (value.isEmpty) return;
    if (index < _digitCount - 1) {
      _digitFocusNodes[index + 1].requestFocus();
    } else {
      _digitFocusNodes[index].unfocus();
      _maybeAutoSubmit();
    }
  }

  void _maybeAutoSubmit() {
    if (_code.length == _digitCount && !_submitting) {
      _completeSignup();
    }
  }

  void _clearDigits() {
    for (final c in _digitControllers) {
      c.clear();
    }
    setState(() {});
    _digitFocusNodes.first.requestFocus();
  }

  Future<void> _resend() async {
    if (_remaining > 0) return;
    setState(() => _resending = true);
    try {
      // Routed through ApiClient — real timeout, and a real connectivity
      // failure is now reported differently than a backend error response.
      final resp = await ApiClient.instance.post(
        '/auth/register-start',
        body: jsonEncode({'phone': widget.payload.phone}),
        requiresAuth: false,
      );

      Map<String, dynamic> responseBody = {};
      try {
        responseBody = jsonDecode(resp.body) as Map<String, dynamic>;
      } catch (_) {}
      final resendIn = (responseBody['resend_in'] is num)
          ? (responseBody['resend_in'] as num).toInt()
          : 60;
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(S.of(context).otpResent)));
      _startCooldown(resendIn > 0 ? resendIn : _cooldownSeconds);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? S.of(context).networkErrorTryAgain)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).networkErrorTryAgain)),
      );
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  /// Persists the freshly-issued session exactly like the login flow does,
  /// so a brand-new account lands the user straight in the app instead of
  /// bouncing them back to the login screen.
  Future<void> _persistSession(Map<String, dynamic> data) async {
    final token = data['token'];
    if (token is! String || token.isEmpty) return;
    final user = (data['user'] as Map<String, dynamic>?) ?? {};

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('loggedIn', true);
    await TokenStorage.save(token);
    await prefs.setInt('userId', (user['id'] ?? 0) as int);
    await prefs.setString('userName', (user['name'] ?? '').toString());
    await prefs.setString('userAddress', (user['address'] ?? '').toString());
    await prefs.setString('userPhone', (user['phone'] ?? '').toString());
    if (user['avatar'] != null) {
      await prefs.setString('userAvatar', user['avatar'].toString());
    }
    if (user['latitude'] != null) {
      await prefs.setString('latitude', user['latitude'].toString());
      await prefs.setString('userLatitude', user['latitude'].toString());
    }
    if (user['longitude'] != null) {
      await prefs.setString('longitude', user['longitude'].toString());
      await prefs.setString('userLongitude', user['longitude'].toString());
    }
    await prefs.setBool('delivery', (user['delivery'] ?? false) == true);
    await prefs.setBool('debt', (user['debt'] ?? false) == true);
  }

  Future<void> _completeSignup() async {
    final code = _code;
    if (code.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).otpInvalidFormat)),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
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

      final streamed =
          await req.send().timeout(const Duration(seconds: 30));
      final bodyText = await streamed.stream.bytesToString();

      if (streamed.statusCode == 200) {
        Map<String, dynamic> data = {};
        try {
          data = jsonDecode(bodyText) as Map<String, dynamic>;
        } catch (_) {}
        await _persistSession(data);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).signUpSuccess)),
        );
        // Reset the whole nav stack (login → signup → OTP) into the app,
        // since the user is now fully signed in.
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/main', (route) => false);
      } else {
        String message = 'Failed';
        if (bodyText.isNotEmpty) {
          try {
            final j = jsonDecode(bodyText);
            if (j is Map && j['error'] != null) {
              message = j['error'].toString();
              final remaining = j['attempts_remaining'];
              if (remaining is num) {
                final n = remaining.toInt();
                message += n == 1
                    ? ' (1 attempt left)'
                    : ' ($n attempts left)';
              }
            } else {
              message = bodyText;
            }
          } catch (_) {
            message = bodyText;
          }
        }
        if (kDebugMode) print('[SIGNUP OTP] failed: ${streamed.statusCode}');
        // Wrong/expired code — clear the boxes so the user isn't stuck
        // editing digits that already failed, without losing their place
        // in the flow.
        _clearDigits();
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } on TimeoutException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request timed out. Please try again.')),
      );
    } on SocketException catch (e) {
      if (kDebugMode) print('[SIGNUP OTP] socket error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).networkErrorTryAgain)),
      );
    } catch (e) {
      // Anything else (e.g. a bad response we couldn't parse) — logged so
      // it's diagnosable instead of silently becoming "network error".
      if (kDebugMode) print('[SIGNUP OTP] unexpected error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).networkErrorTryAgain)),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _buildDigitBox(int index) {
    final filled = _digitControllers[index].text.isNotEmpty;
    return KeyboardListener(
      focusNode: _digitFocusNodes[index],
      onKeyEvent: (event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.backspace &&
            _digitControllers[index].text.isEmpty &&
            index > 0) {
          _digitFocusNodes[index - 1].requestFocus();
          _digitControllers[index - 1].clear();
          setState(() {});
        }
      },
      child: SizedBox(
        width: 46,
        height: 56,
        child: TextField(
          controller: _digitControllers[index],
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          autofocus: index == 0,
          maxLength: _digitCount, // allows pasting a full code into any box
          enableInteractiveSelection: false,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: primaryColor,
          ),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: filled
                ? primaryColor.withValues(alpha: 0.08)
                : Colors.white,
            contentPadding: EdgeInsets.zero,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: primaryColor.withValues(alpha: 0.28),
                width: 1.4,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primaryColor, width: 2),
            ),
          ),
          onChanged: (v) => _handleDigitChange(index, v),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final canResend = _remaining == 0 && !_resending;

    return Scaffold(
      backgroundColor: const Color(0xffD3E4C4),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: primaryColor),
        title: Text(
          s.verificationPhoneOption,
          style: const TextStyle(color: primaryColor, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Card(
              color: const Color(0xffFEFAE0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.sms_outlined,
                        color: primaryColor,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      s.otpSentTo(widget.payload.otpDestination),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children:
                          List.generate(_digitCount, _buildDigitBox),
                    ),
                    const SizedBox(height: 18),
                    TextButton(
                      onPressed: canResend ? _resend : null,
                      child: _resending
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              canResend
                                  ? s.otpResend
                                  : s.otpResendIn(_remaining),
                              style: TextStyle(
                                color: canResend ? primaryColor : Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                    const SizedBox(height: 10),
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
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.4,
                                ),
                              )
                            : Text(
                                s.otpCreateAccountButton,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
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
    );
  }
}
