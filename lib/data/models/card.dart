import 'package:fsrs/fsrs.dart' as fsrs_pkg;

/// How/why vs. what - drives generation mix (FR-8) and analytics (FR-28).
enum CardType {
  anchor, // naming / definition
  mechanism, // why / how it works
  application, // when to use it
}

/// Where the card came from (FR-18, FR-19).
enum CardSource { notes, explore }

/// Lifecycle. Only `approved` cards enter review (FR-14, FR-26).
enum CardStatus { pending, approved, discarded, remakePending }

/// Quality axis, separate from FSRS grade (FR-24). null = un-rated.
enum Quality { liked, disliked }

/// One flashcard. Mirrors the `cards` table (§8).
class GraspCard {
  final String id;
  final String userId;
  final String front;
  final String back;
  final CardType cardType;
  final CardSource source;
  final String? sourcePath; // origin note path
  final String? sourceExcerpt; // trust layer (FR-20)
  final String? referenceUrl; // citation for Explore cards (FR-19)
  final CardStatus status;
  final Quality? quality;

  /// Full serialized FSRS card - the source of truth (§8).
  final Map<String, dynamic> fsrs;

  // Promoted columns for indexing/display (§8).
  final DateTime? due;
  final int reps; // "times seen" (FR-29)
  final int lapses;
  final String? cardState;

  final DateTime createdAt;
  final DateTime updatedAt;

  const GraspCard({
    required this.id,
    required this.userId,
    required this.front,
    required this.back,
    required this.cardType,
    required this.source,
    this.sourcePath,
    this.sourceExcerpt,
    this.referenceUrl,
    required this.status,
    this.quality,
    required this.fsrs,
    this.due,
    this.reps = 0,
    this.lapses = 0,
    this.cardState,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Rehydrate the live FSRS card from stored jsonb.
  fsrs_pkg.Card get fsrsCard => fsrs_pkg.Card.fromMap(fsrs);

  /// Concept = the origin note's name (analytics rolls up by note, §5.8).
  /// Derived from the note filename; empty for source-less Explore cards.
  String get conceptName {
    final base = (sourcePath ?? '').split('/').last;
    return base.replaceAll(RegExp(r'\.md$'), '');
  }

  factory GraspCard.fromJson(Map<String, dynamic> j) => GraspCard(
        id: j['id'] as String,
        userId: j['user_id'] as String,
        front: j['front'] as String,
        back: j['back'] as String,
        cardType: _enum(CardType.values, j['card_type']),
        source: _enum(CardSource.values, j['source']),
        sourcePath: j['source_path'] as String?,
        sourceExcerpt: j['source_excerpt'] as String?,
        referenceUrl: j['reference_url'] as String?,
        status: _statusFromDb(j['status'] as String),
        quality: j['quality'] == null
            ? null
            : _enum(Quality.values, j['quality']),
        fsrs: Map<String, dynamic>.from(j['fsrs'] as Map),
        due: j['due'] == null ? null : DateTime.parse(j['due'] as String),
        reps: (j['reps'] as int?) ?? 0,
        lapses: (j['lapses'] as int?) ?? 0,
        cardState: j['card_state'] as String?,
        createdAt: DateTime.parse(j['created_at'] as String),
        updatedAt: DateTime.parse(j['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'front': front,
        'back': back,
        'card_type': cardType.name,
        'source': source.name,
        'source_path': sourcePath,
        'source_excerpt': sourceExcerpt,
        'reference_url': referenceUrl,
        'status': _statusToDb(status),
        'quality': quality?.name,
        'fsrs': fsrs,
        'due': due?.toIso8601String(),
        'reps': reps,
        'lapses': lapses,
        'card_state': cardState,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  GraspCard copyWith({
    String? front,
    String? back,
    CardStatus? status,
    Quality? quality,
    Map<String, dynamic>? fsrs,
    DateTime? due,
    int? reps,
    int? lapses,
    String? cardState,
    DateTime? updatedAt,
  }) =>
      GraspCard(
        id: id,
        userId: userId,
        front: front ?? this.front,
        back: back ?? this.back,
        cardType: cardType,
        source: source,
        sourcePath: sourcePath,
        sourceExcerpt: sourceExcerpt,
        referenceUrl: referenceUrl,
        status: status ?? this.status,
        quality: quality ?? this.quality,
        fsrs: fsrs ?? this.fsrs,
        due: due ?? this.due,
        reps: reps ?? this.reps,
        lapses: lapses ?? this.lapses,
        cardState: cardState ?? this.cardState,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  // DB uses snake_case for the multi-word status value.
  static String _statusToDb(CardStatus s) =>
      s == CardStatus.remakePending ? 'remake_pending' : s.name;
  static CardStatus _statusFromDb(String s) => s == 'remake_pending'
      ? CardStatus.remakePending
      : _enum(CardStatus.values, s);

  static T _enum<T extends Enum>(List<T> values, Object? name) =>
      values.firstWhere((e) => e.name == name);
}
