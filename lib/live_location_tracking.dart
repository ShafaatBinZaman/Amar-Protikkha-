import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class LiveLocationService {
  LiveLocationService._internal();
  static final LiveLocationService _instance = LiveLocationService._internal();
  factory LiveLocationService() => _instance;

  bool isTracking = false;
  Position? lastPosition;

  StreamSubscription<Position>? _geoSub;
  final _positionController = StreamController<Position>.broadcast();


  Stream<Position> get positionStream => _positionController.stream;

  Future<void> startTracking() async {
    if (isTracking) return;

    isTracking = true;


    _geoSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 2,
      ),
    ).listen((Position pos) {
      lastPosition = pos;
      _positionController.add(pos);
      _saveLocationToFirestore(pos);
    });
  }

  Future<void> stopTracking() async {
    await _geoSub?.cancel();
    _geoSub = null;
    isTracking = false;
  }

  Future<void> _saveLocationToFirestore(Position position) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance
        .collection('live_location_history')
        .doc(uid)
        .collection('history')
        .add({
      'latitude': position.latitude,
      'longitude': position.longitude,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }


  void dispose() {
    _geoSub?.cancel();
    _positionController.close();
  }
}


class LiveLocationTrackingPage extends StatefulWidget {
  const LiveLocationTrackingPage({super.key});

  @override
  State<LiveLocationTrackingPage> createState() =>
      _LiveLocationTrackingPageState();
}

class _LiveLocationTrackingPageState extends State<LiveLocationTrackingPage> {
  final LiveLocationService _service = LiveLocationService();

  Position? _currentPosition;
  bool _isTracking = false;

  StreamSubscription<Position>? _uiSub;

  @override
  void initState() {
    super.initState();


    _isTracking = _service.isTracking;
    _currentPosition = _service.lastPosition;


    _uiSub = _service.positionStream.listen((pos) {
      setState(() {
        _currentPosition = pos;
      });
    });
  }

  @override
  void dispose() {

    _uiSub?.cancel();
    super.dispose();
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return false;
    }

    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }


  Future<void> _startTracking() async {

    final hasPerm = await _handleLocationPermission();
    if (!hasPerm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enable location permission.")),
      );
      return;
    }

    await _service.startTracking();

    setState(() {
      _isTracking = true;
      _currentPosition = _service.lastPosition;
    });
  }


  Future<void> _stopTracking() async {
    await _service.stopTracking();

    setState(() {
      _isTracking = false;
    });
  }

  // my UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Live Location Tracking"),
        backgroundColor: const Color(0xFF1E88E5),
      ),
      body: Center(
        child: !_isTracking
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Click below to start tracking your live location.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _startTracking,
              child: const Text("Start Tracking"),
            ),
          ],
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _currentPosition == null
                ? const CircularProgressIndicator()
                : Column(
              children: [
                Text(
                  "Latitude: ${_currentPosition!.latitude}",
                  style: const TextStyle(fontSize: 20),
                ),
                Text(
                  "Longitude: ${_currentPosition!.longitude}",
                  style: const TextStyle(fontSize: 20),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _stopTracking,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text("Stop Tracking"),
            ),
          ],
        ),
      ),
    );
  }
}
