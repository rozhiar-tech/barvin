// lib/screens/profile.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:barvin/generated/l10n.dart';
import '../main.dart'; // for MyApp.setLocale
import 'login.dart';
import 'edit_profile.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:barvin/screens/home.dart' show apiBase;
import 'package:latlong2/latlong.dart';
import 'LocationPickerPage.dart';
import 'package:barvin/constants/app_constants.dart';
import 'package:barvin/constants/contact.dart';
import 'package:barvin/services/api_client.dart';
import 'package:barvin/services/token_storage.dart';

const Color primaryColor = AppColors.primary;

// Optional: socials (replace with real links)
const _instagram =
    'https://www.instagram.com/barvin.co?igsh=MXVhbjU2bnhibnZtbw==';
const _facebook = 'https://www.facebook.com/share/17FATGwNhc/?mibextid=wwXIfr';
const _tiktok = 'https://www.tiktok.com/@barvin.company?_t=ZS-8zD5KtvJpF2&_r=1';

class Profile extends StatefulWidget {
  const Profile({super.key});
  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  // If you keep apiBase in a shared file, import it; otherwise define here.
  final host = apiBase.replaceAll('/api', '');

  String? avatarUrl;
  bool _loggedIn = false;
  String _name = 'Guest';
  String _address = '';
  String _phone = '';
  String _selectedLanguage = 'English';
  String? _userLat;
  String? _userLng;

