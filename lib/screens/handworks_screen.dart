import 'dart:convert';

import 'package:barvin/constants/contact.dart';
import 'package:barvin/generated/l10n.dart';
import 'package:barvin/models/collections.dart';
import 'package:barvin/services/api_config.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class HandWorksScreen extends StatefulWidget {
  final List<HandWork> initialHandworks;
  const HandWorksScreen({Key? key, this.initialHandworks = const []})
      : super(key: key);

  @override
  State<HandWorksScreen> createState() => _HandWorksScreenState();
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  const _QuantityButton({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: const CircleBorder(),
          side: const BorderSide(color: Color(0xFF567765)),
        ),
        child: Icon(
          icon,
          size: 18,
          color: onPressed == null ? Colors.grey : const Color(0xFF567765),
        ),
      ),
    );
  }
}

class _HandWorksScreenState extends State<HandWorksScreen> {
  late List<HandWork> _handworks;
  bool _loading = false;
  String? _error;
  final Map<int, int> _desiredQty = {};

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

  int _qtyFor(int workId) => _desiredQty[workId] ?? 100;

  void _changeQty(int workId, int delta) {
    setState(() {
      final current = _desiredQty[workId] ?? 100;
      final next = (current + delta).clamp(100, 99900);
      _desiredQty[workId] = next;
    });
  }

  Widget _buildShimmerCard() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(
          height: 210,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
    );
  }

  Future<void> _contact(HandWork work) async {
    final phone = kWhatsAppNumber.replaceAll(RegExp(r'[^0-9]'), '');
    final message =
        'Hello, I\'d like to order "${work.name}" (qty ${_qtyFor(work.id)}) priced at ${work.price.toStringAsFixed(0)} IQD.';
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
            ? ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: 3,
                itemBuilder: (_, __) => _buildShimmerCard(),
              )
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

                  final qty = _qtyFor(work.id);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xffE5EED8),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.07),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: imageUrl == null
                                  ? Container(
                                      width: 110,
                                      height: 110,
                                      color: Colors.grey.shade200,
                                      alignment: Alignment.center,
                                      child: const Icon(Icons.image,
                                          size: 40, color: Colors.grey),
                                    )
                                  : CachedNetworkImage(
                                      imageUrl: imageUrl,
                                      width: 110,
                                      height: 110,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    work.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${work.price.toStringAsFixed(0)} IQD',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    s.handworkDesiredQuantityLabel,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      _QuantityButton(
                                        icon: Icons.remove,
                                        onPressed: qty > 100
                                            ? () => _changeQty(work.id, -100)
                                            : null,
                                      ),
                                      Container(
                                        width: 56,
                                        height: 36,
                                        alignment: Alignment.center,
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          qty.toString(),
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      _QuantityButton(
                                        icon: Icons.add,
                                        onPressed: () => _changeQty(work.id, 100),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    s.handworkAvailableLabel(work.quantity),
                                    style: const TextStyle(
                                        color: Colors.black54, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            work.description.isNotEmpty
                                ? work.description
                                : s.handworkNoDescription,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5D8A4E),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () => _contact(work),
                            child: Text(
                              s.handworkContactButton,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
