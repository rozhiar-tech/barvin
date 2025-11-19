import 'dart:convert';

import 'package:barvin/constants/contact.dart';
import 'package:barvin/generated/l10n.dart';
import 'package:barvin/models/collections.dart';
import 'package:barvin/services/api_config.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class HandWorksScreen extends StatefulWidget {
  final List<HandWork> initialHandworks;
  const HandWorksScreen({Key? key, this.initialHandworks = const []})
      : super(key: key);

  @override
  State<HandWorksScreen> createState() => _HandWorksScreenState();
}

class _HandWorksScreenState extends State<HandWorksScreen> {
  late List<HandWork> _handworks;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _handworks = widget.initialHandworks;
    _fetchHandworks();
  }

  Future<void> _fetchHandworks() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await http.get(apiUrl('/handworks'));
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body) as List;
        final works = data
            .whereType<Map<String, dynamic>>()
            .map(HandWork.fromJson)
            .toList();
        setState(() => _handworks = works);
      } else {
        setState(() =>
            _error = 'Failed to load hand works (HTTP ${res.statusCode}).');
      }
    } catch (e) {
      setState(() => _error = 'Failed to load hand works.');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _contact(HandWork work) async {
    final phone = kWhatsAppNumber.replaceAll(RegExp(r'[^0-9]'), '');
    final message =
        'Hello, I\'d like to order "${work.name}" (qty ${work.quantity}) priced at ${work.price.toStringAsFixed(0)} IQD.';
    final encoded = Uri.encodeComponent(message);
    final uriApp = Uri.parse('whatsapp://send?phone=$phone&text=$encoded');
    final uriWeb = Uri.parse('https://wa.me/$phone?text=$encoded');

    try {
      if (await canLaunchUrl(uriApp)) {
        await launchUrl(uriApp, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(uriWeb)) {
        await launchUrl(uriWeb, mode: LaunchMode.externalApplication);
      } else {
        throw 'Cannot launch WhatsApp';
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open WhatsApp.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      backgroundColor: const Color(0xffD3E4C4),
      appBar: AppBar(
        backgroundColor: const Color(0xffFEFAE0),
        iconTheme: const IconThemeData(color: Color(0xFFbed6be)),
        title: Text(s.handWorkSectionTitle,
            style: const TextStyle(color: Colors.black87)),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchHandworks,
        child: _loading && _handworks.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: _handworks.length + (_error != null ? 1 : 0),
                itemBuilder: (_, idx) {
                  if (_error != null && idx == _handworks.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 24.0),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  final work = _handworks[idx];
                  final image = work.primaryImage;
                  final imageUrl = image == null ? null : mediaUrlFrom(image);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    color: const Color(0xffFEFAE0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: AspectRatio(
                              aspectRatio: 4 / 3,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  imageUrl == null
                                      ? Container(
                                          color: Colors.grey.shade200,
                                          alignment: Alignment.center,
                                          child: const Icon(Icons.image,
                                              color: Colors.grey, size: 48),
                                        )
                                      : CachedNetworkImage(
                                          imageUrl: imageUrl,
                                          fit: BoxFit.cover,
                                          placeholder: (_, __) => Container(
                                            color: Colors.black12,
                                            alignment: Alignment.center,
                                            child:
                                                const CircularProgressIndicator(),
                                          ),
                                          errorWidget: (_, __, ___) => Container(
                                            color: Colors.grey.shade200,
                                            alignment: Alignment.center,
                                            child: const Icon(Icons.broken_image),
                                          ),
                                        ),
                                  Positioned(
                                    right: 12,
                                    bottom: 12,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.6),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        '${work.price.toStringAsFixed(0)} IQD',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            work.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            work.description.isNotEmpty
                                ? work.description
                                : s.handworkNoDescription,
                            style: const TextStyle(fontSize: 14),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Quantity: ${work.quantity}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF25D366),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () => _contact(work),
                            icon: const Icon(Icons.chat),
                            label: const Text('Contact on WhatsApp'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
