import 'package:flutter/material.dart';
import 'trip_model.dart'; // 引入資料結構

// ==========================================
//  1. UI 元件：司機首頁的主體介面 (DriverHomeBody)
// ==========================================
class DriverHomeBody extends StatelessWidget {
  final Color themeColor;
  final Trip? currentActiveTrip;
  final bool isManageMenuVisible;
  
  final List<Trip> exploreTrips;
  final Function(Trip) onJoinTrip;

  final VoidCallback onManageTap;      
  final VoidCallback onMenuClose;      
  final Function(String) onMenuSelect; 
  
  final VoidCallback onSOS;
  final VoidCallback onArrived;
  final VoidCallback onShare;
  final VoidCallback onChat;

  const DriverHomeBody({
    super.key,
    required this.themeColor,
    required this.currentActiveTrip,
    required this.isManageMenuVisible,
    required this.exploreTrips,
    required this.onJoinTrip,
    required this.onManageTap,
    required this.onMenuClose,
    required this.onMenuSelect,
    required this.onSOS,
    required this.onArrived,
    required this.onShare,
    required this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onMenuClose,
      behavior: HitTestBehavior.translucent,
      child: Stack(
        children: [
          // 1. 底層介面
          currentActiveTrip != null 
              ? DriverActiveTripView(
                  trip: currentActiveTrip!,
                  onSOS: onSOS,
                  onArrived: onArrived,
                  onShare: onShare,
                  onChat: onChat,
                ) 
              : DriverExploreView(
                  themeColor: themeColor,
                  trips: exploreTrips,
                  onJoin: onJoinTrip,
                ),      

          // 2. 左上標題：探索行程
          if (currentActiveTrip == null)
            Container(
              height: 80,
              width: double.infinity,
              color: const Color(0xFFF5F5F5).withOpacity(0.9),
              padding: const EdgeInsets.only(top: 40, left: 20),
              alignment: Alignment.topLeft,
              child: Text(
                '探索行程',
                style: TextStyle(
                  fontSize: 24, 
                  fontWeight: FontWeight.bold, 
                  color: Colors.grey[800]
                ),
              ),
            ),

          // 3. 右上按鈕：行程管理
          if (currentActiveTrip == null)
            Positioned(
              top: 35, right: 20,
              child: ElevatedButton.icon(
                onPressed: onManageTap,
                icon: const Icon(Icons.edit_calendar, size: 18),
                label: const Text('行程管理'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white, 
                  foregroundColor: Colors.green[700], 
                  elevation: 2, 
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ),

          // 4. 浮動視窗：行程管理選單
          if (isManageMenuVisible) 
            Positioned(
              top: 80, 
              right: 20, 
              child: DriverManageMenu(
                onUpcomingTap: () => onMenuSelect('即將出發行程'),
                onHistoryTap: () => onMenuSelect('歷史行程'),
              ),
            ),
        ],
      ),
    );
  }
}

// ==========================================
//  2. UI 元件：探索列表視圖 (DriverExploreView)
// ==========================================
class DriverExploreView extends StatelessWidget {
  final Color themeColor;
  final List<Trip> trips;
  final Function(Trip) onJoin;

  const DriverExploreView({
    super.key, 
    required this.themeColor, 
    required this.trips,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    if (trips.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: themeColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.drive_eta_rounded, size: 80, color: themeColor),
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

    return Container(
      color: const Color(0xFFF5F5F5),
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 90, left: 20, right: 20, bottom: 20),
        itemCount: trips.length,
        itemBuilder: (context, index) {
          return DriverExploreTripCard(
            trip: trips[index],
            onJoin: () => onJoin(trips[index]),
          );
        },
      ),
    );
  }
}

// ==========================================
//  3. UI 元件：司機探索行程卡片 (DriverExploreTripCard)
//  [修改] 統一樣式與乘客端一致，移除分隔線
// ==========================================
class DriverExploreTripCard extends StatelessWidget {
  final Trip trip;
  final VoidCallback onJoin;

  const DriverExploreTripCard({
    super.key,
    required this.trip,
    required this.onJoin,
  });

