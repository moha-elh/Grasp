import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/providers.dart';
import '../../../data/models/card.dart';
import '../../../design/tokens.dart';
import '../../../design/typography.dart';
import '../source_note_text.dart';
import 'markdown_note.dart';

/// Screen 04 · Source note (FR-20). Reads the whole vault note (frontmatter,
/// tags and refs stripped) with the card's source passage highlighted, so the
/// user can see where the card came from in context. Explore cards have no
/// vault note, so they list their cited web resources instead - one line per
/// link, as "concept: link". Concept detail passes the whole concept group so
/// every resource of that concept shows.
class SourceNoteSheet extends ConsumerStatefulWidget {
  final GraspCard card;
  final List<GraspCard>? group;
  const SourceNoteSheet(this.card, {super.key, this.group});

  @override
  ConsumerState<SourceNoteSheet> createState() => _SourceNoteSheetState();
}

class _SourceNoteSheetState extends ConsumerState<SourceNoteSheet> {
  Future<String>? _note;

  @override
  void initState() {
    super.initState();
    final path = widget.card.sourcePath;
    if (path != null && path.isNotEmpty) {
      _note = ref.read(dropboxProvider).downloadNote(path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    final title = card.conceptName.isNotEmpty ? card.conceptName : 'Source';
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, scroll) => Padding(
        padding: const EdgeInsets.fromLTRB(T.gutter, T.s8, T.gutter, T.s24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SOURCE NOTE', style: Typo.mono(size: 10, color: T.accent)),
            const SizedBox(height: T.s8),
            Text(title, style: Typo.display(20)),
            const SizedBox(height: T.s12),
            Expanded(child: _body(scroll, card)),
          ],
        ),
      ),
    );
  }

  Widget _body(ScrollController scroll, GraspCard card) {
    // Explore card: no vault note, just its cited web resource(s).
    if (_note == null) {
      // One line per resource across the concept, as "concept name: link".
      // Concept detail passes the whole group, so every source is listed.
      final group = widget.group;
      final resources = (group ?? [card])
          .where((c) => c.referenceUrl != null && c.referenceUrl!.isNotEmpty)
          .toList();
      return ListView(controller: scroll, children: [
        if (group == null &&
            card.sourceExcerpt != null &&
            card.sourceExcerpt!.isNotEmpty)
          MarkdownNote(cleanNoteBody(card.sourceExcerpt!)),
        if (resources.isNotEmpty) ...[
          const SizedBox(height: T.s18),
          Text('RESOURCES', style: Typo.mono(size: 10, color: T.accent)),
          const SizedBox(height: T.s8),
          for (final c in resources) _resource(c),
        ],
      ]);
    }
    return FutureBuilder<String>(
      future: _note,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator(color: T.accent));
        }
        if (snap.hasError || snap.data == null) {
          return ListView(controller: scroll, children: [
            MarkdownNote(cleanNoteBody(card.sourceExcerpt ?? '')),
            const SizedBox(height: T.s12),
            Text('Could not load the full note.',
                style: Typo.meta.copyWith(color: T.slipping)),
          ]);
        }
        final body = cleanNoteBody(snap.data!);
        return ListView(
          controller: scroll,
          children: [
            if (body.trim().isEmpty)
              Text('This note has no readable content.',
                  style: Typo.body.copyWith(color: T.inkMeta))
            else
              MarkdownNote(body, highlight: card.sourceExcerpt),
          ],
        );
      },
    );
  }

  /// One resource line, "<source name>: <link>", tappable to open the source.
  Widget _resource(GraspCard c) => Padding(
        padding: const EdgeInsets.only(bottom: T.s8),
        child: GestureDetector(
          onTap: () => launchUrl(Uri.parse(c.referenceUrl!),
              mode: LaunchMode.externalApplication),
          child: Text('${c.sourceName}: ${c.referenceUrl}',
              style: Typo.meta.copyWith(
                  color: T.accent, decoration: TextDecoration.underline)),
        ),
      );
}
