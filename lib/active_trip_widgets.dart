import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class ActiveTripBody extends StatefulWidget {
  final VoidCallback onSOS;
  final VoidCallback onArrived;
  final VoidCallback onShare;
  final VoidCallback onChat;

  const ActiveTripBody({
    super.key,
    required this.onSOS,
    required this.onArrived,
    required this.onShare,
    required this.onChat,
  });

  @override
  State<ActiveTripBody> createState() => _ActiveTripBodyState();
}

class _ActiveTripBodyState extends State<ActiveTripBody> {
  GoogleMapController? _mapController;
  LatLng? _currentLatLng;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  /// 取得目前位置
  Future<void> _initLocation() async {
    // 1. 檢查定位服務
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    // 2. 檢查權限
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) return;

    // 3. 取得目前位置
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _currentLatLng = LatLng(position.latitude, position.longitude);
    });

    // 4. 地圖移動到目前位置
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(_currentLatLng!, 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ===============================
          // 1. Google Map（目前位置）
          // ===============================
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(25.0478, 121.5170), // 只是暫時用，馬上會移動
              zoom: 15,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              if (_currentLatLng != null) {
                controller.animateCamera(
                  CameraUpdate.newLatLngZoom(_currentLatLng!, 16),
                );
              }
            },
            myLocationEnabled: true,        // 藍點
            myLocationButtonEnabled: true, // 右下定位鍵
            zoomControlsEnabled: false,
          ),

          // ===============================
          // 以下 UI 全部跟你原本一樣
          // ===============================
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '路徑偏移',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),

          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 20,
            child: FloatingActionButton(
              heroTag: 'btn_sos',
              onPressed: widget.onSOS,
              backgroundColor: Colors.red,
              child: const Icon(Icons.sos, color: Colors.white),
            ),
          ),

          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FloatingActionButton(
                  heroTag: 'btn_share',
                  onPressed: widget.onShare,
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  child: const Icon(Icons.share),
                ),
                ElevatedButton(
                  onPressed: widget.onArrived,
                  child: const Text('已到達'),
                ),
                FloatingActionButton(
                  heroTag: 'btn_chat',
                  onPressed: widget.onChat,
                  backgroundColor: Colors.blue,
                  child: const Icon(Icons.chat_bubble),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
