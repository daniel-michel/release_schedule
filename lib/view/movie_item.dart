import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:release_schedule/model/movie.dart';

String durationApproximatedInWords(Duration duration) {
  int seconds = duration.inSeconds;
  int minutes = duration.inMinutes;
  int hours = duration.inHours;
  int days = duration.inDays;
  int weeks = (days / 7).floor();
  int months = (days / 30).floor();
  int years = (days / 365).floor();
  int centuries = (years / 100).floor();
  if (duration == Duration.zero) {
    return "now";
  }
  if (seconds == 0) {
    return "now";
  }
  if (seconds < 60) {
    return seconds > 1 ? "$seconds seconds" : "a second";
  }
  if (minutes < 60) {
    return minutes > 1 ? "$minutes minutes" : "a minute";
  }
  if (hours < 24) {
    return hours > 1 ? "$hours hours" : "an hour";
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

String durationToRelativeTimeString(Duration duration) {
  if (duration.isNegative) {
    return "${durationApproximatedInWords(-duration)} ago";
  } else if (duration == Duration.zero) {
    return "now";
  } else {
    return "in ${durationApproximatedInWords(duration)}";
  }
}

String dateRelativeToNow(DateTime date) {
  DateTime dateOnly = DateTime.utc(date.year, date.month, date.day);
  DateTime now = DateTime.now().toUtc();
  DateTime today = DateTime.utc(now.year, now.month, now.day);
  Duration diff = dateOnly.difference(today);
  return durationToRelativeTimeString(diff);
}

class MovieItem extends StatelessWidget {
  final MovieData movie;
  const MovieItem(this.movie, {super.key});

  @override
  Widget build(BuildContext context) {
    final format = DateFormat(DateFormat.YEAR_MONTH_DAY);

    return AnimatedBuilder(
      animation: movie,
      builder: (context, widget) {
        return ListTile(
            title: Text(movie.title),
            subtitle: Text(
                "${dateRelativeToNow(movie.releaseDate)}, ${format.format(movie.releaseDate)}"));
      },
    );
  }
}
