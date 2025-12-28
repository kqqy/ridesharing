import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';

class ActiveTripBody extends StatefulWidget {
  final VoidCallback onSOS;
  final VoidCallback onArrived;
  final VoidCallback onShare;
  final VoidCallback onChat;

  // ✅ 只有建立者或司機可以結束行程
  final bool isCreator;

  // ✅ 只傳 tripId，自己查 trips 表拿 origin/destination
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

  // ✅ 從 DB 讀到的文字地址
  String? _originText;
  String? _destText;

  // ✅ 轉成座標後
  LatLng? _originLatLng;
  LatLng? _destLatLng;

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  // ✅ 存「路線點」用來做偏移計算
  List<LatLng> _routePoints = [];

  bool _loading = true;
  bool _routeBuilt = false;

  // ✅ 路徑偏移狀態
  static const double _offRouteThresholdMeters = 200.0; // ✅ 你說門檻先 200
  bool _offRoute = false;
  double _offRouteMeters = 0;

  DateTime? _lastOffRouteDialogAt; // 避免狂跳
  static const Duration _dialogCooldown = Duration(seconds: 30);

  StreamSubscription<Position>? _posSub;

  // ⚠️ Directions 仍可能 REQUEST_DENIED（API/限制/Billing 問題），拿不到就畫直線 fallback
  static const String _googleApiKey = 'AIzaSyCQjEBcgsPbLD14kXGPcG7UUvDyd4PlPH0';

  @override
  void initState() {
    super.initState();
    _loadTripAndBuild(); // ✅ 一進來就讀 DB
  }

  @override
  void dispose() {
    _posSub?.cancel();
    super.dispose();
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

      if (origin == null ||
          origin.isEmpty ||
          destination == null ||
          destination.isEmpty) {
        throw '此行程缺少出發地或目的地（trips.origin / trips.destination）';
      }

      _originText = origin;
      _destText = destination;

      // 2) 文字地址 -> 座標
      await _geocodeEndpoints(origin, destination);

      // 3) marker
      _buildMarkers();

      // 4) 畫路線（Directions）；失敗則 fallback 直線
      await _buildRouteOnce();

      // 5) ✅ 開始監聽定位，做偏移偵測
      await _startOffRouteMonitoring();
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

    // ✅ 一進來就對準出發地（mapController 可能還沒建立，沒關係）
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

      debugPrint(
          'Directions status=${result.status} error=${result.errorMessage}');
      debugPrint('Directions points=${result.points.length}');

      if (result.points.isNotEmpty) {
        final routeLatLng = result.points
            .map((p) => LatLng(p.latitude, p.longitude))
            .toList();

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

      // ❗Directions 拿不到（例如 REQUEST_DENIED）→ 用直線先頂著（也給偏移偵測用）
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
    } catch (e) {
      debugPrint('build route failed: $e');
      // 即使失敗也給 fallback
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
  // ✅ 路徑偏移監聽（200m）
  // =========================
  Future<void> _startOffRouteMonitoring() async {
    if (_routePoints.length < 2) return;

    // 1) 檢查定位服務
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('定位服務未開啟，無法偵測路徑偏移')),
      );
      return;
    }

    // 2) 權限
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('定位權限被拒絕，無法偵測路徑偏移')),
      );
      return;
    }

    // 3) 監聽位置（你可依需求調整精度/頻率）
    _posSub?.cancel();
    _posSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // 移動超過 10m 才回報一次（降低耗電）
      ),
    ).listen((pos) {
      final p = LatLng(pos.latitude, pos.longitude);
      final meters = _minDistanceToPolylineMeters(p, _routePoints);

      final bool nowOffRoute = meters > _offRouteThresholdMeters;

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
    if (_lastOffRouteDialogAt != null &&
        now.difference(_lastOffRouteDialogAt!) < _dialogCooldown) {
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

  // 計算：點到 polyline 的最短距離（公尺）
  double _minDistanceToPolylineMeters(LatLng p, List<LatLng> line) {
    if (line.length < 2) return double.infinity;

    double minD = double.infinity;
    for (int i = 0; i < line.length - 1; i++) {
      final a = line[i];
      final b = line[i + 1];
      final d = _distancePointToSegmentMeters(p, a, b);
      if (d < minD) minD = d;
    }
    return minD;
  }

  // 點到線段距離（用平面近似投影，足夠做 200m 門檻）
  double _distancePointToSegmentMeters(LatLng p, LatLng a, LatLng b) {
    // 轉成「公尺座標」做投影（以 p 的緯度當基準）
    final latRad = _degToRad(p.latitude);
    final metersPerDegLat = 111132.92;
    final metersPerDegLng = 111319.49 * math.cos(latRad);

    double ax = (a.longitude - p.longitude) * metersPerDegLng;
    double ay = (a.latitude - p.latitude) * metersPerDegLat;
    double bx = (b.longitude - p.longitude) * metersPerDegLng;
    double by = (b.latitude - p.latitude) * metersPerDegLat;

    // p 在原點 (0,0)
    // 求原點到線段 AB 最短距離
    final abx = bx - ax;
    final aby = by - ay;

    final apx = -ax;
    final apy = -ay;

    final abLen2 = abx * abx + aby * aby;
    if (abLen2 == 0) {
      return math.sqrt(ax * ax + ay * ay);
    }

    double t = (apx * abx + apy * aby) / abLen2;
    t = t.clamp(0.0, 1.0);

    final closestX = ax + abx * t;
    final closestY = ay + aby * t;

    return math.sqrt(closestX * closestX + closestY * closestY);
  }

  double _degToRad(double deg) => deg * math.pi / 180.0;

  // =========================
  // Map 視角工具
  // =========================
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

              // ✅ 地圖 ready 後對準一次出發地
              await _mapController?.moveCamera(
                CameraUpdate.newLatLngZoom(_originLatLng!, 15),
              );
            },
            myLocationEnabled: true, // ✅ 顯示目前位置（方便測）
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            markers: _markers,
            polylines: _polylines,
          ),

          // ✅ 顯示全路線按鈕
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

          // ✅ 只有偏移才顯示紅條
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
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
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
