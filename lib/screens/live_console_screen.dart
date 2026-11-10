import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';

class LiveConsoleScreen extends StatefulWidget {
  const LiveConsoleScreen({super.key});
  @override
  State<LiveConsoleScreen> createState() => _LiveConsoleScreenState();
}

class _LiveConsoleScreenState extends State<LiveConsoleScreen>
    with TickerProviderStateMixin {
  final List<_LogLine> _lines = [];
  final _scroll = ScrollController();
  final _cmd = TextEditingController();
  final _cmdFocus = FocusNode();
  WebSocket? _ws;
  bool _streaming = false;
  bool _autoScroll = true;
  bool _showCmd = false;
  static const int _maxLines = 1000;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.35, end: 1.0).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _ws?.close();
    _scroll.dispose();
    _cmd.dispose();
    _cmdFocus.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (_streaming) return;
    setState(() => _streaming = true);
    try {
      final api = context.read<AuthProvider>().api!;
      final ws = await api.connectEvents();
      _ws = ws;
      ws.listen((data) {
        try {
          final payload = data is String
              ? data
              : data is List<int>
                  ? utf8.decode(data, allowMalformed: true)
                  : null;
          if (payload == null) return;
          final ev = jsonDecode(payload);
          if (ev is! Map) return;
          final t = ev['type'];
          if (t == 'log') {
            final line = (ev['data'] ?? '').toString().trimRight();
            if (line.isNotEmpty) _add(line);
          } else if (t == 'status') {
            _add('── status: ${ev['data']} ──', color: C.accent, isMeta: true);
          }
        } catch (e) {
          _add('! invalid stream event: $e', color: C.warning, isMeta: true);
        }
      },
          onDone: () { if (mounted) setState(() => _streaming = false); },
          onError: (e) {
            if (mounted) {
              setState(() => _streaming = false);
              _add('stream error: $e', color: C.danger, isMeta: true);
            }
          });
    } catch (e) {
      if (mounted) {
        setState(() => _streaming = false);
        _add('failed: $e', color: C.danger, isMeta: true);
      }
    }
  }

  void _stop() {
    _ws?.close();
    _ws = null;
    setState(() => _streaming = false);
  }

  void _add(String text, {Color? color, bool isMeta = false}) {
    if (!mounted) return;
    setState(() {
      _lines.add(_LogLine(text, color ?? _logColor(text), isMeta: isMeta));
      if (_lines.length > _maxLines) _lines.removeAt(0);
    });
    if (_autoScroll) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(_scroll.position.maxScrollExtent,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut);
        }
      });
    }
  }

  Color _logColor(String line) {
    final u = line.toUpperCase();
    if (u.contains('TRACEBACK') || u.contains('CRITICAL') ||
        u.contains('FATAL') || u.contains('EXCEPTION')) {
      return const Color(0xFFFF5252);
    }
    if (u.contains('ERROR') || u.contains('FAIL') || u.contains('✖')) {
      return const Color(0xFFFF7B7B);
    }
    if (u.contains('WARN') || u.contains('⚠')) {
      return const Color(0xFFFFD75F);
    }
    if (u.contains('INFO') || u.contains('ℹ')) {
      return const Color(0xFF6FC3FF);
    }
    if (u.contains('DEBUG') || u.contains('[TRACE]')) {
      return const Color(0xFF9A9AAE);
    }
    if (u.contains('SUCCESS') || u.contains('OK') ||
        u.contains('STARTED') || u.contains('✓') || u.contains('✔')) {
      return const Color(0xFF7BFFA1);
    }
    if (line.startsWith('>')) return C.primary;
    if (line.startsWith('─')) return C.accent;
    return const Color(0xFFE8E8F0);
  }

  Future<void> _send() async {
    final c = _cmd.text.trim();
    if (c.isEmpty) return;
    _cmd.clear();
    _add('> $c', color: C.primary, isMeta: true);
    try {
      final ws = _ws;
      if (ws != null && _streaming) {
        ws.add(jsonEncode({'action': 'command', 'command': c}));
      } else {
        await context.read<AuthProvider>().api!.appCommand(c);
      }
    } catch (e) {
      _add('! send failed: $e', color: C.danger, isMeta: true);
    }
  }

  void _copy() {
    Clipboard.setData(
        ClipboardData(text: _lines.map((l) => l.text).join('\n')));
    _toast('تم نسخ السجل');
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w700)),
      duration: const Duration(seconds: 1),
      behavior: SnackBarBehavior.floating,
      backgroundColor: C.surfaceHi,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _clear() {
    setState(() => _lines.clear());
    _toast('تم المسح');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070710),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [C.primary, C.accent]),
              borderRadius: BorderRadius.circular(9),
              boxShadow: [
                BoxShadow(
                    color: C.primary.withValues(alpha: .55),
                    blurRadius: 14,
                    spreadRadius: 1),
              ],
            ),
            child: const Icon(Icons.terminal, color: Colors.black, size: 15),
          ),
          const SizedBox(width: 10),
          ShaderMask(
            shaderCallback: (r) => const LinearGradient(
                colors: [C.primary, C.accent]).createShader(r),
            child: const Text('LOG BOT',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3.5,
                    color: Colors.white)),
          ),
        ]),
        actions: [
          _glowBtn(
            onTap: _streaming ? _stop : _start,
            icon: _streaming ? Icons.stop_circle : Icons.play_circle_fill,
            color: _streaming ? C.danger : C.success,
          ),
          _glowBtn(
            onTap: () => setState(() => _autoScroll = !_autoScroll),
            icon: _autoScroll
                ? Icons.vertical_align_bottom
                : Icons.pause_circle,
            color: _autoScroll ? C.success : C.muted,
          ),
          _glowBtn(
              onTap: _copy, icon: Icons.copy_rounded, color: C.primary),
          _glowBtn(
              onTap: _clear,
              icon: Icons.delete_sweep_outlined,
              color: C.muted),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(child: Column(children: [
        // Status header with pulse
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, __) => Container(
            margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                (_streaming ? C.success : C.muted).withValues(alpha: .18),
                Colors.transparent,
              ]),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: (_streaming ? C.success : C.muted)
                      .withValues(alpha: .30 + .35 * _pulseAnim.value)),
              boxShadow: _streaming
                  ? [
                      BoxShadow(
                          color: C.success
                              .withValues(alpha: .25 * _pulseAnim.value),
                          blurRadius: 18,
                          spreadRadius: 1),
                    ]
                  : [],
            ),
            child: Row(children: [
              Stack(children: [
                Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                        color: (_streaming ? C.success : C.muted)
                            .withValues(alpha: .25 * _pulseAnim.value),
                        shape: BoxShape.circle)),
                Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                        color: _streaming ? C.success : C.muted,
                        shape: BoxShape.circle,
                        boxShadow: _streaming
                            ? [
                                BoxShadow(
                                    color: C.success.withValues(alpha: .7),
                                    blurRadius: 10,
                                    spreadRadius: 1)
                              ]
                            : [])),
              ]),
              const SizedBox(width: 10),
              Text(_streaming ? 'متصل — يبث مباشرة' : 'غير متصل',
                  style: TextStyle(
                      color: _streaming ? C.success : C.muted,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .5)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: C.primary.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: C.primary.withValues(alpha: .3)),
                ),
                child: Text('${_lines.length} سطر',
                    style: const TextStyle(
                        color: C.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'monospace')),
              ),
            ]),
          ),
        ),
        // Console
        Expanded(child: Container(
          margin: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A14),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: C.border),
            boxShadow: [
              BoxShadow(
                  color: C.primary.withValues(alpha: .06),
                  blurRadius: 24,
                  spreadRadius: 2),
            ],
          ),
          child: _lines.isEmpty
              ? Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: C.primary.withValues(alpha: .1),
                        border: Border.all(
                            color: C.primary.withValues(alpha: .3)),
                      ),
                      child: const Icon(Icons.terminal,
                          color: C.primary, size: 42),
                    )
                        .animate(onPlay: (c) => c.repeat())
                        .shimmer(
                            duration: 2.seconds,
                            color: C.accent.withValues(alpha: .4)),
                    const SizedBox(height: 14),
                    const Text('في انتظار الإخراج…',
                        style: TextStyle(
                            color: C.muted,
                            fontFamily: 'monospace',
                            fontSize: 12)),
                    const SizedBox(height: 6),
                    Text(
                        _streaming
                            ? 'سيظهر السجل تلقائياً عند البدء'
                            : 'اضغط ▶ أعلاه للاتصال',
                        style: TextStyle(
                            color: C.muted.withValues(alpha: .6),
                            fontSize: 10.5)),
                  ]))
              : Scrollbar(
                  controller: _scroll,
                  thumbVisibility: true,
                  child: ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(12),
                    itemCount: _lines.length,
                    itemBuilder: (_, i) => _LogRow(line: _lines[i]),
                  ),
                ),
        )),
        // Command bar
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
          child: _showCmd
              ? Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      C.primary.withValues(alpha: .12),
                      C.accent.withValues(alpha: .12),
                    ]),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: C.primary.withValues(alpha: .4)),
                    boxShadow: [
                      BoxShadow(
                          color: C.primary.withValues(alpha: .2),
                          blurRadius: 14,
                          spreadRadius: 1),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 2),
                  child: Row(children: [
                    const SizedBox(width: 8),
                    const Text('\$',
                        style: TextStyle(
                            color: C.success,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'monospace')),
                    const SizedBox(width: 8),
                    Expanded(
                        child: TextField(
                      controller: _cmd,
                      focusNode: _cmdFocus,
                      style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'اكتب أمراً…',
                        hintStyle:
                            TextStyle(color: C.muted, fontSize: 12),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 14),
                      ),
                      onSubmitted: (_) => _send(),
                    )),
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [C.primary, C.accent]),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                              color: C.primary.withValues(alpha: .5),
                              blurRadius: 10),
                        ],
                      ),
                      child: IconButton(
                        onPressed: _send,
                        icon: const Icon(Icons.send_rounded,
                            color: Colors.black, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                            minWidth: 40, minHeight: 40),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: () =>
                          setState(() => _showCmd = false),
                      icon: const Icon(Icons.close,
                          color: C.muted, size: 16),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 4),
                  ]))
              : TextButton.icon(
                  onPressed: () {
                    setState(() => _showCmd = true);
                    Future.delayed(const Duration(milliseconds: 120),
                        () => _cmdFocus.requestFocus());
                  },
                  icon: const Icon(Icons.keyboard_command_key,
                      color: C.primary, size: 18),
                  label: const Text('إرسال أمر',
                      style: TextStyle(
                          color: C.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5)),
                ),
        ),
      ])),
    );
  }

  Widget _glowBtn(
      {required VoidCallback onTap,
      required IconData icon,
      required Color color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: .35)),
            boxShadow: [
              BoxShadow(
                  color: color.withValues(alpha: .15),
                  blurRadius: 10),
            ],
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }
}

class _LogLine {
  final String text;
  final Color color;
  final bool isMeta;
  _LogLine(this.text, this.color, {this.isMeta = false});
}

class _LogRow extends StatelessWidget {
  final _LogLine line;
  const _LogRow({required this.line});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (line.isMeta)
          Container(
            width: 3,
            height: 16,
            margin: const EdgeInsets.only(right: 8, top: 2),
            decoration: BoxDecoration(
                color: line.color.withValues(alpha: .6),
                borderRadius: BorderRadius.circular(2)),
          )
        else
          const SizedBox(width: 11),
        Expanded(
            child: SelectableText(
          line.text,
          style: TextStyle(
            color: line.color,
            fontSize: 11.5,
            fontFamily: 'monospace',
            height: 1.5,
            fontWeight:
                line.isMeta ? FontWeight.w700 : FontWeight.w400,
          ),
        )),
      ]),
    );
  }
}
