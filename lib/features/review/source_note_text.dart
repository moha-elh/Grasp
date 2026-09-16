// Pure text helpers for the source-note view. Kept UI-free so they can be
// unit-tested: clean an Obsidian note down to readable prose, and locate the
// card's source passage within it for highlighting.

/// Strip the metadata the user does not want to read (frontmatter, tag-only
/// lines) and unwrap Obsidian wiki-links, leaving the note body prose.
/// Metadata labels stripped wherever they head a line (frontmatter, dataview,
/// or plain "Label: value"): the date/tags/status/refs the reader does not want.
final _metaLabel = RegExp(
    r'^(date|created|updated|modified|time|tags?|status|aliases?|alias|author|'
    r'source|sources|link|links|references?|related|see also|url|cssclass(?:es)?|'
    r'publish|up|prev|previous|next|category|categories|type)\b\s*:{1,2}',
    caseSensitive: false);

String _stripFrontmatter(String raw) => raw.replaceAll('\r\n', '\n').replaceFirst(
    RegExp(r'^﻿?\s*---[ \t]*\n.*?\n(---|\.\.\.)[ \t]*(\n|$)', dotAll: true),
    '');

String cleanNoteBody(String raw) {
  var s = _stripFrontmatter(raw);
  // Remove a References / Related / Links / Sources SECTION: the heading plus
  // its following non-heading lines, stopping at the next heading (never to the
  // end of the note, which would wipe everything after an early such heading).
  s = s.replaceAll(
      RegExp(
          r'^#{1,6}[ \t]*(references|related|links|sources|see also)\b.*(?:\n(?!#).*)*',
          multiLine: true,
          caseSensitive: false),
      '');
  // Unwrap [[link|alias]] -> alias, [[link]] -> link.
  s = s.replaceAllMapped(RegExp(r'\[\[([^\]|]+)\|([^\]]+)\]\]'), (m) => m[2]!);
  s = s.replaceAllMapped(RegExp(r'\[\[([^\]]+)\]\]'), (m) => m[1]!);
  s = s
      .split('\n')
      .where((l) {
        final t = l.trim();
        if (t.isEmpty) return true;
        // Tag-only lines (headings "# Title" survive: the hash is followed by a
        // space, not word characters).
        if (RegExp(r'^(#[A-Za-z0-9_/-]+\s*)+$').hasMatch(t)) return false;
        // Labeled metadata: "date: ...", "tags:: ...", "**Status**: done", etc.
        // Strip emphasis markers first so "**Author**:" is still recognised.
        final probe = t.replaceAll(RegExp(r'[*_`]'), '');
        if (_metaLabel.hasMatch(probe)) return false;
        return true;
      })
      .join('\n');
  s = s.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
  // Safety net: never return an empty note when the source had real content.
  if (s.length < 4 && raw.trim().length >= 12) return _stripFrontmatter(raw).trim();
  return s;
}

/// Split [note] around the first occurrence of [quote], tolerant of whitespace
/// differences (the stored quote is often re-flowed). If [quote] is null/blank
/// or not found, the whole note is returned as `before` with an empty `match`.
({String before, String match, String after}) splitOnQuote(
    String note, String? quote) {
  final q = quote?.trim() ?? '';
  if (q.isEmpty) return (before: note, match: '', after: '');
  // Match word-by-word with flexible whitespace between tokens.
  final pattern = q.split(RegExp(r'\s+')).map(RegExp.escape).join(r'\s+');
  final re = RegExp(pattern, caseSensitive: false, dotAll: true);
  final m = re.firstMatch(note);
  if (m == null) return (before: note, match: '', after: '');
  return (
    before: note.substring(0, m.start),
    match: note.substring(m.start, m.end),
    after: note.substring(m.end),
  );
}
