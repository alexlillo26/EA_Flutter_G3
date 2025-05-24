import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fmap;
import 'package:latlong2/latlong.dart' as latlng;

class GymMapTab extends StatelessWidget {
  final double latitude;
  final double longitude;
  const GymMapTab({required this.latitude, required this.longitude, super.key});

  @override
  Widget build(BuildContext context) {
    return fmap.FlutterMap(
      options: fmap.MapOptions(
        center: latlng.LatLng(latitude, longitude),
        zoom: 15.0,
      ),
      children: [
        fmap.TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: ['a', 'b', 'c'],
        ),
        fmap.MarkerLayer(
          markers: [
            fmap.Marker(
              width: 80.0,
              height: 80.0,
              point: latlng.LatLng(latitude, longitude),
              child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
            ),
          ],
        ),
      ],
    );
  }
}