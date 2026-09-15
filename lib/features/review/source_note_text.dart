// Pure text helpers for the source-note view. Kept UI-free so they can be
// unit-tested: clean an Obsidian note down to readable prose, and locate the
// card's source passage within it for highlighting.

/// Strip the metadata the user does not want to read (frontmatter, tag-only
/// lines) and unwrap Obsidian wiki-links, leaving the note body prose.
String cleanNoteBody(String raw) {
  var s = raw.replaceAll('\r\n', '\n');
  // Leading YAML frontmatter block (date, tags, refs live here).
  s = s.replaceFirst(RegExp(r'^---\n.*?\n---\n', dotAll: true), '');
  // Unwrap [[link|alias]] -> alias, [[link]] -> link.
  s = s.replaceAllMapped(RegExp(r'\[\[([^\]|]+)\|([^\]]+)\]\]'), (m) => m[2]!);
  s = s.replaceAllMapped(RegExp(r'\[\[([^\]]+)\]\]'), (m) => m[1]!);
  // Drop lines that are only hashtags (headings like "# Title" are kept, since
  // the hash there is followed by a space, not word characters).
  s = s
      .split('\n')
      .where((l) {
        final t = l.trim();
        if (t.isEmpty) return true;
        return !RegExp(r'^(#[A-Za-z0-9_/-]+\s*)+$').hasMatch(t);
      })
      .join('\n');
  // Collapse runs of blank lines.
  s = s.replaceAll(RegExp(r'\n{3,}'), '\n\n');
  return s.trim();
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
