import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import '../utils/constants.dart';

class CodeViewer extends StatelessWidget {
  final String code;
  final String filename;
  final bool showCopy;

  const CodeViewer({
    super.key,
    required this.code,
    this.filename = 'file.txt',
    this.showCopy = true,
  });

  String get _language {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'py': return 'python';
      case 'dart': return 'dart';
      case 'js': case 'mjs': return 'javascript';
      case 'ts': return 'typescript';
      case 'json': return 'json';
      case 'yml': case 'yaml': return 'yaml';
      case 'sh': case 'bash': return 'bash';
      case 'html': return 'xml';
      case 'css': return 'css';
      case 'md': return 'markdown';
      case 'sql': return 'sql';
      case 'java': return 'java';
      case 'kt': return 'kotlin';
      case 'c': return 'c';
      case 'cpp': case 'cc': case 'h': return 'cpp';
      case 'go': return 'go';
      case 'rs': return 'rust';
      case 'php': return 'php';
      case 'rb': return 'ruby';
      case 'txt': return 'plaintext';
      default: return 'plaintext';
    }
  }

  @override
  Widget build(BuildContext context) {
    final lines = code.split('\n');
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      // header
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E2E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          border: Border(bottom: BorderSide(color: C.border)),
        ),
        child: Row(children: [
          Container(width: 12, height: 12,
              decoration: const BoxDecoration(
                  color: Color(0xFFFF5F57), shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Container(width: 12, height: 12,
              decoration: const BoxDecoration(
                  color: Color(0xFFFFBD2E), shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Container(width: 12, height: 12,
              decoration: const BoxDecoration(
                  color: Color(0xFF27CA40), shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Expanded(child: Text(filename,
              style: const TextStyle(
                color: C.muted, fontSize: 11,
                fontFamily: 'monospace', fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis)),
          Text('${lines.length} lines',
              style: const TextStyle(color: C.muted, fontSize: 10)),
          if (showCopy) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: code));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Copied to clipboard'),
                  duration: Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ));
              },
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.copy, color: C.primary, size: 16),
              ),
            ),
          ],
        ]),
      ),
      // code
      Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A24),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: MediaQuery.of(context).size.width - 32,
            ),
            child: HighlightView(
              code,
              language: _language,
              theme: monokaiSublimeTheme,
              padding: const EdgeInsets.all(14),
              textStyle: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12.5,
                height: 1.5,
              ),
            ),
          ),
        ),
      ),
    ]);
  }
}
