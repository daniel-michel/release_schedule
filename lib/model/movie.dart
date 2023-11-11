import 'package:flutter/material.dart';

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

typedef ReleaseDateInCountry = (String country, DateTime date);
typedef TitleInCountry = (String country, String title);

enum DatePrecision { decade, year, month, day, hour, minute }

class MovieData extends ChangeNotifier {
  String _title;
  DateTime _releaseDate;
  DatePrecision _releaseDatePrecision;

  bool _hasDetails = false;
  List<ReleaseDateInCountry>? _releaseDates;
  List<String>? _genres;
  List<TitleInCountry>? _titles;
  List<Review>? _reviews;

  MovieData(this._title, this._releaseDate, this._releaseDatePrecision);

  String get title {
    return _title;
  }

  DateTime get releaseDate {
    return _releaseDate;
  }

  DatePrecision get releaseDatePrecision {
    return _releaseDatePrecision;
  }

  List<ReleaseDateInCountry>? get releaseDates {
    return _releaseDates;
  }

  List<String>? get genres {
    return _genres;
  }

  List<TitleInCountry>? get titles {
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
        releaseDatePrecision: movie.releaseDatePrecision,
        releaseDates: movie.releaseDates,
        genres: movie.genres,
        titles: movie.titles,
        reviews: movie.reviews);
  }

  void setDetails(
      {String? title,
      DateTime? releaseDate,
      DatePrecision? releaseDatePrecision,
      List<ReleaseDateInCountry>? releaseDates,
      List<String>? genres,
      List<TitleInCountry>? titles,
      List<Review>? reviews}) {
    if (title != null) {
      _title = title;
    }
    if (releaseDate != null) {
      _releaseDate = releaseDate;
    }
    if (releaseDatePrecision != null) {
      _releaseDatePrecision = releaseDatePrecision;
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
    return "$title (${releaseDate.year}${_genres?.isNotEmpty ?? true ? "; ${_genres?.join(", ")}" : ""})";
  }

  Map toJsonEncodable() {
    List? releaseDatesByCountry =
        _releaseDates?.map((e) => [e.$1, e.$2.toIso8601String()]).toList();
    List? titlesByCountry = _titles?.map((e) => [e.$1, e.$2]).toList();
    return {
      "title": title,
      "releaseDate": releaseDate.toIso8601String(),
      "releaseDatePrecision": _releaseDatePrecision.name,
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
        _releaseDate = DateTime.parse(json["releaseDate"]),
        _releaseDatePrecision = DatePrecision.values.firstWhere(
            (element) => element.name == json["releaseDatePrecision"]) {
    setDetails(
        genres: json["genres"],
        releaseDates: json["releaseDates"] != null
            ? (json["releaseDates"] as List<List<dynamic>>)
                .map((release) => ((release[0], DateTime.parse(release[1]))
                    as ReleaseDateInCountry))
                .toList()
            : null,
        reviews: json["reviews"] != null
            ? (json["reviews"] as List<Map<String, dynamic>>)
                .map((review) => Review.fromJsonEncodable(review))
                .toList()
            : null,
        titles: json["titles"] != null
            ? (json["titles"] as List<dynamic>)
                .map((title) => (title[0], title[1]) as TitleInCountry)
                .toList()
            : null);
  }
}
