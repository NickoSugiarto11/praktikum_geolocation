import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Praktikum Geolocator (Dasar)',
      theme: ThemeData(primarySwatch: Colors.blue, visualDensity: VisualDensity.adaptivePlatformDensity),
      debugShowCheckedModeBanner: false,
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Position? _currentPosition;
  String? _errorMessage;
  StreamSubscription<Position>? _positionStream;
  String? _currentAddress;
  String? distanceToPNB;

  // titik tetap PNB
  final double _pnbLatitude = -6.176333;
  final double _pnbLongitude = 106.696969;

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    } else {
      double km = meters / 1000;
      return '${km.toStringAsFixed(2)} Km';
    }
  }

  double _calculateDistance(Position pos) {
    return Geolocator.distanceBetween(
      _pnbLatitude,
      _pnbLongitude,
      pos.latitude, // ’position ’ dari stream
      pos.longitude,
    );
  }

  Future<String> _getAddressFromLatLng(Position position) async {
    List<Placemark> alamat = await placemarkFromCoordinates(position.latitude, position.longitude);
    Placemark tempat = alamat[0];
    String formattedAddress = "${tempat.street} ,${tempat.subLocality}, ${tempat.locality}, ${tempat.country}";
    return formattedAddress;
  }

  Future<Position> _getPermissionAndLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Cek apakah layanan lokasi (GPS) di perangkat aktif
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Jika tidak aktif, kirim error
      return Future.error('Layanan lokasi tidak aktif. Harap aktifkan GPS.');
    }

    // 2. Cek izin lokasi dari aplikasi
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // Jika ditolak, minta izin
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Jika tetap ditolak, kirim error
        return Future.error('Izin lokasi ditolak.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Izin lokasi ditolak permanen. Harap ubah di pengaturan aplikasi.');
    }

    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  // --- FUNGSI AKSI (TOMBOL) ---

  /**
   * Aksi untuk tombol 'Dapatkan Lokasi Sekarang'.
   * Mengambil lokasi satu kali saja.
   */
  void _handleGetLocation() async {
    try {
      Position position = await _getPermissionAndLocation();
      String getAddress = await _getAddressFromLatLng(position);
      double distanceInMeters = _calculateDistance(position);

      setState(() {
        _currentPosition = position;
        _currentAddress = getAddress;
        _errorMessage = null;
        distanceToPNB = _formatDistance(distanceInMeters);
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  void _handleStartTracking() {
    _positionStream?.cancel();

    final LocationSettings locationSettings = LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10);

    try {
      _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position position) async {
        String getAddress = await _getAddressFromLatLng(position);
        double distanceInMeters = _calculateDistance(position);

        setState(() {
          _currentPosition = position;
          _currentAddress = getAddress;
          _errorMessage = null;
          distanceToPNB = _formatDistance(distanceInMeters);
        });
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  void _handleStopTracking() {
    _positionStream?.cancel();
    setState(() {
      _errorMessage = "Pelacakan dihentikan.";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Praktikum Geolocator (Dasar)")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on, size: 50, color: Colors.blue),
                SizedBox(height: 16),

                ConstrainedBox(
                  constraints: BoxConstraints(minHeight: 150),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_errorMessage != null)
                        Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),

                      SizedBox(height: 16),

                      if (_currentPosition != null)
                        Text(
                          "Lat: ${_currentPosition!.latitude}\nLng: ${_currentPosition!.longitude}",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      SizedBox(height: 8),
                      if (_currentAddress != null) Text(_currentAddress!, textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
                      SizedBox(height: 16),

                      Column(
                        children: [
                          Text(
                            "Jarak ke PNB:",
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
                          ),
                          SizedBox(height: 6),

                          Text(
                            distanceToPNB ?? "-",
                            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 32),

                ElevatedButton.icon(
                  icon: Icon(Icons.location_searching),
                  label: Text('Dapatkan Lokasi Sekarang'),
                  onPressed: _handleGetLocation,
                  style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 40)),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      icon: Icon(Icons.play_arrow),
                      label: Text('Mulai Lacak'),
                      onPressed: _handleStartTracking,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    ),
                    ElevatedButton.icon(
                      icon: Icon(Icons.stop),
                      label: Text('Henti Lacak'),
                      onPressed: _handleStopTracking,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
