import 'dart:async';
import 'dart:math' as math;
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:share_plus/share_plus.dart';

class ActiveTripBody extends StatefulWidget {
  final VoidCallback onSOS;
  final VoidCallback onArrived;
  final VoidCallback onShare;
  final VoidCallback onChat;

  final bool isCreator;
  final String tripId;

  const ActiveTripBody({
    super.key,
    required this.onSOS,
    required this.onArrived,
    required this.onShare,
    required this.onChat,
    required this.tripId,
    required this.isCreator,
  });

  @override
  State<ActiveTripBody> createState() => _ActiveTripBodyState();
}

class _ActiveTripBodyState extends State<ActiveTripBody> {
  final supabase = Supabase.instance.client;

  GoogleMapController? _mapController;

  String? _originText;
  String? _destText;
  String? _errorMessage;

  LatLng? _originLatLng;
  LatLng? _destLatLng;

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  List<LatLng> _routePoints = [];

  bool _loading = true;
  bool _routeBuilt = false;

  static const double _offRouteThresholdMeters = 200.0;
  bool _offRoute = false;
  double _offRouteMeters = 0;

  DateTime? _lastOffRouteDialogAt;
  static const Duration _dialogCooldown = Duration(seconds: 30);

  StreamSubscription<Position>? _posSub;

  // 你 Directions 用的 key（分享路線不需要這個 key）
  static const String _googleApiKey = 'AIzaSyCQjEBcgsPbLD14kXGPcG7UUvDyd4PlPH0';

  @override
  void initState() {
    super.initState();
    _loadTripAndBuild();
  }

  @override
  void dispose() {
    _posSub?.cancel();
    super.dispose();
  }

  Future<void> _loadTripAndBuild() async {
    setState(() => _loading = true);

    try {
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

      await _geocodeEndpoints(origin, destination);

      _buildMarkers();

      await _buildRouteOnce();

      await _startOffRouteMonitoring();
    } on PostgrestException catch (e) {
      if (mounted) {
        setState(() => _errorMessage = '讀取行程失敗（DB）：${e.message}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('讀取行程失敗（DB）：${e.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = '定位失敗，請確認地址正確性。\n錯誤資訊：$e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('讀取行程失敗：$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _geocodeEndpoints(String originText, String destText) async {
    try {
      // 1. 嘗試原生 Geocoding (Android: Google, iOS: Apple)
      final originLoc = await locationFromAddress(originText);
      final destLoc = await locationFromAddress(destText);

      _originLatLng = LatLng(originLoc.first.latitude, originLoc.first.longitude);
      _destLatLng = LatLng(destLoc.first.latitude, destLoc.first.longitude);

    } catch (e) {
      debugPrint('原生 Geocoding 失敗 ($e)，嘗試使用 Google API...');

      // 2. 備案：如果失敗，強制使用 Google Geocoding API
      try {
        final origin = await _fetchGoogleGeocoding(originText);
        final dest = await _fetchGoogleGeocoding(destText);

        if (origin != null && dest != null) {
          _originLatLng = origin;
          _destLatLng = dest;
          return; // 成功
        }
      } catch (googleError) {
        debugPrint('Google Geocoding API 也失敗: $googleError');
      }

      // 如果兩者都失敗，拋出原始錯誤供 UI 顯示
      rethrow;
    }
  }

  Future<LatLng?> _fetchGoogleGeocoding(String address) async {
    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(address)}&key=$_googleApiKey');
    
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK' && (data['results'] as List).isNotEmpty) {
        final location = data['results'][0]['geometry']['location'];
        return LatLng(location['lat'], location['lng']);
      }
    }
    return null;
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

      if (result.points.isNotEmpty) {
        final routeLatLng = result.points.map((p) => LatLng(p.latitude, p.longitude)).toList();
        _routePoints = routeLatLng;

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

      _routePoints = [_originLatLng!, _destLatLng!];

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
    } catch (_) {
      _routePoints = [_originLatLng!, _destLatLng!];
      if (mounted) {
        setState(() {
          _polylines
            ..clear()
            ..add(Polyline(
              polylineId: const PolylineId('fallback_line'),
              points: [_originLatLng!, _destLatLng!],
              width: 4,
            ));
        });
      }
    }
  }

  // =========================
  // ✅ 分享：Google Maps 路線連結（最快 demo）
  // =========================
  String _buildGoogleMapsDirectionsUrl() {
    // ✅ 優先用座標（最準）
    if (_originLatLng != null && _destLatLng != null) {
      final origin = '${_originLatLng!.latitude},${_originLatLng!.longitude}';
      final dest = '${_destLatLng!.latitude},${_destLatLng!.longitude}';
      return 'https://www.google.com/maps/dir/?api=1'
          '&origin=${Uri.encodeComponent(origin)}'
          '&destination=${Uri.encodeComponent(dest)}'
          '&travelmode=driving';
    }

    // ❗備用：用文字
    final o = Uri.encodeComponent(_originText ?? '');
    final d = Uri.encodeComponent(_destText ?? '');
    return 'https://www.google.com/maps/dir/?api=1'
        '&origin=$o'
        '&destination=$d'
        '&travelmode=driving';
  }

  Future<void> _shareRouteLink() async {
    final url = _buildGoogleMapsDirectionsUrl();
    final msg = '我的行程路線（點開可直接用 Google Maps 導航）：\n$url';

    try {
      await Share.share(msg);
      widget.onShare(); // 你要做 log 的話保留
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('分享失敗：$e')),
      );
    }
  }

