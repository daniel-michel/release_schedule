import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
    String dateString = switch (precision) {
      DatePrecision.decade || DatePrecision.year => date.year.toString(),
      DatePrecision.month => DateFormat("MMMM yyyy").format(date),
      DatePrecision.day => DateFormat("MMMM d, yyyy").format(date),
      DatePrecision.hour => DateFormat("MMMM d, yyyy, HH").format(date),
      DatePrecision.minute => DateFormat("MMMM d, yyyy, HH:mm").format(date)
    };
    return "$dateString ($country)";
  }
}

enum DatePrecision { decade, year, month, day, hour, minute }

class MovieData extends ChangeNotifier {
  String _title;
  DateWithPrecisionAndCountry _releaseDate;

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

  void updateWithNew(MovieData movie) {
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

  Map toJsonEncodable() {
    List? releaseDatesByCountry =
        _releaseDates?.map((e) => e.toJsonEncodable()).toList();
    List? titlesByCountry = _titles?.map((e) => [e.title, e.language]).toList();
    return {
      "title": title,
      "releaseDate": _releaseDate.toJsonEncodable(),
      "releaseDates": releaseDatesByCountry,
      "genres": genres,
      "titles": titlesByCountry,
      "reviews": reviews,
    };
  }

  bool same(MovieData other) {
    return title == other.title && releaseDate == other.releaseDate;
  }

  MovieData.fromJsonEncodable(Map json)
      : _title = json["title"],
        _releaseDate =
            DateWithPrecisionAndCountry.fromJsonEncodable(json["releaseDate"]) {
    setDetails(
        genres: (json["genres"] as List<dynamic>?)
            ?.map((genre) => genre as String)
            .toList(),
        releaseDates: json["releaseDates"] != null
            ? (json["releaseDates"] as List<List<dynamic>>)
                .map((release) =>
                    DateWithPrecisionAndCountry.fromJsonEncodable(release))
                .toList()
            : null,
        reviews: json["reviews"] != null
            ? (json["reviews"] as List<Map<String, dynamic>>)
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
