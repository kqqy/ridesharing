import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class ActiveTripBody extends StatefulWidget {
  final VoidCallback onSOS;
  final VoidCallback onArrived;
  final VoidCallback onShare;
  final VoidCallback onChat;

  // ✅ 改成只傳 tripId，自己查 trips 表拿 origin/destination
  final String tripId;

  const ActiveTripBody({
    super.key,
    required this.onSOS,
    required this.onArrived,
    required this.onShare,
    required this.onChat,
    required this.tripId,
  });

  @override
  State<ActiveTripBody> createState() => _ActiveTripBodyState();
}

class _ActiveTripBodyState extends State<ActiveTripBody> {
  final supabase = Supabase.instance.client;

  GoogleMapController? _mapController;

  // ✅ 從 DB 讀到的文字地址
  String? _originText;
  String? _destText;

  // ✅ 轉成座標後
  LatLng? _originLatLng;
  LatLng? _destLatLng;

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  bool _loading = true;
  bool _routeBuilt = false;

  // ⚠️ Directions 仍可能 REQUEST_DENIED（API/限制/Billing 問題），拿不到就畫直線 fallback
  static const String _googleApiKey = 'AIzaSyCQjEBcgsPbLD14kXGPcG7UUvDyd4PlPH0';

  @override
  void initState() {
    super.initState();
    _loadTripAndBuild(); // ✅ 一進來就讀 DB
  }

  Future<void> _loadTripAndBuild() async {
    setState(() => _loading = true);

    try {
      // 1) 讀 trips 表：origin/destination
      final trip = await supabase
          .from('trips')
          .select('origin, destination')
          .eq('id', widget.tripId)
          .single();

      final origin = (trip['origin'] as String?)?.trim();
      final destination = (trip['destination'] as String?)?.trim();

      if (origin == null || origin.isEmpty || destination == null || destination.isEmpty) {
        throw '此行程缺少出發地或目的地（trips.origin / trips.destination）';
      }

      _originText = origin;
      _destText = destination;

      // 2) 文字地址 -> 座標
      await _geocodeEndpoints(origin, destination);

      // 3) marker
      _buildMarkers();

      // 4) 嘗試畫路線（Directions）；失敗則 fallback 直線
      await _buildRouteOnce();
    } on PostgrestException catch (e) {
      debugPrint('load trip failed: ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('讀取行程失敗（DB）：${e.message}')),
        );
      }
    } catch (e) {
      debugPrint('load trip failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('讀取行程失敗：$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _geocodeEndpoints(String originText, String destText) async {
    // 這裡不要再用 widget.origin / widget.destination
    // 直接用傳進來的 originText / destText（就是 DB 讀到的）
    final originLoc = await locationFromAddress(originText);
    final destLoc = await locationFromAddress(destText);

    _originLatLng = LatLng(originLoc.first.latitude, originLoc.first.longitude);
    _destLatLng = LatLng(destLoc.first.latitude, destLoc.first.longitude);
  }


  void _buildMarkers() {
    if (_originLatLng == null || _destLatLng == null) return;

    setState(() {
      _markers
        ..clear()
        ..add(Marker(
          markerId: const MarkerId('origin'),
          position: _originLatLng!,
          infoWindow: InfoWindow(title: '出發地', snippet: _originText ?? ''),
        ))
        ..add(Marker(
          markerId: const MarkerId('dest'),
          position: _destLatLng!,
          infoWindow: InfoWindow(title: '目的地', snippet: _destText ?? ''),
        ));
    });
  }

  Future<void> _buildRouteOnce() async {
    if (_routeBuilt) return;
    _routeBuilt = true;

    if (_originLatLng == null || _destLatLng == null) return;

    // ✅ 一進來就對準出發地
    await _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(_originLatLng!, 15),
    );

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
        if (!mounted) return;
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

      // ❗Directions 拿不到（例如 REQUEST_DENIED）→ 用直線先頂著
      if (!mounted) return;
      setState(() {
        _polylines
          ..clear()
          ..add(Polyline(
            polylineId: const PolylineId('fallback_line'),
            points: [_originLatLng!, _destLatLng!],
            width: 4,
          ));
      });
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

    if (_originLatLng == null || _destLatLng == null) {
      return const Scaffold(
        body: Center(child: Text('無法定位出發/終點，請確認 trips 的 origin/destination')),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _originLatLng!,
              zoom: 15,
            ),
            onMapCreated: (controller) async {
              _mapController = controller;

              // ✅ 保險：地圖 ready 後再對準一次出發地
              await _mapController?.moveCamera(
                CameraUpdate.newLatLngZoom(_originLatLng!, 15),
              );

              // ✅ 讓兩點都看得到（你想要就留，不想要就刪掉這行）
              // _fitBounds(_originLatLng!, _destLatLng!);
            },
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            markers: _markers,
            polylines: _polylines,
          ),

          // （可選）顯示全路線按鈕
          Positioned(
            top: MediaQuery.of(context).padding.top + 70,
            right: 20,
            child: FloatingActionButton(
              heroTag: 'btn_fit',
              onPressed: () => _fitBounds(_originLatLng!, _destLatLng!),
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              child: const Icon(Icons.route),
            ),
          ),

          // 你原本疊上去的 UI
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