  // [修改] 統一樣式：灰色圖示
  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12), // 統一圓角
        border: Border.all(color: Colors.grey.shade300), // 統一邊框
        boxShadow: [
          BoxShadow(color: Colors.grey.shade200, blurRadius: 4, offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 資訊區 (順序與乘客端一致：出發 -> 目的 -> 時間 -> 座位)
          _buildInfoRow(Icons.my_location, '出發：${trip.origin}'),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.flag, '目的：${trip.destination}'),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.access_time, '時間：${trip.time}'),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.event_seat, '座位：${trip.seats}'),
          
          const SizedBox(height: 12),
          // [修改] 移除 Divider

          // 按鈕區 (右下角)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: onJoin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  elevation: 0,
                ),
                child: const Text('我要加入', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ==========================================
//  4. UI 元件：行程進行中畫面 (DriverActiveTripView)
// ==========================================
class DriverActiveTripView extends StatelessWidget {
  final Trip trip;
  final VoidCallback onSOS;
  final VoidCallback onArrived;
  final VoidCallback onShare;
  final VoidCallback onChat;

  const DriverActiveTripView({
    super.key,
    required this.trip,
    required this.onSOS,
    required this.onArrived,
    required this.onShare,
    required this.onChat,
  });

  @override
  Widget build(BuildContext context) {
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
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, spreadRadius: 2)
            ]
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.flag, color: Colors.red), 
                  const SizedBox(width: 8), 
                  Expanded(
                    child: Text('目的地：${trip.destination}', 
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold), 
                      overflow: TextOverflow.ellipsis
                    )
                  )
                ]
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  width: double.infinity, 
                  decoration: BoxDecoration(
                    color: Colors.grey[300], 
                    borderRadius: BorderRadius.circular(12), 
                    border: Border.all(color: Colors.grey.shade400)
                  ), 
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center, 
                      children: [
                        Icon(Icons.map, size: 50, color: Colors.grey), 
                        SizedBox(height: 10), 
                        Text('Google Map 預留區', style: TextStyle(color: Colors.grey, fontSize: 18))
                      ]
                    )
                  ),
                )
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.red), 
                      SizedBox(width: 5), 
                      Text('路徑偏移', style: TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.bold))
                    ]
                  ), 
                  ElevatedButton.icon(
                    onPressed: onSOS, 
                    icon: const Icon(Icons.sos, color: Colors.white), 
                    label: const Text('一鍵求助'), 
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red, 
                      foregroundColor: Colors.white, 
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), 
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)
                    )
                  )
                ]
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onShare,
                      icon: const Icon(Icons.share),
                      label: const Text('分享行程'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8), 
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onChat,
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
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onArrived,
                      icon: const Icon(Icons.check_circle),
                      label: const Text('已到達'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green, 
                        foregroundColor: Colors.white, 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), 
                        padding: const EdgeInsets.symmetric(vertical: 15), 
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                      ),
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
}

// ==========================================
//  5. UI 元件：行程管理選單 (DriverManageMenu)
// ==========================================
class DriverManageMenu extends StatelessWidget {
  final VoidCallback onUpcomingTap;
  final VoidCallback onHistoryTap;

  const DriverManageMenu({
    super.key,
    required this.onUpcomingTap,
    required this.onHistoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 40.0), 
          child: CustomPaint(painter: TrianglePainter(), size: const Size(20, 10))
        ),
        Container(
          width: 200,
          decoration: BoxDecoration(
            color: Colors.white, 
            borderRadius: BorderRadius.circular(12), 
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 5))
            ]
          ),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.departure_board, color: Colors.blue), 
                title: const Text('即將出發行程'), 
                onTap: onUpcomingTap,
              ), 
              const Divider(height: 1), 
              ListTile(
                leading: const Icon(Icons.history, color: Colors.grey), 
                title: const Text('歷史行程'), 
                onTap: onHistoryTap,
              )
            ]
          ),
        ),
      ],
    );
  }
}

// ==========================================
//  6. 其他通用元件
// ==========================================

class CompactTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isNumber;
  final bool readOnly;
  final VoidCallback? onTap;

  const CompactTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.isNumber = false,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      readOnly: readOnly,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: Colors.grey),
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        isDense: true,
      ),
    );
  }
}

class PassengerListItem extends StatelessWidget {
  final String name;
  final int rating;
  final VoidCallback onTapDetails;

