import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

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

  /// 記錄違規並更新停權狀態
  Future<void> recordViolation({
    required String userId,
    required String tripId,
    required String violationType,
    String? reason,
  }) async {
    try {
      // 1. 嘗試記錄詳細違規資訊 (若 violations 表不存在可能失敗，但不影響計數)
      try {
        await supabase.from('violations').insert({
          'user_id': userId,
          'trip_id': tripId,
          'type': violationType,
          'reason': reason,
          'created_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        debugPrint('Warning: Failed to insert into violations table (log might be missing): $e');
      }

      // 2. 更新使用者違規計數 (這是核心邏輯)
      final data = await supabase
          .from('suspensions')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (data != null) {
        final currentCount = (data['violation_count'] as int?) ?? 0;
        await supabase
            .from('suspensions')
            .update({'violation_count': currentCount + 1})
            .eq('user_id', userId);
      } else {
        await supabase.from('suspensions').insert({
          'user_id': userId,
          'violation_count': 1,
          'is_permanent': false,
        });
      }
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