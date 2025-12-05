import 'package:flutter/material.dart';
import 'trip_model.dart'; 
import 'driver_widgets.dart'; // 引入 UI 元件
import 'chat_page.dart'; // 引入聊天室頁面

class DriverHome extends StatefulWidget {
  final Color themeColor;

  const DriverHome({super.key, required this.themeColor});

  @override
  State<DriverHome> createState() => _DriverHomeState();
}

class _DriverHomeState extends State<DriverHome> {
  // ==========================================
  //  1. 狀態變數
  // ==========================================
  bool _showCreateForm = false; 
  bool _showManageMenu = false; 
  Trip? _currentActiveTrip; 
  final List<Trip> _upcomingTrips = []; 
  bool _isAutoApprove = false; // 自動審核狀態

  // 控制器
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _seatsController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  void _closeAllDialogs() {
    if (_showCreateForm || _showManageMenu) {
      setState(() {
        _showCreateForm = false;
        _showManageMenu = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _closeAllDialogs,
      behavior: HitTestBehavior.translucent,
      child: Stack(
        children: [
          // 底層介面
          _currentActiveTrip != null ? _buildActiveTripUI() : _buildIdleUI(),      

          // 左上按鈕
          if (_currentActiveTrip == null)
            Positioned(
              top: 20, left: 20,
              child: ElevatedButton.icon(
                onPressed: () => setState(() { _showCreateForm = !_showCreateForm; _showManageMenu = false; }),
                icon: const Icon(Icons.add_location_alt),
                label: const Text('創建行程'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.green[700], elevation: 2, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
              ),
            ),

          // 右上按鈕
          if (_currentActiveTrip == null)
            Positioned(
              top: 20, right: 20,
              child: ElevatedButton.icon(
                onPressed: () => setState(() { _showManageMenu = !_showManageMenu; _showCreateForm = false; }),
                icon: const Icon(Icons.edit_calendar),
                label: const Text('行程管理'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.green[700], elevation: 2, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
              ),
            ),

          // 浮動視窗
          if (_showCreateForm) Positioned(top: 70, left: 20, child: _buildCreateTripForm()),
          if (_showManageMenu) Positioned(top: 70, right: 20, child: _buildManageMenu()),
        ],
      ),
    );
  }

  // ==========================================
  //  3. 介面組件
  // ==========================================

  Widget _buildIdleUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(color: widget.themeColor.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(Icons.drive_eta_rounded, size: 80, color: widget.themeColor),
          ),
          const SizedBox(height: 20),
          const Text('目前還沒有行程', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildActiveTripUI() {
    if (_currentActiveTrip == null) return Container();
    return Container(
      color: Colors.grey[100],
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.75,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, spreadRadius: 2)]),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [const Icon(Icons.flag, color: Colors.red), const SizedBox(width: 8), Expanded(child: Text('目的地：${_currentActiveTrip!.destination}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis))]),
              const SizedBox(height: 16),
              Expanded(child: Container(width: double.infinity, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade400)), child: const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.map, size: 50, color: Colors.grey), SizedBox(height: 10), Text('Google Map 預留區', style: TextStyle(color: Colors.grey, fontSize: 18))])),)),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Row(children: [Icon(Icons.warning_amber_rounded, color: Colors.red), SizedBox(width: 5), Text('路徑偏移', style: TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.bold))]), ElevatedButton.icon(onPressed: () => showDialog(context: context, builder: (context) => const SOSCountdownDialog()), icon: const Icon(Icons.sos, color: Colors.white), label: const Text('一鍵求助'), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)))]),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 1. 分享行程
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.share),
                      label: const Text('分享行程'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8), 
                  // 2. 聊天室
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatPage()));
                      },
                      icon: const Icon(Icons.message, color: Colors.blue),
                      label: const Text('聊天室'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        side: const BorderSide(color: Colors.blue),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8), 
                  // 3. 已到達
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        showDialog(context: context, builder: (context) => AlertDialog(title: const Text('確認到達？'), content: const Text('這將結束目前的行程。'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')), TextButton(onPressed: () { Navigator.pop(context); setState(() { _currentActiveTrip = null; }); _showRatePassengerDialog(); }, child: const Text('確定到達'))]));
                    },
                      icon: const Icon(Icons.check_circle),
                      label: const Text('已到達'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 15), textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  //  4. 浮動視窗與選單
  // ==========================================

  Widget _buildManageMenu() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(padding: const EdgeInsets.only(right: 40.0), child: CustomPaint(painter: TrianglePainter(), size: const Size(20, 10))),
        Container(
          width: 200,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 5))]),
          child: Column(children: [ListTile(leading: const Icon(Icons.departure_board, color: Colors.blue), title: const Text('即將出發行程'), onTap: () { setState(() => _showManageMenu = false); _showUpcomingTripsDialog(); }), const Divider(height: 1), ListTile(leading: const Icon(Icons.history, color: Colors.grey), title: const Text('歷史行程'), onTap: () { setState(() => _showManageMenu = false); _showHistoryTripsDialog(); })]),
        ),
      ],
    );
  }

  Widget _buildCreateTripForm() {
    double screenWidth = MediaQuery.of(context).size.width;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.only(left: 40.0), child: CustomPaint(painter: TrianglePainter(), size: const Size(20, 10))),
        Container(
          width: screenWidth - 40,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 5))]),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 5),
              CompactTextField(controller: _originController, label: '出發地', icon: Icons.my_location),
              const SizedBox(height: 10),
              CompactTextField(controller: _destinationController, label: '目的地', icon: Icons.flag),
              const SizedBox(height: 10),
              CompactTextField(controller: _timeController, label: '出發時間', icon: Icons.access_time, readOnly: true, onTap: () async { DateTime? pickedDate = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2100)); if (pickedDate == null) return; if (!mounted) return; TimeOfDay? pickedTime = await showTimePicker(context: context, initialTime: TimeOfDay.now()); if (pickedTime == null) return; setState(() { _timeController.text = "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')} ${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}"; }); }),
              const SizedBox(height: 15),
              Row(crossAxisAlignment: CrossAxisAlignment.center, children: [const Text('可乘座位數', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), const SizedBox(width: 15), SizedBox(width: 50, child: TextField(controller: _seatsController, keyboardType: TextInputType.number, textAlign: TextAlign.center, decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), isDense: true)))]),
              const SizedBox(height: 15),
              const Text('備註', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              TextField(controller: _noteController, decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), isDense: true)),
              const SizedBox(height: 20),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () {
                  setState(() {
                    _upcomingTrips.add(Trip(origin: _originController.text, destination: _destinationController.text, time: _timeController.text, seats: _seatsController.text, note: _noteController.text));
                    _showCreateForm = false;
                  });
                  _originController.clear(); _destinationController.clear(); _timeController.clear(); _seatsController.clear(); _noteController.clear();
              }, style: ElevatedButton.styleFrom(backgroundColor: Colors.green[600], foregroundColor: Colors.white), child: const Text('創建行程'))),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  //  5. 彈出視窗邏輯 (Dialogs)
  // ==========================================

  void _showUpcomingTripsDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(20),
            height: MediaQuery.of(context).size.height * 0.66,
            child: Column(
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('即將出發行程', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.pop(context))]),
                const Divider(),
                Expanded(
                  child: _upcomingTrips.isEmpty
                      ? const Center(child: Text('目前沒有即將出發的行程', style: TextStyle(fontSize: 16, color: Colors.grey)))
                      : ListView.builder(
                          itemCount: _upcomingTrips.length,
                          itemBuilder: (context, index) => TripCard(
                            trip: _upcomingTrips[index],
                            onDepart: () => _showPassengerManifestDialog(_upcomingTrips[index]),
                            onMenuSelected: (value) {
                              if (value == '行程備註') _showNoteDialog(_upcomingTrips[index].note);
                              else if (value == '編輯行程') _showEditOptionsDialog(_upcomingTrips[index], index, setStateDialog);
                              else if (value == '乘客管理') _showPassengerManagementDialog(context);
                            },
                            onChat: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatPage()));
                            },
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRatePassengerDialog() {
    final List<Map<String, dynamic>> passengers = [
      {'name': '乘客 1', 'rating': 4}, 
      {'name': '乘客 2', 'rating': 5}, 
      {'name': '乘客 3', 'rating': 3}
    ];

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(20),
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Center(
                child: Text('評價乘客', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ),
              const Divider(),

              Expanded(
                child: ListView.builder(
                  itemCount: passengers.length,
                  itemBuilder: (context, index) {
                    final p = passengers[index];
                    return StatefulBuilder(
                      builder: (context, setStateCard) {
                        return RatePassengerCard(
                          name: p['name'], 
                          initialRating: p['rating'], 
                          passengerIndex: index,
                        );
                      }
                    );
                  },
                ),
              ),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('完成評價', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHistoryTripsDialog() { showDialog(context: context, builder: (context) => Dialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), child: Container(padding: const EdgeInsets.all(20), height: MediaQuery.of(context).size.height * 0.66, child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('歷史行程', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.pop(context))]), const Divider(), const Expanded(child: Center(child: Text('目前沒有歷史行程', style: TextStyle(fontSize: 16, color: Colors.grey))))])))); }
  void _showNoteDialog(String note) { showDialog(context: context, builder: (context) => Dialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), child: Container(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [const Center(child: Text('備註', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))), const SizedBox(height: 15), Container(width: double.infinity, padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)), child: Text(note.isEmpty ? '無備註內容' : note, style: const TextStyle(fontSize: 16, height: 1.5))), const SizedBox(height: 20), SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white), child: const Text('關閉')))])))); }
  void _showEditOptionsDialog(Trip trip, int index, StateSetter setStateDialog) { showDialog(context: context, builder: (context) => SimpleDialog(contentPadding: const EdgeInsets.symmetric(vertical: 8), children: [SimpleDialogOption(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24), onPressed: () { Navigator.pop(context); _showModifyTripForm(trip, index, setStateDialog); }, child: const Text('修改行程', style: TextStyle(fontSize: 16))), SimpleDialogOption(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24), onPressed: () { Navigator.pop(context); _showDeleteConfirmDialog(index, setStateDialog); }, child: const Text('取消行程', style: TextStyle(fontSize: 16, color: Colors.red, fontWeight: FontWeight.bold)))])); }
  void _showDeleteConfirmDialog(int index, StateSetter setStateDialog) { showDialog(context: context, builder: (context) => AlertDialog(title: const Text('確定要取消此行程？'), content: const Text('取消後將無法復原，請確認。'), actions: [TextButton(onPressed: () { Navigator.pop(context); }, child: const Text('確定', style: TextStyle(color: Colors.red))), TextButton(onPressed: () => Navigator.pop(context), child: const Text('我再想想', style: TextStyle(color: Colors.blue)))])); }
  void _showPassengerManagementDialog(BuildContext context) { 
    bool isAutoApprove = false; 
    showDialog(
      context: context, 
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), 
          child: Padding(
            padding: const EdgeInsets.all(20.0), 
            child: Column(
              mainAxisSize: MainAxisSize.min, 
              children: [
                const Center(child: Text('乘客管理', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))), 
                const SizedBox(height: 10), 
                const Divider(), 
                
                PassengerManagementContent(
                  isAutoApprove: isAutoApprove,
                  onSwitchToggle: (value) { 
                    setStateDialog(() {
                      isAutoApprove = value; 
                    });
                    if (value == false) {
                      Navigator.pop(context); 
                      _showNewRequestDialog(); 
                    }
                  },
                  onListTap: () { 
                    Navigator.pop(context); 
                    _showPassengerListDialog(); 
                  },
                )
              ]
            )
          )
        )
      )
    ); 
  }
  void _showPassengerListDialog() { final List<Map<String, dynamic>> passengers = [{'name': '乘客 1', 'rating': 4}, {'name': '乘客 2', 'rating': 5}, {'name': '乘客 3', 'rating': 3}]; showDialog(context: context, builder: (context) => Dialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), child: Container(padding: const EdgeInsets.all(20), height: MediaQuery.of(context).size.height * 0.66, child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('乘客清單', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.pop(context))]), const Divider(), Expanded(child: ListView.builder(itemCount: passengers.length, itemBuilder: (context, index) { final p = passengers[index]; return PassengerListItem(name: p['name'], rating: p['rating'], onTapDetails: () { Navigator.pop(context); _showPassengerDetailsDialog(p['name'], p['rating']); }); }))])))); }
  void _showPassengerManifestDialog(Trip trip) { List<String> passengers = ['乘客 A', '乘客 B']; Map<String, int> passengerStatus = { for (var p in passengers) p : 0 }; showDialog(context: context, builder: (context) => StatefulBuilder(builder: (context, setStateDialog) => Dialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), child: Padding(padding: const EdgeInsets.all(20.0), child: Column(mainAxisSize: MainAxisSize.min, children: [const Text('目前乘客', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), const SizedBox(height: 10), const Divider(), const SizedBox(height: 10), Container(constraints: const BoxConstraints(maxHeight: 250), child: ListView(shrinkWrap: true, children: passengers.map((p) => Padding(padding: const EdgeInsets.symmetric(vertical: 10.0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(p, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), Row(children: [InkWell(onTap: () { setStateDialog(() { passengerStatus[p] = 1; }); }, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: passengerStatus[p] == 1 ? Colors.green : Colors.grey[200], borderRadius: BorderRadius.circular(8)), child: Text('已上車', style: TextStyle(color: passengerStatus[p] == 1 ? Colors.white : Colors.black, fontWeight: FontWeight.bold)))), const SizedBox(width: 10), InkWell(onTap: () { setStateDialog(() { passengerStatus[p] = 2; }); }, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: passengerStatus[p] == 2 ? Colors.red : Colors.grey[200], borderRadius: BorderRadius.circular(8)), child: Text('未出現', style: TextStyle(color: passengerStatus[p] == 2 ? Colors.white : Colors.black, fontWeight: FontWeight.bold))))])]))).toList())), const SizedBox(height: 20), Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('取消')), ElevatedButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); setState(() { _currentActiveTrip = trip; }); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white), child: const Text('確認出發'))])]))))); }
  void _showModifyTripForm(Trip trip, int index, StateSetter setStateDialog) { final editOrigin = TextEditingController(text: trip.origin); final editDestination = TextEditingController(text: trip.destination); final editTime = TextEditingController(text: trip.time); final editSeats = TextEditingController(text: trip.seats); final editNote = TextEditingController(text: trip.note); showDialog(context: context, builder: (context) => Dialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), child: Container(padding: const EdgeInsets.all(20), child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [const Text('修改行程', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 15), CompactTextField(controller: editOrigin, label: '出發地', icon: Icons.my_location), const SizedBox(height: 10), CompactTextField(controller: editDestination, label: '目的地', icon: Icons.flag), const SizedBox(height: 10), CompactTextField(controller: editTime, label: '出發時間', icon: Icons.access_time, readOnly: true, onTap: () async { DateTime? pickedDate = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2100)); if (pickedDate == null) return; if (!mounted) return; TimeOfDay? pickedTime = await showTimePicker(context: context, initialTime: TimeOfDay.now()); if (pickedTime == null) return; editTime.text = "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}"; }), const SizedBox(height: 10), Row(children: [const Text('可乘座位數', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(width: 15), SizedBox(width: 50, child: TextField(controller: editSeats, keyboardType: TextInputType.number, textAlign: TextAlign.center, decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), isDense: true)))]), const SizedBox(height: 15), const Align(alignment: Alignment.centerLeft, child: Text('備註', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))), const SizedBox(height: 8), TextField(controller: editNote, decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), isDense: true)), const SizedBox(height: 20), SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () { Navigator.pop(context); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white), child: const Text('儲存修改')))]))))); }
  
  void _showNewRequestDialog() {
    showDialog(
      context: context,
      builder: (context) {
        // 假資料乘客
        const String passengerName = '新乘客';
        const int rating = 4;
        
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('有新乘客申請搭乘', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text('乘客 $passengerName (評分 $rating 星) 申請加入您的行程。'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('拒絕', style: TextStyle(color: Colors.red))),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // 關閉此視窗
                _showPassengerDetailsDialog(passengerName, rating); // 開啟詳細資料
              },
              child: const Text('詳細資料'),
            ),
            ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('同意')),
          ],
        );
      },
    );
  }
  
  void _showPassengerDetailsDialog(String name, int rating) {
    showDialog(
      context: context,
      builder: (context) {
        final bool hasViolation = name == '乘客 1';
        final String violationText = hasViolation ? '有惡意取消行程紀錄' : '無違規紀錄';
        final Color violationColor = hasViolation ? Colors.red : Colors.grey;

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('$name 的詳細資料', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                
                // 1. 星等
                const SizedBox(height: 15),
                const Text('星等：', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Row(
                  children: List.generate(5, (index) => Icon(
                    index < rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 24,
                  )),
                ),
                
                // 2. 違規紀錄
                const SizedBox(height: 20),
                const Text('違規紀錄：', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  violationText,
                  style: TextStyle(color: violationColor, fontSize: 16),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }
}