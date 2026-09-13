/// One review event. Mirrors the `review_logs` table (§8). Feeds analytics
/// and future FSRS optimization. `rating`: 1 again, 2 hard, 3 good, 4 easy.
class ReviewLog {
  final String? id;
  final String userId;
  final String cardId;
  final int rating;
  final DateTime reviewedAt;
  final int elapsedDays;
  final int scheduledDays;

  const ReviewLog({
    this.id,
    required this.userId,
    required this.cardId,
    required this.rating,
    required this.reviewedAt,
    required this.elapsedDays,
    required this.scheduledDays,
  });

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'user_id': userId,
        'card_id': cardId,
        'rating': rating,
        'reviewed_at': reviewedAt.toIso8601String(),
        'elapsed_days': elapsedDays,
        'scheduled_days': scheduledDays,
      };

  factory ReviewLog.fromJson(Map<String, dynamic> j) => ReviewLog(
        id: j['id'] as String?,
        userId: j['user_id'] as String,
        cardId: j['card_id'] as String,
        rating: j['rating'] as int,
        reviewedAt: DateTime.parse(j['reviewed_at'] as String),
        elapsedDays: (j['elapsed_days'] as int?) ?? 0,
        scheduledDays: (j['scheduled_days'] as int?) ?? 0,
      );
}
