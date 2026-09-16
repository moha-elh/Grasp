import 'package:flutter_test/flutter_test.dart';
import 'package:grasp/features/review/source_note_text.dart';

void main() {
  test('cleanNoteBody strips frontmatter and tag lines, keeps headings/body', () {
    const raw = '---\ndate: 2024-01-01\ntags: [a, b]\n---\n'
        '# Title\n'
        '#flashcard #ml\n'
        'Real body text here.';
    final out = cleanNoteBody(raw);
    expect(out.contains('date:'), isFalse);
    expect(out.contains('#flashcard'), isFalse);
    expect(out.contains('# Title'), isTrue);
    expect(out.contains('Real body text here.'), isTrue);
  });

  test('splitOnQuote finds the passage despite whitespace differences', () {
    const note = 'Intro line.\nThe key idea   spans\nmultiple lines.\nOutro.';
    final p = splitOnQuote(note, 'The key idea spans multiple lines.');
    expect(p.match.isNotEmpty, isTrue);
    expect(p.before.contains('Intro line.'), isTrue);
    expect(p.after.contains('Outro.'), isTrue);
  });

  test('cleanNoteBody drops a References section and dataview fields', () {
    const raw = '# Title\n'
        'status:: done\n'
        'Body sentence.\n'
        '## References\n'
        '- [[Some Link]]\n'
        '- another';
    final out = cleanNoteBody(raw);
    expect(out.contains('status::'), isFalse);
    expect(out.contains('References'), isFalse);
    expect(out.contains('Some Link'), isFalse);
    expect(out.contains('Body sentence.'), isTrue);
  });

  test('splitOnQuote returns whole note when there is no match', () {
    final p = splitOnQuote('abc', 'xyz');
    expect(p.match, '');
    expect(p.before, 'abc');
    expect(p.after, '');
  });
}
