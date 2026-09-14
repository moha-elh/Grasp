/// Short FSRS interval label for grading chips: "10m", "3h", "2d", "3mo", "1y".
/// Rounds to the largest sensible unit — cards are answered in a breath, the
/// label just needs to say roughly when it comes back.
String formatInterval(Duration d) {
  final mins = d.inMinutes;
  if (mins < 60) return '${mins < 1 ? 1 : mins}m';
  if (d.inHours < 24) return '${d.inHours}h';
  final days = d.inDays;
  if (days < 30) return '${days < 1 ? 1 : days}d';
  if (days < 365) return '${(days / 30).round()}mo';
  return '${(days / 365).round()}y';
}