  // =========================
  // ✅ 路徑偏移監聽（200m）
  // =========================
  Future<void> _startOffRouteMonitoring() async {
    if (_routePoints.length < 2) return;

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('定位服務未開啟，無法偵測路徑偏移')),
      );
      return;
    }

    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('定位權限被拒絕，無法偵測路徑偏移')),
      );
      return;
    }

    _posSub?.cancel();
    _posSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((pos) {
      final p = LatLng(pos.latitude, pos.longitude);
      final meters = _minDistanceToPolylineMeters(p, _routePoints);

      final nowOffRoute = meters > _offRouteThresholdMeters;

      if (mounted) {
        setState(() {
          _offRoute = nowOffRoute;
          _offRouteMeters = meters;
        });
      }

      if (nowOffRoute) {
        _maybeShowOffRouteDialog(meters);
      }
    });
  }

  void _maybeShowOffRouteDialog(double meters) {
    final now = DateTime.now();
    if (_lastOffRouteDialogAt != null && now.difference(_lastOffRouteDialogAt!) < _dialogCooldown) {
      return;
    }
    _lastOffRouteDialogAt = now;

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('⚠️ 路徑偏移警示'),
        content: Text('偵測到偏離路線約 ${meters.toStringAsFixed(0)} 公尺（門檻 $_offRouteThresholdMeters 公尺）'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('我知道了'),
          ),
        ],
      ),
    );
  }

  double _minDistanceToPolylineMeters(LatLng p, List<LatLng> line) {
    if (line.length < 2) return double.infinity;

    double minD = double.infinity;
    for (int i = 0; i < line.length - 1; i++) {
      final d = _distancePointToSegmentMeters(p, line[i], line[i + 1]);
      if (d < minD) minD = d;
    }
    return minD;
  }

  double _distancePointToSegmentMeters(LatLng p, LatLng a, LatLng b) {
    final latRad = _degToRad(p.latitude);
    final metersPerDegLat = 111132.92;
    final metersPerDegLng = 111319.49 * math.cos(latRad);

    final ax = (a.longitude - p.longitude) * metersPerDegLng;
    final ay = (a.latitude - p.latitude) * metersPerDegLat;
    final bx = (b.longitude - p.longitude) * metersPerDegLng;
    final by = (b.latitude - p.latitude) * metersPerDegLat;

    final abx = bx - ax;
    final aby = by - ay;

    final apx = -ax;
    final apy = -ay;

    final abLen2 = abx * abx + aby * aby;
    if (abLen2 == 0) return math.sqrt(ax * ax + ay * ay);

    double t = (apx * abx + apy * aby) / abLen2;
    t = t.clamp(0.0, 1.0);

    final closestX = ax + abx * t;
    final closestY = ay + aby * t;

    return math.sqrt(closestX * closestX + closestY * closestY);
  }

  double _degToRad(double deg) => deg * math.pi / 180.0;

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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_originLatLng == null || _destLatLng == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  '無法定位出發地或目的地',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '出發地：${_originText ?? "未設定"}\n目的地：${_destText ?? "未設定"}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage ?? '原因不明（可能是地址無效或網路問題）',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() => _errorMessage = null);
                    _loadTripAndBuild();
                  },
                  child: const Text('重試'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('返回'),
                ),
              ],
            ),
          ),
        ),
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
              await _mapController?.moveCamera(
                CameraUpdate.newLatLngZoom(_originLatLng!, 15),
              );
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            markers: _markers,
            polylines: _polylines,
          ),

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

          if (_offRoute)
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '路徑偏移（${_offRouteMeters.toStringAsFixed(0)}m）',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                  onPressed: _shareRouteLink, // ✅ 這裡就是分享路線
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  child: const Icon(Icons.share),
                ),
                if (widget.isCreator)
                  ElevatedButton(
                    onPressed: widget.onArrived,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('已到達', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
