// lib/screens/add_address.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:barvin/generated/l10n.dart';
import 'LocationPickerPage.dart';
import 'package:latlong2/latlong.dart';

const Color primaryColor = Color(0xFF567765);

class AddAddressPage extends StatefulWidget {
  const AddAddressPage({Key? key}) : super(key: key);
  @override
  State<AddAddressPage> createState() => _AddAddressPageState();
}

class _AddAddressPageState extends State<AddAddressPage> {
  final _formKey = GlobalKey<FormState>();
  final _writtenAddrCtrl = TextEditingController();
  String? _latitude;
  String? _longitude;
  bool _saving = false;

  Future<void> _pickOnMap() async {
    final result = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(builder: (_) => const LocationPickerPage()),
    );
    if (result != null) {
      setState(() {
        _latitude = result.latitude.toStringAsFixed(6);
        _longitude = result.longitude.toStringAsFixed(6);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).requiredField)),
      );
      return;
    }

    setState(() => _saving = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userAddress', _writtenAddrCtrl.text.trim());
    await prefs.setString('latitude', _latitude!);
    await prefs.setString('longitude', _longitude!);
    setState(() => _saving = false);
    Navigator.of(context).pop(true);
  }

  @override
  void dispose() {
    _writtenAddrCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.addNewAddress),
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // 1) Written address field
                  TextFormField(
                    controller: _writtenAddrCtrl,
                    decoration: InputDecoration(
                      labelText: s.address,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? s.requiredField : null,
                  ),
                  const SizedBox(height: 16),

                  // 2) Map picker for lat/lng
                  InkWell(
                    onTap: _pickOnMap,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.map, color: primaryColor),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _latitude != null && _longitude != null
                                  ? '${s.latitude}: $_latitude\n${s.longitude}: $_longitude'
                                  : s.tapToPickLocation,
                              style: TextStyle(
                                color: _latitude == null
                                    ? Colors.grey
                                    : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // hidden but forces the validator to run
                  if (_latitude == null || _longitude == null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          s.requiredField,
                          style:
                              const TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const Spacer(),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _saving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(s.save, style: const TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
