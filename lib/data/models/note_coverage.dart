/// Tracks background-generation rotation so under-carded notes get picked
/// next (FR-7). Mirrors the `note_coverage` table (§8).
class NoteCoverage {
  final String? id;
  final String userId;
  final String sourcePath;
  final DateTime? lastGeneratedAt;
  final int cardsGenerated;

  const NoteCoverage({
    this.id,
    required this.userId,
    required this.sourcePath,
    this.lastGeneratedAt,
    this.cardsGenerated = 0,
  });

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'user_id': userId,
        'source_path': sourcePath,
        'last_generated_at': lastGeneratedAt?.toIso8601String(),
        'cards_generated': cardsGenerated,
      };

  factory NoteCoverage.fromJson(Map<String, dynamic> j) => NoteCoverage(
        id: j['id'] as String?,
        userId: j['user_id'] as String,
        sourcePath: j['source_path'] as String,
        lastGeneratedAt: j['last_generated_at'] == null
            ? null
            : DateTime.parse(j['last_generated_at'] as String),
        cardsGenerated: (j['cards_generated'] as int?) ?? 0,
      );
}
