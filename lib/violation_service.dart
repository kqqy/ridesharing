import 'package:supabase_flutter/supabase_flutter.dart';

class ViolationService {
  final supabase = Supabase.instance.client;

  /// 檢查司機取消行程是否違規 (< 6小時)
  bool isDriverCancelViolation(DateTime departTime) {
    final now = DateTime.now();
    final difference = departTime.difference(now).inHours;
    return difference < 6;
  }

  /// 檢查乘客退出行程是否違規 (< 1小時)
  bool isPassengerLeaveViolation(DateTime departTime) {
    final now = DateTime.now();
    final difference = departTime.difference(now).inHours;
    return difference < 1;
  }

  /// 記錄違規並更新停權狀態 (透過 Supabase RPC)
  Future<void> recordViolation({
    required String userId,
    required String tripId,
    required String violationType,
    String? reason,
  }) async {
    try {
      // 改用 rpc 呼叫後端的 handle_violation 函數
      await supabase.rpc('handle_violation', params: {
        'target_user_id': userId,
        'trip_id_param': tripId,
        'violation_type_param': violationType,
        'reason_param': reason,
      });
    } catch (e) {
      throw '記錄違規失敗: $e';
    }
  }

  /// 檢查使用者是否目前被停權
  Future<bool> isUserSuspended(String userId) async {
    final data = await supabase
        .from('suspensions')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (data == null) return false;

    final isPermanent = data['is_permanent'] as bool;
    if (isPermanent) return true;

    final suspendedUntilStr = data['suspended_until'] as String?;
    if (suspendedUntilStr == null) return false; // 只是警告

    final suspendedUntil = DateTime.parse(suspendedUntilStr);
    return DateTime.now().isBefore(suspendedUntil);
  }

  /// 取得違規狀態顯示文字
  Future<Map<String, dynamic>> getViolationStatus(String userId) async {
    final data = await supabase
        .from('suspensions')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (data == null) {
      return {'count': 0, 'status': '正常'};
    }

    final count = data['violation_count'] as int;
    final isPermanent = data['is_permanent'] as bool;
    final suspendedUntilStr = data['suspended_until'] as String?;

    String statusText = '正常';
    if (isPermanent) {
      statusText = '永久停權';
    } else if (suspendedUntilStr != null) {
      final suspendedUntil = DateTime.parse(suspendedUntilStr);
      if (DateTime.now().isBefore(suspendedUntil)) {
        // 格式化日期
        statusText = '停權至 ${suspendedUntil.year}/${suspendedUntil.month}/${suspendedUntil.day}';
      } else {
        statusText = '正常 (曾被停權)';
      }
    } else if (count > 0) {
      statusText = '警告';
    }

    return {'count': count, 'status': statusText};
  }
}