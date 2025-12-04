import 'package:flutter/material.dart';
import 'trip_model.dart'; // 引入資料結構

class DriverHome extends StatefulWidget {
  final Color themeColor;

  const DriverHome({super.key, required this.themeColor});

  @override
  State<DriverHome> createState() => _DriverHomeState();
}

class _DriverHomeState extends State<DriverHome> {
  // 狀態變數
  bool _showCreateForm = false; 
  bool _showManageMenu = false; 

  // ✨ 新增：目前正在進行的行程 (null 代表閒置)
  Trip? _currentActiveTrip;

  // 存放行程的清單
  final List<Trip> _upcomingTrips = [];

  // 輸入框控制器
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
          // 1. 底層內容 (閒置介面 or 導航介面)
          _currentActiveTrip != null 
              ? _buildActiveTripUI() // 行程進行中
              : _buildIdleUI(),      // 閒置中

          // 2. 左上按鈕 (只有閒置時顯示)
          if (_currentActiveTrip == null)
            Positioned(
              top: 20,
              left: 20,
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _showCreateForm = !_showCreateForm;
                    _showManageMenu = false;
                  });
                },
                icon: const Icon(Icons.add_location_alt),
                label: const Text('創建行程'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.green[700],
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),

          // 3. 右上按鈕 (只有閒置時顯示)
          if (_currentActiveTrip == null)
            Positioned(
              top: 20,
              right: 20,
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _showManageMenu = !_showManageMenu;
                    _showCreateForm = false;
                  });
                },
                icon: const Icon(Icons.edit_calendar),
                label: const Text('行程管理'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.green[700],
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),

          // 4. 左邊視窗
          if (_showCreateForm)
            Positioned(
              top: 70,
              left: 20,
              child: _buildCreateTripForm(),
            ),

          // 5. 右邊視窗
          if (_showManageMenu)
            Positioned(
              top: 70,
              right: 20,
              child: _buildManageMenu(),
            ),
        ],
      ),
    );
  }

  // ==========================================
  //  介面：閒置狀態 (無行程)
  // ==========================================
  Widget _buildIdleUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: widget.themeColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.drive_eta_rounded, size: 80, color: widget.themeColor),
          ),
          const SizedBox(height: 20),
          const Text(
            '目前還沒有行程',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // ==========================================
  //  介面：行程執行中 (導航/求助)
  // ==========================================
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
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 2,
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 目的地
              Row(
                children: [
                  const Icon(Icons.flag, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '目的地：${_currentActiveTrip!.destination}',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Google Map 區
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.map, size: 50, color: Colors.grey),
                        SizedBox(height: 10),
                        Text('Google Map 預留區', style: TextStyle(color: Colors.grey, fontSize: 18)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 路徑偏移 & 求助
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.red),
                      SizedBox(width: 5),
                      Text('路徑偏移', style: TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已發送求助訊號！'), backgroundColor: Colors.red));
                    },
                    icon: const Icon(Icons.sos, color: Colors.white),
                    label: const Text('一鍵求助'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // 改成 12
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 分享 & 已到達
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('分享行程連結...')));
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('分享行程'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // 改成 12
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
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
                                setState(() {
                                  _currentActiveTrip = null; // 結束行程
                                });
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('行程已結束')));
                              },
                              child: const Text('確定到達'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.check_circle),
                    label: const Text('已到達'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // 改成 12
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

  // --- Helper Widgets (浮動視窗們) ---

  Widget _buildManageMenu() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 40.0),
          child: CustomPaint(painter: TrianglePainter(), size: const Size(20, 10)),
        ),
        Container(
          width: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 5))],
          ),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.departure_board, color: Colors.blue),
                title: const Text('即將出發行程'),
                onTap: () {
                  setState(() => _showManageMenu = false);
                  _showUpcomingTripsDialog();
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.history, color: Colors.grey),
                title: const Text('歷史行程'),
                onTap: () {
                  setState(() => _showManageMenu = false);
                  _showHistoryTripsDialog();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showUpcomingTripsDialog() {
    double screenHeight = MediaQuery.of(context).size.height;
    double dialogHeight = screenHeight * 0.66;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                padding: const EdgeInsets.all(20),
                height: dialogHeight,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('即將出發行程', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(),
                    Expanded(
                      child: _upcomingTrips.isEmpty
                          ? const Center(child: Text('目前沒有即將出發的行程', style: TextStyle(fontSize: 16, color: Colors.grey)))
                          : ListView.builder(
                              itemCount: _upcomingTrips.length,
                              itemBuilder: (context, index) => _buildTripCard(_upcomingTrips[index], index, setStateDialog),
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showNoteDialog(String note) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(child: Text('備註', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                const SizedBox(height: 15),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    note.isEmpty ? '無備註內容' : note,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                    child: const Text('關閉'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditOptionsDialog(Trip trip, int index, StateSetter setStateDialog) {
    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            SimpleDialogOption(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              onPressed: () {
                Navigator.pop(context);
                _showModifyTripForm(trip, index, setStateDialog);
              },
              child: const Text('修改行程', style: TextStyle(fontSize: 16)),
            ),
            SimpleDialogOption(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              onPressed: () {
                Navigator.pop(context);
                _showDeleteConfirmDialog(index, setStateDialog);
              },
              child: const Text('取消行程', style: TextStyle(fontSize: 16, color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showModifyTripForm(Trip trip, int index, StateSetter setStateDialog) {
    final editOrigin = TextEditingController(text: trip.origin);
    final editDestination = TextEditingController(text: trip.destination);
    final editTime = TextEditingController(text: trip.time);
    final editSeats = TextEditingController(text: trip.seats);
    final editNote = TextEditingController(text: trip.note);

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('修改行程', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  _buildCompactTextField(editOrigin, '出發地', Icons.my_location),
                  const SizedBox(height: 10),
                  _buildCompactTextField(editDestination, '目的地', Icons.flag),
                  const SizedBox(height: 10),
                  _buildCompactTextField(editTime, '出發時間', Icons.access_time, readOnly: true, onTap: () async {
                     DateTime? pickedDate = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2100));
                     if (pickedDate == null) return;
                     if (!mounted) return;
                     TimeOfDay? pickedTime = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                     if (pickedTime == null) return;
                     String formattedDate = "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                     String formattedTime = "${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}";
                     editTime.text = "$formattedDate $formattedTime";
                  }),
                  const SizedBox(height: 10),
                  Row(children: [
                    const Text('可乘座位數', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(width: 15),
                    SizedBox(width: 50, child: TextField(controller: editSeats, keyboardType: TextInputType.number, textAlign: TextAlign.center, decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), isDense: true))),
                  ]),
                  const SizedBox(height: 15),
                  const Align(alignment: Alignment.centerLeft, child: Text('備註', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                  const SizedBox(height: 8),
                  TextField(controller: editNote, decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), isDense: true)),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _upcomingTrips[index] = Trip(
                            origin: editOrigin.text,
                            destination: editDestination.text,
                            time: editTime.text,
                            seats: editSeats.text,
                            note: editNote.text,
                          );
                        });
                        setStateDialog(() {});
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('行程已更新'), backgroundColor: Colors.green));
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                      child: const Text('儲存修改'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDeleteConfirmDialog(int index, StateSetter setStateDialog) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('確定要取消此行程？'),
          content: const Text('取消後將無法復原，請確認。'),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _upcomingTrips.removeAt(index);
                });
                setStateDialog(() {});
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('行程已取消'), backgroundColor: Colors.grey));
              },
              child: const Text('確定', style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('我再想想', style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );
  }

  void _showHistoryTripsDialog() {
    double screenHeight = MediaQuery.of(context).size.height;
    double dialogHeight = screenHeight * 0.66;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(20),
            height: dialogHeight,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('歷史行程', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                const Expanded(
                  child: Center(child: Text('目前沒有歷史行程', style: TextStyle(fontSize: 16, color: Colors.grey))),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPassengerManagementDialog(BuildContext context) {
    bool isAutoApprove = false;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return SimpleDialog(
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                SwitchListTile(
                  title: const Text('自動審核', style: TextStyle(fontSize: 16)),
                  value: isAutoApprove,
                  activeColor: Colors.blue,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  onChanged: (value) {
                    setStateDialog(() {
                      isAutoApprove = value;
                    });
                  },
                ),
                SimpleDialogOption(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  onPressed: () {
                    Navigator.pop(context);
                    _showPassengerListDialog();
                  },
                  child: const Text('乘客清單', style: TextStyle(fontSize: 16)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showPassengerListDialog() {
    double screenHeight = MediaQuery.of(context).size.height;
    double dialogHeight = screenHeight * 0.66;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(20),
            height: dialogHeight,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('乘客清單', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                const Expanded(
                  child: Center(
                    child: Text('目前還沒有乘客', style: TextStyle(fontSize: 16, color: Colors.grey)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTripCard(Trip trip, int index, StateSetter setStateDialog) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(Icons.my_location, '出發：${trip.origin}'),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.flag, '目的：${trip.destination}'),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.access_time, '時間：${trip.time}'),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.event_seat, '剩餘座位：${trip.seats}'),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.more_vert, color: Colors.grey),
                onSelected: (value) {
                  if (value == '行程備註') {
                    _showNoteDialog(trip.note);
                  } else if (value == '編輯行程') {
                    _showEditOptionsDialog(trip, index, setStateDialog);
                  } else if (value == '乘客管理') {
                    _showPassengerManagementDialog(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('點擊了：$value')));
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(value: '行程備註', child: Text('行程備註')),
                  const PopupMenuItem<String>(value: '編輯行程', child: Text('編輯行程')),
                  const PopupMenuItem<String>(value: '乘客管理', child: Text('乘客管理')),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 32,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // 關閉清單視窗
                    setState(() {
                      _currentActiveTrip = trip; // 開始行程
                    });
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('行程開始！祝您一路順風'), backgroundColor: Colors.green));
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12), textStyle: const TextStyle(fontSize: 12)),
                  child: const Text('出發'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 32,
                child: OutlinedButton(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('進入聊天室'))),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12), textStyle: const TextStyle(fontSize: 12)),
                  child: const Text('聊天室'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  Widget _buildCreateTripForm() {
    double screenWidth = MediaQuery.of(context).size.width;
    double formWidth = screenWidth - 40;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 40.0),
          child: CustomPaint(painter: TrianglePainter(), size: const Size(20, 10)),
        ),
        Container(
          width: formWidth,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 5))]),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 5),
              _buildCompactTextField(_originController, '出發地', Icons.my_location),
              const SizedBox(height: 10),
              _buildCompactTextField(_destinationController, '目的地', Icons.flag),
              const SizedBox(height: 10),
              _buildCompactTextField(_timeController, '出發時間', Icons.access_time, readOnly: true, onTap: () async {
                 DateTime? pickedDate = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2100));
                 if (pickedDate == null) return;
                 if (!mounted) return;
                 TimeOfDay? pickedTime = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                 if (pickedTime == null) return;
                 String formattedDate = "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                 String formattedTime = "${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}";
                 setState(() { _timeController.text = "$formattedDate $formattedTime"; });
              }),
              const SizedBox(height: 15),
              Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                const Text('可乘座位數', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(width: 15),
                SizedBox(width: 50, child: TextField(controller: _seatsController, keyboardType: TextInputType.number, textAlign: TextAlign.center, decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), isDense: true))),
              ]),
              const SizedBox(height: 15),
              const Text('備註', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              TextField(controller: _noteController, decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), isDense: true)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_originController.text.isNotEmpty && _destinationController.text.isNotEmpty) {
                      setState(() {
                        _upcomingTrips.add(Trip(
                          origin: _originController.text,
                          destination: _destinationController.text,
                          time: _timeController.text,
                          seats: _seatsController.text,
                          note: _noteController.text,
                        ));
                        _showCreateForm = false;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('行程創建成功！請至行程管理查看'), backgroundColor: Colors.green));
                      _originController.clear();
                      _destinationController.clear();
                      _timeController.clear();
                      _seatsController.clear();
                      _noteController.clear();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('請填寫完整資訊'), backgroundColor: Colors.red));
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green[600], foregroundColor: Colors.white),
                  child: const Text('創建行程'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactTextField(TextEditingController controller, String label, IconData icon, {bool isNumber = false, bool readOnly = false, VoidCallback? onTap}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      readOnly: readOnly,
      onTap: onTap,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, size: 20, color: Colors.grey), contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), isDense: true),
    );
  }
}

class TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(size.width / 2, 0); path.lineTo(0, size.height); path.lineTo(size.width, size.height); path.close();
    canvas.drawShadow(path, Colors.black.withOpacity(0.1), 2.0, false);
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}