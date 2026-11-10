import '../services/api_client.dart';

/// Convert any exception to a user-friendly Arabic message.
String friendlyError(Object e) {
  if (e is AuthException) {
    if (e.status == 401 || e.status == 403) {
      return 'اسم المستخدم أو كلمة المرور غير صحيحة';
    }
    return 'غير مصرح — الرجاء تسجيل الدخول مرة أخرى';
  }
  if (e is HostingException) {
    final detail = e.detail;
    String msg = '';
    if (detail is Map && detail.containsKey('detail')) {
      msg = detail['detail'].toString();
    } else if (detail is Map && detail.containsKey('message')) {
      msg = detail['message'].toString();
    } else {
      msg = detail?.toString() ?? '';
    }
    if (e.status == 404) {
      if (msg.toLowerCase().contains('no server')) {
        return 'لا يوجد سيرفر مُخصّص لك حالياً';
      }
      return msg.isNotEmpty ? msg : 'العنصر غير موجود (404)';
    }
    if (e.status == 422) return msg.isNotEmpty ? msg : 'بيانات غير صحيحة';
    if (e.status == 0) return 'تعذّر الاتصال بالسيرفر';
    return msg.isNotEmpty ? msg : 'خطأ في الاتصال [${e.status}]';
  }
  return e.toString();
}
