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
  bool _showManageMenu = false; 
  Trip? _currentActiveTrip; 
  final List<Trip> _upcomingTrips = []; 
  bool _isAutoApprove = false; 

  // 探索行程假資料
  final List<Trip> _exploreTrips = [
    Trip(
      origin: '台中市政府', 
      destination: '勤美誠品', 
      time: '12-08 14:00', 
      seats: '2/4', 
      note: '徵求共乘'
    ),
    Trip(
      origin: '逢甲夜市', 
      destination: '高鐵台中站', 
      time: '12-08 18:30', 
      seats: '3/4', 
      note: '行李箱可放'
    ),
    Trip(
      origin: '新光三越', 
      destination: '台中火車站', 
      time: '12-09 10:00', 
      seats: '1/4', 
      note: '準時出發'
    ),
  ];

  void _closeAllDialogs() {
    if (_showManageMenu) {
      setState(() {
        _showManageMenu = false;
      });
    }
  }

  // [修改] 處理加入行程 (靜默模式，不跳出視窗)
  void _handleJoinTrip(Trip trip) {
    // 直接執行加入邏輯
    print('已加入行程: ${trip.destination} (靜默模式)');
  }

  // 處理選單項目選擇
  void _handleMenuSelection(String value) {
    setState(() => _showManageMenu = false); 
    
    if (value == '即將出發行程') {
      _showUpcomingTripsDialog();
    } else if (value == '歷史行程') {
      _showHistoryTripsDialog();
    }
  }

  // 處理 SOS
  void _handleSOS() {
    showDialog(context: context, builder: (context) => const SOSCountdownDialog());
  }

  // 處理到達
  void _handleArrived() {
    showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        title: const Text('確認到達？'), 
        content: const Text('這將結束目前的行程。'), 
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')), 
          TextButton(
            onPressed: () { 
              Navigator.pop(context); 
              setState(() { _currentActiveTrip = null; }); 
              _showRatePassengerDialog(); 
            }, 
            child: const Text('確定到達')
          )
        ]
      )
    );
  }

  // 處理聊天室
  void _handleChat() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatPage()));
  }

  @override
  Widget build(BuildContext context) {
    return DriverHomeBody(
      themeColor: widget.themeColor,
      currentActiveTrip: _currentActiveTrip,
      isManageMenuVisible: _showManageMenu,
      exploreTrips: _exploreTrips, 
      onJoinTrip: _handleJoinTrip, // 傳遞修改後的靜默函式
      onManageTap: () => setState(() { _showManageMenu = !_showManageMenu; }),
      onMenuClose: _closeAllDialogs,
      onMenuSelect: _handleMenuSelection,
      onSOS: _handleSOS,
      onArrived: _handleArrived,
      onShare: () {}, 
      onChat: _handleChat,
    );
  }

  // ==========================================
  //  彈出視窗邏輯 (Dialogs)
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
                            onChat: _handleChat,
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
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: PassengerDetailsContent(name: name, rating: rating),
        );
      },
    );
  }
}