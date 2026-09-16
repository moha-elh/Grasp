import 'package:flutter/material.dart';

import '../../../design/tokens.dart';
import '../../../design/typography.dart';
import '../source_note_text.dart';

/// A small, dependency-free Markdown renderer for the source note. Handles the
/// subset Obsidian notes actually use (headings, bold/italic/code, bullets,
/// blockquotes) and shades the line(s) the card was drawn from, so the reader
/// sees where it came from in context.
class MarkdownNote extends StatelessWidget {
  final String text;
  final String? highlight;
  const MarkdownNote(this.text, {super.key, this.highlight});

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');
    // Locate the highlighted passage in the whole text, then map it to lines.
    final p = splitOnQuote(text, highlight);
    final hlStart = p.match.isEmpty ? -1 : p.before.length;
    final hlEnd = p.match.isEmpty ? -1 : p.before.length + p.match.length;

    final widgets = <Widget>[];
    var offset = 0;
    for (final line in lines) {
      final start = offset;
      final end = offset + line.length;
      offset = end + 1; // +1 for the '\n'
      final highlighted =
          hlStart >= 0 && start < hlEnd && end > hlStart && line.trim().isNotEmpty;
      widgets.add(_line(line, highlighted));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _line(String raw, bool highlighted) {
    final line = raw.trimRight();
    if (line.trim().isEmpty) return const SizedBox(height: T.s12);

    // Headings.
    final h = RegExp(r'^(#{1,6})\s+(.*)$').firstMatch(line);
    if (h != null) {
      final level = h.group(1)!.length;
      final size = level <= 1 ? 21.0 : (level == 2 ? 18.0 : 16.0);
      return _block(
        highlighted,
        Padding(
          padding: const EdgeInsets.only(top: T.s12, bottom: T.s4),
          child: Text.rich(
            TextSpan(children: _inline(h.group(2)!, _heading(size))),
          ),
        ),
      );
    }

    // Blockquote.
    final q = RegExp(r'^>\s?(.*)$').firstMatch(line);
    if (q != null) {
      return _block(
        highlighted,
        Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.only(left: T.s12),
          decoration: const BoxDecoration(
            border: Border(left: BorderSide(color: T.hairline, width: 3)),
          ),
          child: Text.rich(TextSpan(
              children: _inline(q.group(1)!,
                  Typo.body.copyWith(color: T.inkMeta, fontStyle: FontStyle.italic)))),
        ),
      );
    }

    // Bullet list item.
    final b = RegExp(r'^[-*+]\s+(.*)$').firstMatch(line);
    if (b != null) {
      return _block(
        highlighted,
        Padding(
          padding: const EdgeInsets.only(left: T.s8, top: 2, bottom: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('•  ', style: Typo.body.copyWith(color: T.inkMeta)),
              Expanded(
                  child: Text.rich(
                      TextSpan(children: _inline(b.group(1)!, Typo.body)))),
            ],
          ),
        ),
      );
    }

    // Plain paragraph line.
    return _block(
      highlighted,
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text.rich(TextSpan(children: _inline(line, Typo.body))),
      ),
    );
  }

  Widget _block(bool highlighted, Widget child) {
    if (!highlighted) return child;
    return Container(
      width: double.infinity,
      color: T.accent.withValues(alpha: 0.14),
      padding: const EdgeInsets.symmetric(horizontal: T.s8, vertical: 1),
      child: child,
    );
  }

  TextStyle _heading(double size) =>
      Typo.body.copyWith(fontSize: size, fontWeight: FontWeight.w700, color: T.ink);

  /// Parse **bold**, *italic* / _italic_, and `code` into styled spans.
  List<InlineSpan> _inline(String text, TextStyle base) {
    final spans = <InlineSpan>[];
    final re = RegExp(r'(\*\*.+?\*\*)|(\*.+?\*|_.+?_)|(`.+?`)');
    var last = 0;
    for (final m in re.allMatches(text)) {
      if (m.start > last) {
        spans.add(TextSpan(text: text.substring(last, m.start), style: base));
      }
      final tok = m.group(0)!;
      if (tok.startsWith('**')) {
        spans.add(TextSpan(
            text: tok.substring(2, tok.length - 2),
            style: base.copyWith(fontWeight: FontWeight.w700, color: T.ink)));
      } else if (tok.startsWith('`')) {
        spans.add(TextSpan(
            text: tok.substring(1, tok.length - 1), style: Typo.mono(size: 13)));
      } else {
        spans.add(TextSpan(
            text: tok.substring(1, tok.length - 1),
            style: base.copyWith(fontStyle: FontStyle.italic)));
      }
      last = m.end;
    }
    if (last < text.length) {
      spans.add(TextSpan(text: text.substring(last), style: base));
    }
    return spans;
  }
}
