/// Compares dates relative to each other. Times are ignored.
String dateRelativeToNow(DateTime date) {
  DateTime dateOnly = DateTime.utc(date.year, date.month, date.day);
  DateTime now = DateTime.now().toUtc();
  DateTime today = DateTime.utc(now.year, now.month, now.day);
  Duration diff = dateOnly.difference(today);
  return _durationToRelativeDateString(diff);
}

String _durationToRelativeDateString(Duration duration) {
  if (duration == const Duration(days: 1)) {
    return "Tomorrow";
  } else if (duration == const Duration(days: -1)) {
    return "Yesterday";
  }
  if (duration.isNegative) {
    String result = _durationApproximatedInWords(-duration);
    return "${result[0].toUpperCase()}${result.substring(1)} ago";
  } else if (duration == Duration.zero) {
    return "Today";
  } else {
    return "In ${_durationApproximatedInWords(duration)}";
  }
}

String _durationApproximatedInWords(Duration duration) {
  int days = duration.inDays;
  int weeks = (days / 7).floor();
  int months = (days / 30).floor();
  int years = (days / 365).floor();
  int centuries = (years / 100).floor();
  if (duration == Duration.zero) {
    return "now";
  }
  if (days < 7) {
    return days > 1 ? "$days days" : "a day";
  }
  if (months == 0) {
    return weeks > 1 ? "$weeks weeks" : "a week";
  }
  if (years == 0) {
    return months > 1 ? "$months months" : "a month";
  }
  if (years < 100) {
    return years > 1 ? "$years years" : "a year";
  }
  return centuries > 1 ? "$centuries centuries" : "a century";
}
