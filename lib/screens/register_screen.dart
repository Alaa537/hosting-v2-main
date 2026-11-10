import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../widgets/confetti_burst.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _u = TextEditingController();
  final _p = TextEditingController();
  final _i = TextEditingController();
  bool _busy = false;
  bool _obscure = true;
  String? _err;
  String? _pending;

  @override
  void dispose() {
    _u.dispose();
    _p.dispose();
    _i.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _err = null;
      _pending = null;
    });

    final result = await context.read<AuthProvider>().register(
      _u.text.trim(),
      _p.text,
      _i.text.trim(),
    );
    if (!mounted) return;

    setState(() => _busy = false);
    if (result == null) {
      await _showSuccessDialog();
      if (!mounted) return;
      // شاشة التسجيل واللوجين routes مؤقتة؛ ارجع للجذر كي تظهر HomeShell
      // مباشرة بدل بقاء المستخدم فوق شاشة إنشاء الحساب.
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }

    setState(() {
      if (result.startsWith('PENDING:')) {
        final parts = result.substring(8).split('|');
        final reason = parts.length > 1 ? parts[1] : 'admin_required';
        if (reason == 'ip_rate_limit') {
          _pending = 'تم رصد محاولات كثيرة من نفس الشبكة. طلبك في انتظار المراجعة.';
        } else if (reason == 'admin_required') {
          _pending = 'تم إنشاء طلبك بنجاح. في انتظار موافقة الإدارة.';
        } else {
          _pending = parts.first;
        }
      } else {
        _err = result;
      }
    });
  }

  Future<void> _showSuccessDialog() async {
    ConfettiBurst.fire(context);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
          decoration: BoxDecoration(
            color: C.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: C.primary.withValues(alpha: .55)),
            boxShadow: [
              BoxShadow(color: C.primary.withValues(alpha: .22), blurRadius: 34, spreadRadius: 2),
              BoxShadow(color: C.accent.withValues(alpha: .18), blurRadius: 50, spreadRadius: 4),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(colors: [C.primary, C.accent]),
                  boxShadow: [BoxShadow(color: C.primary.withValues(alpha: .38), blurRadius: 24)],
                ),
                child: const Icon(Icons.verified_rounded, color: Colors.black, size: 46),
              ).animate().scale(begin: const Offset(.55, .55), curve: Curves.elasticOut, duration: 700.ms),
              const SizedBox(height: 20),
              const Text('تم إنشاء حسابك بنجاح', textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
              const SizedBox(height: 9),
              const Text('حسابك جاهز. خلّينا ندخلك على لوحة التحكم فورًا.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: C.muted, fontSize: 13, height: 1.6)),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [C.primary, C.accent]),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [BoxShadow(color: C.primary.withValues(alpha: .28), blurRadius: 18)],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(dialogContext),
                    icon: const Icon(Icons.rocket_launch_rounded, color: Colors.black),
                    label: const Text('ادخل إلى حسابك الآن', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('لاحقًا', style: TextStyle(color: C.muted)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إنشاء حساب')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 28),
          child: Form(
            key: _form,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [C.primary.withValues(alpha: .13), C.accent.withValues(alpha: .10)]),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: C.primary.withValues(alpha: .25)),
                ),
                child: const Row(children: [
                  Icon(Icons.auto_awesome_rounded, color: C.primary, size: 28),
                  SizedBox(width: 14),
                  Expanded(child: Text('أنشئ حسابك وابدأ إدارة استضافتك من مكان واحد.',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, height: 1.45))),
                ]),
              ).animate().fadeIn().slideY(begin: -.08, end: 0),
              const SizedBox(height: 26),
              _field(_u, 'اسم المستخدم', Icons.person_outline, validator: (v) {
                if (v == null || v.trim().isEmpty) return 'اكتب اسم المستخدم';
                if (v.trim().length < 3) return 'اسم المستخدم 3 أحرف على الأقل';
                return null;
              }),
              const SizedBox(height: 15),
              _field(_p, 'كلمة المرور (8 أحرف على الأقل)', Icons.lock_outline,
                  obscure: _obscure,
                  suffix: IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: C.muted),
                  ), validator: (v) {
                if (v == null || v.isEmpty) return 'اكتب كلمة المرور';
                if (v.length < 8) return 'كلمة المرور 8 أحرف على الأقل';
                return null;
              }),
              const SizedBox(height: 15),
              _field(_i, 'كود الدعوة (اختياري)', Icons.vpn_key_outlined),
              if (_err != null) ...[
                const SizedBox(height: 15),
                _message(_err!, C.danger, Icons.error_outline),
              ],
              if (_pending != null) ...[
                const SizedBox(height: 15),
                _message(_pending!, C.warning, Icons.hourglass_top_rounded),
              ],
              const SizedBox(height: 25),
              SizedBox(
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _busy ? null : _submit,
                  icon: _busy
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : const Icon(Icons.person_add_alt_1_rounded),
                  label: Text(_busy ? 'جاري إنشاء الحساب…' : 'إنشاء الحساب'),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController controller, String label, IconData icon,
      {bool obscure = false, Widget? suffix, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, color: C.primary), suffixIcon: suffix),
    );
  }

  Widget _message(String text, Color color, IconData icon) => Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(color: color.withValues(alpha: .10), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withValues(alpha: .35))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 9),
          Expanded(child: Text(text, style: TextStyle(color: color, height: 1.45))),
        ]),
      );
}
