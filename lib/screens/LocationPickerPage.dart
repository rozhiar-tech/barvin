import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class LocationPickerPage extends StatefulWidget {
  const LocationPickerPage({Key? key}) : super(key: key);

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  LatLng? _picked;
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Your Location'),
        actions: [
          TextButton(
            onPressed: _picked == null
                ? null
                : () => Navigator.of(context).pop(_picked),
            child: const Text(
              'OK',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: LatLng(36.2021, 43.6150), // Erbil coordinates
          initialZoom: 13,
          onTap: (tapPos, latlng) {
            // immediately return the picked LatLng
            Navigator.of(context).pop(latlng);
          },
        ),
        children: [
          TileLayer(
            urlTemplate:
                'https://tile.openstreetmap.org/{z}/{x}/{y}.png', // For demonstration only
            userAgentPackageName:
                'com.example.barvin', // Add your app identifier
          ),
          if (_picked != null)
            MarkerLayer(
              markers: [
                Marker(
                  point: _picked!,
                  width: 40,
                  height: 40,
                  child: const Icon(
                    Icons.location_pin,
                    size: 40,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
