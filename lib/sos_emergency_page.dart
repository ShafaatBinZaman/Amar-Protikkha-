import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

class SOSEmergencyPage extends StatefulWidget {
  final List<String> emergencyContacts; // List of emergency contacts passed from HomePage

  SOSEmergencyPage({required this.emergencyContacts});

  @override
  _SOSEmergencyPageState createState() => _SOSEmergencyPageState();
}

class _SOSEmergencyPageState extends State<SOSEmergencyPage> {
  Position? _currentPosition;
  bool _isSendingSOS = false;


  Future<void> _requestSMSPermission() async {
    PermissionStatus status = await Permission.sms.request();
    if (status != PermissionStatus.granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please grant SMS permission to send the message.")),
      );
    }
  }


  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please enable location services.")));
      return Future.error('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please grant location permissions.")));
        return Future.error('Location permissions are denied');
      }
    }

    _currentPosition = await Geolocator.getCurrentPosition();
  }


  Future<void> _openSMSApp() async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Location not available. Please try again.")));
      return;
    }


    String locationMessage = 'I need help! My location is: https://www.google.com/maps?q=${_currentPosition!.latitude},${_currentPosition!.longitude}';
    String finalMessage = 'Help! I\'m in danger. $locationMessage';


    String smsUrl = 'sms:${widget.emergencyContacts.join(',')}?body=$finalMessage';


    try {
      if (await canLaunch(smsUrl)) {
        await launch(smsUrl);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Unable to open SMS app.")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SOS Emergency'),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning,
              color: Colors.red,
              size: 60,
            ),
            SizedBox(height: 20),
            Text(
              'Press SOS to send alert.',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            Text(
              'This will alert your selected contacts via SMS.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () async {
                if (_isSendingSOS) return;
                await _getCurrentLocation();
                await _openSMSApp();
              },
              child: Text(
                _isSendingSOS ? 'Sending SOS...' : 'SEND SOS',
                style: TextStyle(fontSize: 20),
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                backgroundColor: Colors.red,  // Red button for SOS
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
