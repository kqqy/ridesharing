import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class ActiveTripBody extends StatefulWidget {
  final VoidCallback onSOS;
  final VoidCallback onArrived;
  final VoidCallback onShare;
  final VoidCallback onChat;

  final String origin;
  final String destination;

  const ActiveTripBody({
    super.key,
    required this.onSOS,
    required this.onArrived,
    required this.onShare,
    required this.onChat,
    required this.origin,
    required this.destination,
  });

  @override
  State<ActiveTripBody> createState() => _ActiveTripBodyState();
}

class _ActiveTripBodyState extends State<ActiveTripBody> {
  GoogleMapController? _mapController;

  LatLng? _originLatLng;
  LatLng? _destLatLng;

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  bool _loading = true;
  bool _routeBuilt = false;

  // ⚠️ 換成你的 API Key（要啟用 Directions API + Billing）
  static const String _googleApiKey = 'AIzaSyCQjEBcgsPbLD14kXGPcG7UUvDyd4PlPH0';

  @override
  void initState() {
    super.initState();
    _geocodeEndpoints(); // 先把起終點轉成座標
  }

  Future<void> _geocodeEndpoints() async {
    setState(() => _loading = true);

    try {
      // ✅ 建議補上城市，避免同名地點找錯
      final originText = widget.origin.contains('台中') ? widget.origin : '${widget.origin}, 台中';
      final destText = widget.destination.contains('台中') ? widget.destination : '${widget.destination}, 台中';

      final originLoc = await locationFromAddress(originText);
      final destLoc = await locationFromAddress(destText);

      _originLatLng = LatLng(originLoc.first.latitude, originLoc.first.longitude);
      _destLatLng = LatLng(destLoc.first.latitude, destLoc.first.longitude);

      _markers
        ..clear()
        ..add(Marker(
          markerId: const MarkerId('origin'),
          position: _originLatLng!,
          infoWindow: InfoWindow(title: '出發地', snippet: widget.origin),
        ))
        ..add(Marker(
          markerId: const MarkerId('dest'),
          position: _destLatLng!,
          infoWindow: InfoWindow(title: '目的地', snippet: widget.destination),
        ));
    } catch (e) {
      debugPrint('geocode failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('地址定位失敗：$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _buildRouteOnce() async {
    if (_routeBuilt) return;
    _routeBuilt = true;

    if (_originLatLng == null || _destLatLng == null) return;

    // ✅ 先把鏡頭對準出發點（解決你說的「一開始跑到台北」）
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_originLatLng!, 14));

    // ✅ 再 fitBounds（讓兩點都在畫面裡）
    _fitBounds(_originLatLng!, _destLatLng!);

    // 嘗試用 Directions 畫路線
    try {
      final polylinePoints = PolylinePoints();
      final result = await polylinePoints.getRouteBetweenCoordinates(
        googleApiKey: _googleApiKey,
        request: PolylineRequest(
          origin: PointLatLng(_originLatLng!.latitude, _originLatLng!.longitude),
          destination: PointLatLng(_destLatLng!.latitude, _destLatLng!.longitude),
          mode: TravelMode.driving,
        ),
      );

      debugPrint('Directions status=${result.status} error=${result.errorMessage}');
      debugPrint('Directions points=${result.points.length}');

      if (result.points.isNotEmpty) {
        final routeLatLng = result.points.map((p) => LatLng(p.latitude, p.longitude)).toList();
        setState(() {
          _polylines
            ..clear()
            ..add(Polyline(
              polylineId: const PolylineId('route'),
              points: routeLatLng,
              width: 6,
            ));
        });
        return;
      }

      // ❗如果 Directions 拿不到，就先畫直線（至少確認兩點正確）
      setState(() {
        _polylines
          ..clear()
          ..add(Polyline(
            polylineId: const PolylineId('fallback_line'),
            points: [_originLatLng!, _destLatLng!],
            width: 4,
          ));
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('拿不到路線（Directions 未回傳）。已先用直線連接起終點。')),
        );
      }
    } catch (e) {
      debugPrint('build route failed: $e');
    }
  }

  void _fitBounds(LatLng a, LatLng b) {
    final sw = LatLng(
      (a.latitude < b.latitude) ? a.latitude : b.latitude,
      (a.longitude < b.longitude) ? a.longitude : b.longitude,
    );
    final ne = LatLng(
      (a.latitude > b.latitude) ? a.latitude : b.latitude,
      (a.longitude > b.longitude) ? a.longitude : b.longitude,
    );

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(LatLngBounds(southwest: sw, northeast: ne), 60),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // 如果 geocode 失敗
    if (_originLatLng == null || _destLatLng == null) {
      return const Scaffold(
        body: Center(child: Text('無法定位出發/終點，請確認地址文字')),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            // ✅ 初始就用出發點（不是台北）
            initialCameraPosition: CameraPosition(
              target: _originLatLng!,
              zoom: 14,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _buildRouteOnce();
              });
            },
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            markers: _markers,
            polylines: _polylines,
          ),

          // 你原本疊上去的 UI (SOS/分享/到達/聊天) 照放
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
