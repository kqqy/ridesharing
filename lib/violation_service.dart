import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class ViolationService {
  final supabase = Supabase.instance.client;

  /// 檢查司機取消行程是否違規 (< 6小時)
  bool isDriverCancelViolation(DateTime departTime) {
    final now = DateTime.now();
    // 統一轉為 Local 進行比較，並使用分鐘計算以提高精確度
    final departLocal = departTime.toLocal();
    final differenceInMinutes = departLocal.difference(now).inMinutes;

    debugPrint('👮 違規檢查 (司機): 出發=$departLocal, 現在=$now, 剩餘=${differenceInMinutes}分');

    // 6 小時 = 360 分鐘
    return differenceInMinutes < 360;
  }

  /// 檢查乘客退出行程是否違規 (< 1小時)
  bool isPassengerLeaveViolation(DateTime departTime) {
    final now = DateTime.now();
    final departLocal = departTime.toLocal();
    final differenceInMinutes = departLocal.difference(now).inMinutes;

    debugPrint('👮 違規檢查 (乘客): 出發=$departLocal, 現在=$now, 剩餘=${differenceInMinutes}分');

    // 1 小時 = 60 分鐘
    return differenceInMinutes < 60;
  }

  /// 預測下一次違規的後果
  Future<String> predictConsequence(String userId) async {
    final data = await supabase
        .from('suspensions')
        .select('violation_count')
        .eq('user_id', userId)
        .maybeSingle();

    final currentCount = (data?['violation_count'] as int?) ?? 0;
    final nextCount = currentCount + 1;

    if (nextCount == 1) return '警告信一支';
    if (nextCount == 2) return '停權 2 週';
    if (nextCount == 3) return '停權 3 週';
    return '永久停權'; // >= 4
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
        final newCount = currentCount + 1;
        
        DateTime? suspendedUntil;
        bool isPermanent = false;

        // 實作停權規則
        if (newCount == 1) {
          // 第 1 次：警告 (不設定 suspended_until)
        } else if (newCount == 2) {
          // 第 2 次：停權 2 週
          suspendedUntil = DateTime.now().add(const Duration(days: 14));
        } else if (newCount == 3) {
          // 第 3 次：停權 3 週
          suspendedUntil = DateTime.now().add(const Duration(days: 21));
        } else if (newCount >= 4) {
          // 第 4 次：永久停權
          isPermanent = true;
          // 設定一個極遠的日期作為備用
          suspendedUntil = DateTime(9999, 12, 31);
        }

        await supabase
            .from('suspensions')
            .update({
              'violation_count': newCount,
              'suspended_until': suspendedUntil?.toIso8601String(),
              'is_permanent': isPermanent,
            })
            .eq('user_id', userId);
      } else {
        // 第一次違規建立記錄 (第 1 次：警告)
        await supabase.from('suspensions').insert({
          'user_id': userId,
          'violation_count': 1,
          'is_permanent': false,
          'suspended_until': null,
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