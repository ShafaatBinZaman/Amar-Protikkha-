import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class NearbyPoliceStationsPage extends StatefulWidget {
  const NearbyPoliceStationsPage({Key? key}) : super(key: key);

  @override
  _NearbyPoliceStationsPageState createState() =>
      _NearbyPoliceStationsPageState();
}

class _NearbyPoliceStationsPageState extends State<NearbyPoliceStationsPage> {
  LatLng _currentLocation = const LatLng(0, 0);
  bool _loadingLocation = true;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _loadingLocation = false;
      });
    } catch (e) {
      setState(() => _loadingLocation = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location error: $e')),
      );
    }
  }

  Future<void> _openGoogleMaps(String placeQuery) async {
    final googleMapsUrl =
        'https://www.google.com/maps/search/?api=1&query=$placeQuery+near+${_currentLocation.latitude},${_currentLocation.longitude}';

    final uri = Uri.parse(googleMapsUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Maps.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nearby Help Services"),
        backgroundColor: const Color(0xFF1E88E5),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: _loadingLocation
              ? const CircularProgressIndicator()
              : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => _openGoogleMaps('police stations'),
                  child: const Text('Search Nearby Police Stations'),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => _openGoogleMaps('hospitals'),
                  child: const Text('Search Nearby Hospitals'),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => _openGoogleMaps('pharmacies'),
                  child: const Text('Search Nearby Pharmacies'),
                ),
              ),
              const SizedBox(height: 14),
              // ✅ NEW ATM FEATURE
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => _openGoogleMaps('atm'),
                  child: const Text('Search Nearby ATMs'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
