import 'package:intl/intl.dart';

DateTime getToday() {
  DateTime now = DateTime.now().toUtc();
  return DateTime.utc(now.year, now.month, now.day);
}

enum DatePrecision { decade, year, month, day, hour, minute }

extension DatePrecisionComparison on DatePrecision {
  bool operator <(DatePrecision other) {
    return index < other.index;
  }

  bool operator <=(DatePrecision other) {
    return index <= other.index;
  }

  bool operator >(DatePrecision other) {
    return index > other.index;
  }

  bool operator >=(DatePrecision other) {
    return index >= other.index;
  }
}

DateTime simplifyDateToPrecision(DateTime date, DatePrecision precision) {
  switch (precision) {
    case DatePrecision.decade:
      return DateTime(date.year ~/ 10 * 10);
    case DatePrecision.year:
      return DateTime(date.year);
    case DatePrecision.month:
      return DateTime(date.year, date.month);
    case DatePrecision.day:
      return DateTime(date.year, date.month, date.day);
    case DatePrecision.hour:
      return DateTime(date.year, date.month, date.day, date.hour);
    case DatePrecision.minute:
      return DateTime(date.year, date.month, date.day, date.hour, date.minute);
  }
}

class DateWithPrecision implements Comparable<DateWithPrecision> {
  DateTime date;
  DatePrecision precision;

  DateWithPrecision(DateTime date, this.precision)
      : date = simplifyDateToPrecision(date, precision);

  DateWithPrecision.fromJsonEncodable(List<dynamic> json)
      : date = DateTime.parse(json[0]),
        precision = DatePrecision.values
            .firstWhere((element) => element.name == json[1]);

  DateWithPrecision.today() : this(DateTime.now().toUtc(), DatePrecision.day);
  DateWithPrecision.unspecified() : this(DateTime(0), DatePrecision.decade);

  List<dynamic> toJsonEncodable() {
    return [date.toIso8601String(), precision.name];
  }

  @override
  String toString() {
    return switch (precision) {
      DatePrecision.decade =>
        "${DateFormat("yyyy").format(date).substring(0, 3)}0s",
      DatePrecision.year => DateFormat.y().format(date),
      DatePrecision.month => DateFormat.yMMMM().format(date),
      DatePrecision.day => DateFormat.yMMMMd().format(date),
      DatePrecision.hour => DateFormat("MMMM d, yyyy, HH").format(date),
      DatePrecision.minute => DateFormat("MMMM d, yyyy, HH:mm").format(date)
    };
  }

  @override
  int compareTo(DateWithPrecision other) {
    if (date.isBefore(other.date)) {
      return -1;
    } else if (date.isAfter(other.date)) {
      return 1;
    } else {
      return precision.index - other.precision.index;
    }
  }

  @override
  bool operator ==(Object other) {
    return other is DateWithPrecision &&
        date == other.date &&
        precision == other.precision;
  }

  @override
  int get hashCode {
    return date.hashCode ^ precision.hashCode;
  }

  bool includes(DateTime date) {
    switch (precision) {
      case DatePrecision.decade:
        return this.date.year ~/ 10 == date.year ~/ 10;
      case DatePrecision.year:
        return this.date.year == date.year;
      case DatePrecision.month:
        return this.date.year == date.year && this.date.month == date.month;
      case DatePrecision.day:
        return this.date.year == date.year &&
            this.date.month == date.month &&
            this.date.day == date.day;
      case DatePrecision.hour:
        return this.date.year == date.year &&
            this.date.month == date.month &&
            this.date.day == date.day &&
            this.date.hour == date.hour;
      case DatePrecision.minute:
        return this.date.year == date.year &&
            this.date.month == date.month &&
            this.date.day == date.day &&
            this.date.hour == date.hour &&
            this.date.minute == date.minute;
    }
  }
}

class Dated<T> {
  final T value;
  final DateTime date;

  Dated(this.value, this.date);

  Dated.now(this.value) : date = DateTime.now().toUtc();
  Dated.outdated(this.value) : date = DateTime(0);

  bool isOutdated(Duration maxAge) {
    return DateTime.now().toUtc().difference(date) > maxAge;
  }

  Dated.fromJsonEncodable(
      dynamic json, T Function(dynamic) valueFromJsonEncodable)
      : value = valueFromJsonEncodable(json["value"]),
        date = DateTime.parse(json["date"]);

  Map<String, dynamic> toJsonEncodable(
      dynamic Function(T) valueToJsonEncodable) {
    return {
      "value": valueToJsonEncodable(value),
      "date": date.toIso8601String()
    };
  }

  @override
  toString() => "$value as of $date";
}