  const PassengerListItem({
    super.key,
    required this.name,
    required this.rating,
    required this.onTapDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < rating ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 20,
              );
            }),
          ),
          SizedBox(
            height: 30,
            child: OutlinedButton(
              onPressed: onTapDetails,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('詳細', style: TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }
}

class TripCard extends StatelessWidget {
  final Trip trip;
  final Function(String) onMenuSelected;
  final VoidCallback onDepart;
  final VoidCallback onChat;

  const TripCard({
    super.key,
    required this.trip,
    required this.onMenuSelected,
    required this.onDepart,
    required this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(color: Colors.grey.shade200, blurRadius: 4, offset: const Offset(0, 2))
        ],
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
                onSelected: onMenuSelected,
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem(value: '行程備註', child: Text('行程備註')),
                  const PopupMenuItem(value: '編輯行程', child: Text('編輯行程')),
                  const PopupMenuItem(value: '乘客管理', child: Text('乘客管理')),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 32,
                child: ElevatedButton(
                  onPressed: onDepart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                  child: const Text('出發'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 32,
                child: OutlinedButton(
                  onPressed: onChat,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
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
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

class PassengerManagementContent extends StatelessWidget {
  final bool isAutoApprove;
  final ValueChanged<bool> onSwitchToggle;
  final VoidCallback onListTap;

  const PassengerManagementContent({
    super.key,
    required this.isAutoApprove,
    required this.onSwitchToggle,
    required this.onListTap,
  });

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        SwitchListTile(
          title: const Text('自動審核', style: TextStyle(fontSize: 16)),
          value: isAutoApprove,
          activeColor: Colors.blue,
          contentPadding: const EdgeInsets.symmetric(horizontal: 24),
          onChanged: onSwitchToggle,
        ),
        SimpleDialogOption(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          onPressed: onListTap,
          child: const Text('乘客清單', style: TextStyle(fontSize: 16)),
        ),
      ],
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

class SOSCountdownDialog extends StatelessWidget {
  const SOSCountdownDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Center(
        child: Text(
          '確定要撥打求救電話?',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
        ),
      ),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '倒數 2 秒', 
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.redAccent),
          ),
        ],
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('確定'),
            ),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('取消'),
            ),
          ],
        ),
      ],
    );
  }
}

class RatePassengerCard extends StatefulWidget {
  final String name;
  final int initialRating;
  final int passengerIndex;

  const RatePassengerCard({
    super.key,
    required this.name,
    required this.initialRating,
    required this.passengerIndex,
  });

  @override
  State<RatePassengerCard> createState() => _RatePassengerCardState();
}

class _RatePassengerCardState extends State<RatePassengerCard> {
  int _rating = 5; 
  bool _isPolite = true;
  bool _isPunctual = true;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating; 
  }

  Widget _buildToggleRow(String title, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 16)),
        Row(
          children: [
            Checkbox(
              value: value,
              onChanged: (newValue) => onChanged(true),
              activeColor: Colors.green,
            ),
            const Text('是'),
            const SizedBox(width: 10),
            Checkbox(
              value: !value,
              onChanged: (newValue) => onChanged(false),
              activeColor: Colors.red,
            ),
            const Text('否'),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1.0),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _rating = index + 1;
                          });
                        },
                        child: Icon(
                          index < _rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 24,
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
            const Divider(height: 20),
            _buildToggleRow('是否準時', _isPunctual, (val) => setState(() => _isPunctual = val)),
            const SizedBox(height: 10),
            _buildToggleRow('是否禮貌', _isPolite, (val) => setState(() => _isPolite = val)),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('評論', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(width: 15),
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      hintText: '輸入你的評論...',
                      isDense: true,
                      contentPadding: const EdgeInsets.all(10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PassengerDetailsContent extends StatelessWidget {
  final String name;
  final int rating;
  
  const PassengerDetailsContent({super.key, required this.name, required this.rating});

  @override
  Widget build(BuildContext context) {
    final bool hasViolation = name == '乘客 1';
    final String violationText = hasViolation ? '有惡意取消行程紀錄' : '無違規紀錄';
    final Color violationColor = hasViolation ? Colors.red : Colors.grey;

    return Container(
      padding: const EdgeInsets.all(10),
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
          const SizedBox(height: 15),
          const Text('星等：', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Row(
            children: List.generate(5, (index) => Icon(
              index < rating ? Icons.star : Icons.star_border,
              color: Colors.amber,
              size: 24,
            )),
          ),
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
    );
  }
}