import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MovieData extends ChangeNotifier {
  String _title;
  DateWithPrecisionAndCountry _releaseDate;
  bool _bookmarked = false;

  bool _hasDetails = false;
  List<DateWithPrecisionAndCountry>? _releaseDates;
  List<String>? _genres;
  List<TitleInLanguage>? _titles;
  List<Review>? _reviews;

  MovieData(this._title, this._releaseDate);

  String get title {
    return _title;
  }

  DateWithPrecisionAndCountry get releaseDate {
    return _releaseDate;
  }

  bool get bookmarked {
    return _bookmarked;
  }

  List<DateWithPrecisionAndCountry>? get releaseDates {
    return _releaseDates;
  }

  List<String>? get genres {
    return _genres;
  }

  List<TitleInLanguage>? get titles {
    return _titles;
  }

  List<Review>? get reviews {
    return _reviews;
  }

  bool get hasDetails {
    return _hasDetails;
  }

  /// Updates the information with that of a new version of the movie
  /// but ignores fields that are user controlled, like whether the movie was bookmarked.
  void updateWithNewIgnoringUserControlled(MovieData movie) {
    setDetails(
        title: movie.title,
        releaseDate: movie.releaseDate,
        releaseDates: movie.releaseDates,
        genres: movie.genres,
        titles: movie.titles,
        reviews: movie.reviews);
  }

  void setDetails(
      {String? title,
      DateWithPrecisionAndCountry? releaseDate,
      bool? bookmarked,
      List<DateWithPrecisionAndCountry>? releaseDates,
      List<String>? genres,
      List<TitleInLanguage>? titles,
      List<Review>? reviews}) {
    if (title != null) {
      _title = title;
    }
    if (releaseDate != null) {
      _releaseDate = releaseDate;
    }
    if (bookmarked != null) {
      _bookmarked = bookmarked;
    }
    if (releaseDates != null) {
      _releaseDates = releaseDates;
    }
    if (genres != null) {
      _genres = genres;
    }
    if (titles != null) {
      _titles = titles;
    }
    if (reviews != null) {
      _reviews = reviews;
    }
    _hasDetails = true;
    notifyListeners();
  }

  @override
  String toString() {
    return "$title (${_releaseDate.toString()}${_genres?.isNotEmpty ?? true ? "; ${_genres?.join(", ")}" : ""})";
  }

  bool same(MovieData other) {
    return title == other.title && releaseDate.date == other.releaseDate.date;
  }

  Map toJsonEncodable() {
    List? releaseDatesByCountry =
        _releaseDates?.map((e) => e.toJsonEncodable()).toList();
    List? titlesByCountry = _titles?.map((e) => [e.title, e.language]).toList();
    return {
      "title": title,
      "releaseDate": _releaseDate.toJsonEncodable(),
      "bookmarked": _bookmarked,
      "releaseDates": releaseDatesByCountry,
      "genres": genres,
      "titles": titlesByCountry,
      "reviews": reviews?.map((review) => review.toJsonEncodable()).toList(),
    };
  }

  MovieData.fromJsonEncodable(Map json)
      : _title = json["title"],
        _releaseDate =
            DateWithPrecisionAndCountry.fromJsonEncodable(json["releaseDate"]) {
    setDetails(
        bookmarked: json["bookmarked"] as bool,
        genres: (json["genres"] as List<dynamic>?)
            ?.map((genre) => genre as String)
            .toList(),
        releaseDates: json["releaseDates"] != null
            ? (json["releaseDates"] as List<dynamic>)
                .map((release) =>
                    DateWithPrecisionAndCountry.fromJsonEncodable(release))
                .toList()
            : null,
        reviews: json["reviews"] != null
            ? (json["reviews"] as List<dynamic>)
                .map((review) => Review.fromJsonEncodable(review))
                .toList()
            : null,
        titles: json["titles"] != null
            ? (json["titles"] as List<dynamic>)
                .map((title) =>
                    (title: title[0], language: title[1]) as TitleInLanguage)
                .toList()
            : null);
  }
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

typedef TitleInLanguage = ({String title, String language});

class DateWithPrecisionAndCountry {
  DateTime date;
  DatePrecision precision;
  String country;

  DateWithPrecisionAndCountry(this.date, this.precision, this.country);

  DateWithPrecisionAndCountry.fromJsonEncodable(List<dynamic> json)
      : date = DateTime.parse(json[0]),
        precision = DatePrecision.values
            .firstWhere((element) => element.name == json[1]),
        country = json[2];

  toJsonEncodable() {
    return [date.toIso8601String(), precision.name, country];
  }

  @override
  String toString() {
    return "${toDateString()} ($country)";
  }

  String toDateString() {
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
}

class Review {
  String score;
  String by;
  DateTime asOf;
  int count;

  Review(this.score, this.by, this.asOf, this.count);
  Review.fromJsonEncodable(Map json)
      : score = json["score"],
        by = json["by"],
        asOf = DateTime.parse(json["asOf"]),
        count = json["count"];

  Map toJsonEncodable() {
    return {
      "score": score,
      "by": by,
      "asOf": asOf.toIso8601String(),
      "count": count,
    };
  }
}