  String? get rawPath => avatarUrl == null
      ? null
      : (avatarUrl!.startsWith('/') ? avatarUrl!.substring(1) : avatarUrl!);
  String? get mediaUrl => rawPath == null ? null : '$host/$rawPath';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void showCustomAboutDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final l10n = S.of(ctx);
        return AlertDialog(
          title: Row(
            children: [
              // optional app icon
              // FlutterLogo(size: 28),
              // const SizedBox(width: 12),
              Expanded(child: Text(l10n.appName)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('v1.6.1', style: Theme.of(ctx).textTheme.bodySmall),
              const SizedBox(height: 8),
              Text(l10n.slogan),
              // Add any extra content here...
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(MaterialLocalizations.of(ctx).okButtonLabel),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool('loggedIn') ?? false;
    final langCode = prefs.getString('locale') ?? 'en';
    final langLabel = {
          'en': 'English',
          'ku': 'Kurdish',
          'ar': 'Arabic'
        }[langCode] ??
        'English';

    setState(() {
      _loggedIn = loggedIn;
      _selectedLanguage = langLabel;
      if (loggedIn) {
        _name = prefs.getString('userName') ?? 'John Doe';
        _address = prefs.getString('userAddress') ?? '';
        _phone = prefs.getString('userPhone') ?? '';
        avatarUrl = prefs.getString('userAvatar');
        _userLat = prefs.getString('userLatitude');
        _userLng = prefs.getString('userLongitude');
      } else {
        _name = S.of(context).guest;
        _address = '';
        _phone = '';
        avatarUrl = null;
      }
    });
  }

  Future<void> _signIn() async {
    final result = await Navigator.push<bool>(
        context, MaterialPageRoute(builder: (_) => LoginPage()));
    if (result == true) _loadProfile();
  }

  Future<void> _logOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    setState(() {
      _loggedIn = false;
      _name = S.of(context).guest;
      _address = '';
      _phone = '';
      _selectedLanguage = 'English';
      avatarUrl = null;
    });
  }

  Future<void> _deleteAccount() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
            'This will delete your account. You can contact support to reactivate.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok != true) return;

    final prefs = await SharedPreferences.getInstance();
    final token = await TokenStorage.read();
    final userId = prefs.getInt('userId');
    if (token == null || userId == null) return;

    try {
      await ApiClient.instance.patch(
        '/users/$userId/deactivate',
      );
      if (!mounted) return;
      await prefs.clear();
      await TokenStorage.delete();
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => LoginPage()), (_) => false);
    } on ApiException catch (e) {
      final msg = e.message ?? 'Server error';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Deactivate failed: $msg')));
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Network error — please try again')));
    }
  }

  Future<void> _changeLanguage(String? lang) async {
    if (lang == null) return;
    final code = {'English': 'en', 'Kurdish': 'ku', 'Arabic': 'ar'}[lang]!;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', code);
    MyApp.setLocale(context, Locale(code));
    setState(() => _selectedLanguage = lang);
  }

  // Address editor (bottom sheet with map picker)
  Future<void> _editAddress() async {
    final addressCtrl = TextEditingController(text: _address);
    String? newLat = _userLat;
    String? newLng = _userLng;

    final result = await showModalBottomSheet<Map<String, String?>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Change Address',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryColor)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: addressCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Enter your delivery address',
                      filled: true,
                      fillColor: const Color(0xFFF7F7F7),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Location picker button
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.map, color: primaryColor),
                        onPressed: () async {
                          final location =
                              await Navigator.of(context).push<LatLng>(
                            MaterialPageRoute(
                              builder: (_) => const LocationPickerPage(),
                            ),
                          );
                          if (location != null) {
                            setModalState(() {
                              newLat = location.latitude.toStringAsFixed(5);
                              newLng = location.longitude.toStringAsFixed(5);
                            });
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          newLat != null && newLng != null
                              ? S
                                  .of(context)
                                  .signUpLocationPicked(newLat!, newLng!)
                              : S.of(context).signUpNoLocationSelected,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    onPressed: () => Navigator.pop(ctx, {
                      'address': addressCtrl.text.trim(),
                      'lat': newLat,
                      'lng': newLng,
                    }),
                    child: const Text('Save',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    if (result == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userAddress', result['address'] ?? '');
    if (result['lat'] != null) {
      await prefs.setString('userLatitude', result['lat']!);
      // Checkout reads the 'latitude'/'longitude' keys — keep them in sync
      // so an address change here actually reaches delivery.
      await prefs.setString('latitude', result['lat']!);
    }
    if (result['lng'] != null) {
      await prefs.setString('userLongitude', result['lng']!);
      await prefs.setString('longitude', result['lng']!);
    }
    setState(() {
      _address = result['address'] ?? '';
      _userLat = result['lat'];
      _userLng = result['lng'];
    });
  }

  // Contact helpers
  Future<void> _call(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri))
      await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFD3E4C4),
      appBar: AppBar(
        backgroundColor: Color(0xffFEFAE0),
        elevation: 1,
        iconTheme: const IconThemeData(color: primaryColor),
        title: Text(s.profileTitle,
            style: const TextStyle(
                color: primaryColor, fontWeight: FontWeight.bold)),
        actions: [
          // 3-dot menu with Logout & Delete
          if (_loggedIn)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: primaryColor),
              onSelected: (value) {
                if (value == 'logout') _logOut();
                if (value == 'delete') _deleteAccount();
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(
                    value: 'logout', child: Text(S.of(context).logout)),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(S.of(context).delete,
                      style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header card (avatar + name + phone)
            _ProfileCard(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 42,
                    backgroundColor: primaryColor.withValues(alpha: 0.12),
                    backgroundImage: (avatarUrl?.isNotEmpty ?? false)
                        ? NetworkImage(mediaUrl!)
                        : null,
                    child: (mediaUrl == null || mediaUrl!.isEmpty)
                        ? const Icon(Icons.person,
                            size: 54, color: primaryColor)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(_name,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: primaryColor)),
                  const SizedBox(height: 4),
                  if (_phone.isNotEmpty)
                    Text(_phone, style: const TextStyle(color: Colors.black87)),
                  if (_loggedIn) ...[
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EditProfilePage(),
                          ),
                        );
                        if (result == true) {
                          _loadProfile();
                        }
                      },
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit Profile'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Address card
            if (_loggedIn)
              _ProfileCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.location_on, color: primaryColor),
                  title: Text(S.of(context).delivery2,
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    _address.isEmpty ? S.of(context).tap : _address,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.edit, color: primaryColor),
                  onTap: _editAddress,
                ),
              ),

            // Language card
            _ProfileCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Icon(Icons.language, color: primaryColor),
                    SizedBox(width: 12),
                    Text(S.of(context).language,
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ]),
                  DropdownButton<String>(
                    value: _selectedLanguage,
                    underline: const SizedBox.shrink(),
                    items: const ['Kurdish', 'English', 'Arabic']
                        .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                        .toList(),
                    onChanged: _changeLanguage,
                  )
                ],
              ),
            ),

            // About & Contact
            _ProfileCard(
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading:
                        const Icon(Icons.info_outline, color: primaryColor),
                    title: Text(S.of(context).about,
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    trailing:
                        const Icon(Icons.chevron_right, color: primaryColor),
                    onTap: () => showCustomAboutDialog(context),
                  ),
                  const Divider(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading:
                        const Icon(Icons.phone_in_talk, color: primaryColor),
                    title: Text(S.of(context).contact,
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('$kSupportPhone1 – $kSupportPhone2'),
                    trailing:
                        const Icon(Icons.chevron_right, color: primaryColor),
                    onTap: () => _showContactSheet(),
                  ),
                ],
              ),
            ),

            // Socials
            // Socials (no overflow on small screens)
            _ProfileCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.share_rounded, color: primaryColor),
                    SizedBox(width: 12),
                    Text(S.of(context).follow,
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ]),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _SocialChip(
                          icon: Icons.camera_alt_outlined,
                          label: S.of(context).instagram,
                          onTap: () => _openUrl(_instagram)),
                      _SocialChip(
                          icon: Icons.facebook_outlined,
                          label: S.of(context).facebook,
                          onTap: () => _openUrl(_facebook)),
                      _SocialChip(
                          icon: Icons.movie_filter_outlined,
                          label: S.of(context).tiktok,
                          onTap: () => _openUrl(_tiktok)),
                    ],
                  ),
                ],
              ),
            ),

            // Sign in call-to-action for guests
            if (!_loggedIn)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _signIn,
                  child: Text(S.of(context).login,
                      style: const TextStyle(color: Colors.white)),
                ),
              ),

            const SizedBox(height: 16),
            const Center(
                child: Text("Designed and Developed by Rozhyar Omer Rashid",
                    style: TextStyle(fontSize: 12))),
          ],
        ),
      ),
    );
  }

  void _showContactSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(S.of(context).contact,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryColor)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                  child: _PhoneTile(
                      number: kSupportPhone1,
                      onTap: () => _call(kSupportPhone1))),
              const SizedBox(width: 8),
              Expanded(
                  child: _PhoneTile(
                      number: kSupportPhone2,
                      onTap: () => _call(kSupportPhone2))),
            ]),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _SocialIcon(
                    icon: Icons.camera_alt_outlined,
                    onTap: () => _openUrl(_instagram)),
                const SizedBox(width: 12),
                _SocialIcon(
                    icon: Icons.facebook_outlined,
                    onTap: () => _openUrl(_facebook)),
                const SizedBox(width: 12),
                _SocialIcon(
                    icon: Icons.movie_filter_outlined,
                    onTap: () => _openUrl(_tiktok)),
              ],
            ),
            const SizedBox(height: 8),
          ]),
        );
      },
    );
  }
}

// ===== Small UI helpers =====

class _ProfileCard extends StatelessWidget {
  final Widget child;
  const _ProfileCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xffFEFAE0),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: child,
    );
  }
}

class _PhoneTile extends StatelessWidget {
  final String number;
  final VoidCallback onTap;
  const _PhoneTile({required this.number, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFEFEFEF)),
          borderRadius: BorderRadius.circular(12),
          color: Color(0xffFEFAE0),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.call, color: primaryColor, size: 18),
          const SizedBox(width: 8),
          Text(number, style: const TextStyle(fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

class _SocialChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SocialChip(
      {required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Color(0xffFEFAE0),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(children: [
          Icon(icon, color: primaryColor, size: 18),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  color: primaryColor, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

class _SocialIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SocialIcon({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.1), shape: BoxShape.circle),
        child: Icon(icon, color: primaryColor),
      ),
    );
  }
}
